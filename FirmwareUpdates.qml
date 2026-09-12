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

  property bool opened: false
  property bool checking: false
  property string errorText: ""
  property var updates: []
  property string rawOutput: ""

  readonly property color foreground: Color.menu.text
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color surface: Color.menu.background
  readonly property color border: Color.menu.border
  readonly property color accent: Color.accent
  readonly property string fontFamily: Style.font.menuFamily

  function alpha(color, opacity) {
    return Qt.rgba(color.r, color.g, color.b, opacity)
  }

  function open(payloadJson) {
    opened = true
    refresh()
  }

  function close() {
    opened = false
    if (root.controller) root.controller.hide()
  }

  function refresh() {
    if (!checkProcess.running) {
      checking = true
      errorText = ""
      checkProcess.running = true
    }
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

  Process {
    id: checkProcess
    command: ["env", "LANG=C", "fwupdmgr", "get-updates"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.rawOutput = text
        root.updates = root.parseUpdates(text)
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: if (text.trim() !== "") root.errorText = text.trim()
    }

    onExited: {
      root.checking = false
      if (exitCode !== 0 && root.errorText === "")
        root.errorText = "fwupdmgr exited with status " + exitCode
    }
  }

  Rectangle {
    anchors.centerIn: parent
    width: Math.min(Style.space(620), parent.width - Style.gapsOut * 2)
    height: Math.min(Style.space(520), parent.height - Style.gapsOut * 2)
    radius: Style.cornerRadius
    color: root.surface
    border.color: root.border
    border.width: 1

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.spacing.panelPadding
      spacing: Style.spacing.md

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Firmware updates"
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

      ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
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
