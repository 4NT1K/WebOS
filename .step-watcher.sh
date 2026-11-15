#!/usr/bin/env bash
cd /home/brah/sanusos
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
    notify "Step complete: ISO built. Running verification."
    printf 'docker exec webos-build bash -lc "/sanusos/.post-iso.sh"\n' | newgrp docker >/dev/null 2>&1 || true
    sleep 5
    # wait for verify
    while ! grep -aq '^rc=' build/verify.log 2>/dev/null; do sleep 15; done
    if grep -aq '^rc=0' build/verify.log 2>/dev/null; then
      notify "Step complete: ISO verification finished (see build/verify.log)."
      # commit audit/status and mark done (no shutdown)
      {
        echo; echo "## Final build"; echo "- ISO built and verified: $(date -u +'%Y-%m-%d %H:%M UTC')"; echo "- See build/verify.log and build/iso-build.log";
      } >> AUDIT.md
      touch build/.all-done
      git add AUDIT.md STATUS.md build/verify.log 2>/dev/null || true
      git add -u AUDIT.md STATUS.md 2>/dev/null || true
      git -c user.name='WebOS Build' -c user.email='dev@webos.local' commit -m "build: ISO verified and ready" >/dev/null 2>&1 || true
      git push origin main >/dev/null 2>&1 || true
      notify "WebOS ISO ready. All steps complete."
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
