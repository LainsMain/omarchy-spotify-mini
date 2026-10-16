const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const model = {};
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../Model.js'), 'utf8').replace(/^\.pragma library\s*/, ''), model);
const spotify = (name, playing) => ({dbusName: name, isPlaying: playing});

test('a playing browser or remote proxy must not trigger the Spotify indicator', () => {
  assert.equal(model.selectPlayer([
    spotify('org.mpris.MediaPlayer2.chromium.instance123', true),
    spotify('org.mpris.MediaPlayer2.kdeconnect.mpris.spotify', true),
    spotify('org.mpris.MediaPlayer2.spotifyfake', true),
    {}, null
  ]), null);
});
test('supports Spotify instance names and prefers playback over a paused instance', () => {
  const paused = spotify('org.mpris.MediaPlayer2.spotify', false);
  const playing = spotify('org.mpris.MediaPlayer2.spotify.instance42', true);
  assert.equal(model.selectPlayer([paused, playing]), playing);
  assert.equal(model.selectPlayer([paused]), paused);
  assert.equal(model.selectPlayer([]), null);
});
test('track times handle missing metadata, invalid numbers, and long tracks', () => {
  for (const value of [undefined, NaN, Infinity, -5]) assert.equal(model.timestamp(value), '0:00');
  assert.equal(model.timestamp(9.9), '0:09');
  assert.equal(model.timestamp(65), '1:05');
  assert.equal(model.timestamp(3601), '60:01');
});
