pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Local calendar events, persisted as a plain JSON array beside the session
 * flags (~/.local/state/ricelin/events.json) and watched for external edits so
 * a hand-edit or a second daemon's write reloads live. The file holds an array
 * of { id, date: "YYYY-MM-DD", time: "HH:MM", endTime: "HH:MM", text }; time and
 * endTime may be "" for an all-day or open-ended entry.
 *
 * A bare array is simpler than a JsonAdapter for a growing list: read the text,
 * JSON.parse, mutate the array, JSON.stringify back through setText. Every parse
 * is guarded so a truncated or corrupt file never throws and never wipes the
 * singleton — a bad read just leaves the last good `events` in place.
 *
 * Ids come from a monotonic counter seeded past the highest id already on disk,
 * never Date.now() or Math.random() (both throw in this engine), so every add is
 * uniquely addressable for remove() even within the same minute.
 */
Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ricelin"

    property var events: []
    property int nextId: 1

    /**
     * Re-read the file text into `events` and advance the id counter past every
     * id present, so a freshly added event can never collide with one loaded
     * from disk. A FileNotFound or malformed body is treated as an empty list.
     */
    function reloadEvents() {
        var arr = [];
        try {
            var t = file.text();
            if (t && t.trim().length > 0) {
                var parsed = JSON.parse(t);
                if (Array.isArray(parsed))
                    arr = parsed;
            }
        } catch (e) {
            arr = [];
        }
        var maxId = 0;
        for (var i = 0; i < arr.length; i++) {
            var n = Number(arr[i].id);
            if (n > maxId)
                maxId = n;
        }
        root.nextId = maxId + 1;
        root.events = arr;
    }

    function persist() {
        file.setText(JSON.stringify(root.events));
    }

    /** Events on `dateStr`, sorted by start time; an empty time sorts first. */
    function forDate(dateStr) {
        var out = root.events.filter(function (e) { return e.date === dateStr; });
        out.sort(function (a, b) {
            var at = a.time || "";
            var bt = b.time || "";
            if (at === bt)
                return 0;
            if (at === "")
                return -1;
            if (bt === "")
                return 1;
            return at < bt ? -1 : 1;
        });
        return out;
    }

    function hasEvents(dateStr) {
        for (var i = 0; i < root.events.length; i++) {
            if (root.events[i].date === dateStr)
                return true;
        }
        return false;
    }

    /** Append an event and persist; reassigns `events` so bindings refresh. */
    function add(dateStr, time, endTime, text) {
        var next = root.events.slice();
        next.push({
            id: root.nextId,
            date: dateStr,
            time: time || "",
            endTime: endTime || "",
            text: text || ""
        });
        root.nextId += 1;
        root.events = next;
        root.persist();
    }

    function remove(id) {
        root.events = root.events.filter(function (e) { return e.id !== id; });
        root.persist();
    }

    Component.onCompleted: reloadEvents()

    FileView {
        id: file
        path: root.stateDir + "/events.json"
        blockLoading: true
        watchChanges: true
        printErrors: false

        onFileChanged: {
            reload();
            root.reloadEvents();
        }
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound)
                file.setText("[]");
        }
    }
}
