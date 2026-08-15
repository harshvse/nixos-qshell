// Starter config: one panel across the top of every screen, wallust
// colors wired up, a clock so you can see it's alive. Everything else
// (workspaces, window title, tray, network, audio, etc.) is on you —
// that's the point. Run `quickshell` directly in a terminal (kill the
// autostarted one first: `pkill quickshell`) to see QML errors live
// while you iterate; it prints them straight to stdout.
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.cache/wallust/quickshell-colors.json"
        watchChanges: true
        onFileChanged: reload()

        // Defaults only matter before the first-ever `wallust run`.
        adapter: JsonAdapter {
            id: palette
            property string background: "#1e1e2e"
            property string foreground: "#cdd6f4"
            property string color0: "#45475a"
            property string color1: "#f38ba8"
            property string color2: "#a6e3a1"
            property string color3: "#f9e2af"
            property string color4: "#89b4fa"
            property string color5: "#f5c2e7"
            property string color6: "#94e2d5"
            property string color7: "#bac2de"
            property string color8: "#585b70"
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            // Children of a Variants delegate can't resolve bindings to an
            // outer document id directly — `palette.color5` inside the Text
            // below evaluates once as undefined and never updates, even
            // though the exact same expression works fine right here on the
            // delegate root. Forwarding it through a property declared on
            // the root (which *does* bind/update correctly) and having
            // children reference that instead works around it. Apply the
            // same `bar.pal.xxx` pattern to any new child you add here.
            property var pal: palette

            anchors { top: true; left: true; right: true }
            implicitHeight: 32
            color: palette.background

            Text {
                anchors.centerIn: parent
                color: bar.pal.color5
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12

                property date now: new Date()
                Timer { interval: 1000; running: true; repeat: true; onTriggered: parent.now = new Date() }
                text: Qt.formatDateTime(now, "ddd dd MMM  hh:mm")
            }
        }
    }
}
