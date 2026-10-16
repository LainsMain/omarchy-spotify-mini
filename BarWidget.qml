import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons
import "Model.js" as Model

BarWidget {
    id: root
    moduleName: "lainsmain.spotify-mini"

    readonly property var players: Mpris.players.values
    readonly property var player: Model.selectPlayer(players)
    readonly property bool playing: player !== null && player.isPlaying
    readonly property bool shown: player !== null
    readonly property string title: player ? String(player.trackTitle || "Spotify") : "Spotify"
    readonly property string artist: player ? String(player.trackArtist || "") : ""
    readonly property string album: player ? String(player.trackAlbum || "") : ""
    readonly property string artwork: player ? String(player.trackArtUrl || "") : ""
    readonly property color panelForeground: root.bar ? root.bar.foreground : Color.foreground
    readonly property string panelFont: root.bar ? root.bar.fontFamily : Style.font.family
    property bool popupOpen: false
    property int clockTick: 0
    readonly property real duration: player && player.lengthSupported ? Math.max(0, player.length) : 0
    readonly property real playhead: {
        var tick = clockTick;
        return player && player.positionSupported ? Math.max(0, Math.min(duration, player.position)) : 0;
    }

    visible: shown
    implicitWidth: shown ? Style.bar.iconSlot : 0
    implicitHeight: shown ? barSize : 0

    function close() {
        popupOpen = false;
    }
    function toggle() {
        if (player)
            popupOpen = !popupOpen;
    }
    function playPause() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
    function seekTo(value) {
        if (player && player.canSeek && duration > 0)
            player.position = Math.max(0, Math.min(duration, value));
    }
    function timestamp(seconds) {
        return Model.timestamp(seconds);
    }
    readonly property bool opened: popupOpen
    function open() {
        if (player)
            popupOpen = true;
    }
    onPopupOpenChanged: clockTick++
    onPlayerChanged: if (!player)
        close()

    Timer {
        interval: 1000
        running: root.popupOpen && root.playing
        repeat: true
        onTriggered: root.clockTick++
    }

    IpcHandler {
        target: "lainsmain.spotify-mini"
        function toggle(): void {
            root.toggle();
        }
        function close(): void {
            root.close();
        }
        function playPause(): void {
            root.playPause();
        }
        function seek(seconds: real): void {
            root.seekTo(seconds);
        }
        function status(): string {
            return JSON.stringify({
                available: !!root.player,
                playing: root.playing,
                shown: root.shown,
                popupOpen: root.popupOpen,
                title: root.title,
                artist: root.artist,
                album: root.album,
                artwork: root.artwork,
                position: root.playhead,
                duration: root.duration
            });
        }
    }

    BarIconButton {
        id: indicator
        anchors.fill: parent
        bar: root.bar
        tooltipText: root.title + (root.artist ? " — " + root.artist : "")
        text: "󰓇"
        foreground: root.bar ? root.bar.barForeground : Color.foreground
        onPressed: function (button) {
            if (button === Qt.MiddleButton)
                root.playPause();
            else
                root.toggle();
        }
    }

    KeyboardPanel {
        id: popup
        anchorItem: indicator
        owner: root
        bar: root.bar
        open: root.popupOpen
        focusTarget: keyCatcher
        contentWidth: popup.fittedContentWidth(Style.space(400))
        contentHeight: popup.fittedContentHeight(content.implicitHeight)

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onSpacePressed: root.playPause()
            Keys.onLeftPressed: root.seekTo(root.playhead - 5)
            Keys.onRightPressed: root.seekTo(root.playhead + 5)
        }

        Column {
            id: content
            width: parent.width
            spacing: Style.space(14)

            // Use the same hero, status treatment and dividers as native panels.
            Item {
                width: parent.width
                implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)
                Text {
                    id: heroIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰓇"
                    color: root.panelForeground
                    font.family: root.panelFont
                    font.pixelSize: Style.font.display
                }
                Column {
                    id: heroLabels
                    anchors.left: heroIcon.right
                    anchors.leftMargin: Style.space(14)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(2)
                    Text {
                        width: parent.width
                        text: "Spotify"
                        color: root.panelForeground
                        font.family: root.panelFont
                        font.pixelSize: Style.font.title
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: root.playing ? "NOW PLAYING" : "PAUSED"
                        color: Qt.darker(root.panelForeground, 1.4)
                        font.family: root.panelFont
                        font.pixelSize: Style.font.caption
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }
            }
            PanelSeparator {
                foreground: root.panelForeground
            }

            Row {
                id: trackRow
                width: parent.width
                spacing: Style.spacing.panelGap
                height: Math.max(art.height, details.implicitHeight)

                Rectangle {
                    id: art
                    width: Style.space(72)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Style.cornerRadius
                    color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
                    clip: true
                    Image {
                        id: cover
                        anchors.fill: parent
                        source: root.popupOpen ? root.artwork : ""
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(256, 256)
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: cover.status !== Image.Ready
                        text: "󰝚"
                        color: Qt.darker(root.panelForeground, 1.4)
                        font.family: root.panelFont
                        font.pixelSize: Style.font.display
                    }
                }

                Column {
                    id: details
                    width: parent.width - art.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacing.labelGap
                    Text {
                        width: parent.width
                        text: root.title
                        textFormat: Text.PlainText
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        color: root.panelForeground
                        font.family: root.panelFont
                        font.pixelSize: Style.font.subtitle
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        text: root.artist
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Qt.darker(root.panelForeground, 1.3)
                        font.family: root.panelFont
                        font.pixelSize: Style.font.bodySmall
                    }
                    Text {
                        width: parent.width
                        text: root.album
                        textFormat: Text.PlainText
                        visible: text !== ""
                        elide: Text.ElideRight
                        color: Qt.darker(root.panelForeground, 1.6)
                        font.family: root.panelFont
                        font.pixelSize: Style.font.caption
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Style.space(2)
                visible: root.duration > 0
                PanelSlider {
                    width: parent.width
                    bar: root.bar
                    minimum: 0
                    maximum: Math.max(1, root.duration)
                    value: root.playhead
                    step: 5
                    enabled: root.player !== null && root.player.canSeek
                    fillColor: root.panelForeground
                    onReleased: function (value) {
                        root.seekTo(value);
                    }
                }
                Row {
                    width: parent.width
                    Text {
                        width: parent.width / 2
                        text: root.timestamp(root.playhead)
                        color: Qt.darker(root.panelForeground, 1.4)
                        font.family: root.panelFont
                        font.pixelSize: Style.font.caption
                    }
                    Text {
                        width: parent.width / 2
                        text: root.timestamp(root.duration)
                        horizontalAlignment: Text.AlignRight
                        color: Qt.darker(root.panelForeground, 1.4)
                        font.family: root.panelFont
                        font.pixelSize: Style.font.caption
                    }
                }
            }

            PanelSeparator {
                foreground: root.panelForeground
            }
            Item {
                width: parent.width
                implicitHeight: controls.implicitHeight
                Row {
                    id: controls
                    anchors.left: parent.left
                    spacing: Style.spacing.controlGap
                    Button {
                        iconText: "󰒮"
                        tooltipText: "Previous track"
                        focusable: true
                        enabled: root.player !== null && root.player.canGoPrevious
                        opacity: enabled ? 1 : 0.35
                        onClicked: if (root.player)
                            root.player.previous()
                    }
                    Button {
                        iconText: root.playing ? "󰏤" : "󰐊"
                        tooltipText: root.playing ? "Pause · Space" : "Play · Space"
                        focusable: true
                        bordered: true
                        foreground: root.panelForeground
                        iconSize: Style.font.iconLarge
                        horizontalPadding: Style.spacing.panelGap
                        enabled: root.player !== null && root.player.canTogglePlaying
                        onClicked: root.playPause()
                    }
                    Button {
                        iconText: "󰒭"
                        tooltipText: "Next track"
                        focusable: true
                        enabled: root.player !== null && root.player.canGoNext
                        opacity: enabled ? 1 : 0.35
                        onClicked: if (root.player)
                            root.player.next()
                    }
                }

                Button {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Open Spotify"
                    focusable: true
                    fontSize: Style.font.bodySmall
                    onClicked: {
                        if (root.player && root.player.canRaise)
                            root.player.raise();
                        else
                            Quickshell.execDetached(["spotify"]);
                        root.close();
                    }
                }
            }
        }
    }
}
