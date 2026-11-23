/* WebOS now-playing bridge for BetterSoundCloud.
 *
 * Plugins are sandboxed (no fs, no process), but bsc.storage writes a JSON
 * file we can read from the rice: ~/.config/BetterSoundCloud/plugin-data/
 * webos-now-playing.json. webos-music and webos-mpris watch that file.
 *
 * SoundCloud's own title is often "<uploader> - <song> #tag" with the uploader
 * repeated as the artist, which looks like a playlist in the bar. Use the
 * track URL to recover the real artist and song before publishing.
 */

function cleanTrack(nowPlaying) {
  const title = String(nowPlaying.title || "");
  let artist = String(nowPlaying.artist || "");
  let song = title;

  let account = "";
  let slug = "";
  try {
    const parts = new URL(nowPlaying.url || "").pathname.split("/").filter(Boolean);
    if (parts.length >= 2 && parts[parts.length - 2] !== "sets") {
      account = parts[parts.length - 2];
      slug = parts[parts.length - 1];
    }
  } catch (_) {
    /* No URL: keep the values SoundCloud gave us. */
  }

  const accountName = decodeURIComponent(account).replace(/[-_]+/g, " ").trim();
  const separator = song.indexOf(" - ");
  if (accountName && separator > 0) {
    const prefix = song.slice(0, separator).trim();
    if (prefix.toLowerCase() === accountName.toLowerCase()) {
      song = song.slice(separator + 3).trim();
    }
  }

  // Trailing hashtags are promo tags, not part of the song name.
  song = song.replace(/\s+#\S+.*$/, "").trim();

  // "/mandy-archive/jaydes-addict" means artist "jaydes", song "addict".
  if (slug) {
    const bits = decodeURIComponent(slug).split("-");
    if (bits.length > 1) {
      const guessedArtist = bits[0].replace(/_/g, " ").trim();
      const guessedSong = bits.slice(1).join("-").replace(/_/g, " ").trim();
      if (guessedSong && song.toLowerCase().includes(guessedSong.toLowerCase())) {
        artist = guessedArtist;
        song = guessedSong;
      }
    }
  }

  return {
    title: song,
    artist: artist,
    artwork: nowPlaying.artwork || "",
    elapsed: Number(nowPlaying.elapsed) || 0,
    duration: Number(nowPlaying.duration) || 0,
    playing: nowPlaying.playing === true,
    url: nowPlaying.url || ""
  };
}

function publish(bsc, nowPlaying) {
  // Fire-and-forget: storage writes are local and tiny, and a rejection here
  // must never take the plugin host down.
  void bsc.storage.set("track", nowPlaying ? cleanTrack(nowPlaying) : null).catch(() => {});
}

module.exports = {
  activate(bsc) {
    const unsubscribe = bsc.nowPlaying.onChange((nowPlaying) => publish(bsc, nowPlaying));
    void bsc.nowPlaying.get().then((nowPlaying) => publish(bsc, nowPlaying));
    return () => unsubscribe();
  }
};
