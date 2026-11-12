# Build status (auto-updated ~every 5 min) — 2026-11-12 17:35:55 UTC

- Local time: 2026-11-12 17:35:55 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 137 of 180 complete                                           Load avg: 13.0, 13.5, 13.8
>>> Jobs: 137 of 180 complete, 1 running                                Load avg: 13.0, 13.5, 13.8
>>> Emerging (138 of 180) gui-libs/xdg-desktop-portal-wlr-0.8.5::gentoo
>>> Jobs: 137 of 180 complete, 1 running                                Load avg: 13.0, 13.5, 13.8
>>> Jobs: 137 of 180 complete                                           Load avg: 12.1, 13.3, 13.7
>>> Installing (138 of 180) gui-libs/xdg-desktop-portal-wlr-0.8.5::gentoo
>>> Jobs: 137 of 180 complete, 1 merge wait                             Load avg: 12.1, 13.3, 13.7
>>> Completed (138 of 180) gui-libs/xdg-desktop-portal-wlr-0.8.5::gentoo
>>> Jobs: 137 of 180 complete                                           Load avg: 12.1, 13.3, 13.7
>>> Jobs: 138 of 180 complete                                           Load avg: 12.1, 13.3, 13.7
>>> Jobs: 138 of 180 complete, 1 running                                Load avg: 12.1, 13.3, 13.7
>>> Emerging (139 of 180) media-video/mpv-0.42.0::gentoo
>>> Jobs: 138 of 180 complete, 1 running                                Load avg: 12.1, 13.3, 13.7
>>> Jobs: 138 of 180 complete                                           Load avg: 13.1, 13.4, 13.8
>>> Installing (139 of 180) media-video/mpv-0.42.0::gentoo
>>> Jobs: 138 of 180 complete, 1 merge wait                             Load avg: 13.1, 13.4, 13.8
>>> Completed (139 of 180) media-video/mpv-0.42.0::gentoo
>>> Jobs: 138 of 180 complete                                           Load avg: 11.4, 13.0, 13.7
>>> Jobs: 139 of 180 complete                                           Load avg: 11.4, 13.0, 13.7
>>> Jobs: 139 of 180 complete, 1 running                                Load avg: 11.4, 13.0, 13.7
>>> Emerging (140 of 180) sys-apps/xdg-desktop-portal-gtk-1.15.3::gentoo
>>> Jobs: 139 of 180 complete, 1 running                                Load avg: 11.4, 13.0, 13.7
>>> Jobs: 139 of 180 complete                                           Load avg: 10.7, 12.9, 13.6
>>> Installing (140 of 180) sys-apps/xdg-desktop-portal-gtk-1.15.3::gentoo
>>> Jobs: 139 of 180 complete, 1 merge wait                             Load avg: 10.7, 12.9, 13.6
>>> Completed (140 of 180) sys-apps/xdg-desktop-portal-gtk-1.15.3::gentoo
>>> Jobs: 139 of 180 complete                                           Load avg: 10.7, 12.9, 13.6
>>> Jobs: 140 of 180 complete                                           Load avg: 10.7, 12.9, 13.6
>>> Jobs: 140 of 180 complete, 1 running                                Load avg: 10.7, 12.9, 13.6
>>> Emerging (141 of 180) x11-terms/alacritty-0.17.0::gentoo
>>> Jobs: 140 of 180 complete, 1 running                                Load avg: 10.7, 12.9, 13.6
>>> Jobs: 140 of 180 complete                                           Load avg: 10.4, 12.6, 13.5
>>> Installing (141 of 180) x11-terms/alacritty-0.17.0::gentoo
>>> Jobs: 140 of 180 complete, 1 merge wait                             Load avg: 10.4, 12.6, 13.5
>>> Completed (141 of 180) x11-terms/alacritty-0.17.0::gentoo
>>> Jobs: 140 of 180 complete                                           Load avg: 10.4, 12.6, 13.5
>>> Jobs: 141 of 180 complete                                           Load avg: 10.4, 12.6, 13.5
>>> Jobs: 141 of 180 complete, 1 running                                Load avg: 10.4, 12.6, 13.5
>>> Emerging (142 of 180) x11-terms/wezterm-20260929.043349::gentoo
>>> Jobs: 141 of 180 complete, 1 running                                Load avg: 10.4, 12.6, 13.5
```
- Result: rc=1

## rootfs-build
```
     rm -r /var/cache/binpkgs/*
16. Rebuild world:
   emerge --ask --emptytree @world
[1] https://wiki.gentoo.org/wiki/Project:Toolchain/23.0_profile_transition
[2] https://wiki.gentoo.org/wiki/Project:Toolchain/23.0_profile_timeline
[3] https://www.gentoo.org/support/news-items/2019-06-05-amd64-17-1-profiles-are-now-stable.html
[4] https://www.gentoo.org/support/news-items/2022-12-01-systemd-usrmerge.html
[5] https://wiki.gentoo.org/wiki/Project:Toolchain/23.0_update_table
[6] https://wiki.gentoo.org/wiki/Changing_the_CHOST_variable#Verifying_things_work
Configuring pkg...
 [32m*[0m Re-applying the SanusOS rice
[34m  ->[0m backed up /etc/gtk-4.0/settings.ini -> /etc/gtk-4.0/settings.ini.sanus-orig
[34m  ->[0m backed up /etc/gtk-3.0/gtk.css -> /etc/gtk-3.0/gtk.css.sanus-orig
[34m  ->[0m backed up /etc/gtk-4.0/gtk.css -> /etc/gtk-4.0/gtk.css.sanus-orig
[32m  ok[0m system GTK theme written to /etc/gtk-3.0 and /etc/gtk-4.0
[33mwarn[0m greetd is not installed; skipping login setup
[34m  ->[0m applying rice to /etc/skel
[32m  ok[0m rice applied to /etc/skel
[34m  ->[0m applying rice to /root
[32m  ok[0m rice applied to /root
[32m  ok[0m system rice applied
==> rootfs: finalizing
>>> Regenerating /etc/ld.so.cache...
  ok rootfs exported to /sanusos/build/rootfs (7.4G)
rc=0
```
- Result: rc=0

## Artifacts
```
total 20K
-rwxr-xr-x 1 root root 6.4M Nov 12 02:18 build/chroot/usr/bin/sanus-installer
iso: (none)
checksums: (none)
```
