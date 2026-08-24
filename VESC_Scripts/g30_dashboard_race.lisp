; G30 dashboard support lisp script v1.3 by Izuna and AKA13
; Tested with VESC 7.00 on Spintend Ubox Single 85 200
; Based on https://github.com/1zun4/vesc_scooter_support - licensed GPL-3.0,
; so this fork is GPL-3.0 too (see LICENSE in the repository root).
;
; Custom fork: adds a "Race" profile alongside the "Original" profile.
; Tuned for a 72V pack on a Ubox. Switch profiles by double-pressing the
; button while holding brake AND throttle at the same time (toggles the
; "unlock" state -> Race profile; same gesture switches back).
; NOTE: battery voltage/cutoffs for the 72V pack are NOT set here - configure
; those in the VESC motor/battery config (VESC Tool), this script only reads
; get-batt() which already accounts for whatever cutoffs you set there.
;
; This is v3.2. Full version history in CHANGELOG.md in the repository.

; -> Installation
; UART Wiring: red=5V black=GND yellow=COM-TX (UART-HDX) green=COM-RX (button)+3.3V with 1K Resistor
; Guide (German): https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/

; =====================================================================
;  QUICK-EDIT PARAMETERS - change these for day-to-day tuning. Everything
;  below "Code starts here" is implementation, only touch it if you know
;  what you're doing.
; =====================================================================

; --- 1) Speed profiles ------------------------------------------------
; speed = km/h target (max-speed) | current = current-scale, 0-1 (fraction
; of your configured motor max current) | watts = watt ceiling | fw = field
; weakening current in A (0 = off)

; Original profile (default on power-up/lock)
(def eco-speed         (/ 15 3.6))   (def eco-current         0.6)  (def eco-watts         450)     (def eco-fw         0)
(def drive-speed       (/ 20 3.6))   (def drive-current       0.7)  (def drive-watts       650)     (def drive-fw       0)
(def sport-speed       (/ 22 3.6))   (def sport-current       1.0)  (def sport-watts       1000)    (def sport-fw       0)

; Race profile (2x button press while holding brake+throttle to toggle)
(def race-eco-speed    (/ 200 3.6))  (def race-eco-current    1.0)  (def race-eco-watts    100000)  (def race-eco-fw    20)
(def race-drive-speed  (/ 35 3.6))   (def race-drive-current  1.0)  (def race-drive-watts  100000)  (def race-drive-fw  0)
(def race-sport-speed  (/ 48 3.6))   (def race-sport-current  1.0)  (def race-sport-watts  100000)  (def race-sport-fw  0)

(def race-enabled 1) ; 0 disables the Race-profile toggle gesture entirely (brake+throttle+2x press just does lock/unlock instead)

; --- 2) Dashboard display ---------------------------------------------
; Two fields, four slots each (standing still / riding, per profile).
;
;   MAIN  = the big number in the middle.
;   BLINK = the error-code field -> anything non-zero shows up RED BLINKING.
;           A real VESC fault always wins here, so it can never hide an error.
;
; Codes:  0 speed km/h   1 battery %   2 motor temp   3 controller temp
;         4 trip km      5 cell volt x10 (41 = 4.1V)  6 off
;
; Code 5 needs si-battery-cells set in VESC Tool, otherwise it shows 0.

;                        standing still        riding
(def show-normal-idle    0)   (def show-normal-ride    0)  ; Original: always km/h
(def show-race-idle      1)   (def show-race-ride      0)  ; Race: battery when stopped, km/h when riding

(def blink-normal-idle   6)   (def blink-normal-ride   6)  ; Original: nothing blinking, ever
(def blink-race-idle     6)   (def blink-race-ride     2)  ; Race: motor temp blinking red while riding

; --- 3) Alarm ---------------------------------------------------------
; Anti-theft alarm for when the scooter is switched OFF (long button press).
; If it gets rolled or pushed while off, the display flashes and beeps.
; The scooter stays switched off the whole time - the alarm only changes
; what is sent to the display, it never enables the motor.
(def alarm-enabled 1)  ; 1 = alarm on, 0 = off
(def alarm-speed 2)    ; km/h - movement above this while off sets it off
(def alarm-seconds 10) ; s - how long it flashes and beeps per trigger

