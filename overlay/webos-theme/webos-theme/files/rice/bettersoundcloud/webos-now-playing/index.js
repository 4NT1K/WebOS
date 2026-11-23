/* WebOS now-playing bridge for BetterSoundCloud.
 *
 * Plugins are sandboxed (no fs, no process), but bsc.storage writes a JSON
 * file we can read from the rice: ~/.config/BetterSoundCloud/plugin-data/
 * webos-now-playing.json. webos-music watches that file and shows the track
 * in the Super+M card whenever Spotify is idle.
 */

function publish(bsc, nowPlaying) {
  const track = nowPlaying
    ? {
        title: nowPlaying.title || "",
        artist: nowPlaying.artist || "",
        artwork: nowPlaying.artwork || "",
        elapsed: Number(nowPlaying.elapsed) || 0,
        duration: Number(nowPlaying.duration) || 0,
        playing: nowPlaying.playing === true,
        url: nowPlaying.url || ""
      }
    : null;

  // Fire-and-forget: storage writes are local and tiny, and a rejection here
  // must never take the plugin host down.
  void bsc.storage.set("track", track).catch(() => {});
}

module.exports = {
  activate(bsc) {
    const unsubscribe = bsc.nowPlaying.onChange((nowPlaying) => publish(bsc, nowPlaying));
    void bsc.nowPlaying.get().then((nowPlaying) => publish(bsc, nowPlaying));
    return () => unsubscribe();
  }
};
