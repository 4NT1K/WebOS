#!/usr/bin/env bash
set -Eeuo pipefail
cd /home/brah/sanusos
INTERVAL=${STATUS_INTERVAL:-180}
LOG=/tmp/sanus-status-updater.log

snapshot() {
  local now_utc now_local
  now_utc=$(date -u +'%Y-%m-%d %H:%M:%S UTC')
  now_local=$(date +'%Y-%m-%d %H:%M:%S %Z')
  echo "# Build status (auto-updated ~every 3 min) — ${now_utc}"
  echo
  echo "- Local time: ${now_local}"
  echo "- Host: $(hostname 2>/dev/null || echo unknown)"
  echo
  if [[ -f build/desktop-fix.log ]]; then
    echo "## desktop-fix (corrective @desktop emerge)"
    echo '```'
    tr '\r' '\n' < build/desktop-fix.log | sed '/^[[:space:]]*$/d' | tail -n 40 || true
    echo '```'
    if grep -aq '^rc=' build/desktop-fix.log; then
      echo "- Result: $(tail -n 1 <(grep -a '^rc=' build/desktop-fix.log))"
    else
      echo "- Result: running"
    fi
    echo
  fi
  if [[ -f build/rootfs-build.log ]]; then
    echo "## rootfs-build"
    echo '```'
    tr '\r' '\n' < build/rootfs-build.log | sed '/^[[:space:]]*$/d' | tail -n 25 || true
    echo '```'
    grep -aq '^rc=' build/rootfs-build.log && echo "- Result: $(tail -n 1 <(grep -a '^rc=' build/rootfs-build.log))" || echo "- Result: running/unknown"
    echo
  fi
  if [[ -f build/iso-build.log ]]; then
    echo "## iso-build"
    echo '```'
    tr '\r' '\n' < build/iso-build.log | sed '/^[[:space:]]*$/d' | tail -n 30 || true
    echo '```'
    grep -aq '^rc=' build/iso-build.log && echo "- Result: $(tail -n 1 <(grep -a '^rc=' build/iso-build.log))" || echo "- Result: running"
    echo
  fi
  echo "## Artifacts"
  echo '```'
  ls -lh build/rootfs 2>/dev/null | head -1 || echo "rootfs: (none)"
  ls -lh build/chroot/usr/bin/sanus-installer 2>/dev/null || echo "installer: (none)"
  ls -lh build/sanus-*.iso build/webos-*.iso 2>/dev/null || echo "iso: (none)"
  ls -lh build/*.sha256 2>/dev/null || echo "checksums: (none)"
  echo '```'
}

post_update() {
  local ts msg short
  ts=$(date -u +'%Y-%m-%d %H:%M UTC')
  snapshot > STATUS.md
  short=$(tr '\r' '\n' < build/desktop-fix.log 2>/dev/null | grep -E 'Jobs:|Emerging|Installing|>>>|rc=' | tail -n 1 | sed 's/[[:space:]]\+/ /g' | cut -c1-120 || true)
  [[ -z "$short" && -f build/iso-build.log ]] && short=$(tr '\r' '\n' < build/iso-build.log | grep -E '==>|iso|rc=' | tail -n 1 | cut -c1-120 || true)
  [[ -z "$short" ]] && short="progress update"
  msg="status: ${ts} — ${short}"
  git add STATUS.md >/dev/null 2>&1 || true
  if ! git diff --cached --quiet 2>/dev/null; then
    git -c user.name='SanusOS Build' -c user.email='dev@sanusos.org' commit -q -m "$msg" >/dev/null 2>&1 || true
    git push origin main >/dev/null 2>&1 || true
  fi
}

while true; do
  post_update >> "$LOG" 2>&1 || true
  if [[ -f build/.all-done ]] || ( [[ -f build/iso-build.log ]] && grep -aq '^rc=0' build/iso-build.log && ls build/webos-*.iso build/sanus-*.iso >/dev/null 2>&1 ); then
    post_update >> "$LOG" 2>&1 || true
    echo "done $(date -u +'%Y-%m-%dT%H:%MZ')" >> "$LOG"
    exit 0
  fi
  sleep "$INTERVAL"
done