; --- 4) Tuning / hardware behavior ------------------------------------
(def software-adc 1)
(def min-adc-throttle 0.3) ; V - throttle-held threshold for button gestures (raised from 0.1 to avoid ADC drift/noise false-triggering)
(def min-adc-brake 0.3) ; V - brake-held threshold for button gestures (raised from 0.1 to avoid ADC drift/noise false-triggering)
(def temp-warning-motor 100) ; degC - motor temp warning icon threshold
(def temp-warning-fet 80) ; degC - FET temp warning icon threshold
(def min-speed 1) ; km/h - minimum speed to enable throttle and brake
(def button-safety-speed (/ 0.1 3.6)) ; km/h - button gestures only register below this speed (safety)
(def speed-limit-start 0.5) ; fraction of max-speed where the speed governor starts tapering current (VESC default 0.8) - lower = earlier/more gradual taper, less noise when you hit the cap

; -> Code starts here (DO NOT CHANGE ANYTHING BELOW THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING)

; Load VESC CAN code serer
(import "pkg@://vesc_packages/lib_code_server/code_server.vescpkg" 'code-server)
(read-eval-program code-server)

; Button handling
(def press-time (systime))
(def presses 0)

; Mode states
(def off 0)
(def lock 0)
(def speedmode 4)
(def light 0)
(def unlock 0) ; unlock = 1 means Race profile is active

; sound feedback
(def feedback 0)

; alarm state
(def alarm-active 0)         ; 1 while the alarm is going off
(def alarm-time (systime))   ; when the current burst started
(def alarm-tick 0)           ; frame counter, drives the flashing

; last fault code seen, for print-fault below
(def last-fault 0)

; Best-effort map from a VESC fault code (get-fault, see mc_fault_code in
; the VESC firmware) to the closest matching real Ninebot G30 dashboard
; error code, so the dash shows a code you can actually look up instead of
; VESC's internal fault number. There is no official VESC <-> Ninebot
; cross-reference - these are two unrelated fault systems - so this is an
; approximation, not an authoritative table. Encoder/resolver faults
; (codes 11-13, 20-30) don't apply to this hardware (the G30 hub motor has
; neither) and fall back to the generic "10" comm/control-board code.
(defun fault-to-ninebot(code)
    (cond
        ((= code 0) 0)   ; FAULT_CODE_NONE -> no error
        ((= code 1) 19)  ; OVER_VOLTAGE -> abnormal battery voltage
        ((= code 2) 19)  ; UNDER_VOLTAGE -> abnormal battery voltage
        ((= code 3) 11)  ; DRV -> motor phase current abnormal
        ((= code 4) 11)  ; ABS_OVER_CURRENT -> motor phase current abnormal
        ((= code 5) 40)  ; OVER_TEMP_FET -> control board temperature abnormal
        ((= code 6) 41)  ; OVER_TEMP_MOTOR -> motor temperature abnormal
        ((= code 7) 19)  ; GATE_DRIVER_OVER_VOLTAGE -> battery voltage abnormal
        ((= code 8) 19)  ; GATE_DRIVER_UNDER_VOLTAGE -> battery voltage abnormal
        ((= code 9) 19)  ; MCU_UNDER_VOLTAGE -> battery voltage abnormal
        ((= code 14) 50) ; FLASH_CORRUPTION -> firmware/setup error
        ((= code 15) 11) ; HIGH_OFFSET_CURRENT_SENSOR_1
        ((= code 16) 12) ; HIGH_OFFSET_CURRENT_SENSOR_2
        ((= code 17) 13) ; HIGH_OFFSET_CURRENT_SENSOR_3
        ((= code 18) 11) ; UNBALANCED_CURRENTS
        ((= code 19) 15) ; BRK -> brake sensor abnormal
        ((= code 23) 50) ; FLASH_CORRUPTION_APP_CFG -> firmware/setup error
        ((= code 24) 50) ; FLASH_CORRUPTION_MC_CFG -> firmware/setup error
        ((= code 27) 11) ; PHASE_FILTER
        ((= code 29) 19) ; LV_OUTPUT_FAULT -> battery voltage abnormal
        (t 10) ; anything else (incl. encoder/resolver faults) -> generic comm/control-board error
    )
)

