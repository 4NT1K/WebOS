# Build status (auto-updated ~every 5 min) — 2026-11-12 17:20:49 UTC

- Local time: 2026-11-12 17:20:49 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 107 of 180 complete                                           Load avg: 11.9, 13.9, 13.5
>>> Jobs: 107 of 180 complete, 1 running                                Load avg: 11.9, 13.9, 13.5
>>> Emerging (108 of 180) dev-libs/kirigami-addons-1.16.1::gentoo
>>> Jobs: 107 of 180 complete, 1 running                                Load avg: 11.9, 13.9, 13.5
>>> Jobs: 107 of 180 complete                                           Load avg: 17.0, 15.1, 14.0
>>> Installing (108 of 180) dev-libs/kirigami-addons-1.16.1::gentoo
>>> Jobs: 107 of 180 complete, 1 merge wait                             Load avg: 17.0, 15.1, 14.0
>>> Completed (108 of 180) dev-libs/kirigami-addons-1.16.1::gentoo
>>> Jobs: 107 of 180 complete                                           Load avg: 17.0, 15.1, 14.0
>>> Jobs: 108 of 180 complete                                           Load avg: 17.0, 15.1, 14.0
>>> Jobs: 108 of 180 complete, 1 running                                Load avg: 17.0, 15.1, 14.0
>>> Emerging (109 of 180) kde-plasma/milou-6.8.3::gentoo
>>> Jobs: 108 of 180 complete, 1 running                                Load avg: 17.0, 15.1, 14.0
>>> Jobs: 108 of 180 complete                                           Load avg: 15.8, 14.9, 13.9
>>> Installing (109 of 180) kde-plasma/milou-6.8.3::gentoo
>>> Jobs: 108 of 180 complete, 1 merge wait                             Load avg: 15.8, 14.9, 13.9
>>> Completed (109 of 180) kde-plasma/milou-6.8.3::gentoo
>>> Jobs: 108 of 180 complete                                           Load avg: 14.7, 14.7, 13.9
>>> Jobs: 109 of 180 complete                                           Load avg: 14.7, 14.7, 13.9
>>> Jobs: 109 of 180 complete, 1 running                                Load avg: 14.7, 14.7, 13.9
>>> Emerging (110 of 180) kde-plasma/kglobalacceld-6.8.3::gentoo
>>> Jobs: 109 of 180 complete, 1 running                                Load avg: 14.7, 14.7, 13.9
>>> Jobs: 109 of 180 complete                                           Load avg: 13.6, 14.5, 13.8
>>> Installing (110 of 180) kde-plasma/kglobalacceld-6.8.3::gentoo
>>> Jobs: 109 of 180 complete, 1 merge wait                             Load avg: 13.6, 14.5, 13.8
>>> Completed (110 of 180) kde-plasma/kglobalacceld-6.8.3::gentoo
>>> Jobs: 109 of 180 complete                                           Load avg: 13.6, 14.5, 13.8
>>> Jobs: 110 of 180 complete                                           Load avg: 13.6, 14.5, 13.8
>>> Jobs: 110 of 180 complete, 1 running                                Load avg: 13.6, 14.5, 13.8
>>> Emerging (111 of 180) kde-plasma/plasma5support-6.8.3::gentoo
>>> Jobs: 110 of 180 complete, 1 running                                Load avg: 13.6, 14.5, 13.8
>>> Jobs: 110 of 180 complete                                           Load avg: 15.8, 14.9, 14.0
>>> Installing (111 of 180) kde-plasma/plasma5support-6.8.3::gentoo
>>> Jobs: 110 of 180 complete, 1 merge wait                             Load avg: 15.8, 14.9, 14.0
>>> Completed (111 of 180) kde-plasma/plasma5support-6.8.3::gentoo
>>> Jobs: 110 of 180 complete                                           Load avg: 14.8, 14.7, 13.9
>>> Jobs: 111 of 180 complete                                           Load avg: 14.8, 14.7, 13.9
>>> Jobs: 111 of 180 complete, 1 running                                Load avg: 14.8, 14.7, 13.9
>>> Emerging (112 of 180) kde-frameworks/baloo-6.31.0-r2::gentoo
>>> Jobs: 111 of 180 complete, 1 running                                Load avg: 14.8, 14.7, 13.9
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
