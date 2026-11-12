# Build status (auto-updated ~every 5 min) — 2026-11-12 17:05:43 UTC

- Local time: 2026-11-12 17:05:43 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 82 of 180 complete, 3 merge wait                              Load avg: 9.7, 11.1, 11.1
>>> Completed (83 of 180) dev-qt/qtspeech-6.11.3::gentoo
>>> Jobs: 82 of 180 complete                                            Load avg: 9.1, 11.0, 11.0
>>> Jobs: 83 of 180 complete                                            Load avg: 9.1, 11.0, 11.0
>>> Completed (84 of 180) kde-frameworks/kauth-6.31.0::gentoo
>>> Jobs: 83 of 180 complete                                            Load avg: 9.1, 11.0, 11.0
>>> Jobs: 84 of 180 complete                                            Load avg: 9.1, 11.0, 11.0
>>> Completed (85 of 180) kde-plasma/kpipewire-6.8.3::gentoo
>>> Jobs: 84 of 180 complete                                            Load avg: 9.1, 11.0, 11.0
>>> Jobs: 85 of 180 complete                                            Load avg: 9.1, 11.0, 11.0
>>> Jobs: 85 of 180 complete, 1 running                                 Load avg: 9.1, 11.0, 11.0
>>> Emerging (86 of 180) x11-base/xwayland-24.1.15::gentoo
>>> Jobs: 85 of 180 complete, 1 running                                 Load avg: 9.1, 11.0, 11.0
>>> Jobs: 85 of 180 complete                                            Load avg: 11.4, 11.4, 11.1
>>> Installing (86 of 180) x11-base/xwayland-24.1.15::gentoo
>>> Jobs: 85 of 180 complete, 1 merge wait                              Load avg: 11.4, 11.4, 11.1
>>> Completed (86 of 180) x11-base/xwayland-24.1.15::gentoo
>>> Jobs: 85 of 180 complete                                            Load avg: 11.4, 11.4, 11.1
>>> Jobs: 86 of 180 complete                                            Load avg: 11.4, 11.4, 11.1
>>> Jobs: 86 of 180 complete, 1 running                                 Load avg: 11.4, 11.4, 11.1
>>> Emerging (87 of 180) gui-libs/hyprtoolkit-0.6.0::hyproverlay
>>> Jobs: 86 of 180 complete, 1 running                                 Load avg: 11.4, 11.4, 11.1
>>> Jobs: 86 of 180 complete                                            Load avg: 13.0, 11.7, 11.3
>>> Installing (87 of 180) gui-libs/hyprtoolkit-0.6.0::hyproverlay
>>> Jobs: 86 of 180 complete, 1 merge wait                              Load avg: 13.0, 11.7, 11.3
>>> Completed (87 of 180) gui-libs/hyprtoolkit-0.6.0::hyproverlay
>>> Jobs: 86 of 180 complete                                            Load avg: 13.0, 11.7, 11.3
>>> Jobs: 87 of 180 complete                                            Load avg: 13.0, 11.7, 11.3
>>> Jobs: 87 of 180 complete, 1 running                                 Load avg: 13.0, 11.7, 11.3
>>> Emerging (88 of 180) gui-libs/hyprland-guiutils-0.2.2::hyproverlay
>>> Jobs: 87 of 180 complete, 1 running                                 Load avg: 13.0, 11.7, 11.3
>>> Jobs: 87 of 180 complete                                            Load avg: 11.4, 11.4, 11.2
>>> Installing (88 of 180) gui-libs/hyprland-guiutils-0.2.2::hyproverlay
>>> Jobs: 87 of 180 complete, 1 merge wait                              Load avg: 11.4, 11.4, 11.2
>>> Completed (88 of 180) gui-libs/hyprland-guiutils-0.2.2::hyproverlay
>>> Jobs: 87 of 180 complete                                            Load avg: 11.4, 11.4, 11.2
>>> Jobs: 88 of 180 complete                                            Load avg: 11.4, 11.4, 11.2
>>> Jobs: 88 of 180 complete, 1 running                                 Load avg: 11.4, 11.4, 11.2
>>> Emerging (89 of 180) gui-wm/hyprland-0.57.2::hyproverlay
>>> Jobs: 88 of 180 complete, 1 running                                 Load avg: 11.4, 11.4, 11.2
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
