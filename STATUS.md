# Build status (auto-updated ~every 5 min) — 2026-11-12 17:25:52 UTC

- Local time: 2026-11-12 17:25:52 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 116 of 180 complete, 1 running                                Load avg: 15.1, 15.1, 14.3
>>> Jobs: 116 of 180 complete                                           Load avg: 13.1, 14.6, 14.1
>>> Installing (117 of 180) kde-misc/kio-fuse-5.1.1::gentoo
>>> Jobs: 116 of 180 complete, 1 merge wait                             Load avg: 13.1, 14.6, 14.1
>>> Completed (117 of 180) kde-misc/kio-fuse-5.1.1::gentoo
>>> Jobs: 116 of 180 complete                                           Load avg: 13.1, 14.6, 14.1
>>> Jobs: 117 of 180 complete                                           Load avg: 13.1, 14.6, 14.1
>>> Jobs: 117 of 180 complete, 1 running                                Load avg: 13.1, 14.6, 14.1
>>> Emerging (118 of 180) kde-frameworks/purpose-6.31.0::gentoo
>>> Jobs: 117 of 180 complete, 1 running                                Load avg: 13.1, 14.6, 14.1
>>> Jobs: 117 of 180 complete                                           Load avg: 12.8, 14.4, 14.1
>>> Installing (118 of 180) kde-frameworks/purpose-6.31.0::gentoo
>>> Jobs: 117 of 180 complete, 1 merge wait                             Load avg: 12.8, 14.4, 14.1
>>> Completed (118 of 180) kde-frameworks/purpose-6.31.0::gentoo
>>> Jobs: 117 of 180 complete                                           Load avg: 11.9, 14.2, 14.0
>>> Jobs: 118 of 180 complete                                           Load avg: 11.9, 14.2, 14.0
>>> Jobs: 118 of 180 complete, 1 running                                Load avg: 11.9, 14.2, 14.0
>>> Emerging (119 of 180) kde-frameworks/knotifyconfig-6.31.0::gentoo
>>> Jobs: 118 of 180 complete, 1 running                                Load avg: 11.9, 14.2, 14.0
>>> Jobs: 118 of 180 complete                                           Load avg: 11.5, 14.1, 14.0
>>> Installing (119 of 180) kde-frameworks/knotifyconfig-6.31.0::gentoo
>>> Jobs: 118 of 180 complete, 1 merge wait                             Load avg: 11.5, 14.1, 14.0
>>> Completed (119 of 180) kde-frameworks/knotifyconfig-6.31.0::gentoo
>>> Jobs: 118 of 180 complete                                           Load avg: 10.8, 13.9, 13.9
>>> Jobs: 119 of 180 complete                                           Load avg: 10.8, 13.9, 13.9
>>> Jobs: 119 of 180 complete, 1 running                                Load avg: 10.8, 13.9, 13.9
>>> Emerging (120 of 180) gui-apps/xwaylandvideobridge-0.5.3::gentoo
>>> Jobs: 119 of 180 complete, 1 running                                Load avg: 10.8, 13.9, 13.9
>>> Jobs: 119 of 180 complete                                           Load avg: 9.8, 13.6, 13.8
>>> Installing (120 of 180) gui-apps/xwaylandvideobridge-0.5.3::gentoo
>>> Jobs: 119 of 180 complete, 1 merge wait                             Load avg: 9.8, 13.6, 13.8
>>> Completed (120 of 180) gui-apps/xwaylandvideobridge-0.5.3::gentoo
>>> Jobs: 119 of 180 complete                                           Load avg: 9.2, 13.4, 13.7
>>> Jobs: 120 of 180 complete                                           Load avg: 9.2, 13.4, 13.7
>>> Jobs: 120 of 180 complete, 1 running                                Load avg: 9.2, 13.4, 13.7
>>> Emerging (121 of 180) kde-plasma/ksshaskpass-6.8.3::gentoo
>>> Jobs: 120 of 180 complete, 1 running                                Load avg: 9.2, 13.4, 13.7
>>> Jobs: 120 of 180 complete                                           Load avg: 8.7, 13.2, 13.7
>>> Installing (121 of 180) kde-plasma/ksshaskpass-6.8.3::gentoo
>>> Jobs: 120 of 180 complete, 1 merge wait                             Load avg: 8.7, 13.2, 13.7
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
