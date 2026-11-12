#!/usr/bin/env bash
msg="${1:-Input needed for WebOS build}"
title="${2:-WebOS Build}"
if command -v notify-send >/dev/null 2>&1; then
  notify-send -u critical "$title" "$msg" >/dev/null 2>&1 && exit 0
fi
if command -v kdialog >/dev/null 2>&1; then
  kdialog --title "$title" --passivepopup "$msg" 10 >/dev/null 2>&1 && exit 0
fi
if command -v zenity >/dev/null 2>&1; then
  zenity --notification --text="$title: $msg" >/dev/null 2>&1 && exit 0
fi
printf '\a' >/dev/tty 2>/dev/null || true
exit 0
