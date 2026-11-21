#!/usr/bin/env bash
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"
notify(){ ./scripts/notify-user.sh "$1" "WebOS Build" >/dev/null 2>&1 || true; }
# wait for finalize-rootfs
while true; do
  if grep -aq '^rc=0' build/finalize-rootfs.log 2>/dev/null; then
    notify "Step complete: rootfs re-exported (WebOS + desktops). Starting ISO build."
    break
  elif grep -aq '^rc=[1-9]' build/finalize-rootfs.log 2>/dev/null; then
    notify "Step failed: finalize-rootfs. Check build/finalize-rootfs.log"
    exit 1
  fi
  sleep 20
done
# wait for ISO
while true; do
  if grep -aq '^rc=0' build/iso-build.log 2>/dev/null && (ls build/webos-*.iso >/dev/null 2>&1 || ls build/webos-*.iso >/dev/null 2>&1); then
    notify "Step complete: ISO built. Run ./.post-iso.sh to verify it."
    sleep 5
    # wait for verify
    while ! grep -aq '^rc=' build/verify.log 2>/dev/null; do sleep 15; done
    if grep -aq '^rc=0' build/verify.log 2>/dev/null; then
      notify "Step complete: ISO verification finished (see build/verify.log)."
      # Leave tracked docs alone; a human decides what to commit and publish.
      touch build/.all-done
      notify "WebOS ISO ready. Review build/verify.log, then commit/publish manually."
    else
      notify "Step failed/issues: ISO verification. Check build/verify.log"
    fi
    exit 0
  elif grep -aq '^rc=[1-9]' build/iso-build.log 2>/dev/null; then
    notify "Step failed: ISO build. Check build/iso-build.log"
    exit 1
  fi
  sleep 30
done
