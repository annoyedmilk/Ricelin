// rishot — minimal hotkey popover floated above the toolbar gear. Content is only the current
// hotkey + a Record button. Record -> listens for the next key chord -> maps to a Hyprland keyname
// (lib/keymap.js) -> rewrites rishot.lua -> hyprctl reload -> updates the label live. Vermilion glass.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "lib/keymap.js" as Keymap

Item {
    id: panel
    property string luaPath: ""          // absolute path to rishot.lua
    property string hotkey: "—"          // current bind string, parsed from the file
    property bool listening: false       // true while waiting for a key chord

    signal closeRequested()              // Esc while not listening -> close popover
    signal rebound()                     // hotkey rewritten + reloaded -> close rishot so the new key is usable now

    readonly property color glassBg: Qt.rgba(24 / 255, 28 / 255, 38 / 255, 0.97)
    readonly property color glassBorder: "#3a4456"
    readonly property color vermilion: "#e0563b"
    readonly property color idle: "#c4ccda"

    readonly property int arrow: 7
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight + arrow

    // ---- read current hotkey on load ----
    FileView {
        id: reader
        path: panel.luaPath
        onLoaded: { var b = Keymap.parseBind(text()); if (b) panel.hotkey = b; }
    }

    // ---- write rewritten file, then reload Hyprland on success ----
    FileView {
        id: writer
        path: panel.luaPath
        atomicWrites: true
        onSaved: reloadProc.running = true
        onSaveFailed: (err) => console.log("rishot: rishot.lua write failed: " + err)
    }

    Process {
        id: reloadProc
        command: ["hyprctl", "reload"]
        onExited: (code) => { console.log("rishot: hyprctl reload exit " + code); panel.rebound(); }
    }

    // Commit a captured chord: update label, rewrite file, reload.
    function applyBind(bind) {
        panel.hotkey = bind;
        panel.listening = false;
        writer.setText(Keymap.luaFile(bind));
    }

    Rectangle {
        id: card
        width: parent.width
        height: parent.height - panel.arrow
        radius: 10
        color: panel.glassBg
        border.color: panel.glassBorder
        border.width: 1
        implicitWidth: content.implicitWidth + 20
        implicitHeight: 44

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: panel.hotkey
                color: panel.idle
                font.family: "JetBrains Mono"
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                id: recBtn
                Layout.preferredHeight: 28
                Layout.preferredWidth: recLabel.implicitWidth + 24
                radius: 6
                color: panel.listening ? panel.vermilion
                    : (recHover.hovered ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.06))
                border.color: panel.listening ? panel.vermilion : panel.glassBorder
                border.width: 1

                Text {
                    id: recLabel
                    anchors.centerIn: parent
                    text: panel.listening ? "Press a key…" : "Record"
                    color: panel.listening ? "#ffffff" : panel.idle
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
                }

                HoverHandler { id: recHover }
                TapHandler {
                    onTapped: {
                        panel.listening = !panel.listening;
                        if (panel.listening) keyCatcher.forceActiveFocus();
                    }
                }
            }
        }
    }

    // Subtle downward arrow pointing at the gear.
    Canvas {
        width: panel.arrow * 2
        height: panel.arrow
        anchors.top: card.bottom
        anchors.horizontalCenter: card.horizontalCenter
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width / 2, height);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(24 / 255, 28 / 255, 38 / 255, 0.97);
            ctx.fill();
        }
    }

    // Focused key sink, active only while open. Captures the next complete chord; Esc closes.
    Item {
        id: keyCatcher
        focus: panel.visible
        Keys.onPressed: (e) => {
            e.accepted = true;
            if (e.key === Qt.Key_Escape) {
                if (panel.listening) panel.listening = false;
                else panel.closeRequested();
                return;
            }
            if (!panel.listening) return;
            var bind = Keymap.bindString(e.key, e.modifiers, e.text);
            if (bind !== null) panel.applyBind(bind);   // else: bare modifier, keep listening
        }
    }
}
