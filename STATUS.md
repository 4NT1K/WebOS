# Build status (auto-updated ~every 5 min) — 2026-11-12 17:40:58 UTC

- Local time: 2026-11-12 17:40:58 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
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
>>> Jobs: 141 of 180 complete                                           Load avg: 9.3, 12.7, 13.5
>>> Installing (142 of 180) x11-terms/wezterm-20260929.043349::gentoo
>>> Jobs: 141 of 180 complete, 1 merge wait                             Load avg: 9.3, 12.7, 13.5
>>> Completed (142 of 180) x11-terms/wezterm-20260929.043349::gentoo
>>> Jobs: 141 of 180 complete                                           Load avg: 8.7, 12.6, 13.4
>>> Jobs: 142 of 180 complete                                           Load avg: 8.7, 12.6, 13.4
>>> Jobs: 142 of 180 complete, 1 running                                Load avg: 8.7, 12.6, 13.4
>>> Emerging (143 of 180) kde-plasma/libksysguard-6.8.3::gentoo
>>> Jobs: 142 of 180 complete, 1 running                                Load avg: 8.7, 12.6, 13.4
>>> Jobs: 142 of 180 complete                                           Load avg: 11.7, 12.8, 13.5
>>> Installing (143 of 180) kde-plasma/libksysguard-6.8.3::gentoo
>>> Jobs: 142 of 180 complete, 1 merge wait                             Load avg: 11.7, 12.8, 13.5
>>> Completed (143 of 180) kde-plasma/libksysguard-6.8.3::gentoo
>>> Jobs: 142 of 180 complete                                           Load avg: 11.7, 12.8, 13.5
>>> Jobs: 143 of 180 complete                                           Load avg: 11.7, 12.8, 13.5
>>> Jobs: 143 of 180 complete, 1 running                                Load avg: 11.7, 12.8, 13.5
>>> Emerging (144 of 180) kde-plasma/xdg-desktop-portal-kde-6.8.3::gentoo
>>> Jobs: 143 of 180 complete, 1 running                                Load avg: 11.7, 12.8, 13.5
>>> Jobs: 143 of 180 complete                                           Load avg: 14.2, 13.5, 13.7
>>> Installing (144 of 180) kde-plasma/xdg-desktop-portal-kde-6.8.3::gentoo
>>> Jobs: 143 of 180 complete, 1 merge wait                             Load avg: 14.2, 13.5, 13.7
>>> Completed (144 of 180) kde-plasma/xdg-desktop-portal-kde-6.8.3::gentoo
>>> Jobs: 143 of 180 complete                                           Load avg: 14.2, 13.5, 13.7
>>> Jobs: 144 of 180 complete                                           Load avg: 14.2, 13.5, 13.7
>>> Jobs: 144 of 180 complete, 1 running                                Load avg: 14.2, 13.5, 13.7
>>> Emerging (145 of 180) kde-plasma/aurorae-6.8.3::gentoo
>>> Jobs: 144 of 180 complete, 1 running                                Load avg: 14.2, 13.5, 13.7
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
