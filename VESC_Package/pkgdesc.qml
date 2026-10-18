import QtQuick 2.15

Item {
    property string pkgName: "G30 Dashboard Race"
    property string pkgDescriptionMd: "README.md"
    property string pkgLisp: "g30_dashboard_race.lisp"
    property string pkgQml: "ui.qml"
    property bool pkgQmlIsFullscreen: false
    property string pkgOutput: "g30_dashboard_race.vescpkg"

    function isCompatible (fwRxParams) {
        var hwType = fwRxParams.hwTypeStr().toLowerCase()
        return hwType === "vesc"
    }
}
