pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * 場 WORKSPACES hub: a glance at Hyprland's special spaces and the keys that
 * summon them. Each row pairs the space's name and a one-line note with a dim
 * key-cap chip on the right. Stash is the only configurable one — its row navs
 * into the app manager that edits stash-apps.lua — so it carries a chevron; the
 * Private and Minimized rows are read-only reminders of what those keys do.
 *
 * Built on the plain surface base like Stash and Keybinds; the host routes its
 * header-back to the settings index and the Stash row's tap to the stash surface.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 19
    mRight: 19
    mBottom: 14

    implicitHeight: content.implicitHeight

    signal requestSurface(string name)

    ameForm: "off"

    readonly property var spaces: [
        { name: "Stash", key: "Super + S", note: "Background apps that open here", surface: "stash" },
        { name: "Private", key: "Super + P", note: "Hidden scratchpad", surface: "" },
        { name: "Minimized", key: "Super + Shift + M", note: "Minimized windows", surface: "" }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            width: parent.width
            height: 22 * root.s

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Flags.showGlyphs
                    text: "場"
                    color: Theme.cream
                    font.family: Theme.fontJp
                    font.weight: Font.Medium
                    font.pixelSize: 16 * root.s
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WORKSPACES"
                    color: Theme.subtle
                    font.family: Theme.font
                    font.pixelSize: 10 * root.s
                    font.weight: Font.DemiBold
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.6 * root.s
                }
            }

            GlyphIcon {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-left"
                color: Theme.iconDim
                stroke: 2.2
            }
        }

        Item { width: 1; height: 8 * root.s }

        Repeater {
            model: root.spaces

            delegate: Item {
                id: wrow
                required property int index
                required property var modelData

                readonly property bool nav: modelData.surface.length > 0
                readonly property bool last: wrow.index === root.spaces.length - 1

                width: parent.width
                height: 50 * root.s

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3 * root.s
                    anchors.bottomMargin: 3 * root.s
                    radius: 10 * root.s
                    color: (wrow.nav && navHover.hovered) ? Theme.frameBg : "transparent"
                    border.width: 1
                    border.color: (wrow.nav && navHover.hovered) ? Theme.frameBorder : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }

                HoverHandler { id: navHover; enabled: wrow.nav }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 12 * root.s
                    anchors.right: rightRow.left
                    anchors.rightMargin: 10 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3 * root.s

                    Text {
                        width: parent.width
                        text: wrow.modelData.name
                        color: Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 12.5 * root.s
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: wrow.modelData.note
                        color: Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 10.5 * root.s
                        elide: Text.ElideRight
                    }
                }

                Row {
                    id: rightRow
                    anchors.right: parent.right
                    anchors.rightMargin: 12 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8 * root.s

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: keyText.implicitWidth + 16 * root.s
                        height: keyText.implicitHeight + 8 * root.s
                        radius: 7 * root.s
                        color: Theme.frameBg
                        border.width: 1
                        border.color: Theme.hairSoft

                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: wrow.modelData.key
                            color: Theme.subtle
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: Font.Bold
                            font.letterSpacing: 0.3 * root.s
                        }
                    }

                    GlyphIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: wrow.nav
                        width: 16 * root.s
                        height: 16 * root.s
                        name: "chevron-right"
                        color: navHover.hovered ? Theme.cream : Theme.iconDim
                        stroke: 2.2
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: wrow.nav
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestSurface(wrow.modelData.surface)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.hairSoft
                    visible: !wrow.last
                }
            }
        }

        Item { width: 1; height: 4 * root.s }
    }
}
