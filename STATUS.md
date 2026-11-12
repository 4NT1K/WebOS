# Build status (auto-updated ~every 5 min) — 2026-11-12 17:15:47 UTC

- Local time: 2026-11-12 17:15:47 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 98 of 180 complete                                            Load avg: 12.0, 14.1, 13.2
>>> Jobs: 98 of 180 complete, 1 running                                 Load avg: 12.0, 14.1, 13.2
>>> Emerging (99 of 180) gnome-base/gvfs-1.60.3::gentoo
>>> Jobs: 98 of 180 complete, 1 running                                 Load avg: 12.0, 14.1, 13.2
>>> Jobs: 98 of 180 complete                                            Load avg: 11.6, 13.9, 13.1
>>> Installing (99 of 180) gnome-base/gvfs-1.60.3::gentoo
>>> Jobs: 98 of 180 complete, 1 merge wait                              Load avg: 11.6, 13.9, 13.1
>>> Completed (99 of 180) gnome-base/gvfs-1.60.3::gentoo
>>> Jobs: 98 of 180 complete                                            Load avg: 11.6, 13.9, 13.1
>>> Jobs: 99 of 180 complete                                            Load avg: 11.6, 13.9, 13.1
>>> Jobs: 99 of 180 complete, 1 running                                 Load avg: 11.6, 13.9, 13.1
>>> Emerging (100 of 180) x11-libs/libfm-1.3.2-r1::gentoo
>>> Jobs: 99 of 180 complete, 1 running                                 Load avg: 11.6, 13.9, 13.1
>>> Jobs: 99 of 180 complete                                            Load avg: 10.3, 13.5, 13.0
>>> Installing (100 of 180) x11-libs/libfm-1.3.2-r1::gentoo
>>> Jobs: 99 of 180 complete, 1 merge wait                              Load avg: 10.3, 13.5, 13.0
>>> Completed (100 of 180) x11-libs/libfm-1.3.2-r1::gentoo
>>> Jobs: 99 of 180 complete                                            Load avg: 10.3, 13.5, 13.0
>>> Jobs: 100 of 180 complete                                           Load avg: 10.3, 13.5, 13.0
>>> Jobs: 100 of 180 complete, 1 running                                Load avg: 10.3, 13.5, 13.0
>>> Emerging (101 of 180) kde-frameworks/kio-6.31.0::gentoo
>>> Jobs: 100 of 180 complete, 1 running                                Load avg: 10.3, 13.5, 13.0
>>> Jobs: 100 of 180 complete                                           Load avg: 15.4, 14.9, 13.6
>>> Installing (101 of 180) kde-frameworks/kio-6.31.0::gentoo
>>> Jobs: 100 of 180 complete, 1 merge wait                             Load avg: 15.4, 14.9, 13.6
>>> Completed (101 of 180) kde-frameworks/kio-6.31.0::gentoo
>>> Jobs: 100 of 180 complete                                           Load avg: 15.4, 14.9, 13.6
>>> Jobs: 101 of 180 complete                                           Load avg: 15.4, 14.9, 13.6
>>> Jobs: 101 of 180 complete, 1 running                                Load avg: 15.4, 14.9, 13.6
>>> Emerging (102 of 180) kde-frameworks/kcmutils-6.31.0::gentoo
>>> Jobs: 101 of 180 complete, 1 running                                Load avg: 15.4, 14.9, 13.6
>>> Jobs: 101 of 180 complete                                           Load avg: 12.8, 14.2, 13.4
>>> Installing (102 of 180) kde-frameworks/kcmutils-6.31.0::gentoo
>>> Jobs: 101 of 180 complete, 1 merge wait                             Load avg: 12.8, 14.2, 13.4
>>> Completed (102 of 180) kde-frameworks/kcmutils-6.31.0::gentoo
>>> Jobs: 101 of 180 complete                                           Load avg: 12.8, 14.2, 13.4
>>> Jobs: 102 of 180 complete                                           Load avg: 12.8, 14.2, 13.4
>>> Jobs: 102 of 180 complete, 1 running                                Load avg: 12.8, 14.2, 13.4
>>> Emerging (103 of 180) kde-plasma/libplasma-6.8.3::gentoo
>>> Jobs: 102 of 180 complete, 1 running                                Load avg: 12.8, 14.2, 13.4
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
