pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property int fast:     140
    readonly property int standard: 300
    readonly property int morph:    540
    readonly property int shapeshift: 820
    readonly property int glide:    260
    readonly property int heat:     1100
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeMorph:    Easing.OutExpo
    readonly property real rSmall: 7
    readonly property real rTile:  13
}
