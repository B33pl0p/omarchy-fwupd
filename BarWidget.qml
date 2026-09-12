import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.biplop.fwupd"

  property bool updateAvailable: false
  property bool checking: false
  property int refreshIntervalSec: Math.max(300, Number(setting("refreshIntervalSec", 21600)))

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function refresh() {
    if (!checkProcess.running) {
      checking = true
      checkProcess.running = true
    }
  }

  function showOverlay() {
    if (root.bar) root.bar.run("omarchy-shell shell summon io.github.biplop.fwupd")
  }

  visible: updateAvailable || checking
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: checkProcess
    command: ["env", "LANG=C", "fwupdmgr", "get-updates"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateAvailable = root.hasUpdates(text)
    }

    stderr: StdioCollector {
      waitForEnd: true
    }

    onExited: root.checking = false
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  function hasUpdates(output) {
    return String(output || "").indexOf("New version:") >= 0
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "FW"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: root.checking ? "Checking firmware updates" : "Firmware updates available"
    onPressed: root.showOverlay()
  }
}
