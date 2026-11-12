# Build status (auto-updated ~every 5 min) — 2026-11-12 17:30:53 UTC

- Local time: 2026-11-12 17:30:53 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 124 of 180 complete                                           Load avg: 7.6, 12.4, 13.4
>>> Jobs: 124 of 180 complete, 1 running                                Load avg: 7.6, 12.4, 13.4
>>> Emerging (125 of 180) kde-plasma/kup-6.8.3::gentoo
>>> Jobs: 124 of 180 complete, 1 running                                Load avg: 7.6, 12.4, 13.4
>>> Jobs: 124 of 180 complete, 2 running                                Load avg: 7.3, 12.3, 13.3
>>> Emerging (126 of 180) kde-plasma/bluedevil-6.8.3::gentoo
>>> Jobs: 124 of 180 complete, 2 running                                Load avg: 7.3, 12.3, 13.3
>>> Jobs: 124 of 180 complete, 1 running                                Load avg: 22.2, 15.7, 14.4
>>> Jobs: 124 of 180 complete, 1 merge wait                             Load avg: 21.1, 15.5, 14.4
>>> Installing (126 of 180) kde-plasma/bluedevil-6.8.3::gentoo
>>> Jobs: 124 of 180 complete, 2 merge wait                             Load avg: 21.1, 15.5, 14.4
>>> Installing (125 of 180) kde-plasma/kup-6.8.3::gentoo
>>> Jobs: 124 of 180 complete, 2 merge wait                             Load avg: 21.1, 15.5, 14.4
>>> Completed (126 of 180) kde-plasma/bluedevil-6.8.3::gentoo
>>> Jobs: 124 of 180 complete                                           Load avg: 21.1, 15.5, 14.4
>>> Jobs: 125 of 180 complete                                           Load avg: 21.1, 15.5, 14.4
>>> Completed (125 of 180) kde-plasma/kup-6.8.3::gentoo
>>> Jobs: 125 of 180 complete                                           Load avg: 19.5, 15.3, 14.3
>>> Jobs: 126 of 180 complete                                           Load avg: 19.5, 15.3, 14.3
>>> Jobs: 126 of 180 complete, 1 running                                Load avg: 19.5, 15.3, 14.3
>>> Emerging (127 of 180) kde-plasma/drkonqi-legacy-6.3.80_p20250417::gentoo
>>> Jobs: 126 of 180 complete, 1 running                                Load avg: 19.5, 15.3, 14.3
>>> Jobs: 126 of 180 complete                                           Load avg: 15.8, 14.9, 14.2
>>> Installing (127 of 180) kde-plasma/drkonqi-legacy-6.3.80_p20250417::gentoo
>>> Jobs: 126 of 180 complete, 1 merge wait                             Load avg: 15.8, 14.9, 14.2
>>> Completed (127 of 180) kde-plasma/drkonqi-legacy-6.3.80_p20250417::gentoo
>>> Jobs: 126 of 180 complete                                           Load avg: 15.8, 14.9, 14.2
>>> Jobs: 127 of 180 complete                                           Load avg: 15.8, 14.9, 14.2
>>> Jobs: 127 of 180 complete, 1 running                                Load avg: 15.8, 14.9, 14.2
>>> Emerging (128 of 180) kde-plasma/spectacle-6.8.3::gentoo
>>> Jobs: 127 of 180 complete, 1 running                                Load avg: 15.8, 14.9, 14.2
>>> Jobs: 127 of 180 complete                                           Load avg: 16.5, 15.2, 14.4
>>> Installing (128 of 180) kde-plasma/spectacle-6.8.3::gentoo
>>> Jobs: 127 of 180 complete, 1 merge wait                             Load avg: 16.5, 15.2, 14.4
>>> Completed (128 of 180) kde-plasma/spectacle-6.8.3::gentoo
>>> Jobs: 127 of 180 complete                                           Load avg: 15.3, 15.0, 14.3
>>> Jobs: 128 of 180 complete                                           Load avg: 15.3, 15.0, 14.3
>>> Jobs: 128 of 180 complete, 1 running                                Load avg: 15.3, 15.0, 14.3
>>> Emerging (129 of 180) app-misc/nwg-look-1.0.6::guru
>>> Jobs: 128 of 180 complete, 1 running                                Load avg: 15.3, 15.0, 14.3
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
