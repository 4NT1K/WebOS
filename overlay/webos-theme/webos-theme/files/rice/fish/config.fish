# WebOS fish — minimal monochrome prompt.
if status is-interactive
    set -g fish_greeting
    if test -z "$WEBOS_FASTFETCH_SHOWN"
        set -gx WEBOS_FASTFETCH_SHOWN 1
        if command -q webos-fastfetch
            webos-fastfetch
        else if command -q fastfetch
            fastfetch
        end
    end
end