; Prints to the VESC Tool terminal whenever the fault code changes, so real
; VESC faults are visible while testing, alongside the Ninebot-style code
; shown on the dashboard.
(defun print-fault()
    {
        (var current-fault (get-fault))
        (if (not (= current-fault last-fault))
            {
                (print (str-merge "VESC fault " (str-from-n last-fault) " -> " (str-from-n current-fault)
                    " (dash shows Ninebot code " (str-from-n (fault-to-ninebot current-fault)) ")"))
                (set 'last-fault current-fault)
            }
        )
    }
)

(defun adc-input(buffer) ; Frame 0x65
    {
        (let ((throttle (/(bufget-u8 uart-buf 5) 77.2)) ; 255/3.3 = 77.2
            (brake (/(bufget-u8 uart-buf 6) 77.2)))
            {
                (if (< throttle 0)
                    (setf throttle 0))
                (if (> throttle 3.3)
                    (setf throttle 3.3))
                (if (< brake 0)
                    (setf brake 0))
                (if (> brake 3.3)
                    (setf brake 3.3))

                ; Pass through throttle and brake to VESC
                (app-adc-override 0 throttle)
                (app-adc-override 1 brake)
            }
        )
    }
)

(defun handle-features()
    {
        (var current-speed (* (get-lowest-speed) 3.6))

        (if (or (or (= off 1) (= lock 1) (< current-speed min-speed)))
            (if (not (app-is-output-disabled)) ; Disable output when scooter is turned off
                {
                    (app-adc-override 0 0)
                    (app-adc-override 1 0)
                    (app-disable-output -1)
                    (set-current 0)
                    ; rcode canset
                    ;(loopforeach i (can-list-devs)
                    ;    (canset-current i 0)
                    ;)
                }
            )
            (if (app-is-output-disabled) ; Enable output when scooter is turned on
                (app-disable-output 0)
            )
        )

        (handle-lock)
        (handle-alarm (abs current-speed))
        (print-fault)
    }
)

; Picks which of a field's four configured slots applies right now:
; Original vs Race profile (unlock), standing still vs riding (moving).
(defun pick-display(normal-idle normal-ride race-idle race-ride moving)
    (if (= unlock 1)
        (if moving race-ride race-idle)
        (if moving normal-ride normal-idle)
    )
)

; Keeps a value inside the 0-255 range a dashboard frame byte can hold
; (temperatures can go negative in winter, distance can grow past 255).
(defun clamp-u8(v)
    (if (< v 0)
        0
        (if (> v 255) 255 v)
    )
)

; Turns a display code (see the table at the top of the file) into the
; number actually written into the dashboard frame.
(defun dash-value(code speed battery)
    (clamp-u8
        (cond
            ((= code 0) speed)                ; speed in km/h
            ((= code 1) battery)              ; battery %
            ((= code 2) (get-temp-mot))       ; motor temperature
            ((= code 3) (get-temp-fet))       ; controller/FET temperature
            ((= code 4) (/ (get-dist) 1000))  ; trip distance, get-dist is in meters
            ((= code 5)                       ; cell voltage x10, 0 if cell count unset
                (let ((cells (conf-get 'si-battery-cells)))
                    (if (> cells 0) (* (/ (get-vin) cells) 10) 0)
                )
            )
            (t 0)                             ; 6 (or anything else) = off
        )
    )
)

; Fills the whole dashboard frame while the alarm is going off. While the
; scooter is off the dash is told "mode 16 = off" and shows nothing, so to
; make it flash the alarm alternates between a lit-up display (mode + light
; + battery) and the blank off display. The buzzer field is set on every
; frame, so it beeps continuously. Toggling every 3rd frame keeps the flash
; slow enough to read instead of a fast flicker.
(defun dash-alarm-frame(battery)
    {
        (set 'alarm-tick (+ alarm-tick 1))
        (if (< (mod alarm-tick 6) 3)
            {
                (bufset-u8 tx-frame 7 speedmode) ; display lit up
                (bufset-u8 tx-frame 8 battery)
                (bufset-u8 tx-frame 9 1)         ; light on
                (bufset-u8 tx-frame 11 0)
                (bufset-u8 tx-frame 12 0)
            }
            {
                (bufset-u8 tx-frame 7 16)        ; display blank (off)
                (bufset-u8 tx-frame 8 0)
                (bufset-u8 tx-frame 9 0)         ; light off
                (bufset-u8 tx-frame 11 0)
                (bufset-u8 tx-frame 12 0)
            }
        )
        (bufset-u8 tx-frame 10 1) ; beep, the whole time
    }
)

(defun update-dash(buffer) ; Frame 0x64
    {
        (var current-speed (abs (* (get-lowest-speed) 3.6)))
        (var battery (*(get-batt) 100))
        (var moving (> current-speed 1))

        (if (= alarm-active 1)
            (dash-alarm-frame battery) ; alarm takes over the whole display
            {

            ; mode field (1=drive, 2=eco, 4=sport, 8=charge, 16=off, 32=lock)
            (if (= off 1)
                (bufset-u8 tx-frame 7 16)
                (if (= lock 1)
                    (bufset-u8 tx-frame 7 32) ; lock display
                    (if (or (> (get-temp-fet) temp-warning-fet) (> (get-temp-mot) temp-warning-motor)) ; temp icon will show up above warning degree
                        (bufset-u8 tx-frame 7 (+ 128 speedmode))
                        (bufset-u8 tx-frame 7 speedmode)
                    )
                )
            )

            ; batt field
            (if (= lock 1)
                (bufset-u8 tx-frame 8 0) ; lock display
                (bufset-u8 tx-frame 8 battery)
            )

            ; light field
            (if (= off 0)
                (bufset-u8 tx-frame 9 light)
                (bufset-u8 tx-frame 9 0)
            )

            ; beep field
            (if (> feedback 0)
                {
                    (bufset-u8 tx-frame 10 1)
                    (set 'feedback (- feedback 1))
                }
                (bufset-u8 tx-frame 10 0)
            )

            ; main field - content configured at the top of the file
            (if (= lock 1)
                (bufset-u8 tx-frame 11 0) ; lock display
                (bufset-u8 tx-frame 11
                    (dash-value
                        (pick-display show-normal-idle show-normal-ride show-race-idle show-race-ride moving)
                        current-speed battery))
            )

            ; blink field (the dash's error-code field, shows red and blinking).
            ; A real VESC fault always wins here and is shown as a Ninebot G30
            ; error code; only when there is no fault is the field free for the
            ; readout configured at the top of the file.
            (if (= (get-fault) 0)
                (if (= lock 1)
                    (bufset-u8 tx-frame 12 0) ; lock display
                    (bufset-u8 tx-frame 12
                        (dash-value
                            (pick-display blink-normal-idle blink-normal-ride blink-race-idle blink-race-ride moving)
                            current-speed battery))
                )
                (bufset-u8 tx-frame 12 (fault-to-ninebot (get-fault)))
            )

            } ; end of the normal (non-alarm) display
        )

        ; calc crc

        (var crcout 0)
        (looprange i 2 13
        (set 'crcout (+ crcout (bufget-u8 tx-frame i))))
        (set 'crcout (bitwise-xor crcout 0xFFFF))
        (bufset-u8 tx-frame 13 crcout)
        (bufset-u8 tx-frame 14 (shr crcout 8))

        ; write
        (uart-write tx-frame)
    }
)

(defun read-frames()
    (loopwhile t
        {
            (uart-read-bytes uart-buf 3 0)
            (if (= (bufget-u16 uart-buf 0) 0x5aa5)
                {
                    (var len (bufget-u8 uart-buf 2))
                    (var crc len)
                    (if (and (> len 0) (< len 60)) ; max 64 bytes
                        {
                            (uart-read-bytes uart-buf (+ len 6) 0) ;read remaining 6 bytes + payload, overwrite buffer

                            (let ((code (bufget-u8 uart-buf 2)) (checksum (bufget-u16 uart-buf (+ len 4))))
                                {
                                    (looprange i 0 (+ len 4) (set 'crc (+ crc (bufget-u8 uart-buf i))))

                                    (if (= checksum (bitwise-and (+ (shr (bitwise-xor crc 0xFFFF) 8) (shl (bitwise-xor crc 0xFFFF) 8)) 65535)) ;If the calculated checksum matches with sent checksum, forward comman
                                        (handle-frame code)
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
    )
)

(defun handle-frame(code)
    {
        (if (and (= code 0x65) (= software-adc 1))
            (adc-input uart-buf)
        )

        (if(= code 0x64)
            (update-dash uart-buf)
        )
    }
)

(defun handle-button()
    (if (= presses 1) ; single press
        (if (= off 1) ; is it off? turn on scooter again
            {
                (set 'off 0) ; turn on
                (set 'feedback 1) ; beep feedback
                (set 'unlock 0) ; Disable Race profile on turn off
                (apply-mode) ; Apply mode on start-up
                (stats-reset) ; reset stats when turning on
            }
            (if (= lock 1) ; is it locked?
                (set 'feedback 1) ; beep feedback
                (set 'light (bitwise-xor light 1)) ; toggle light
            )

        )
        (if (>= presses 2) ; double press
            {
                (if (> (get-adc-decoded 1) min-adc-brake) ; if brake is pressed
                    (if (and (= race-enabled 1) (> (get-adc-decoded 0) min-adc-throttle))
                        {
                            (set 'unlock (bitwise-xor unlock 1)) ; toggle Original <-> Race profile
                            (set 'feedback 2) ; beep 2x
                            (apply-mode)
                        }
                        {
                            (set 'unlock 0)
                            (apply-mode)
                            (set 'lock (bitwise-xor lock 1)) ; lock on or off
                            (set 'light 0) ; turn off light when locking
                            (set 'feedback 1) ; beep feedback
                        }
                    )
                    {
                        (if (= lock 0)
                            {
                                (cond
                                    ((= speedmode 1) (set 'speedmode 4))
                                    ((= speedmode 2) (set 'speedmode 1))
                                    ((= speedmode 4) (set 'speedmode 2))
                                )
                                (apply-mode)
                            }
                        )
                    }
                )
            }
        )
    )
)

(defun handle-holding-button()
    {
        (if (= (+ lock off) 0) ; it is locked and off?
            {
                (set 'light 0) ; turn off light
                (set 'feedback 1) ; beep feedback
                (set 'unlock 0) ; Disable Race profile on turn off
                (apply-mode)
                (set 'off 1) ; turn off
            }
        )
    }
)

(defun reset-button()
    {
        (set 'press-time (systime)) ; reset press time again
        (set 'presses 0)
    }
)

; Speed mode implementation
(defun apply-mode()
    (if (= unlock 0)
        (cond
            ((= speedmode 1) (configure-speed drive-speed drive-watts drive-current drive-fw))
            ((= speedmode 2) (configure-speed eco-speed eco-watts eco-current eco-fw))
            ((= speedmode 4) (configure-speed sport-speed sport-watts sport-current sport-fw))
        )
        (cond
            ((= speedmode 1) (configure-speed race-drive-speed race-drive-watts race-drive-current race-drive-fw))
            ((= speedmode 2) (configure-speed race-eco-speed race-eco-watts race-eco-current race-eco-fw))
            ((= speedmode 4) (configure-speed race-sport-speed race-sport-watts race-sport-current race-sport-fw))
        )
    )
)

(defun configure-speed(speed watts current fw)
    {
        (set-param 'max-speed speed)
        (set-param 'l-watt-max watts)
        (set-param 'l-current-max-scale current)
        (set-param 'foc-fw-current-max fw)
        (set-param 'l-erpm-start speed-limit-start)
    }
)

(defun set-param(param value)
    {
        (conf-set param value)
        (loopforeach id (can-list-devs)
            (looprange i 0 5 {
                (if (eq (rcode-run id 0.1 `(conf-set (quote ,param) ,value)) t) (break t))
                false
            })
        )
    }
)

; Lock is a plain immobilizer - it just cuts throttle, no forced auto-brake.
(defun handle-lock()
    (if (= lock 1)
        (set-current-rel 0) ; No current input when locked
    )
)

; Anti-theft alarm, only while the scooter is switched OFF. Rolling or
; pushing it above alarm-speed starts a burst of alarm-seconds. If it is
; still being moved when the burst ends, the next one starts right away, so
; it keeps going as long as the scooter moves and falls silent a few seconds
; after it stops. This only sets a flag - the flashing and beeping itself is
; done in dash-alarm-frame, and the motor stays disabled throughout.
(defun handle-alarm(speed)
    (if (and (= alarm-enabled 1) (= off 1))
        {
            (if (and (= alarm-active 0) (> speed alarm-speed))
                {
                    (set 'alarm-active 1)
                    (set 'alarm-time (systime))
                    (set 'alarm-tick 0)
                }
            )
            (if (and (= alarm-active 1) (> (secs-since alarm-time) alarm-seconds))
                (set 'alarm-active 0)
            )
        }
        (set 'alarm-active 0) ; switched on, or alarm disabled -> never active
    )
)

(defun get-lowest-speed()
    {
        (var speed (get-speed))
        (loopforeach i (can-list-devs)
            {
                (var can-speed (canget-speed i))
                (if (< can-speed speed)
                    (set 'speed can-speed)
                )
            }
        )

        speed
    }
)

; Reads the button pin as a 3-sample majority vote over 60ms (20ms apart)
; instead of a single raw read, so a brief noise/EMI glitch on the shared
; button/UART line (e.g. from a hard e-brake pull) doesn't get read as a
; real press by itself - it needs 2 of 3 samples to agree. Same polarity as
; a raw gpio-read: 0 = pressed, 1 = not pressed (pin-rx is pulled up).
(defun read-button-pin()
    {
        (var sample-num 3)
        (var sample-sum 0)
        (looprange i 0 sample-num
            {
                (sleep 0.02)
                (setq sample-sum (+ sample-sum (gpio-read 'pin-rx)))
            }
        )
        (if (> sample-sum (/ sample-num 2)) 1 0)
    }
)

(defun button-logic()
    {
        ; Assume button is not pressed by default
        (var buttonold 0)
        (loopwhile t
            {
                (var button (read-button-pin))

                (if (> buttonold button)
                    (if (<= (get-speed) button-safety-speed) ; only count presses while actually stationary
                        {
                            (set 'presses (+ presses 1))
                            (set 'press-time (systime))
                        }
                        (reset-button) ; moving (e.g. spinning down under e-brake) - discard, not a real button press
                    )
                    (button-apply button)
                )

                (set 'buttonold button)
                (handle-features)
            }
        )
    }
)

(defun button-apply(button)
    {
        (var time-passed (- (systime) press-time))
        (var is-active (or (= off 1) (<= (get-speed) button-safety-speed)))

        (if (> time-passed 2500) ; after 2500 ms
            (if (= button 0) ; check button is still pressed
                (if (> time-passed 6000) ; long press after 6000 ms
                    {
                        (if is-active
                            (handle-holding-button)
                        )
                        (reset-button) ; reset button
                    }
                )
                (if (> presses 0) ; if presses > 0
                    {
                        (if is-active
                            (handle-button) ; handle button presses
                        )
                        (reset-button) ; reset button
                    }
                )
            )
        )
    )
)

(defun main () {
        ; Packet handling
        (uart-start 115200 'half-duplex)
        (gpio-configure 'pin-rx 'pin-mode-in-pu)
        (define tx-frame (array-create 15))
        (bufset-u16 tx-frame 0 0x5AA5) ;Ninebot protocol
        (bufset-u8 tx-frame 2 0x06) ;Payload length is 5 bytes
        (bufset-u16 tx-frame 3 0x2021) ; Packet is from ESC to BLE
        (bufset-u16 tx-frame 5 0x6400) ; Packet is from ESC to BLE
        (def uart-buf (array-create 64))

        (if (= software-adc 1)
            (app-adc-detach 3 1)
            (app-adc-detach 3 0)
        )

        ; Apply mode on start-up
        (apply-mode)

        ; Spawn UART reading frames thread
        (spawn 150 read-frames)
        (button-logic) ; Start button logic in main thread - this will block the main thread
})

(image-save)
(main)

; Version history: see CHANGELOG.md in the repository, which lists every
; version, what is new in it and what it fixes:
; https://github.com/ShrillingFly/Lejipy-g30-vesc-lisb-scribt/blob/main/CHANGELOG.md
