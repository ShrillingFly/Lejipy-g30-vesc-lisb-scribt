; G30 dashboard support lisp script v1.3 by Izuna and AKA13
; Tested with VESC 7.00 on Spintend Ubox Single 85 200
;
; Custom fork: adds a "Race" profile alongside the "Original" profile.
; Tuned for a 72V pack on a Ubox.
;   - Original profile: stock eco/drive/sport limits (unchanged from upstream).
;   - Race profile: eco = highest speed cap / max power, no field weakening;
;                    drive = capped at ~35 km/h, no field weakening;
;                    sport = capped at ~45-50 km/h, no field weakening.
; Switch profiles by double-pressing the button while holding brake AND throttle
; at the same time (this toggles the existing "unlock" state -> Race profile).
; NOTE: battery voltage/cutoffs for the 72V pack are NOT set here - configure
; those in the VESC motor/battery config (VESC Tool), this script only reads
; get-batt() which already accounts for whatever cutoffs you set there.
;
; v1.4 changes (troubleshooting a real dashboard):
;   - min-adc-throttle/min-adc-brake raised from 0.1 -> 0.3V. At 0.1V a small
;     ADC zero-offset/noise on the brake line was enough to make the button
;     logic think the brake was constantly held, which made every double-press
;     fall into the lock/race-toggle branch instead of ever cycling
;     eco/drive/sport. This only affects the button GESTURE detection, not the
;     actual throttle/brake pass-through (that still uses the raw ADC value).
;     If mode-cycling is still unreliable, recalibrate ADC in VESC Tool ->
;     App Settings -> ADC (check the resting voltage is near 0 for both lines).
;   - race-eco/drive/sport-watts lowered from 1500000 -> 20000 W and
;     race-eco-speed lowered from 999 -> 80 km/h. Passing a physically
;     impossible target (near-infinite watts, a speed the motor can't reach
;     without field weakening) makes the control loop hold max duty trying to
;     get there, which is a likely cause of the "b3" (DRV / fault code 3)
;     shown on the dashboard. 20000 W / 80 km/h is still far beyond what a
;     G30 hub motor can do, so it still behaves as "no real limit" - tune
;     these down to your actual motor/battery max current in VESC Tool if
;     you want a real, hardware-matched ceiling instead.
;   - Added fault-code printing to the VESC Tool terminal (see print-fault
;     below) so you can see exactly when/what faults trip while testing.
;
; v1.5 changes:
;   - Race watt ceilings opened back up (20000 -> 100000 W), and
;     race-eco-speed raised again (80 -> 200 km/h). Real power delivery is
;     throttle-proportional (the ADC pass-through), not something max-speed/
;     l-watt-max force on their own - those are just ceilings, so raising
;     them doesn't make the controller push current on its own. Only
;     race-eco-speed/watts are "wide open"; race-drive (35 km/h) and
;     race-sport (~48 km/h) keep their explicit speed targets, just with
;     the same opened-up watt ceiling.
;   - The dashboard's error field (and print-fault) now show a best-effort
;     mapping to real Ninebot G30 error codes (fault-to-ninebot, see below)
;     instead of VESC's raw internal fault number. VESC and Ninebot use two
;     completely unrelated fault-code systems (there is no official VESC
;     <-> Ninebot cross-reference) - this maps each VESC fault to the
;     closest matching real Ninebot code (e.g. VESC FAULT_CODE_BRK -> "15"
;     brake sensor abnormal, VESC FAULT_CODE_DRV -> "11" motor phase current
;     abnormal) so what you see on the dash is a code you can actually look
;     up. Codes with no sane G30 equivalent (encoder/resolver faults - this
;     hardware has neither) fall back to "10" (generic comm/control-board
;     error).
;
; v1.6 changes:
;   - Removed the whole alarm/anti-theft subsystem: no more gyro/speed
;     movement detection, no siren tones, no forced full-power auto-brake
;     while locked. Locking (double-press without throttle/brake held) now
;     only does the immobilizer part - cuts throttle, nothing else. All the
;     "alarm" state, start-alarm/stop-alarm, play-tone/stop-tone and
;     get-gyro code is gone.
;   - No "walk mode" existed in this script to begin with, so there was
;     nothing to remove for that.

