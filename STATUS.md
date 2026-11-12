# Build status (auto-updated ~every 5 min) — 2026-11-12 17:46:01 UTC

- Local time: 2026-11-12 17:46:01 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 145 of 180 complete                                           Load avg: 13.4, 13.4, 13.6
>>> Jobs: 145 of 180 complete, 1 running                                Load avg: 13.4, 13.4, 13.6
>>> Emerging (146 of 180) kde-frameworks/frameworkintegration-6.31.0::gentoo
>>> Jobs: 145 of 180 complete, 1 running                                Load avg: 13.4, 13.4, 13.6
>>> Jobs: 145 of 180 complete                                           Load avg: 12.5, 13.2, 13.5
>>> Installing (146 of 180) kde-frameworks/frameworkintegration-6.31.0::gentoo
>>> Jobs: 145 of 180 complete, 1 merge wait                             Load avg: 12.5, 13.2, 13.5
>>> Completed (146 of 180) kde-frameworks/frameworkintegration-6.31.0::gentoo
>>> Jobs: 145 of 180 complete                                           Load avg: 11.7, 13.0, 13.5
>>> Jobs: 146 of 180 complete                                           Load avg: 11.7, 13.0, 13.5
>>> Jobs: 146 of 180 complete, 1 running                                Load avg: 11.7, 13.0, 13.5
>>> Emerging (147 of 180) kde-plasma/kinfocenter-6.8.3::gentoo
>>> Jobs: 146 of 180 complete, 1 running                                Load avg: 11.7, 13.0, 13.5
>>> Jobs: 146 of 180 complete                                           Load avg: 14.3, 13.6, 13.7
>>> Installing (147 of 180) kde-plasma/kinfocenter-6.8.3::gentoo
>>> Jobs: 146 of 180 complete, 1 merge wait                             Load avg: 14.3, 13.6, 13.7
>>> Completed (147 of 180) kde-plasma/kinfocenter-6.8.3::gentoo
>>> Jobs: 146 of 180 complete                                           Load avg: 13.4, 13.4, 13.6
>>> Jobs: 147 of 180 complete                                           Load avg: 13.4, 13.4, 13.6
>>> Jobs: 147 of 180 complete, 1 running                                Load avg: 13.4, 13.4, 13.6
>>> Emerging (148 of 180) kde-plasma/kdeplasma-addons-6.8.3::gentoo
>>> Jobs: 147 of 180 complete, 1 running                                Load avg: 13.4, 13.4, 13.6
>>> Jobs: 147 of 180 complete                                           Load avg: 18.6, 15.9, 14.5
>>> Installing (148 of 180) kde-plasma/kdeplasma-addons-6.8.3::gentoo
>>> Jobs: 147 of 180 complete, 1 merge wait                             Load avg: 18.6, 15.9, 14.5
>>> Completed (148 of 180) kde-plasma/kdeplasma-addons-6.8.3::gentoo
>>> Jobs: 147 of 180 complete                                           Load avg: 17.3, 15.6, 14.4
>>> Jobs: 148 of 180 complete                                           Load avg: 17.3, 15.6, 14.4
>>> Jobs: 148 of 180 complete, 1 running                                Load avg: 17.3, 15.6, 14.4
>>> Emerging (149 of 180) kde-plasma/kscreen-6.8.3::gentoo
>>> Jobs: 148 of 180 complete, 1 running                                Load avg: 17.3, 15.6, 14.4
>>> Jobs: 148 of 180 complete                                           Load avg: 17.2, 16.0, 14.6
>>> Installing (149 of 180) kde-plasma/kscreen-6.8.3::gentoo
>>> Jobs: 148 of 180 complete, 1 merge wait                             Load avg: 17.2, 16.0, 14.6
>>> Completed (149 of 180) kde-plasma/kscreen-6.8.3::gentoo
>>> Jobs: 148 of 180 complete                                           Load avg: 17.2, 16.0, 14.6
>>> Jobs: 149 of 180 complete                                           Load avg: 17.2, 16.0, 14.6
>>> Jobs: 149 of 180 complete, 1 running                                Load avg: 17.2, 16.0, 14.6
>>> Emerging (150 of 180) kde-plasma/plasma-welcome-6.8.3::gentoo
>>> Jobs: 149 of 180 complete, 1 running                                Load avg: 17.2, 16.0, 14.6
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
