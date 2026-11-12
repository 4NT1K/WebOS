# Build status (auto-updated ~every 3 min) — 2026-11-12 16:45:30 UTC

- Local time: 2026-11-12 16:45:30 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 40 of 180 complete, 3 running                                 Load avg: 7.35, 10.00, 9.24
>>> Jobs: 40 of 180 complete, 2 running                                 Load avg: 16.0, 11.8, 9.8
>>> Jobs: 40 of 180 complete, 1 running, 1 merge wait                   Load avg: 16.8, 12.0, 9.9
>>> Jobs: 40 of 180 complete, 2 merge wait                              Load avg: 11.5, 11.3, 9.8
>>> Installing (42 of 180) kde-frameworks/kunitconversion-6.31.0::gentoo
>>> Jobs: 40 of 180 complete, 3 merge wait                              Load avg: 11.5, 11.3, 9.8
>>> Installing (43 of 180) lxqt-base/liblxqt-2.5.0::gentoo
>>> Jobs: 40 of 180 complete, 3 merge wait                              Load avg: 11.5, 11.3, 9.8
>>> Installing (41 of 180) dev-qt/qtquick3d-6.11.3::gentoo
>>> Jobs: 40 of 180 complete, 3 merge wait                              Load avg: 11.5, 11.3, 9.8
>>> Completed (42 of 180) kde-frameworks/kunitconversion-6.31.0::gentoo
>>> Jobs: 40 of 180 complete                                            Load avg: 11.5, 11.3, 9.8
>>> Jobs: 41 of 180 complete                                            Load avg: 11.5, 11.3, 9.8
>>> Completed (43 of 180) lxqt-base/liblxqt-2.5.0::gentoo
>>> Jobs: 41 of 180 complete                                            Load avg: 11.5, 11.3, 9.8
>>> Jobs: 42 of 180 complete                                            Load avg: 11.5, 11.3, 9.8
>>> Completed (41 of 180) dev-qt/qtquick3d-6.11.3::gentoo
>>> Jobs: 42 of 180 complete                                            Load avg: 11.5, 11.3, 9.8
>>> Jobs: 43 of 180 complete                                            Load avg: 11.5, 11.3, 9.8
>>> Jobs: 43 of 180 complete, 1 running                                 Load avg: 11.5, 11.3, 9.8
>>> Emerging (44 of 180) dev-qt/qtlocation-6.11.3::gentoo
>>> Jobs: 43 of 180 complete, 1 running                                 Load avg: 11.5, 11.3, 9.8
>>> Jobs: 43 of 180 complete                                            Load avg: 7.5, 10.3, 9.5
>>> Installing (44 of 180) dev-qt/qtlocation-6.11.3::gentoo
>>> Jobs: 43 of 180 complete, 1 merge wait                              Load avg: 7.5, 10.3, 9.5
>>> Completed (44 of 180) dev-qt/qtlocation-6.11.3::gentoo
>>> Jobs: 43 of 180 complete                                            Load avg: 7.1, 10.2, 9.5
>>> Jobs: 44 of 180 complete                                            Load avg: 7.1, 10.2, 9.5
>>> Jobs: 44 of 180 complete, 1 running                                 Load avg: 7.1, 10.2, 9.5
>>> Emerging (45 of 180) app-crypt/qca-2.3.12::gentoo
>>> Jobs: 44 of 180 complete, 1 running                                 Load avg: 7.1, 10.2, 9.5
>>> Jobs: 44 of 180 complete, 2 running                                 Load avg: 7.1, 10.2, 9.5
>>> Emerging (46 of 180) media-libs/kquickimageeditor-0.7.0.1::gentoo
>>> Jobs: 44 of 180 complete, 2 running                                 Load avg: 7.1, 10.2, 9.5
>>> Jobs: 44 of 180 complete, 1 running                                 Load avg: 14.8, 11.8, 10.1
>>> Jobs: 44 of 180 complete, 1 merge wait                              Load avg: 11.9, 11.3, 9.9
>>> Installing (45 of 180) app-crypt/qca-2.3.12::gentoo
>>> Jobs: 44 of 180 complete, 2 merge wait                              Load avg: 11.9, 11.3, 9.9
>>> Installing (46 of 180) media-libs/kquickimageeditor-0.7.0.1::gentoo
>>> Jobs: 44 of 180 complete, 2 merge wait                              Load avg: 11.9, 11.3, 9.9
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
