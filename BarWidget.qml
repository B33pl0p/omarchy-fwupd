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
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

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

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  visible: true
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

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.settings = root.settings
  }

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("FirmwareUpdates.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
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
    tooltipText: root.checking ? "Checking firmware updates" :
      root.updateAvailable ? "Firmware updates available" : "Firmware status"
    onPressed: root.togglePanel()
  }
}
