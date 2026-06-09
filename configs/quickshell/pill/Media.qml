pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "Singletons"

/**
 * Media surface: an art-forward now-playing card. The album art is blurred and
 * warm-tinted to fill the whole surface, with a sharp square cover, track text,
 * transport controls and a full-width seek bar laid over it. Driven by the
 * active MPRIS player; fills the body of the morphing pill edge to edge.
 */
Item {
    id: root

    property real s: 1
    property bool active: false
    property real radius: 22 * s
    signal requestClose()

    readonly property var player: {
        var list = Mpris.players.values;
        if (!list || list.length === 0)
            return null;
        var controllable = null;
        for (var i = 0; i < list.length; i++) {
            var p = list[i];
            if (!p)
                continue;
            if (p.isPlaying)
                return p;
            if (!controllable && p.canControl)
                controllable = p;
        }
        return controllable ? controllable : list[0];
    }

    readonly property bool hasPlayer: player !== null
    readonly property bool playing: hasPlayer && player.isPlaying
    readonly property string title: hasPlayer && player.trackTitle ? player.trackTitle : "Nothing playing"
    readonly property string artist: {
        if (!hasPlayer)
            return "";
        if (player.trackArtists && player.trackArtists.length > 0)
            return player.trackArtists;
        return player.trackArtist ? player.trackArtist : "";
    }
    readonly property string artUrl: hasPlayer && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property bool hasArt: artSource.status === Image.Ready && artUrl != ""
    readonly property real lengthSec: hasPlayer && player.length > 0 ? player.length : 0
    readonly property real positionSec: hasPlayer ? player.position : 0
    readonly property real frac: lengthSec > 0 ? Math.max(0, Math.min(1, positionSec / lengthSec)) : 0

    function fmt(sec) {
        if (!(sec > 0))
            return "0:00";
        var t = Math.floor(sec);
        var m = Math.floor(t / 60);
        var ss = t % 60;
        return m + ":" + (ss < 10 ? "0" + ss : ss);
    }

    Timer {
        interval: 1000
        running: root.active && root.playing
        repeat: true
        onTriggered: if (root.player) root.player.positionChanged();
    }

    Image {
        id: artSource
        source: root.artUrl
        asynchronous: true
        cache: true
        visible: false
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.cardBot

        Image {
            id: bgFill
            anchors.fill: parent
            source: root.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: bgFill
            visible: root.hasArt
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            brightness: -0.18
            saturation: 0.08
        }
        Rectangle {
            anchors.fill: parent
            visible: !root.hasArt
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.cardTop }
                GradientStop { position: 1.0; color: Theme.cardBot }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.16, 0.11, 0.08, 0.52) }
                GradientStop { position: 1.0; color: Qt.rgba(0.09, 0.06, 0.04, 0.84) }
            }
        }

        Item {
            anchors.fill: parent
            anchors.topMargin: 15 * root.s
            anchors.leftMargin: 15 * root.s
            anchors.rightMargin: 15 * root.s
            anchors.bottomMargin: 28 * root.s

            ClippingRectangle {
                id: cover
                anchors.left: parent.left
                anchors.top: parent.top
                width: height
                height: parent.height
                radius: 11 * root.s
                color: Qt.rgba(1, 1, 1, 0.05)

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: root.hasArt
                }
                GlyphIcon {
                    anchors.centerIn: parent
                    width: parent.width * 0.34
                    height: width
                    name: "music"
                    color: Theme.subtle
                    visible: !root.hasArt
                }
            }

            Column {
                anchors.left: cover.right
                anchors.leftMargin: 15 * root.s
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 3 * root.s
                spacing: 3 * root.s

                Text {
                    width: parent.width
                    text: root.title
                    color: Theme.onAccent
                    font.family: Theme.font
                    font.pixelSize: 16 * root.s
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: root.artist
                    color: Qt.rgba(0.95, 0.91, 0.88, 0.7)
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    elide: Text.ElideRight
                    visible: text.length > 0
                }
            }

            Row {
                anchors.left: cover.right
                anchors.leftMargin: 15 * root.s
                anchors.bottom: parent.bottom
                spacing: 18 * root.s

                Item {
                    width: 22 * root.s
                    height: 22 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    GlyphIcon {
                        anchors.fill: parent
                        name: "prev"
                        color: prevArea.containsMouse ? Theme.vermLit : (prevArea.enabled ? Theme.onAccent : Qt.rgba(1, 1, 1, 0.3))
                    }
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -6 * root.s
                        hoverEnabled: true
                        enabled: root.hasPlayer && root.player.canGoPrevious
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.previous();
                    }
                }

                Rectangle {
                    width: 34 * root.s
                    height: 34 * root.s
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: ppArea.containsMouse ? Theme.vermLit : Theme.verm
                    Behavior on color { ColorAnimation { duration: 120 } }

                    GlyphIcon {
                        anchors.centerIn: parent
                        width: 16 * root.s
                        height: width
                        name: root.playing ? "pause" : "play"
                        color: Theme.onAccent
                    }
                    MouseArea {
                        id: ppArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.hasPlayer && root.player.canTogglePlaying
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.togglePlaying();
                    }
                }

                Item {
                    width: 22 * root.s
                    height: 22 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    GlyphIcon {
                        anchors.fill: parent
                        name: "next"
                        color: nextArea.containsMouse ? Theme.vermLit : (nextArea.enabled ? Theme.onAccent : Qt.rgba(1, 1, 1, 0.3))
                    }
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -6 * root.s
                        hoverEnabled: true
                        enabled: root.hasPlayer && root.player.canGoNext
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.player) root.player.next();
                    }
                }
            }

        }

        Item {
            id: progress
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 15 * root.s
            anchors.rightMargin: 15 * root.s
            anchors.bottomMargin: 11 * root.s
            height: 12 * root.s

            Text {
                id: tcur
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.positionSec)
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: Theme.font
                font.pixelSize: 9.5 * root.s
                font.features: { "tnum": 1 }
            }
            Text {
                id: ttot
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmt(root.lengthSec)
                color: Qt.rgba(1, 1, 1, 0.6)
                font.family: Theme.font
                font.pixelSize: 9.5 * root.s
                font.features: { "tnum": 1 }
            }
            Rectangle {
                id: track
                anchors.left: tcur.right
                anchors.leftMargin: 9 * root.s
                anchors.right: ttot.left
                anchors.rightMargin: 9 * root.s
                anchors.verticalCenter: parent.verticalCenter
                height: 3 * root.s
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.22)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * root.frac
                    radius: parent.radius
                    color: Theme.vermLit
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -7 * root.s
                    enabled: root.hasPlayer && root.player.canSeek && root.lengthSec > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (e) => {
                        var f = Math.max(0, Math.min(1, (e.x + 7 * root.s) / track.width));
                        if (root.player)
                            root.player.position = f * root.lengthSec;
                    }
                }
            }
        }
    }
}