; -> Installation
; UART Wiring: red=5V black=GND yellow=COM-TX (UART-HDX) green=COM-RX (button)+3.3V with 1K Resistor
; Guide (German): https://rollerplausch.com/threads/vesc-controller-einbau-1s-pro2-g30.6032/

; -> User parameters (change these to your needs)
(def software-adc 1)
(def min-adc-throttle 0.3) ; raised from 0.1 - avoids false "throttle held" from ADC drift/noise
(def min-adc-brake 0.3) ; raised from 0.1 - avoids false "brake held" from ADC drift/noise
(def temp-warning-motor 100) ; temperature warning for motor in degree celsius
(def temp-warning-fet 80) ; temperature warning for fet in degree celsius
(def show-batt-in-idle 1)
(def min-speed 1) ; minimum speed in km/h to enable throttle and brake
(def button-safety-speed (/ 0.1 3.6)) ; disabling button above 0.1 km/h (due to safety reasons)

; Original profile - speed modes (km/h, watts, current scale)
(def eco-speed (/ 7 3.6))
(def eco-current 0.6)
(def eco-watts 400)
(def eco-fw 0)
(def drive-speed (/ 17 3.6))
(def drive-current 0.7)
(def drive-watts 500)
(def drive-fw 0)
(def sport-speed (/ 22 3.6))
(def sport-current 1.0)
(def sport-watts 700)
(def sport-fw 0)

; Race profile. To enable, press the button 2 times while holding brake and throttle at the same time.
; (press again the same way to switch back to the Original profile above)
(def race-enabled 1)
(def race-eco-speed (/ 200 3.6)) ; wide open, no real cap - see v1.5 notes above
(def race-eco-current 1.0) ; max power (scale of configured motor max current)
(def race-eco-watts 100000) ; wide open, no real cap - actual power still comes from the throttle
(def race-eco-fw 0) ; no field weakening
(def race-drive-speed (/ 35 3.6))
(def race-drive-current 1.0)
(def race-drive-watts 100000) ; watt ceiling opened up - speed cap above is what actually limits this mode
(def race-drive-fw 0) ; no field weakening
(def race-sport-speed (/ 48 3.6)) ; chill 45-50 km/h, adjust to taste
(def race-sport-current 1.0)
(def race-sport-watts 100000) ; watt ceiling opened up - speed cap above is what actually limits this mode
(def race-sport-fw 0) ; no field weakening

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
        (print-fault)
    }
)

(defun update-dash(buffer) ; Frame 0x64
    {
        (var current-speed (abs (* (get-lowest-speed) 3.6)))
        (var battery (*(get-batt) 100))

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

        (if (= lock 1)
            (bufset-u8 tx-frame 11 0) ; lock display
            (if (= (+ show-batt-in-idle unlock) 2)
                (if (> current-speed 1)
                    (bufset-u8 tx-frame 11 current-speed)
                    (bufset-u8 tx-frame 11 battery))
                (bufset-u8 tx-frame 11 current-speed)
            )
        )

        ; error field - shown as a real Ninebot G30 error code
        (bufset-u8 tx-frame 12 (fault-to-ninebot (get-fault)))

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

; No alarm/anti-theft system - lock just cuts throttle, no siren, no gyro
; monitoring, no forced auto-brake.
(defun handle-lock()
    (if (= lock 1)
        (set-current-rel 0) ; No current input when locked
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

(defun button-logic()
    {
        ; Assume button is not pressed by default
        (var buttonold 0)
        (loopwhile t
            {
                (var button (gpio-read 'pin-rx))
                (sleep 0.03) ; wait 30 ms to debounce
                (var buttonconfirm (gpio-read 'pin-rx))
                (if (not (= button buttonconfirm))
                    (set 'button 0)
                )

                (if (> buttonold button)
                    {
                        (set 'presses (+ presses 1))
                        (set 'press-time (systime))
                    }
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
