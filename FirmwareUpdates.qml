import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.biplop.fwupd"
  ipcTarget: "io.github.biplop.fwupd"

  property bool checking: false
  property string errorText: ""
  property string productName: "Laptop"
  property string vendorName: ""
  property string biosVersion: ""
  property string lastChecked: "Never"
  property var anchorItem: null
  property var hostWidget: null
  property var updates: []
  property string rawOutput: ""

  readonly property color foreground: Color.menu.text
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color surface: Color.menu.background
  readonly property color border: Color.menu.border
  readonly property color accent: Color.accent
  readonly property string fontFamily: Style.font.menuFamily
  readonly property var barIdentity: hostWidget || root

  function alpha(color, opacity) {
    return Qt.rgba(color.r, color.g, color.b, opacity)
  }

  function open(payloadJson) {
    root.controller.show()
    refresh()
    loadHardwareInfo()
  }

  function close() {
    root.controller.hide()
  }

  function refresh() {
    if (!checkProcess.running) {
      checking = true
      errorText = ""
      checkProcess.running = true
    }
  }

  function intervalSeconds() {
    return Math.max(300, Number(setting("refreshIntervalSec", 604800)))
  }

  function intervalLabel(seconds) {
    if (seconds >= 2592000) return "Monthly"
    if (seconds >= 604800) return "Weekly"
    if (seconds >= 86400) return "Daily"
    if (seconds >= 21600) return "Every 6 hours"
    return "Hourly"
  }

  function saveInterval(seconds) {
    var entry = { id: root.moduleName, refreshIntervalSec: seconds }
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function parseUpdates(output) {
    var lines = String(output || "").split("\n")
    var result = []
    var title = ""
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line.indexOf("├─") === 0 || line.indexOf("└─") === 0)
        title = line.replace(/^[├└─\s]+/, "").replace(/:$/, "")
      if (line.indexOf("New version:") === 0) {
        var version = line.substring("New version:".length).trim()
        result.push({ title: title || "Firmware device", version: version })
      }
    }
    return result
  }

  function installUpdates() {
    if (root.bar) root.bar.run("omarchy-launch-floating-terminal-with-presentation fwupdmgr update")
    close()
  }

  function loadHardwareInfo() {
    if (!hardwareProcess.running) hardwareProcess.running = true
  }

  Process {
    id: hardwareProcess
    command: ["sh", "-c", "printf '%s\\n' \"$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)\" \"$(cat /sys/class/dmi/id/product_name 2>/dev/null)\" \"$(cat /sys/class/dmi/id/bios_version 2>/dev/null)\""]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").trim().split("\n")
        if (lines.length > 0 && lines[0] !== "") root.vendorName = lines[0].trim()
        if (lines.length > 1 && lines[1] !== "") root.productName = lines[1].trim()
        if (lines.length > 2 && lines[2] !== "") root.biosVersion = lines[2].trim()
      }
    }
  }

  Process {
    id: checkProcess
    command: ["env", "LANG=C", "fwupdmgr", "get-updates"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.rawOutput = text
        root.updates = root.parseUpdates(text)
        root.lastChecked = Qt.formatTime(new Date(), "HH:mm")
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") root.errorText = text.trim()
    }

    onExited: function(exitCode) {
      root.checking = false
      if (exitCode !== 0 && root.errorText === "")
        root.errorText = "fwupdmgr exited with status " + exitCode
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    contentWidth: panel.fittedContentWidth(Style.space(620))
    contentHeight: panel.fittedContentHeight(contentColumn.implicitHeight)

    ColumnLayout {
      id: contentColumn
      width: panel.contentWidth - panel.padding * 2 - Style.space(4)
      spacing: Style.spacing.md

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Firmware center"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
          Layout.fillWidth: true
        }

        Button {
          text: "Refresh"
          enabled: !root.checking
          onClicked: root.refresh()
        }

        Button {
          text: "Close"
          onClicked: root.close()
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: deviceInfo.implicitHeight + Style.spacing.md * 2
        radius: Style.cornerRadius
        color: root.alpha(root.foreground, 0.07)

        Column {
          id: deviceInfo
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: Style.spacing.md
          spacing: Style.spacing.xs

          Text {
            text: root.vendorName !== "" ? root.vendorName + " " + root.productName : root.productName
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
          }

          Text {
            text: "Current BIOS: " + (root.biosVersion !== "" ? root.biosVersion : "Unavailable")
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
            width: parent.width
          }
        }
      }

      Text {
        Layout.fillWidth: true
        text: root.checking ? "Checking LVFS metadata and device firmware..." :
          root.updates.length > 0 ? root.updates.length + " update(s) available" :
          root.errorText !== "" ? root.errorText : "No firmware updates available"
        color: root.errorText !== "" ? Color.urgent : root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }

      Text {
        Layout.fillWidth: true
        text: "Last checked: " + root.lastChecked
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Automatic checks"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          Layout.fillWidth: true
        }

        ComboBox {
          id: frequencyBox
          model: [
            { label: "Hourly", seconds: 3600 },
            { label: "Every 6 hours", seconds: 21600 },
            { label: "Daily", seconds: 86400 },
            { label: "Weekly", seconds: 604800 },
            { label: "Monthly", seconds: 2592000 }
          ]
          currentIndex: {
            var selected = root.intervalSeconds()
            for (var i = 0; i < model.length; i++)
              if (model[i].seconds === selected) return i
            return 3
          }
          textRole: "label"
          onActivated: root.saveInterval(model[currentIndex].seconds)
        }
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(220)
        clip: true
        spacing: Style.spacing.sm
        model: root.updates

        delegate: Rectangle {
          required property var modelData
          width: ListView.view.width
          height: titleText.implicitHeight + versionText.implicitHeight + Style.spacing.sm * 2
          radius: Style.cornerRadius
          color: root.alpha(root.foreground, 0.08)

          Column {
            anchors.fill: parent
            anchors.margins: Style.spacing.sm
            spacing: Style.spacing.xs

            Text {
              id: titleText
              width: parent.width
              text: modelData.title
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              elide: Text.ElideRight
            }

            Text {
              id: versionText
              text: "New version: " + modelData.version
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Installation requires authentication and may require a reboot."
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }

        Button {
          text: "Install updates"
          enabled: root.updates.length > 0 && !root.checking
          onClicked: root.installUpdates()
        }
      }
    }
  }
}
