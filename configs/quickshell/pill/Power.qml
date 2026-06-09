pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import "Singletons"

/**
 * Power surface: a row of hand-drawn session glyphs. Safe actions fire on a tap;
 * destructive ones (restart, shutdown) require a press-and-hold while a ring
 * sweeps the glyph, so a stray click can never reboot the machine. Only the
 * hovered action shows its label, keeping the resting layout minimal.
 */
Item {
    id: root

    property real s: 1
    property bool active: false
    signal requestClose()

    property string hovered: ""

    readonly property var actions: [
        { key: "lock",     glyph: "lock",     label: "Lock",     confirm: false, dispatch: "",             argv: ["sh", "-c", "$HOME/.config/hypr/scripts/lock.sh"] },
        { key: "logout",   glyph: "logout",   label: "Logout",   confirm: false, dispatch: "hl.dsp.exit()", argv: [] },
        { key: "suspend",  glyph: "suspend",  label: "Sleep",    confirm: false, dispatch: "",             argv: ["systemctl", "suspend"] },
        { key: "reboot",   glyph: "reboot",   label: "Restart",  confirm: true,  dispatch: "",             argv: ["systemctl", "reboot"] },
        { key: "shutdown", glyph: "shutdown", label: "Shutdown", confirm: true,  dispatch: "",             argv: ["systemctl", "poweroff"] }
    ]

    function run(a) {
        if (a.dispatch && a.dispatch.length)
            Hyprland.dispatch(a.dispatch);
        else
            Quickshell.execDetached(a.argv);
        root.requestClose();
    }

    onActiveChanged: if (!active) hovered = "";

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 22 * root.s

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * root.s
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "電"
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 16 * root.s
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "POWER"
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 10 * root.s
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.6 * root.s
            }
        }
    }

    Row {
        id: tiles
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: header.bottom
        anchors.topMargin: 14 * root.s
        spacing: 12 * root.s

        Repeater {
            model: root.actions

            delegate: Item {
                id: tile
                required property var modelData
                width: 48 * root.s
                height: 48 * root.s

                property real hold: 0
                readonly property bool isHover: root.hovered === tile.modelData.key
                readonly property bool lit: isHover || tile.hold > 0
                readonly property color accent: tile.modelData.confirm ? Theme.vermLit : Theme.cream

                Rectangle {
                    anchors.fill: parent
                    radius: 13 * root.s
                    color: tile.isHover ? Theme.tileBg : "transparent"
                    border.width: 1
                    border.color: tile.isHover ? Theme.border : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                Shape {
                    anchors.fill: parent
                    visible: tile.hold > 0.001
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.vermLit
                        strokeWidth: 2 * root.s
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: tile.width / 2
                            centerY: tile.height / 2
                            radiusX: tile.width / 2 - 2 * root.s
                            radiusY: tile.height / 2 - 2 * root.s
                            startAngle: -90
                            sweepAngle: 360 * tile.hold
                        }
                    }
                }

                GlyphIcon {
                    anchors.centerIn: parent
                    width: 22 * root.s
                    height: 22 * root.s
                    name: tile.modelData.glyph
                    color: tile.lit ? tile.accent : Theme.iconDim
                    stroke: 1.9
                }

                NumberAnimation {
                    id: fill
                    target: tile
                    property: "hold"
                    from: 0
                    to: 1
                    duration: 850
                    onFinished: root.run(tile.modelData)
                }
                NumberAnimation {
                    id: cancel
                    target: tile
                    property: "hold"
                    to: 0
                    duration: 180
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hovered = tile.modelData.key
                    onExited: {
                        if (root.hovered === tile.modelData.key)
                            root.hovered = "";
                        if (tile.modelData.confirm) {
                            fill.stop();
                            cancel.restart();
                        }
                    }
                    onPressed: {
                        if (tile.modelData.confirm) {
                            cancel.stop();
                            fill.restart();
                        }
                    }
                    onReleased: {
                        if (tile.modelData.confirm) {
                            fill.stop();
                            if (tile.hold < 1)
                                cancel.restart();
                        }
                    }
                    onClicked: {
                        if (!tile.modelData.confirm)
                            root.run(tile.modelData);
                    }
                }
            }
        }
    }

    Text {
        id: label
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: tiles.bottom
        anchors.topMargin: 12 * root.s
        readonly property var act: {
            for (var i = 0; i < root.actions.length; i++)
                if (root.actions[i].key === root.hovered)
                    return root.actions[i];
            return null;
        }
        text: act ? (act.confirm ? act.label + " — hold" : act.label) : ""
        color: act && act.confirm ? Theme.vermLit : Theme.subtle
        font.family: Theme.font
        font.pixelSize: 11 * root.s
        font.weight: Font.Medium
        font.letterSpacing: 0.4 * root.s
        opacity: text.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }
}
