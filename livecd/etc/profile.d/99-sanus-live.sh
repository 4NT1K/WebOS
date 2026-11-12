# SanusOS live medium: turn the root TTY login into the live session.
#
# Present only on the live squashfs. The installer removes this file, the
# /etc/sanus-live marker, the getty override and the inittab backup from the
# target system, so an installed SanusOS boots to a normal login.
#
# Only fires for a root login shell on tty1, and only once (SANUS_LIVE_SESSION
# guards against the session itself sourcing this file again).

if [[ -f /etc/sanus-live \
   && -z ${SANUS_LIVE_SESSION:-} \
   && ${EUID:-$(id -u)} -eq 0 \
   && "$(tty 2>/dev/null)" == "/dev/tty1" \
   && -x /usr/local/bin/sanus-live-session ]]; then
	export SANUS_LIVE_SESSION=1
	exec /usr/local/bin/sanus-live-session
fi
