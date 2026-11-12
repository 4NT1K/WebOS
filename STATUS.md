# Build status (auto-updated ~every 3 min) — 2026-11-12 16:51:33 UTC

- Local time: 2026-11-12 16:51:33 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 56 of 180 complete                                            Load avg: 9.2, 10.2, 9.7
>>> Jobs: 56 of 180 complete, 1 running                                 Load avg: 9.2, 10.2, 9.7
>>> Emerging (57 of 180) kde-frameworks/kbookmarks-6.31.0::gentoo
>>> Jobs: 56 of 180 complete, 1 running                                 Load avg: 9.2, 10.2, 9.7
>>> Jobs: 56 of 180 complete                                            Load avg: 9.2, 10.2, 9.7
>>> Installing (57 of 180) kde-frameworks/kbookmarks-6.31.0::gentoo
>>> Jobs: 56 of 180 complete, 1 merge wait                              Load avg: 9.2, 10.2, 9.7
>>> Completed (57 of 180) kde-frameworks/kbookmarks-6.31.0::gentoo
>>> Jobs: 56 of 180 complete                                            Load avg: 9.2, 10.2, 9.7
>>> Jobs: 57 of 180 complete                                            Load avg: 9.2, 10.2, 9.7
>>> Jobs: 57 of 180 complete, 1 running                                 Load avg: 9.2, 10.2, 9.7
>>> Emerging (58 of 180) kde-frameworks/qqc2-desktop-style-6.31.0::gentoo
>>> Jobs: 57 of 180 complete, 1 running                                 Load avg: 9.2, 10.2, 9.7
>>> Jobs: 57 of 180 complete                                            Load avg: 11.7, 10.7, 9.9
>>> Installing (58 of 180) kde-frameworks/qqc2-desktop-style-6.31.0::gentoo
>>> Jobs: 57 of 180 complete, 1 merge wait                              Load avg: 11.7, 10.7, 9.9
>>> Completed (58 of 180) kde-frameworks/qqc2-desktop-style-6.31.0::gentoo
>>> Jobs: 57 of 180 complete                                            Load avg: 11.7, 10.7, 9.9
>>> Jobs: 58 of 180 complete                                            Load avg: 11.7, 10.7, 9.9
>>> Jobs: 58 of 180 complete, 1 running                                 Load avg: 11.7, 10.7, 9.9
>>> Emerging (59 of 180) kde-plasma/qqc2-breeze-style-6.8.3::gentoo
>>> Jobs: 58 of 180 complete, 1 running                                 Load avg: 11.7, 10.7, 9.9
>>> Jobs: 58 of 180 complete                                            Load avg: 14.1, 11.5, 10.2
>>> Installing (59 of 180) kde-plasma/qqc2-breeze-style-6.8.3::gentoo
>>> Jobs: 58 of 180 complete, 1 merge wait                              Load avg: 14.1, 11.5, 10.2
>>> Completed (59 of 180) kde-plasma/qqc2-breeze-style-6.8.3::gentoo
>>> Jobs: 58 of 180 complete                                            Load avg: 14.1, 11.5, 10.2
>>> Jobs: 59 of 180 complete                                            Load avg: 14.1, 11.5, 10.2
>>> Jobs: 59 of 180 complete, 1 running                                 Load avg: 14.1, 11.5, 10.2
>>> Emerging (60 of 180) kde-plasma/union-6.8.3::gentoo
>>> Jobs: 59 of 180 complete, 1 running                                 Load avg: 14.1, 11.5, 10.2
>>> Jobs: 59 of 180 complete                                            Load avg: 16.2, 12.9, 10.9
>>> Installing (60 of 180) kde-plasma/union-6.8.3::gentoo
>>> Jobs: 59 of 180 complete, 1 merge wait                              Load avg: 16.2, 12.9, 10.9
>>> Completed (60 of 180) kde-plasma/union-6.8.3::gentoo
>>> Jobs: 59 of 180 complete                                            Load avg: 16.2, 12.9, 10.9
>>> Jobs: 60 of 180 complete                                            Load avg: 16.2, 12.9, 10.9
>>> Jobs: 60 of 180 complete, 1 running                                 Load avg: 16.2, 12.9, 10.9
>>> Emerging (61 of 180) kde-plasma/kdesu-gui-6.8.3::gentoo
>>> Jobs: 60 of 180 complete, 1 running                                 Load avg: 16.2, 12.9, 10.9
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
