import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

ShellRoot {
  id: root

  property date now: new Date()

  property int workspaceCount: {
    let highest = 5
    for (const workspace of Hyprland.workspaces.values) {
      if (workspace.id > highest) highest = workspace.id
    }
    return highest
  }

  property var player: Mpris.players.values.find(player => player.isPlaying)
                       || Mpris.players.values[0]
                       || null
  property var battery: UPower.devices.values.find(device => device.isLaptopBattery) || null

  function batteryGlyph(battery) {
    const level = Math.min(9, Math.max(0, Math.floor(battery.percentage * 10)))
    const discharging = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    const charging = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    return battery.iconName.includes("charging") ? charging[level] : discharging[level]
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  component BarModule: Rectangle {
    color: "#2a2636"
    radius: 6
    height: 29
  }

  component BarLabel: Text {
    font.family: "Lexend"
    font.pixelSize: 14
    font.weight: Font.DemiBold
    verticalAlignment: Text.AlignVCenter
    color: "#cdd6f4"
  }

  PanelWindow {
    id: bar
    // Prefer the internal panel whenever it is enabled; otherwise use the dock.
    screen: Quickshell.screens.find(screen => Hyprland.monitorFor(screen)?.name === "eDP-1") || Quickshell.screens[0]
    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: 43
    color: "transparent"
    exclusiveZone: 43

    // Each probe owns one value, so a slow command cannot block another widget.
    property string cpuUsage: "--"
    property string memoryUsage: "--"
    property string downloadRate: "--"
    property string uploadRate: "--"
    property real previousRxBytes: -1
    property real previousTxBytes: -1
    property double previousNetworkSampleMs: 0
    property string volume: "--"
    property bool muted: false
    property bool hasNotifications: false
    property bool japaneseInput: false
    property string systemInfo: "Loading system information..."
    property var calendarEvents: []

    Process {
      id: cpuProbe
      command: ["sh", "-c", "LC_ALL=C top -bn1 | awk '/Cpu\\(s\\)/ { printf \"%.0f\", 100 - $8 }'"]
      stdout: StdioCollector {
        onStreamFinished: bar.cpuUsage = this.text.trim() || "--"
      }
    }

    Process {
      id: memoryProbe
      command: ["sh", "-c", "free -b | awk '/Mem:/ { printf \"%.1f\", $3 / 1000000000 }'"]
      stdout: StdioCollector {
        onStreamFinished: bar.memoryUsage = this.text.trim() || "--"
      }
    }

    Process {
      id: networkProbe
      command: ["sh", "-c", "awk -F ':' 'NR > 2 { gsub(/^[[:space:]]+/, \"\", $1); gsub(/^[[:space:]]+/, \"\", $2); if ($1 != \"lo\") { split($2, fields, /[[:space:]]+/); rx += fields[1]; tx += fields[9] } } END { print rx, tx }' /proc/net/dev"]
      stdout: StdioCollector {
        onStreamFinished: {
          const counters = this.text.trim().split(" ")
          const now = Date.now()
          if (counters.length === 2 && bar.previousNetworkSampleMs > 0) {
            const seconds = (now - bar.previousNetworkSampleMs) / 1000
            const downBytesPerSecond = (Number(counters[0]) - bar.previousRxBytes) / seconds
            const upBytesPerSecond = (Number(counters[1]) - bar.previousTxBytes) / seconds
            bar.downloadRate = bar.formatNetworkRate(downBytesPerSecond)
            bar.uploadRate = bar.formatNetworkRate(upBytesPerSecond)
          }
          bar.previousRxBytes = Number(counters[0])
          bar.previousTxBytes = Number(counters[1])
          bar.previousNetworkSampleMs = now
        }
      }
    }

    function formatNetworkRate(bytesPerSecond) {
      const kilobytesPerSecond = Math.max(0, bytesPerSecond) / 1000
      return kilobytesPerSecond >= 1000
        ? `${(kilobytesPerSecond / 1000).toFixed(1)}M`
        : `${Math.round(kilobytesPerSecond)}K`
    }

    Process {
      id: volumeProbe
      command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
      stdout: StdioCollector {
        onStreamFinished: {
          const result = text.trim()
          const match = result.match(/Volume:\s+([0-9.]+)/)
          if (match) bar.volume = Math.round(Number(match[1]) * 100)
          bar.muted = result.includes("MUTED")
        }
      }
    }

    Process {
      id: notificationProbe
      command: ["swaync-client", "-c"]
      stdout: StdioCollector {
        onStreamFinished: bar.hasNotifications = Number(text.trim()) > 0
      }
    }

    Process {
      id: fcitxProbe
      command: ["sh", "-c", "fcitx5-remote; fcitx5-remote -n"]
      stdout: StdioCollector {
        onStreamFinished: {
          const state = this.text.trim().split("\n")
          bar.japaneseInput = state[0] === "2" && /mozc|anthy|skk|japanese/i.test(state[1] || "")
        }
      }
    }

    // Keep the input-mode indicator responsive without increasing metric polling.
    Timer {
      interval: 150
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: fcitxProbe.running = true
    }

    Process {
      id: systemInfoProbe
      command: ["sh", "-c", "printf 'OS: '; . /etc/os-release; printf '%s\\n' \"$PRETTY_NAME\"; printf 'Kernel: '; uname -r; printf 'Uptime: '; uptime -p | sed 's/up //'; printf 'CPU: '; lscpu | awk -F: '/Model name/ { gsub(/^ +/, \"\", $2); sub(/^11th Gen Intel\\(R\\) Core\\(TM\\) /, \"\", $2); sub(/ @.*/, \"\", $2); print $2; exit }'; printf 'Memory: '; free -b | awk '/Mem:/ { printf \"%.1f GB / %.1f GB\\n\", $3 / 1000000000, $2 / 1000000000 }'; printf 'Disk: '; df -h / | awk 'NR==2 { print $3 \" / \" $2 \" (\" $5 \")\" }'"]
      stdout: StdioCollector {
        onStreamFinished: bar.systemInfo = text.trim()
      }
    }

    Process {
      id: calendarProbe
      command: ["gcalcli", "agenda", "--tsv", "--military", "today", "7 days"]
      stdout: StdioCollector {
        onStreamFinished: {
          const lines = this.text.trim().split("\n")
          bar.calendarEvents = lines.slice(1).filter(line => line.length > 0).map(line => {
            const fields = line.split("\t")
            return {
              startDate: fields[0],
              startTime: fields[1],
              endDate: fields[2],
              endTime: fields[3],
              title: fields.slice(4).join("\t")
            }
          })
        }
      }
    }

    Timer {
      interval: 300000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: calendarProbe.running = true
    }

    Timer {
      interval: 1000
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        cpuProbe.running = true
        memoryProbe.running = true
        networkProbe.running = true
        volumeProbe.running = true
        notificationProbe.running = true
      }
    }

    Row {
      id: leftModules
      anchors.left: parent.left
      anchors.leftMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      BarModule {
        width: 31
        BarLabel {
          anchors.centerIn: parent
          text: ""
          color: "#fab489"
          font.pixelSize: 17
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            systemInfoProbe.running = true
            systemPopup.visible = !systemPopup.visible
          }
        }
      }

      BarModule {
        width: workspaceRow.width + 12
        Row {
          id: workspaceRow
          anchors.centerIn: parent
          spacing: 5
          Repeater {
            model: root.workspaceCount
            delegate: Rectangle {
              required property int index
              property int workspaceId: index + 1
              property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === workspaceId
              width: active ? 18 : 7
              height: 7
              radius: height / 2
              color: active ? "#fab489" : "#6c5960"
              Behavior on width { NumberAnimation { duration: 140 } }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${parent.workspaceId}`)
                onWheel: wheel => Hyprland.dispatch(`workspace ${wheel.angleDelta.y > 0 ? "e-1" : "e+1"}`)
              }
            }
          }
        }
      }

      BarModule {
        width: Math.min(430, Math.max(80, titleLabel.implicitWidth + 20))
        BarLabel {
          id: titleLabel
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
          color: "#f4d6cd"
          elide: Text.ElideRight
        }
      }
    }

    BarModule {
      id: clockModule
      anchors.centerIn: parent
      width: clockLabel.implicitWidth + 20
      BarLabel {
        id: clockLabel
        anchors.centerIn: parent
        text: Qt.formatDateTime(root.now, "HH:mm:ss")
        color: "#fab489"
        font.pixelSize: 16
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mediaPopup.visible = !mediaPopup.visible
      }
    }

    Row {
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      BarModule {
        width: cpuContent.width + 20
        Row {
          id: cpuContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel { text: ""; color: "#d5e294" }
          BarLabel { text: `${bar.cpuUsage}%`; color: "#d5e294" }
        }
      }

      BarModule {
        width: memoryContent.width + 20
        Row {
          id: memoryContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel { text: ""; color: "#f7a6cb" }
          BarLabel { text: `${bar.memoryUsage}GB`; color: "#f7a6cb" }
        }
      }

      BarModule {
        width: networkContent.width + 20
        Row {
          id: networkContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel { text: "󰛳"; color: "#89b4fa" }
          BarLabel { text: bar.downloadRate; color: "#89b4fa" }
          BarLabel { text: "󰛴"; color: "#89b4fa" }
          BarLabel { text: bar.uploadRate; color: "#89b4fa" }
        }
      }

      BarModule {
        width: volumeContent.width + 20
        Row {
          id: volumeContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel {
            text: bar.muted ? "" : ""
            color: bar.muted ? "#c8ada6" : "#febeb4"
          }
          BarLabel {
            text: bar.muted ? "muted" : `${bar.volume}%`
            color: bar.muted ? "#c8ada6" : "#febeb4"
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            bar.muted = !bar.muted
            muteProcess.running = true
          }
          onWheel: wheel => {
            volumeAdjust.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", wheel.angleDelta.y > 0 ? "5%+" : "5%-"]
            volumeAdjust.running = true
          }
        }
      }

      BarModule {
        visible: trayRepeater.count > 0
        width: trayRow.width + 12
        Row {
          id: trayRow
          anchors.centerIn: parent
          spacing: 6
          Repeater {
            id: trayRepeater
            model: SystemTray.items
            delegate: Item {
              required property var modelData
              implicitWidth: 17
              implicitHeight: 17
              IconImage {
                anchors.fill: parent
                source: String(parent.modelData.icon).includes("input-keyboard-symbolic") || parent.modelData.id === "Fcitx" ? "" : parent.modelData.icon
              }
              BarLabel {
                anchors.centerIn: parent
                text: parent.modelData.id === "Fcitx" ? (bar.japaneseInput ? "あ" : "A") : ""
                font.family: parent.modelData.id === "Fcitx" && bar.japaneseInput ? "Noto Sans CJK JP" : "Lexend"
                font.pixelSize: 15
                color: parent.modelData.id === "Fcitx" ? "#fab489" : "#cdd6f4"
                visible: String(parent.modelData.icon).includes("input-keyboard-symbolic") || parent.modelData.id === "Fcitx"
              }
              MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                  if (mouse.button === Qt.LeftButton) parent.modelData.activate()
                  else if (mouse.button === Qt.MiddleButton) parent.modelData.secondaryActivate()
                  else if (parent.modelData.hasMenu) parent.modelData.display(bar, parent.x, parent.y + parent.height)
                }
              }
            }
          }
        }
      }

      BarModule {
        width: 29
        BarLabel {
          anchors.centerIn: parent
          text: bar.hasNotifications ? "󰡟" : "󰅺"
          color: "#cdd6f4"
          font.pixelSize: 16
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: notificationToggle.running = true
        }
      }

      BarModule {
        visible: root.battery !== null
        width: batteryLabel.implicitWidth + 18
        BarLabel {
          id: batteryLabel
          anchors.centerIn: parent
          text: root.battery ? `${Math.round(root.battery.percentage * 100)}% ${root.batteryGlyph(root.battery)}` : ""
          color: root.battery && root.battery.percentage <= 0.1 ? "#f38ba8" : "#ffffff"
        }
      }

      BarModule {
        width: 29
        BarLabel {
          anchors.centerIn: parent
          anchors.verticalCenterOffset: 2
          text: "⏻"
          color: "#f38ba8"
          font.pixelSize: 17
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: powerMenu.running = true
        }
      }
    }

    Process { id: muteProcess; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"] }
    Process { id: volumeAdjust }
    Process { id: notificationToggle; command: ["sh", "-c", "sleep 0.1 && swaync-client -t -sw"] }
    Process { id: powerMenu; command: ["wlogout", "-p", "layer-shell"] }

    PopupWindow {
      id: systemPopup
      anchor.window: bar
      anchor.rect.x: 6
      anchor.rect.y: bar.height + 6
      implicitWidth: 360
      implicitHeight: systemColumn.implicitHeight + 28
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#181825"
        border.color: "#46363a"
        border.width: 1
        opacity: systemPopup.visible ? 1 : 0
        transform: Translate {
          y: systemPopup.visible ? 0 : -14
          Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Column {
          id: systemColumn
          anchors.fill: parent
          anchors.margins: 14
          spacing: 8
          BarLabel { text: "  System"; color: "#fab489"; font.pixelSize: 17 }
          BarLabel {
            width: parent.width
            text: bar.systemInfo
            wrapMode: Text.Wrap
            lineHeight: 1.35
            color: "#cdd6f4"
          }
        }
      }
    }

    PopupWindow {
      id: mediaPopup
      anchor.window: bar
      anchor.rect.x: bar.width / 2 - width / 2
      anchor.rect.y: bar.height + 6
      implicitWidth: 600
      implicitHeight: 440
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#181825"
        border.color: "#46363a"
        border.width: 1
        opacity: mediaPopup.visible ? 1 : 0
        transform: Translate {
          y: mediaPopup.visible ? 0 : -14
          Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        RowLayout {
          anchors.fill: parent
          anchors.margins: 16
          spacing: 22

          ColumnLayout {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: 10
            BarLabel {
              Layout.fillWidth: true
              text: Qt.formatDateTime(root.now, "dddd, d MMMM")
              color: "#ecc774"
              font.pixelSize: 17
            }
            Grid {
              columns: 7
              columnSpacing: 8
              rowSpacing: 8
              Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]
                delegate: BarLabel {
                  required property var modelData
                  width: 28
                  horizontalAlignment: Text.AlignHCenter
                  text: modelData
                  color: "#f9e2af"
                }
              }
              Repeater {
                model: 42
                delegate: Rectangle {
                  required property int index
                  property date today: root.now
                  property int firstDay: new Date(today.getFullYear(), today.getMonth(), 1).getDay()
                  property int day: index - firstDay + 1
                  property int monthDays: new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()
                  width: 28
                  height: 28
                  radius: 14
                  color: day === today.getDate() ? "#f38ba8" : "transparent"
                  // Invisible Grid children collapse; retain empty leading cells for alignment.
                  opacity: day > 0 && day <= monthDays ? 1 : 0
                  BarLabel {
                    anchors.centerIn: parent
                    text: parent.day
                    color: parent.day === parent.today.getDate() ? "#181825" : "#cdd6f4"
                  }
                }
              }
            }
            BarLabel {
              Layout.topMargin: 4
              text: "Upcoming"
              color: "#a6e3a1"
              font.pixelSize: 15
            }
            ListView {
              Layout.fillWidth: true
              Layout.preferredHeight: 82
              clip: true
              spacing: 3
              model: bar.calendarEvents
              delegate: Row {
                required property var modelData
                width: parent.width
                spacing: 7
                BarLabel {
                  width: 72
                  text: `${modelData.startDate.slice(5)} ${modelData.startTime}`
                  color: "#89b4fa"
                  font.pixelSize: 12
                }
                BarLabel {
                  width: parent.width - 79
                  text: modelData.title
                  color: "#cdd6f4"
                  font.pixelSize: 12
                  elide: Text.ElideRight
                }
              }
              BarLabel {
                anchors.centerIn: parent
                visible: bar.calendarEvents.length === 0
                text: "No upcoming events"
                color: "#9399b2"
                font.pixelSize: 12
              }
            }
          }

          Rectangle { Layout.fillHeight: true; Layout.preferredWidth: 1; color: "#46363a" }

          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            BarLabel { text: "Now Playing"; color: "#a6e3a1"; font.pixelSize: 17 }
            Image {
              Layout.alignment: Qt.AlignHCenter
              Layout.preferredWidth: 130
              Layout.preferredHeight: 130
              source: root.player ? root.player.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              visible: source !== ""
            }
            BarLabel {
              Layout.fillWidth: true
              text: root.player ? (root.player.trackTitle || "Unknown Title") : "Nothing playing"
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              color: "#f4d6cd"
            }
            BarLabel {
              Layout.fillWidth: true
              text: root.player ? (root.player.trackArtist || root.player.identity) : "Open a media player to begin"
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              color: "#9399b2"
            }
            RowLayout {
              Layout.alignment: Qt.AlignHCenter
              spacing: 18
              BarLabel {
                text: ""
                color: root.player && root.player.canGoPrevious ? "#cdd6f4" : "#585b70"
                MouseArea { anchors.fill: parent; enabled: root.player && root.player.canGoPrevious; onClicked: root.player.previous() }
              }
              BarLabel {
                text: root.player && root.player.isPlaying ? "" : ""
                font.pixelSize: 22
                color: root.player ? "#a6e3a1" : "#585b70"
                MouseArea { anchors.fill: parent; enabled: root.player && root.player.canTogglePlaying; onClicked: root.player.togglePlaying() }
              }
              BarLabel {
                text: ""
                color: root.player && root.player.canGoNext ? "#cdd6f4" : "#585b70"
                MouseArea { anchors.fill: parent; enabled: root.player && root.player.canGoNext; onClicked: root.player.next() }
              }
            }
          }
        }
      }
    }
  }
}
