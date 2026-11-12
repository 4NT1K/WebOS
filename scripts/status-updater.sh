#!/usr/bin/env bash
set -Eeuo pipefail
cd /home/brah/sanusos
INTERVAL=${STATUS_INTERVAL:-300}
LOG=/tmp/sanus-status-updater.log

fmt_dur() {
  local s=$1
  (( s < 0 )) && s=0
  local h=$((s/3600)) m=$(((s%3600)/60))
  if (( h > 0 )); then printf '%dh %dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

progress_section() {
  local phase pct eta detail now
  now=$(date +%s)
  phase="idle"; pct=0; eta="unknown"; detail="No active build detected."

  # 1) desktop-fix emerge
  if [[ -f build/desktop-fix.log ]]; then
    local line rc
    line=$(tr '\r' '\n' < build/desktop-fix.log | grep -E 'Jobs: [0-9]+ of [0-9]+ complete' | tail -n 1 || true)
    rc=$(grep -a '^rc=' build/desktop-fix.log 2>/dev/null | tail -n 1 || true)
    if [[ -n "$line" && -z "$rc" ]]; then
      local done total
      done=$(sed -n 's/.*Jobs: \([0-9][0-9]*\) of \([0-9][0-9]*\) complete.*/\1/p' <<<"$line" | tail -n1)
      total=$(sed -n 's/.*Jobs: \([0-9][0-9]*\) of \([0-9][0-9]*\) complete.*/\2/p' <<<"$line" | tail -n1)
      if [[ -n "$done" && -n "$total" && "$total" -gt 0 ]]; then
        phase="Corrective desktop emerge"
        pct=$(( 5 + done * 55 / total ))
        local start elapsed rate remain
        start=$(stat -c %Y build/desktop-fix.log 2>/dev/null || echo $now)
        # better: use first line time not available; estimate from mtime of log start approx via file birth not reliable; use process elapsed if possible not here. fallback heuristic
        elapsed=$(( now - start ))
        (( elapsed < 600 )) && elapsed=3600
        # rough: assume emerged so far took elapsed proportionally? not accurate; use package rate heuristic
        remain=$(( (total - done) * 90 ))
        eta=$(fmt_dur $remain)
        detail="$line"
      fi
    fi
  fi

  # 2) finalize rootfs
  if [[ -f build/finalize-rootfs.log ]]; then
    local frc
    frc=$(grep -a '^rc=' build/finalize-rootfs.log 2>/dev/null | tail -n 1 || true)
    if [[ -z "$frc" ]]; then
      phase="Finalize rootfs (rebuild installer + re-export)"
      # detect substep
      if grep -aq 're-exporting' build/finalize-rootfs.log 2>/dev/null; then
        pct=68; eta="10-30m"; detail="Re-exporting rootfs (rsync)."
      elif grep -aq 'Emerging (1 of 1) app-admin/sanus-installer' build/finalize-rootfs.log 2>/dev/null; then
        pct=63; eta="10-20m"; detail="Rebuilding WebOS-branded installer."
      else
        pct=62; eta="15-30m"; detail="Applying branding and preparing installer."
      fi
    elif [[ "$frc" == "rc=0" ]]; then
      # only set baseline if later phases not active
      [[ "$phase" == "idle" || "$phase" == "Corrective desktop emerge" ]] && true
    fi
  fi

  # 3) ISO build
  if [[ -f build/iso-build.log ]]; then
    local irc
    irc=$(grep -a '^rc=' build/iso-build.log 2>/dev/null | tail -n 1 || true)
    if [[ -z "$irc" ]]; then
      phase="ISO build"
      if grep -aq 'grub-mkrescue' build/iso-build.log 2>/dev/null; then
        pct=92; eta="5-15m"; detail="Building hybrid ISO image (grub-mkrescue/xorriso)."
      elif grep -aq 'compressing live filesystem' build/iso-build.log 2>/dev/null; then
        pct=82; eta="15-45m"; detail="Compressing live filesystem (squashfs, zstd)."
      elif grep -aq 'building live initramfs' build/iso-build.log 2>/dev/null; then
        pct=74; eta="35-60m"; detail="Building initramfs (dracut)."
      elif grep -aq 'iso: building live medium' build/iso-build.log 2>/dev/null; then
        pct=72; eta="40-70m"; detail="Preparing ISO staging."
      else
        pct=72; eta="40-70m"; detail="ISO stage running."
      fi
    elif [[ "$irc" == "rc=0" ]]; then
      phase="ISO verification / publish"
      if [[ -f build/.all-done ]]; then
        pct=100; eta="done"; detail="All steps complete. ISO ready."
      elif grep -aq 'rc=0' build/verify.log 2>/dev/null; then
        pct=99; eta="<5m"; detail="Verification passed, finalizing."
      elif [[ -f build/verify.log ]]; then
        pct=97; eta="5-10m"; detail="Verifying ISO contents."
      else
        pct=96; eta="5-15m"; detail="ISO built; verification pending."
      fi
    else
      phase="ISO build failed"
      pct=70; eta="needs fix"; detail="Last ISO attempt failed (see iso-build log)."
    fi
  fi

  # if desktop-fix done and no later active phase
  if grep -aq '^rc=0' build/desktop-fix.log 2>/dev/null && [[ "$phase" == "Corrective desktop emerge" ]]; then
    phase="Post-emerge (awaiting next step)"
    pct=60; eta="unknown"; detail="Desktop packages emerged."
  fi

  echo "## Progress"
  echo
  echo "- **Overall:** ${pct}% complete (estimated)"
  echo "- **Phase:** ${phase}"
  echo "- **ETA:** ${eta}"
  echo "- **Detail:** ${detail}"
  echo
  # simple bar
  local filled=$((pct/5)) empty=$((20-filled))
  local bar=""; for ((i=0;i<filled;i++)); do bar+="█"; done; for ((i=0;i<empty;i++)); do bar+="░"; done
  echo "[${bar}] ${pct}%"
  echo
  echo "_Updated every ~5 minutes. Percent/ETA are estimates._"
  echo
}

snapshot() {
  local now_utc now_local
  now_utc=$(date -u +'%Y-%m-%d %H:%M:%S UTC')
  now_local=$(date +'%Y-%m-%d %H:%M:%S %Z')
  echo "# WebOS build status"
  echo
  progress_section
  echo "- UTC: ${now_utc}"
  echo "- Local: ${now_local}"
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
  if [[ -f build/finalize-rootfs.log ]]; then
    echo "## finalize-rootfs"
    echo '```'
    tr '\r' '\n' < build/finalize-rootfs.log | sed '/^[[:space:]]*$/d' | tail -n 25 || true
    echo '```'
    grep -aq '^rc=' build/finalize-rootfs.log && echo "- Result: $(tail -n 1 <(grep -a '^rc=' build/finalize-rootfs.log))" || echo "- Result: running"
    echo
  fi
  if [[ -f build/rootfs-build.log ]]; then
    echo "## rootfs-build"
    echo '```'
    tr '\r' '\n' < build/rootfs-build.log | sed '/^[[:space:]]*$/d' | tail -n 15 || true
    echo '```'
    grep -aq '^rc=' build/rootfs-build.log && echo "- Result: $(tail -n 1 <(grep -a '^rc=' build/rootfs-build.log))" || echo "- Result: unknown"
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
  if [[ -f build/verify.log ]]; then
    echo "## verify"
    echo '```'
    tr '\r' '\n' < build/verify.log | sed '/^[[:space:]]*$/d' | tail -n 40 || true
    echo '```'
    grep -aq '^rc=' build/verify.log && echo "- Result: $(tail -n 1 <(grep -a '^rc=' build/verify.log))" || echo "- Result: running"
    echo
  fi
  echo "## Artifacts"
  echo '```'
  ls -lh build/rootfs 2>/dev/null | head -1 || echo "rootfs: (none)"
  ls -lh build/chroot/usr/bin/sanus-installer 2>/dev/null || echo "installer: (none)"
  ls -lh build/webos-*.iso build/sanus-*.iso 2>/dev/null || echo "iso: (none)"
  ls -lh build/*.sha256 2>/dev/null || echo "checksums: (none)"
  echo '```'
}

post_update() {
  local ts msg short
  ts=$(date -u +'%Y-%m-%d %H:%M UTC')
  snapshot > STATUS.md
  short=$(tr '\r' '\n' < build/iso-build.log 2>/dev/null | grep -E '==>|mksquashfs|xorriso|grub|dracut|rc=' | tail -n 1 | sed 's/[[:space:]]\+/ /g' | cut -c1-100 || true)
  [[ -z "$short" ]] && short=$(tr '\r' '\n' < build/desktop-fix.log 2>/dev/null | grep -E 'Jobs:|Emerging|Installing|rc=' | tail -n 1 | cut -c1-100 || true)
  [[ -z "$short" ]] && short="progress update"
  msg="status: ${ts} — ${short}"
  git add STATUS.md >/dev/null 2>&1 || true
  if ! git diff --cached --quiet 2>/dev/null; then
    git -c user.name='WebOS Build' -c user.email='dev@webos.local' commit -q -m "$msg" >/dev/null 2>&1 || true
    git push origin main >/dev/null 2>&1 || true
  fi
}

while true; do
  post_update >> "$LOG" 2>&1 || true
  if [[ -f build/.all-done ]]; then
    post_update >> "$LOG" 2>&1 || true
    echo "done $(date -u +'%Y-%m-%dT%H:%MZ')" >> "$LOG"
    exit 0
  fi
  sleep "$INTERVAL"
done
