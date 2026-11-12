#!/usr/bin/env bash
msg="${1:-Input needed for WebOS build}"
title="${2:-WebOS Build}"
play_sound() {
  if command -v canberra-gtk-play >/dev/null 2>&1; then
    canberra-gtk-play -i message-new-instant >/dev/null 2>&1 & return 0
  fi
  if command -v paplay >/dev/null 2>&1; then
    for s in /usr/share/sounds/freedesktop/stereo/complete.oga /usr/share/sounds/freedesktop/stereo/message.oga /usr/share/sounds/freedesktop/stereo/bell.oga; do
      [[ -f "$s" ]] && paplay "$s" >/dev/null 2>&1 & return 0
    done
  fi
  if command -v aplay >/dev/null 2>&1; then
    for s in /usr/share/sounds/alsa/Front_Center.wav /usr/share/sounds/freedesktop/stereo/bell.oga; do
      [[ -f "$s" ]] && aplay "$s" >/dev/null 2>&1 & return 0
    done
  fi
  printf '\a' >/dev/tty 2>/dev/null || true
}
if command -v notify-send >/dev/null 2>&1; then
  notify-send -u critical "$title" "$msg" >/dev/null 2>&1 || true
  play_sound
  exit 0
fi
if command -v kdialog >/dev/null 2>&1; then
  kdialog --title "$title" --passivepopup "$msg" 10 >/dev/null 2>&1 || true
  play_sound
  exit 0
fi
if command -v zenity >/dev/null 2>&1; then
  zenity --notification --text="$title: $msg" >/dev/null 2>&1 || true
  play_sound
  exit 0
fi
play_sound
exit 0
