# WebOS: show the fastfetch card in every interactive fish shell.
# webos-shell (used by kitty/foot) sets WEBOS_FASTFETCH_SHOWN so the card is
# not printed twice when the terminal wrapper already drew it.
if status is-interactive
    if test -z "$WEBOS_FASTFETCH_SHOWN"; and command -q webos-fastfetch
        set -gx WEBOS_FASTFETCH_SHOWN 1
        webos-fastfetch 2>/dev/null; or true
    end
end
