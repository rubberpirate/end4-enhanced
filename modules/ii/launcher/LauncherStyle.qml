pragma Singleton
import QtQuick

// Launcher dimensions and motion timings from Nebula; see README.md and LICENSE.
QtObject {
    readonly property int size: 380
    readonly property int ringRadius: 136
    readonly property int itemSize: 50
    readonly property int labelWidth: 80
    readonly property int labelGap: 4
    readonly property int iconSize: 26
    readonly property int labelSize: 13
    readonly property int stagger: 25
    readonly property int searchWidth: 170
    readonly property int searchHeight: 40
    readonly property int searchIconSize: 20
    readonly property real backdropDim: 0.12
    readonly property real glassTint: 0.45
    readonly property real glassLight: 0.14
    readonly property real glassPad: 0.25
    readonly property int fast: 150
    readonly property int medium: 300
    readonly property int slow: 500
    readonly property int island: 550
    readonly property real overshoot: 1.2
}
