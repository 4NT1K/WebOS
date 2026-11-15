# WebOS — shell environment. Sourced by login shells.
# Managed by webos-theme/webos-theme. Machine-local changes go in
# /etc/profile.d/local.sh or ~/.profile.

# Make sure user-local binaries are on PATH before anything else looks.
case ":${PATH}:" in
	*":${HOME}/.local/bin:"*) ;;
	*) PATH="${HOME}/.local/bin:${PATH}" ;;
esac
export PATH

# Wayland-first toolkit defaults, so GTK/Qt/Electron apps behave even when
# launched outside the Hyprland session.
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"
export GDK_BACKEND="${GDK_BACKEND:-wayland,x11}"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-wayland,x11}"
export CLUTTER_BACKEND="${CLUTTER_BACKEND:-wayland}"
export MOZ_ENABLE_WAYLAND="${MOZ_ENABLE_WAYLAND:-1}"
export ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}"
export _JAVA_AWT_WM_NONREPARENTING=1

# Gaming niceties that only make sense when a session is present.
export GAMEMODE_AUTO="${GAMEMODE_AUTO:-1}"

# WebOS marker.
export WEBOS_OS=1


# Dark mode defaults
export GTK_THEME="${GTK_THEME:-Adwaita:dark}"
export GTK_APPLICATION_PREFER_DARK_THEME=1
export QT_STYLE_OVERRIDE="${QT_STYLE_OVERRIDE:-kvantum-dark}"
