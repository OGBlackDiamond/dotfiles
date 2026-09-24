import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
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
  property var defaultAudioSink: Pipewire.defaultAudioSink

  // PipeWire only exposes live volume state for tracked objects.
  PwObjectTracker {
    objects: [root.defaultAudioSink]
  }

  function batteryGlyph(battery) {
    const level = Math.min(9, Math.max(0, Math.floor(battery.percentage * 10)))
    const discharging = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    const charging = ["󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"]
    return battery.iconName.includes("charging") ? charging[level] : discharging[level]
  }

  function weatherGlyph(code, isDay = true) {
    if (code === 0) return isDay ? "󰖙" : "󰖔"
    if (code <= 2) return isDay ? "󰖕" : "󰖔"
    if (code === 3) return "󰖐"
    if (code <= 48) return "󰖑"
    if (code <= 57) return "󰖗"
    if (code <= 67) return "󰖖"
    if (code <= 77) return "󰖘"
    if (code <= 82) return "󰖖"
    return "󰖓"
  }

  function weatherDescription(code) {
    if (code === 0) return "Clear sky"
    if (code <= 2) return "Partly cloudy"
    if (code === 3) return "Overcast"
    if (code <= 48) return "Foggy"
    if (code <= 57) return "Drizzle"
    if (code <= 67) return "Rain"
    if (code <= 77) return "Snow"
    if (code <= 82) return "Showers"
    return "Thunderstorms"
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  component BarModule: Rectangle {
    color: "#2d2722"
    radius: 6
    height: 29
  }

  component BarLabel: Text {
    font.family: "Lexend"
    font.pixelSize: 14
    font.weight: Font.DemiBold
    verticalAlignment: Text.AlignVCenter
    color: "#e5d5c2"
  }

  component HistoryGraph: Canvas {
    property var samples: []
    property color lineColor: "#cdd6f4"
    property real maximum: 100
    antialiasing: true

    onSamplesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)
      if (samples.length < 2 || width <= 0 || height <= 0) return

      const scale = Math.max(1, maximum)
      context.beginPath()
      for (let index = 0; index < samples.length; index++) {
        const x = index * width / (samples.length - 1)
        const y = height - Math.min(1, Math.max(0, samples[index] / scale)) * height
        if (index === 0) context.moveTo(x, y)
        else context.lineTo(x, y)
      }
      context.lineTo(width, height)
      context.lineTo(0, height)
      context.closePath()
      context.globalAlpha = 0.18
      context.fillStyle = lineColor
      context.fill()
      context.globalAlpha = 1
      context.strokeStyle = lineColor
      context.lineWidth = 1.5
      context.lineJoin = "round"
      context.beginPath()
      for (let index = 0; index < samples.length; index++) {
        const x = index * width / (samples.length - 1)
        const y = height - Math.min(1, Math.max(0, samples[index] / scale)) * height
        if (index === 0) context.moveTo(x, y)
        else context.lineTo(x, y)
      }
      context.stroke()
    }
  }

  component DualHistoryGraph: Canvas {
    property var uploadSamples: []
    property var downloadSamples: []
    property color uploadColor: "#94e2d5"
    property color downloadColor: "#89b4fa"
    property real maximum: 1
    antialiasing: true

    onUploadSamplesChanged: requestPaint()
    onDownloadSamplesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
      const context = getContext("2d")
      context.clearRect(0, 0, width, height)
      if (width <= 0 || height <= 0) return

      const middle = height / 2
      context.strokeStyle = "#5b5352"
      context.lineWidth = 1
      context.beginPath()
      context.moveTo(0, middle)
      context.lineTo(width, middle)
      context.stroke()

      const scale = Math.max(1, maximum)
      const draw = (samples, color, direction) => {
        if (samples.length < 2) return
        context.beginPath()
        for (let index = 0; index < samples.length; index++) {
          const x = index * width / (samples.length - 1)
          const y = middle - direction * Math.min(1, Math.max(0, samples[index] / scale)) * middle
          if (index === 0) context.moveTo(x, y)
          else context.lineTo(x, y)
        }
        context.lineTo(width, middle)
        context.lineTo(0, middle)
        context.closePath()
        context.globalAlpha = 0.18
        context.fillStyle = color
        context.fill()
        context.globalAlpha = 1
        context.strokeStyle = color
        context.lineWidth = 1.5
        context.lineJoin = "round"
        context.beginPath()
        for (let index = 0; index < samples.length; index++) {
          const x = index * width / (samples.length - 1)
          const y = middle - direction * Math.min(1, Math.max(0, samples[index] / scale)) * middle
          if (index === 0) context.moveTo(x, y)
          else context.lineTo(x, y)
        }
        context.stroke()
      }
      draw(uploadSamples, uploadColor, 1)
      draw(downloadSamples, downloadColor, -1)
    }
  }

  PanelWindow {
    id: bar
    // Prefer the enabled internal panel; otherwise stay on one stable dock display.
    screen: Quickshell.screens.find(screen => {
      const monitor = Hyprland.monitorFor(screen)
      return monitor?.name === "eDP-1" && monitor.activeWorkspace !== null
    }) || Quickshell.screens.find(screen => Hyprland.monitorFor(screen)?.description === "Dell Inc. DELL U2424HE 8NCB4X3") || Quickshell.screens[0]
    anchors {
      top: true
      left: true
      right: true
    }
    implicitHeight: 43
    color: "transparent"
    exclusiveZone: 43

    property string cpuUsage: "--"
    property string memoryUsage: "--"
    property string downloadRate: "--"
    property string uploadRate: "--"
    property var cpuHistory: []
    property var cpuCoreUsage: []
    property var previousCpuCounters: []
    property var memoryHistory: []
    property var memoryStats: ({})
    property var downloadHistory: []
    property var uploadHistory: []
    property string networkInterface: ""
    property real networkRxBytes: 0
    property real networkTxBytes: 0
    property real previousRxBytes: -1
    property real previousTxBytes: -1
    property double previousNetworkSampleMs: 0
    property string volume: root.defaultAudioSink?.audio
      ? Math.round(root.defaultAudioSink.audio.volume * 100).toString()
      : "--"
    property bool muted: root.defaultAudioSink?.audio?.muted || false
    property bool hasNotifications: false
    property string hostname: ""
    property string systemInfo: "Loading system information..."
    property var calendarEvents: []
    property var weather: null
    property int weatherHourIndex: 0

    FileView {
      id: weatherLocationFile
      path: Quickshell.env("HOME") + "/.config/quickshell/weather.local.json"
      watchChanges: true
      onFileChanged: reload()
      onLoaded: weatherFetch.running = true
      JsonAdapter {
        id: weatherLocation
        property string name: ""
        property real latitude: 0
        property real longitude: 0
        property string timezone: "auto"
      }
    }

    Process {
      id: weatherFetch
      command: [
        "curl", "--fail", "--silent", "--show-error",
        `https://api.open-meteo.com/v1/forecast?latitude=${weatherLocation.latitude}&longitude=${weatherLocation.longitude}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day&hourly=temperature_2m,precipitation_probability,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=${weatherLocation.timezone}&forecast_days=7`
      ]
      stdout: StdioCollector {
        onStreamFinished: {
          try {
            const forecast = JSON.parse(this.text)
            bar.weather = forecast
            const currentHour = forecast.current.time.slice(0, 13)
            bar.weatherHourIndex = Math.max(0, forecast.hourly.time.findIndex(time => time.startsWith(currentHour)))
          } catch (error) {
            console.warn(`Unable to parse Open-Meteo response: ${error}`)
          }
        }
      }
      stderr: SplitParser {
        onRead: data => console.warn(`Open-Meteo request failed: ${data}`)
      }
    }

    Timer {
      interval: 900000
      running: true
      repeat: true
      onTriggered: if (!weatherFetch.running) weatherFetch.running = true
    }

    FileView {
      id: cpuStatFile
      path: "/proc/stat"
      onLoaded: bar.updateCpu(text())
    }

    FileView {
      id: memoryInfoFile
      path: "/proc/meminfo"
      onLoaded: bar.updateMemory(text())
    }

    FileView {
      id: networkRouteFile
      path: "/proc/net/route"
      onLoaded: bar.updateNetworkInterface(text())
    }

    FileView {
      id: networkDevFile
      path: "/proc/net/dev"
      onLoaded: bar.updateNetwork(text())
    }

    function formatNetworkRate(bytesPerSecond) {
      const kilobytesPerSecond = Math.max(0, bytesPerSecond) / 1000
      return kilobytesPerSecond >= 1000
        ? `${(kilobytesPerSecond / 1000).toFixed(1)}M`
        : `${Math.round(kilobytesPerSecond)}K`
    }

    function appendHistory(history, value) {
      const next = history.concat([value])
      return next.length > 60 ? next.slice(next.length - 60) : next
    }

    function historyMaximum(history) {
      return history.reduce((maximum, value) => Math.max(maximum, value), 1)
    }

    function formatBytes(bytes) {
      const units = ["B", "KiB", "MiB", "GiB", "TiB"]
      let value = Math.max(0, bytes)
      let unit = 0
      while (value >= 1024 && unit < units.length - 1) {
        value /= 1024
        unit++
      }
      return `${value >= 10 || unit === 0 ? Math.round(value) : value.toFixed(1)} ${units[unit]}`
    }

    function updateCpu(text) {
      const counters = text.split("\n").filter(line => /^cpu\d*\s/.test(line)).map(line =>
        line.trim().split(/\s+/).slice(1, 9).map(Number))
      if (counters.length === 0) return

      if (previousCpuCounters.length === counters.length) {
        const usage = counters.map((current, index) => {
          const previous = previousCpuCounters[index]
          const totalDelta = current.reduce((sum, value) => sum + value, 0)
            - previous.reduce((sum, value) => sum + value, 0)
          const idleDelta = (current[3] + current[4]) - (previous[3] + previous[4])
          return totalDelta > 0 ? Math.max(0, Math.min(100, 100 * (totalDelta - idleDelta) / totalDelta)) : 0
        })
        cpuUsage = Math.round(usage[0]).toString()
        cpuCoreUsage = usage.slice(1)
        cpuHistory = appendHistory(cpuHistory, usage[0])
      }
      previousCpuCounters = counters
    }

    function updateMemory(text) {
      const values = {}
      text.split("\n").forEach(line => {
        const match = /^(\w+):\s+(\d+)/.exec(line)
        if (match) values[match[1]] = Number(match[2]) * 1024
      })
      if (!values.MemTotal || !values.MemAvailable) return

      const used = values.MemTotal - values.MemAvailable
      memoryStats = {
        total: values.MemTotal,
        used: used,
        available: values.MemAvailable,
        free: values.MemFree || 0,
        buffers: values.Buffers || 0,
        cache: (values.Cached || 0) + (values.SReclaimable || 0),
        swapTotal: values.SwapTotal || 0,
        swapUsed: (values.SwapTotal || 0) - (values.SwapFree || 0)
      }
      memoryUsage = (used / 1024 / 1024 / 1024).toFixed(1)
      memoryHistory = appendHistory(memoryHistory, 100 * used / values.MemTotal)
    }

    function updateNetworkInterface(text) {
      const route = text.split("\n").slice(1).map(line => line.trim().split(/\s+/)).find(fields =>
        fields.length >= 4 && fields[1] === "00000000" && (Number.parseInt(fields[3], 16) & 1))
      const nextInterface = route ? route[0] : ""
      if (networkInterface !== nextInterface) {
        networkInterface = nextInterface
        previousRxBytes = -1
        previousTxBytes = -1
        previousNetworkSampleMs = 0
        downloadHistory = []
        uploadHistory = []
      }
    }

    function updateNetwork(text) {
      if (!networkInterface) return
      const line = text.split("\n").find(entry => entry.trim().startsWith(`${networkInterface}:`))
      if (!line) return
      const fields = line.split(":")[1].trim().split(/\s+/).map(Number)
      if (fields.length < 9) return

      const now = Date.now()
      const rxBytes = fields[0]
      const txBytes = fields[8]
      if (previousNetworkSampleMs > 0) {
        const seconds = (now - previousNetworkSampleMs) / 1000
        const downBytesPerSecond = Math.max(0, rxBytes - previousRxBytes) / seconds
        const upBytesPerSecond = Math.max(0, txBytes - previousTxBytes) / seconds
        downloadRate = formatNetworkRate(downBytesPerSecond)
        uploadRate = formatNetworkRate(upBytesPerSecond)
        downloadHistory = appendHistory(downloadHistory, downBytesPerSecond)
        uploadHistory = appendHistory(uploadHistory, upBytesPerSecond)
      }
      previousRxBytes = rxBytes
      previousTxBytes = txBytes
      previousNetworkSampleMs = now
      networkRxBytes = rxBytes
      networkTxBytes = txBytes
    }

    Process {
      id: notificationSubscription
      command: ["swaync-client", "-swb"]
      running: true
      onRunningChanged: if (!running) notificationReconnect.restart()
      stdout: SplitParser {
        onRead: data => {
          try {
            const state = JSON.parse(data)
            bar.hasNotifications = state.alt === "notification"
          } catch (error) {
            console.warn(`Unable to parse SwayNC state: ${data}`)
          }
        }
      }
    }

    Timer {
      id: notificationReconnect
      interval: 1000
      onTriggered: notificationSubscription.running = true
    }

    Process {
      id: hostnameProbe
      command: ["uname", "-n"]
      running: true
      stdout: StdioCollector {
        onStreamFinished: bar.hostname = this.text.trim()
      }
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
      interval: 500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: {
        cpuStatFile.reload()
        memoryInfoFile.reload()
        networkRouteFile.reload()
        networkDevFile.reload()
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

    Row {
      id: centerModules
      anchors.centerIn: parent
      spacing: 3

      BarModule {
        id: clockModule
        width: clockLabel.implicitWidth + 20
        color: Qt.rgba(45 / 255, 39 / 255, 34 / 255, 0.72)
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

      BarModule {
        id: weatherModule
        width: weatherContent.width + 20
        color: Qt.rgba(45 / 255, 39 / 255, 34 / 255, 0.72)
        Row {
          id: weatherContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel {
            text: bar.weather ? root.weatherGlyph(bar.weather.current.weather_code, bar.weather.current.is_day === 1) : "󰖐"
            color: "#89b4fa"
          }
          BarLabel {
            text: bar.weather ? `${Math.round(bar.weather.current.temperature_2m)}°` : "--"
            color: "#89b4fa"
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (!bar.weather && !weatherFetch.running) weatherFetch.running = true
            weatherPopup.visible = !weatherPopup.visible
          }
        }
      }
    }

    Row {
      id: rightModules
      anchors.right: parent.right
      anchors.rightMargin: 6
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      BarModule {
        id: cpuModule
        width: cpuContent.width + 20
        Row {
          id: cpuContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel { text: ""; color: "#d5e294" }
          HistoryGraph {
            width: 42
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            samples: bar.cpuHistory
            lineColor: "#d5e294"
          }
          BarLabel { text: `${bar.cpuUsage}%`; color: "#d5e294" }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: cpuPopup.visible = !cpuPopup.visible
        }
      }

      BarModule {
        id: memoryModule
        width: memoryContent.width + 20
        Row {
          id: memoryContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel { text: ""; color: "#f7a6cb" }
          HistoryGraph {
            width: 42
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            samples: bar.memoryHistory
            lineColor: "#f7a6cb"
          }
          BarLabel { text: `${bar.memoryUsage}GB`; color: "#f7a6cb" }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: memoryPopup.visible = !memoryPopup.visible
        }
      }

      BarModule {
        id: networkModule
        width: networkContent.width + 20
        Row {
          id: networkContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel { text: "󰛳"; color: "#89b4fa" }
          BarLabel { text: bar.downloadRate; color: "#89b4fa" }
          DualHistoryGraph {
            width: 42
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            uploadSamples: bar.uploadHistory
            downloadSamples: bar.downloadHistory
            maximum: Math.max(bar.historyMaximum(bar.uploadHistory), bar.historyMaximum(bar.downloadHistory))
          }
          BarLabel { text: "󰛴"; color: "#89b4fa" }
          BarLabel { text: bar.uploadRate; color: "#94e2d5" }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: networkPopup.visible = !networkPopup.visible
        }
      }

      BarModule {
        width: volumeContent.width + 20
        Row {
          id: volumeContent
          anchors.centerIn: parent
          spacing: 5
          BarLabel {
            text: {
              if (bar.muted) return ""
              const sink = root.defaultAudioSink
              return sink && /bluez|headphones?|headset|airpods|buds/i.test(`${sink.name} ${sink.description}`)
                ? ""
                : ""
            }
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
              readonly property bool isFcitx: modelData.id === "Fcitx"
              implicitWidth: 17
              implicitHeight: 17
              IconImage {
                id: trayIcon
                anchors.fill: parent
                source: parent.isFcitx || String(parent.modelData.icon).includes("input-keyboard-symbolic")
                  ? ""
                  : parent.modelData.icon
              }
              BarLabel {
                anchors.centerIn: parent
                text: parent.isFcitx && /japanese|mozc|anthy|skk|hiragana|katakana/i.test(parent.modelData.tooltipTitle)
                  ? "あ"
                  : parent.isFcitx ? "A" : ""
                font.family: parent.isFcitx ? "Noto Sans CJK JP" : "Lexend"
                font.pixelSize: 15
                color: parent.isFcitx ? "#fab489" : "#cdd6f4"
                visible: parent.isFcitx || trayIcon.source === ""
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
      id: cpuPopup
      anchor.window: bar
      anchor.rect.x: rightModules.x + cpuModule.x + cpuModule.width / 2 - width / 2
      anchor.rect.y: bar.height + 6
      implicitWidth: 470
      implicitHeight: cpuDetails.implicitHeight + 28
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(47 / 255, 49 / 255, 35 / 255, 0.88)
        border.color: "#66704c"
        border.width: 1
        opacity: cpuPopup.visible ? 1 : 0
        transform: Translate {
          y: cpuPopup.visible ? 0 : -14
          Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Column {
          id: cpuDetails
          anchors.fill: parent
          anchors.margins: 14
          spacing: 10
          Row {
            spacing: 8
            BarLabel { text: "CPU"; color: "#d5e294"; font.pixelSize: 18 }
            BarLabel { text: `${bar.cpuUsage}% overall`; color: "#cdd6f4"; font.pixelSize: 14 }
            BarLabel { text: "Last 30 seconds"; color: "#9399b2"; font.pixelSize: 12 }
          }
          HistoryGraph {
            width: parent.width
            height: 70
            samples: bar.cpuHistory
            lineColor: "#d5e294"
          }
          Rectangle { width: parent.width; height: 1; color: "#46363a" }
          BarLabel { text: "Logical CPUs"; color: "#f9e2af"; font.pixelSize: 14 }
          Grid {
            columns: 2
            columnSpacing: 18
            rowSpacing: 5
            Repeater {
              model: bar.cpuCoreUsage
              delegate: Row {
                required property int index
                required property var modelData
                width: 200
                BarLabel { width: 62; text: `CPU ${index}`; color: "#cdd6f4"; font.pixelSize: 13 }
                Rectangle {
                  width: 92
                  height: 7
                  anchors.verticalCenter: parent.verticalCenter
                  radius: 4
                  color: "#46363a"
                  Rectangle {
                    width: parent.width * Math.min(1, modelData / 100)
                    height: parent.height
                    radius: parent.radius
                    color: "#d5e294"
                  }
                }
                BarLabel {
                  width: 40
                  horizontalAlignment: Text.AlignRight
                  text: `${Math.round(modelData)}%`
                  color: "#d5e294"
                  font.pixelSize: 13
                }
              }
            }
          }
        }
      }
    }

    PopupWindow {
      id: memoryPopup
      anchor.window: bar
      anchor.rect.x: rightModules.x + memoryModule.x + memoryModule.width / 2 - width / 2
      anchor.rect.y: bar.height + 6
      implicitWidth: 430
      implicitHeight: memoryDetails.implicitHeight + 28
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(48 / 255, 37 / 255, 44 / 255, 0.88)
        border.color: "#754c63"
        border.width: 1
        opacity: memoryPopup.visible ? 1 : 0
        transform: Translate {
          y: memoryPopup.visible ? 0 : -14
          Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Column {
          id: memoryDetails
          anchors.fill: parent
          anchors.margins: 14
          spacing: 10
          Row {
            spacing: 8
            BarLabel { text: "Memory"; color: "#f7a6cb"; font.pixelSize: 18 }
            BarLabel {
              text: bar.memoryStats.total ? `${bar.formatBytes(bar.memoryStats.used)} used of ${bar.formatBytes(bar.memoryStats.total)}` : "Loading..."
              color: "#cdd6f4"
              font.pixelSize: 14
            }
          }
          HistoryGraph {
            width: parent.width
            height: 70
            samples: bar.memoryHistory
            lineColor: "#f7a6cb"
          }
          Rectangle { width: parent.width; height: 1; color: "#46363a" }
          Grid {
            columns: 2
            columnSpacing: 50
            rowSpacing: 6
            Repeater {
              model: [
                ["Used", bar.memoryStats.used],
                ["Available", bar.memoryStats.available],
                ["Cache", bar.memoryStats.cache],
                ["Buffers", bar.memoryStats.buffers],
                ["Free", bar.memoryStats.free],
                ["Swap", bar.memoryStats.swapUsed]
              ]
              delegate: Row {
                required property var modelData
                width: 170
                BarLabel { width: 78; text: modelData[0]; color: "#9399b2"; font.pixelSize: 13 }
                BarLabel {
                  text: bar.memoryStats.total ? bar.formatBytes(modelData[1]) : "--"
                  color: "#cdd6f4"
                  font.pixelSize: 13
                }
              }
            }
          }
          BarLabel {
            text: bar.memoryStats.swapTotal ? `Swap: ${bar.formatBytes(bar.memoryStats.swapUsed)} / ${bar.formatBytes(bar.memoryStats.swapTotal)}` : "No swap configured"
            color: "#9399b2"
            font.pixelSize: 12
          }
        }
      }
    }

    PopupWindow {
      id: networkPopup
      anchor.window: bar
      anchor.rect.x: rightModules.x + networkModule.x + networkModule.width / 2 - width / 2
      anchor.rect.y: bar.height + 6
      implicitWidth: 450
      implicitHeight: networkDetails.implicitHeight + 28
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(36 / 255, 41 / 255, 51 / 255, 0.88)
        border.color: "#4d6387"
        border.width: 1
        opacity: networkPopup.visible ? 1 : 0
        transform: Translate {
          y: networkPopup.visible ? 0 : -14
          Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Column {
          id: networkDetails
          anchors.fill: parent
          anchors.margins: 14
          spacing: 10
          Row {
            spacing: 8
            BarLabel { text: "Network"; color: "#89b4fa"; font.pixelSize: 18 }
            BarLabel { text: bar.networkInterface || "No default route"; color: "#cdd6f4"; font.pixelSize: 14 }
            BarLabel { text: "Last 30 seconds"; color: "#9399b2"; font.pixelSize: 12 }
          }
          Row {
            width: parent.width
            BarLabel { width: parent.width / 2; text: `󰛴  ${bar.uploadRate}`; color: "#94e2d5"; font.pixelSize: 14 }
            BarLabel { width: parent.width / 2; horizontalAlignment: Text.AlignRight; text: `󰛳  ${bar.downloadRate}`; color: "#89b4fa"; font.pixelSize: 14 }
          }
          DualHistoryGraph {
            width: parent.width
            height: 120
            uploadSamples: bar.uploadHistory
            downloadSamples: bar.downloadHistory
            maximum: Math.max(bar.historyMaximum(bar.uploadHistory), bar.historyMaximum(bar.downloadHistory))
          }
          Rectangle { width: parent.width; height: 1; color: "#46363a" }
          Row {
            spacing: 24
            BarLabel { text: `Received: ${bar.formatBytes(bar.networkRxBytes)}`; color: "#cdd6f4"; font.pixelSize: 13 }
            BarLabel { text: `Sent: ${bar.formatBytes(bar.networkTxBytes)}`; color: "#cdd6f4"; font.pixelSize: 13 }
          }
        }
      }
    }

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
        color: Qt.rgba(36 / 255, 31 / 255, 27 / 255, 0.82)
        border.color: "#725442"
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
          BarLabel { text: bar.hostname || "System"; color: "#fab489"; font.pixelSize: 17 }
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
      anchor.rect.x: centerModules.x + clockModule.x + clockModule.width / 2 - width / 2
      anchor.rect.y: bar.height + 6
      implicitWidth: 600
      implicitHeight: 440
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(36 / 255, 31 / 255, 27 / 255, 0.82)
        border.color: "#725442"
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
            Layout.fillWidth: true
            Layout.preferredWidth: 1
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
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            spacing: 10
            BarLabel {
              Layout.fillWidth: true
              horizontalAlignment: Text.AlignHCenter
              text: "Now Playing"
              color: "#a6e3a1"
              font.pixelSize: 17
            }
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

    PopupWindow {
      id: weatherPopup
      anchor.window: bar
      anchor.rect.x: centerModules.x + weatherModule.x + weatherModule.width / 2 - width / 2
      anchor.rect.y: bar.height + 6
      implicitWidth: 590
      implicitHeight: weatherColumn.implicitHeight + 28
      visible: false
      grabFocus: true
      color: "transparent"
      Rectangle {
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(36 / 255, 31 / 255, 27 / 255, 0.82)
        border.color: "#725442"
        border.width: 1
        opacity: weatherPopup.visible ? 1 : 0
        transform: Translate {
          y: weatherPopup.visible ? 0 : -14
          Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Column {
          id: weatherColumn
          anchors.fill: parent
          anchors.margins: 14
          spacing: 13

          Row {
            width: parent.width
            spacing: 8
            BarLabel {
              text: weatherLocation.name || "Weather"
              color: "#89b4fa"
              font.pixelSize: 18
            }
            BarLabel {
              anchors.verticalCenter: parent.verticalCenter
              text: bar.weather ? `Updated ${bar.weather.current.time.slice(11)}` : "Loading forecast..."
              color: "#9399b2"
              font.pixelSize: 12
            }
          }

          Row {
            width: parent.width
            spacing: 16
            BarLabel {
              width: 68
              horizontalAlignment: Text.AlignHCenter
              text: bar.weather ? root.weatherGlyph(bar.weather.current.weather_code, bar.weather.current.is_day === 1) : "󰖐"
              color: "#89b4fa"
              font.pixelSize: 42
            }
            Column {
              width: 155
              spacing: 2
              BarLabel {
                text: bar.weather ? `${Math.round(bar.weather.current.temperature_2m)}°F` : "--"
                color: "#cdd6f4"
                font.pixelSize: 30
              }
              BarLabel {
                text: bar.weather ? root.weatherDescription(bar.weather.current.weather_code) : ""
                color: "#cdd6f4"
                font.pixelSize: 13
              }
              BarLabel {
                text: bar.weather ? `Feels like ${Math.round(bar.weather.current.apparent_temperature)}°F` : ""
                color: "#9399b2"
                font.pixelSize: 12
              }
            }
            Column {
              spacing: 4
              BarLabel {
                text: bar.weather ? `󰖎  ${bar.weather.current.relative_humidity_2m}% humidity` : ""
                color: "#a6e3a1"
                font.pixelSize: 13
              }
              BarLabel {
                text: bar.weather ? `󰖝  ${Math.round(bar.weather.current.wind_speed_10m)} mph wind` : ""
                color: "#a6e3a1"
                font.pixelSize: 13
              }
              BarLabel {
                text: bar.weather ? `󰖛  Sunrise ${bar.weather.daily.sunrise[0].slice(11)}  Sunset ${bar.weather.daily.sunset[0].slice(11)}` : ""
                color: "#a6e3a1"
                font.pixelSize: 13
              }
            }
          }

          Rectangle { width: parent.width; height: 1; color: "#46363a" }

          Column {
            width: parent.width
            spacing: 7
            BarLabel { text: "Next hours"; color: "#f9e2af"; font.pixelSize: 14 }
            Row {
              spacing: 18
              Repeater {
                model: 6
                delegate: Column {
                  required property int index
                  width: 75
                  spacing: 2
                  BarLabel {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: bar.weather ? bar.weather.hourly.time[bar.weatherHourIndex + index].slice(11) : "--:--"
                    color: "#9399b2"
                    font.pixelSize: 12
                  }
                  BarLabel {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: bar.weather ? root.weatherGlyph(bar.weather.hourly.weather_code[bar.weatherHourIndex + index]) : ""
                    color: "#89b4fa"
                    font.pixelSize: 18
                  }
                  BarLabel {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: bar.weather ? `${Math.round(bar.weather.hourly.temperature_2m[bar.weatherHourIndex + index])}°` : ""
                    color: "#cdd6f4"
                    font.pixelSize: 13
                  }
                  BarLabel {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: bar.weather && bar.weather.hourly.precipitation_probability[bar.weatherHourIndex + index] > 0
                      ? `${bar.weather.hourly.precipitation_probability[bar.weatherHourIndex + index]}% rain`
                      : ""
                    color: "#94e2d5"
                    font.pixelSize: 11
                  }
                }
              }
            }
          }

          Rectangle { width: parent.width; height: 1; color: "#46363a" }

          Column {
            width: parent.width
            spacing: 7
            BarLabel { text: "Five-day forecast"; color: "#f9e2af"; font.pixelSize: 14 }
            Repeater {
              model: 5
              delegate: Row {
                required property int index
                width: parent.width
                spacing: 8
                BarLabel {
                  width: 96
                  text: bar.weather
                    ? index === 0 ? "Today" : Qt.formatDateTime(new Date(`${bar.weather.daily.time[index]}T12:00`), "ddd")
                    : "--"
                  color: "#cdd6f4"
                  font.pixelSize: 13
                }
                BarLabel {
                  width: 24
                  horizontalAlignment: Text.AlignHCenter
                  text: bar.weather ? root.weatherGlyph(bar.weather.daily.weather_code[index]) : ""
                  color: "#89b4fa"
                  font.pixelSize: 16
                }
                BarLabel {
                  width: 170
                  text: bar.weather ? root.weatherDescription(bar.weather.daily.weather_code[index]) : ""
                  color: "#9399b2"
                  font.pixelSize: 13
                }
                BarLabel {
                  width: 90
                  horizontalAlignment: Text.AlignRight
                  text: bar.weather ? `${Math.round(bar.weather.daily.temperature_2m_max[index])}° / ${Math.round(bar.weather.daily.temperature_2m_min[index])}°` : ""
                  color: "#cdd6f4"
                  font.pixelSize: 13
                }
                BarLabel {
                  width: 105
                  horizontalAlignment: Text.AlignRight
                  text: bar.weather && bar.weather.daily.precipitation_probability_max[index] > 0
                    ? `${bar.weather.daily.precipitation_probability_max[index]}% rain`
                    : ""
                  color: "#94e2d5"
                  font.pixelSize: 12
                }
              }
            }
          }
        }
      }
    }
  }
}
