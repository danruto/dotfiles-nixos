// Theme picker for the DMS launcher. Type the trigger ("th") to filter to this
// plugin: in that mode DMS renders the whole item list, while its desktop-entry
// search caps at 10 hits and can never show 350+ themes.
//
// The list comes from scripts/theme-entries, which writes themes.json and one
// SVG swatch per theme. Enter runs scripts/theme-set <name> (fast path).
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginService: null
    property string trigger: "th"

    signal itemsChanged()

    property var themes: []
    property string script: ""

    FileView {
        id: manifest
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/theme-swatches/themes.json"
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text())
                root.script = data.script || ""
                root.themes = data.themes || []
            } catch (e) {
                console.warn("themeSwitcher: bad manifest:", e)
                root.themes = []
            }
            root.itemsChanged()
        }
        onLoadFailed: {
            root.themes = []
            root.itemsChanged()
        }
    }

    function getItems(query) {
        const q = (query || "").trim().toLowerCase()
        const items = []
        for (let i = 0; i < root.themes.length; i++) {
            const t = root.themes[i]
            if (q && t.name.toLowerCase().indexOf(q) === -1)
                continue
            items.push({
                name: t.name,
                icon: "svg:" + t.icon,
                comment: t.polarity,
                action: "theme:" + t.name,
                categories: ["Themes"]
            })
        }
        return items
    }

    function executeItem(item) {
        if (!item || !item.action || item.action.indexOf("theme:") !== 0)
            return
        if (!root.script) {
            console.warn("themeSwitcher: no script path in manifest")
            return
        }
        // setsid: the switch restarts DMS, which would otherwise kill it midway.
        Quickshell.execDetached(["setsid", "-f", root.script, item.action.substring(6)])
    }
}
