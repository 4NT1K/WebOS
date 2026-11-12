# Build status — 2026-11-12 16:35:16 UTC

- Local time: 2026-11-12 16:35:16 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 17 of 180 complete                                            Load avg: 9.0, 11.0, 7.6
>>> Jobs: 17 of 180 complete, 1 running                                 Load avg: 9.0, 11.0, 7.6
>>> Emerging (18 of 180) kde-plasma/layer-shell-qt-6.8.3::gentoo
>>> Jobs: 17 of 180 complete, 1 running                                 Load avg: 9.0, 11.0, 7.6
>>> Jobs: 17 of 180 complete                                            Load avg: 7.9, 10.7, 7.5
>>> Installing (18 of 180) kde-plasma/layer-shell-qt-6.8.3::gentoo
>>> Jobs: 17 of 180 complete, 1 merge wait                              Load avg: 7.9, 10.7, 7.5
>>> Completed (18 of 180) kde-plasma/layer-shell-qt-6.8.3::gentoo
>>> Jobs: 17 of 180 complete                                            Load avg: 7.9, 10.7, 7.5
>>> Jobs: 18 of 180 complete                                            Load avg: 7.9, 10.7, 7.5
>>> Jobs: 18 of 180 complete, 1 running                                 Load avg: 7.9, 10.7, 7.5
>>> Emerging (19 of 180) kde-frameworks/kholidays-6.31.0::gentoo
>>> Jobs: 18 of 180 complete, 1 running                                 Load avg: 7.9, 10.7, 7.5
>>> Jobs: 18 of 180 complete, 2 running                                 Load avg: 7.4, 10.5, 7.5
>>> Emerging (20 of 180) kde-frameworks/networkmanager-qt-6.31.0::gentoo
>>> Jobs: 18 of 180 complete, 2 running                                 Load avg: 7.4, 10.5, 7.5
>>> Jobs: 18 of 180 complete, 1 running                                 Load avg: 10.1, 11.0, 7.7
>>> Jobs: 18 of 180 complete, 1 merge wait                              Load avg: 17.0, 13.6, 9.1
>>> Installing (19 of 180) kde-frameworks/kholidays-6.31.0::gentoo
>>> Jobs: 18 of 180 complete, 2 merge wait                              Load avg: 17.0, 13.6, 9.1
>>> Installing (20 of 180) kde-frameworks/networkmanager-qt-6.31.0::gentoo
>>> Jobs: 18 of 180 complete, 2 merge wait                              Load avg: 17.0, 13.6, 9.1
>>> Completed (19 of 180) kde-frameworks/kholidays-6.31.0::gentoo
>>> Jobs: 18 of 180 complete                                            Load avg: 17.0, 13.6, 9.1
>>> Jobs: 19 of 180 complete                                            Load avg: 17.0, 13.6, 9.1
>>> Completed (20 of 180) kde-frameworks/networkmanager-qt-6.31.0::gentoo
>>> Jobs: 19 of 180 complete                                            Load avg: 17.0, 13.6, 9.1
>>> Jobs: 20 of 180 complete                                            Load avg: 17.0, 13.6, 9.1
>>> Jobs: 20 of 180 complete, 1 running                                 Load avg: 17.0, 13.6, 9.1
>>> Emerging (21 of 180) dev-qt/qtpositioning-6.11.3::gentoo
>>> Jobs: 20 of 180 complete, 1 running                                 Load avg: 17.0, 13.6, 9.1
>>> Jobs: 20 of 180 complete                                            Load avg: 10.3, 12.3, 8.9
>>> Installing (21 of 180) dev-qt/qtpositioning-6.11.3::gentoo
>>> Jobs: 20 of 180 complete, 1 merge wait                              Load avg: 10.3, 12.3, 8.9
>>> Completed (21 of 180) dev-qt/qtpositioning-6.11.3::gentoo
>>> Jobs: 20 of 180 complete                                            Load avg: 10.3, 12.3, 8.9
>>> Jobs: 21 of 180 complete                                            Load avg: 10.3, 12.3, 8.9
>>> Jobs: 21 of 180 complete, 1 running                                 Load avg: 10.3, 12.3, 8.9
>>> Emerging (22 of 180) kde-frameworks/kquickcharts-6.31.0::gentoo
>>> Jobs: 21 of 180 complete, 1 running                                 Load avg: 10.3, 12.3, 8.9
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
