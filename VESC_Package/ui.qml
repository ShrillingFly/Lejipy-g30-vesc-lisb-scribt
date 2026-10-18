import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Vedder.vesc.commands 1.0
import Vedder.vesc.utility 1.0

Item {
    id: root
    anchors.fill: parent

    property Commands mCommands: VescIf.commands()

    // Order matches the display codes in the lisp script (0-6)
    readonly property var displayNames: [
        "km/h", "Akku %", "Motortemperatur", "Controllertemperatur",
        "Tageskilometer", "Zellspannung x10", "Aus"
    ]

    // Every setting the script knows: name in the lisp script, control, kind,
    // decimals, allowed range and the label used in error messages
    readonly property var fields: [
        { name: "software-adc", item: softwareAdc, kind: "flag" },
        { name: "temp-warning-motor", item: tempWarningMotor, kind: "real", dec: 0, min: 0, max: 200, label: "Warnung Motortemp." },
        { name: "temp-warning-fet", item: tempWarningFet, kind: "real", dec: 0, min: 0, max: 200, label: "Warnung Controllertemp." },
        { name: "min-speed", item: minSpeed, kind: "real", dec: 1, min: 0, max: 50, label: "Anfahrgeschwindigkeit" },
        { name: "speed-limit-start", item: speedLimitStart, kind: "real", dec: 2, min: 0.1, max: 1, label: "Limit-Übergang" },
        { name: "min-adc-throttle", item: minAdcThrottle, kind: "real", dec: 2, min: 0.05, max: 1, label: "Gas-Schwelle" },
        { name: "min-adc-brake", item: minAdcBrake, kind: "real", dec: 2, min: 0.05, max: 1, label: "Brems-Schwelle" },

        { name: "eco-speed", item: ecoSpeed, kind: "real", dec: 1, min: 0, max: 300, label: "Original Eco km/h" },
        { name: "eco-current", item: ecoCurrent, kind: "real", dec: 2, min: 0, max: 1, label: "Original Eco Strom" },
        { name: "eco-watts", item: ecoWatts, kind: "real", dec: 0, min: 0, max: 1000000, label: "Original Eco Watt" },
        { name: "eco-fw", item: ecoFw, kind: "real", dec: 1, min: 0, max: 100, label: "Original Eco Field Weakening" },
        { name: "drive-speed", item: driveSpeed, kind: "real", dec: 1, min: 0, max: 300, label: "Original Drive km/h" },
        { name: "drive-current", item: driveCurrent, kind: "real", dec: 2, min: 0, max: 1, label: "Original Drive Strom" },
        { name: "drive-watts", item: driveWatts, kind: "real", dec: 0, min: 0, max: 1000000, label: "Original Drive Watt" },
        { name: "drive-fw", item: driveFw, kind: "real", dec: 1, min: 0, max: 100, label: "Original Drive Field Weakening" },
        { name: "sport-speed", item: sportSpeed, kind: "real", dec: 1, min: 0, max: 300, label: "Original Sport km/h" },
        { name: "sport-current", item: sportCurrent, kind: "real", dec: 2, min: 0, max: 1, label: "Original Sport Strom" },
        { name: "sport-watts", item: sportWatts, kind: "real", dec: 0, min: 0, max: 1000000, label: "Original Sport Watt" },
        { name: "sport-fw", item: sportFw, kind: "real", dec: 1, min: 0, max: 100, label: "Original Sport Field Weakening" },
        { name: "show-normal-idle", item: showNormalIdle, kind: "code" },
        { name: "show-normal-ride", item: showNormalRide, kind: "code" },
        { name: "blink-normal-idle", item: blinkNormalIdle, kind: "code" },
        { name: "blink-normal-ride", item: blinkNormalRide, kind: "code" },

        { name: "race-enabled", item: raceEnabled, kind: "flag" },
        { name: "race-eco-speed", item: raceEcoSpeed, kind: "real", dec: 1, min: 0, max: 300, label: "Race Eco km/h" },
        { name: "race-eco-current", item: raceEcoCurrent, kind: "real", dec: 2, min: 0, max: 1, label: "Race Eco Strom" },
        { name: "race-eco-watts", item: raceEcoWatts, kind: "real", dec: 0, min: 0, max: 1000000, label: "Race Eco Watt" },
        { name: "race-eco-fw", item: raceEcoFw, kind: "real", dec: 1, min: 0, max: 100, label: "Race Eco Field Weakening" },
        { name: "race-drive-speed", item: raceDriveSpeed, kind: "real", dec: 1, min: 0, max: 300, label: "Race Drive km/h" },
        { name: "race-drive-current", item: raceDriveCurrent, kind: "real", dec: 2, min: 0, max: 1, label: "Race Drive Strom" },
        { name: "race-drive-watts", item: raceDriveWatts, kind: "real", dec: 0, min: 0, max: 1000000, label: "Race Drive Watt" },
        { name: "race-drive-fw", item: raceDriveFw, kind: "real", dec: 1, min: 0, max: 100, label: "Race Drive Field Weakening" },
        { name: "race-sport-speed", item: raceSportSpeed, kind: "real", dec: 1, min: 0, max: 300, label: "Race Sport km/h" },
        { name: "race-sport-current", item: raceSportCurrent, kind: "real", dec: 2, min: 0, max: 1, label: "Race Sport Strom" },
        { name: "race-sport-watts", item: raceSportWatts, kind: "real", dec: 0, min: 0, max: 1000000, label: "Race Sport Watt" },
        { name: "race-sport-fw", item: raceSportFw, kind: "real", dec: 1, min: 0, max: 100, label: "Race Sport Field Weakening" },
        { name: "show-race-idle", item: showRaceIdle, kind: "code" },
        { name: "show-race-ride", item: showRaceRide, kind: "code" },
        { name: "blink-race-idle", item: blinkRaceIdle, kind: "code" },
        { name: "blink-race-ride", item: blinkRaceRide, kind: "code" },

        { name: "alarm-enabled", item: alarmEnabled, kind: "flag" },
        { name: "alarm-speed", item: alarmSpeed, kind: "real", dec: 1, min: 0.5, max: 50, label: "Alarm ab" },
        { name: "alarm-seconds", item: alarmSeconds, kind: "real", dec: 0, min: 1, max: 120, label: "Alarmdauer" },
        { name: "overheat-temp", item: overheatTemp, kind: "real", dec: 0, min: 40, max: 200, label: "Überhitzung ab" },
        { name: "overheat-release", item: overheatRelease, kind: "real", dec: 0, min: 30, max: 200, label: "Wieder frei unter" }
    ]

    // Editing is blocked until every setting arrived, empty fields would save as zero
    property var loadedNames: ({})
    property int loadedCount: 0
    readonly property bool settingsLoaded: loadedCount === fields.length

    // Commands still waiting to be confirmed by the script
    property var saveQueue: []
    property bool saving: false

    function sendCode(str) {
        mCommands.sendCustomAppData(str + "\0")
    }

    function findField(name) {
        for (var i = 0; i < fields.length; i++) {
            if (fields[i].name === name) {
                return fields[i]
            }
        }
        return null
    }

    // Accepts both "15.5" and "15,5"
    function parseNumber(text) {
        return Number.parseFloat(String(text).replace(",", "."))
    }

    function setFieldValue(f, value) {
        var number = parseNumber(value)
        if (!Number.isFinite(number)) {
            return false
        }

        if (f.kind === "flag") {
            f.item.checked = number === 1
        } else if (f.kind === "code") {
            var index = Math.round(number)
            if (index < 0 || index >= f.item.count) {
                return false
            }
            f.item.currentIndex = index
        } else {
            f.item.text = number.toFixed(f.dec)
        }
        return true
    }

    function fieldValue(f) {
        if (f.kind === "flag") {
            return f.item.checked ? "1" : "0"
        }
        if (f.kind === "code") {
            return String(f.item.currentIndex)
        }
        return parseNumber(f.item.text).toFixed(f.dec)
    }

    // Returns an error message, or "" when every value is in range
    function checkFields() {
        for (var i = 0; i < fields.length; i++) {
            var f = fields[i]
            if (f.kind !== "real") {
                continue
            }
            var number = parseNumber(f.item.text)
            if (!Number.isFinite(number) || number < f.min || number > f.max) {
                return f.label + ": erlaubt " + f.min + " bis " + f.max
            }
        }
        if (parseNumber(overheatRelease.text) >= parseNumber(overheatTemp.text)) {
            return "\"Wieder frei unter\" muss kleiner sein als \"Überhitzung ab\""
        }
        return ""
    }

    function getSettings() {
        loadedNames = ({})
        loadedCount = 0
        sendCode("(send-settings)")
    }

    function applySettingsLine(line) {
        var parts = line.split(" ")
        for (var i = 1; i < parts.length; i++) {
            var pair = parts[i].split("=")
            if (pair.length !== 2) {
                continue
            }
            var f = findField(pair[0])
            if (f !== null && setFieldValue(f, pair[1]) && !loadedNames[f.name]) {
                loadedNames[f.name] = true
                loadedCount++
            }
        }
    }

    function saveAllSettings() {
        if (!settingsLoaded || saving) {
            return
        }

        var error = checkFields()
        if (error !== "") {
            VescIf.emitStatusMessage(error, false)
            return
        }

        // A few settings per command, so a single message never gets too long
        var queue = []
        var pairs = []
        for (var i = 0; i < fields.length; i++) {
            pairs.push("(" + fields[i].name + " . " + fieldValue(fields[i]) + ")")
            if (pairs.length === 8 || i === fields.length - 1) {
                queue.push("(save-pairs '(" + pairs.join(" ") + "))")
                pairs = []
            }
        }
        queue.push("(finish-settings-save)")

        saveQueue = queue
        saving = true
        sendSaveStep()
    }

    // Writing a setting locks the VESC while it writes flash, which drops anything that
    // arrives meanwhile. One command at a time, and only once the last one was confirmed.
    function sendSaveStep() {
        if (saveQueue.length === 0) {
            saving = false
            return
        }

        ackTimer.restart()
        sendCode(saveQueue[0])
    }

    function saveStepDone(ok) {
        if (!saving) {
            return
        }

        ackTimer.stop()

        if (!ok) {
            abortSave()
            return
        }

        saveQueue = saveQueue.slice(1)
        sendSaveStep()
    }

    function abortSave() {
        ackTimer.stop()
        saving = false
        saveQueue = []
        VescIf.emitStatusMessage("Speichern fehlgeschlagen, bitte nochmal versuchen.", false)
        getSettings()
    }

    Component.onCompleted: {
        getSettings()
    }

    // Lisp may still be starting up, keep asking until everything is here
    Timer {
        id: retryTimer
        interval: 2000
        repeat: true
        running: !settingsLoaded && !saving
        onTriggered: sendCode("(send-settings)")
    }

    // Never resend the pending command, a second ack would skip the next one
    Timer {
        id: ackTimer
        interval: 5000
        onTriggered: abortSave()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        TabBar {
            id: tabBar
            currentIndex: swipeView.currentIndex
            Layout.fillWidth: true
            implicitWidth: 0
            clip: true
            enabled: settingsLoaded

            property int buttons: 4
            property int buttonWidth: 90

            TabButton {
                text: "Allgemein"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
            TabButton {
                text: "Original"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
            TabButton {
                text: "Race"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
            TabButton {
                text: "Schutz"
                width: Math.max(tabBar.buttonWidth, tabBar.width / tabBar.buttons)
            }
        }

        SwipeView {
            id: swipeView
            currentIndex: tabBar.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            enabled: settingsLoaded
            opacity: settingsLoaded ? 1.0 : 0.0

            // --- Allgemein ---
            Page {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    GridLayout {
                        width: parent.width
                        columns: 2
                        rowSpacing: 4
                        columnSpacing: 8

                        CheckBox {
                            id: softwareAdc
                            Layout.columnSpan: 2
                            text: "Gas/Bremse über Display (Software-ADC)"
                        }

                        Label { text: "Warnung Motortemp. (°C)" }
                        TextField { id: tempWarningMotor; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Warnung Controllertemp. (°C)" }
                        TextField { id: tempWarningFet; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Anfahrgeschwindigkeit (km/h)" }
                        TextField { id: minSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Limit-Übergang (0,1-1)" }
                        TextField { id: speedLimitStart; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Gas-Schwelle Gesten (0-1)" }
                        TextField { id: minAdcThrottle; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Brems-Schwelle Gesten (0-1)" }
                        TextField { id: minAdcBrake; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                    }
                }
            }

            // --- Original ---
            Page {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 6

                            Item { Layout.fillWidth: true }
                            Label { text: "Eco"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Drive"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Sport"; font.bold: true; Layout.fillWidth: true }

                            Label { text: "km/h" }
                            TextField { id: ecoSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: driveSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: sportSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                            Label { text: "Strom (0-1)" }
                            TextField { id: ecoCurrent; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: driveCurrent; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: sportCurrent; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                            Label { text: "Watt" }
                            TextField { id: ecoWatts; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: driveWatts; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: sportWatts; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                            Label { text: "Field Weak. (A)" }
                            TextField { id: ecoFw; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: driveFw; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: sportFw; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 8

                            Label { text: "Anzeige im Stand" }
                            ComboBox { id: showNormalIdle; Layout.fillWidth: true; model: root.displayNames }

                            Label { text: "Anzeige beim Fahren" }
                            ComboBox { id: showNormalRide; Layout.fillWidth: true; model: root.displayNames }

                            Label { text: "Blinkfeld im Stand" }
                            ComboBox { id: blinkNormalIdle; Layout.fillWidth: true; model: root.displayNames }

                            Label { text: "Blinkfeld beim Fahren" }
                            ComboBox { id: blinkNormalRide; Layout.fillWidth: true; model: root.displayNames }
                        }
                    }
                }
            }

            // --- Race ---
            Page {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: 8

                        CheckBox {
                            id: raceEnabled
                            text: "Race-Profil per Geste aktivierbar"
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 4
                            rowSpacing: 4
                            columnSpacing: 6

                            Item { Layout.fillWidth: true }
                            Label { text: "Eco"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Drive"; font.bold: true; Layout.fillWidth: true }
                            Label { text: "Sport"; font.bold: true; Layout.fillWidth: true }

                            Label { text: "km/h" }
                            TextField { id: raceEcoSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceDriveSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceSportSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                            Label { text: "Strom (0-1)" }
                            TextField { id: raceEcoCurrent; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceDriveCurrent; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceSportCurrent; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                            Label { text: "Watt" }
                            TextField { id: raceEcoWatts; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceDriveWatts; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceSportWatts; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                            Label { text: "Field Weak. (A)" }
                            TextField { id: raceEcoFw; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceDriveFw; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                            TextField { id: raceSportFw; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 8

                            Label { text: "Anzeige im Stand" }
                            ComboBox { id: showRaceIdle; Layout.fillWidth: true; model: root.displayNames }

                            Label { text: "Anzeige beim Fahren" }
                            ComboBox { id: showRaceRide; Layout.fillWidth: true; model: root.displayNames }

                            Label { text: "Blinkfeld im Stand" }
                            ComboBox { id: blinkRaceIdle; Layout.fillWidth: true; model: root.displayNames }

                            Label { text: "Blinkfeld beim Fahren" }
                            ComboBox { id: blinkRaceRide; Layout.fillWidth: true; model: root.displayNames }
                        }
                    }
                }
            }

            // --- Schutz ---
            Page {
                ScrollView {
                    anchors.fill: parent
                    contentWidth: availableWidth
                    clip: true

                    GridLayout {
                        width: parent.width
                        columns: 2
                        rowSpacing: 4
                        columnSpacing: 8

                        CheckBox {
                            id: alarmEnabled
                            Layout.columnSpan: 2
                            text: "Alarmanlage (wenn ausgeschaltet)"
                        }

                        Label { text: "Alarm ab (km/h)" }
                        TextField { id: alarmSpeed; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Alarmdauer (s)" }
                        TextField { id: alarmSeconds; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Überhitzung ab (°C)" }
                        TextField { id: overheatTemp; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }

                        Label { text: "Wieder frei unter (°C)" }
                        TextField { id: overheatRelease; Layout.fillWidth: true; inputMethodHints: Qt.ImhFormattedNumbersOnly }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                Layout.fillWidth: true
                text: "Laden"
                enabled: !saving
                onClicked: getSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Speichern"
                enabled: settingsLoaded && !saving
                onClicked: saveAllSettings()
            }

            Button {
                Layout.fillWidth: true
                text: "Standard"
                enabled: settingsLoaded && !saving
                onClicked: resetDialog.open()
            }
        }
    }

    Dialog {
        id: resetDialog
        anchors.centerIn: parent
        modal: true
        title: "Alle Werte auf Standard zurücksetzen?"
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            loadedNames = ({})
            loadedCount = 0
            sendCode("(restore-settings-ui)")
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: !settingsLoaded || saving
        visible: running
    }

    Connections {
        target: mCommands

        function onCustomAppDataReceived(data) {
            var message = data.toString().trim()

            if (message === "ack") {
                saveStepDone(true)
            } else if (message === "err") {
                saveStepDone(false)
            } else if (message === "ok") {
                VescIf.emitStatusMessage("Einstellungen gespeichert.", true)
            } else if (message.indexOf("settings ") === 0) {
                applySettingsLine(message)
            }
        }
    }
}
