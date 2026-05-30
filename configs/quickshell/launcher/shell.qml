import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "lib/fuzzy.js" as Fuzzy

ShellRoot {
    id: root

    property string query: ""
    property var usage: ({})

    readonly property var focusedScreen: {
        var m = Hyprland.focusedMonitor;
        return m ? m.screen : Quickshell.screens[0];
    }

    FileView {
        id: usageStore
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ricelin/launcher-usage.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        var raw = usageStore.text();
        try {
            root.usage = raw && raw.length ? JSON.parse(raw) : ({});
        } catch (e) {
            root.usage = ({});
        }
    }

    readonly property var allEntries: {
        var src = DesktopEntries.applications.values;
        var out = [];
        for (var i = 0; i < src.length; i++)
            if (src[i] && !src[i].noDisplay) out.push(src[i]);
        return out;
    }

    readonly property int totalCount: allEntries.length
    readonly property var results: Fuzzy.rank(allEntries, query, usage)

    function run(entry) {
        if (entry) {
            if (entry.id) {
                root.usage[entry.id] = (root.usage[entry.id] || 0) + 1;
                usageStore.setText(JSON.stringify(root.usage));
                usageStore.waitForJob();
            }
            entry.execute();
        }
        Qt.quit();
    }

    PanelWindow {
        id: win
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "launcher"

        anchors { top: true; left: true; right: true; bottom: true }

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
        }

        Launcher {
            id: launcher
            anchors.centerIn: parent

            entries: root.results
            total: root.totalCount

            onLaunch: (entry) => root.run(entry)
            onQuit: Qt.quit()
        }

        Connections {
            target: launcher
            function onQueryChanged() {
                root.query = launcher.query;
                launcher.selectedIndex = 0;
            }
        }

        Component.onCompleted: launcher.focusField()
    }
}
