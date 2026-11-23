/* WebOS now-playing bridge for BetterSoundCloud.
 *
 * Plugins are sandboxed (no fs, no process), but bsc.storage writes a JSON
 * file we can read from the rice: ~/.config/BetterSoundCloud/plugin-data/
 * webos-now-playing.json. webos-music and webos-mpris watch that file.
 *
 * SoundCloud titles are usually "Artist - Song". Two cases need care:
 *   - "mandy - mascara", uploader mandy-archive: "mandy" is the uploader, and
 *     the real artist is encoded in the URL slug (jaydes-addict -> jaydes).
 *   - "Lucy bedroque - Urr mad", uploader selftoincubation: the prefix is the
 *     real artist, so the URL slug (urr-mad) must not be split into artist/song.
 * Compare the title prefix with the uploader account before trusting the slug.
 */

function normalize(value) {
  return decodeURIComponent(String(value || ""))
    .toLowerCase()
    .replace(/[-_]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function cleanTrack(nowPlaying) {
  const rawArtist = String(nowPlaying.artist || "");
  let song = String(nowPlaying.title || "").replace(/\s+#\S+.*$/, "").trim();
  let artist = rawArtist;

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

  const accountName = normalize(account);
  const separator = song.indexOf(" - ");
  if (separator > 0) {
    const prefix = song.slice(0, separator).trim();
    const remainder = song.slice(separator + 3).trim();
    const normalizedPrefix = normalize(prefix);
    const isUploader =
      accountName &&
      (normalizedPrefix === accountName ||
        accountName.indexOf(normalizedPrefix + " ") === 0 ||
        normalizedPrefix.indexOf(accountName + " ") === 0);

    if (isUploader) {
      // The prefix is just the uploader's name. Recover the real artist from
      // the slug, but only when it is not the uploader itself.
      const bits = decodeURIComponent(slug || "").split("-");
      const slugArtist = bits.length > 1 ? bits[0].replace(/_/g, " ").trim() : "";
      artist = slugArtist && normalize(slugArtist) !== accountName ? slugArtist : rawArtist;
      const slugSong = bits.length > 1 ? bits.slice(1).join("-").replace(/_/g, " ").trim() : "";
      if (slugSong && normalize(remainder).indexOf(normalize(slugSong)) >= 0) {
        song = slugSong;
      } else {
        song = remainder;
      }
    } else {
      // A genuine "Artist - Song" credit: use it verbatim. Never split the
      // URL slug here, or "Urr mad" becomes artist "urr", song "mad".
      artist = prefix;
      song = remainder;
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
