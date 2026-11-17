# WebOS: show the fastfetch card in every interactive bash shell.
# webos-shell (used by kitty/foot) sets WEBOS_FASTFETCH_SHOWN so the card is
# not printed twice when the terminal wrapper already drew it.
[[ $- == *i* ]] || return 0
if [[ -z ${WEBOS_FASTFETCH_SHOWN:-} ]] && command -v webos-fastfetch >/dev/null 2>&1; then
	export WEBOS_FASTFETCH_SHOWN=1
	webos-fastfetch 2>/dev/null || true
fi
