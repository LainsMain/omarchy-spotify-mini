.pragma library

// Match the desktop app, not web browsers or KDE Connect's remote-player proxy.
function isSpotify(player) {
    return !!player && /^org\.mpris\.MediaPlayer2\.spotify(?:[._-]|$)/i.test(String(player.dbusName || ""));
}

function selectPlayer(players) {
    var paused = null;
    for (var i = 0; i < players.length; i++) {
        var player = players[i];
        if (!isSpotify(player)) continue;
        if (player.isPlaying) return player;
        if (!paused) paused = player;
    }
    return paused;
}

function timestamp(seconds) {
    var value = Number(seconds);
    var total = isFinite(value) ? Math.max(0, Math.floor(value)) : 0;
    return Math.floor(total / 60) + ":" + (total % 60 < 10 ? "0" : "") + total % 60;
}
