# Build status (auto-updated ~every 5 min) — 2026-11-12 18:16:15 UTC

- Local time: 2026-11-12 18:16:15 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 165 of 180 complete, 1 running                                Load avg: 10.0, 14.9, 15.1
>>> Jobs: 165 of 180 complete                                           Load avg: 10.6, 15.0, 15.1
>>> Installing (166 of 180) media-sound/pavucontrol-6.1-r1::gentoo
>>> Jobs: 165 of 180 complete, 1 merge wait                             Load avg: 10.6, 15.0, 15.1
>>> Completed (166 of 180) media-sound/pavucontrol-6.1-r1::gentoo
>>> Jobs: 165 of 180 complete                                           Load avg: 9.9, 14.8, 15.0
>>> Jobs: 166 of 180 complete                                           Load avg: 9.9, 14.8, 15.0
>>> Jobs: 166 of 180 complete, 1 running                                Load avg: 9.9, 14.8, 15.0
>>> Emerging (167 of 180) x11-misc/pcmanfm-1.3.2-r2::gentoo
>>> Jobs: 166 of 180 complete, 1 running                                Load avg: 9.9, 14.8, 15.0
>>> Jobs: 166 of 180 complete                                           Load avg: 9.3, 14.6, 14.9
>>> Installing (167 of 180) x11-misc/pcmanfm-1.3.2-r2::gentoo
>>> Jobs: 166 of 180 complete, 1 merge wait                             Load avg: 9.3, 14.6, 14.9
>>> Completed (167 of 180) x11-misc/pcmanfm-1.3.2-r2::gentoo
>>> Jobs: 166 of 180 complete                                           Load avg: 9.3, 14.6, 14.9
>>> Jobs: 167 of 180 complete                                           Load avg: 9.3, 14.6, 14.9
>>> Jobs: 167 of 180 complete, 1 running                                Load avg: 9.3, 14.6, 14.9
>>> Emerging (168 of 180) kde-plasma/kscreenlocker-6.8.3::gentoo
>>> Jobs: 167 of 180 complete, 1 running                                Load avg: 9.3, 14.6, 14.9
>>> Jobs: 167 of 180 complete                                           Load avg: 10.7, 14.4, 14.9
>>> Installing (168 of 180) kde-plasma/kscreenlocker-6.8.3::gentoo
>>> Jobs: 167 of 180 complete, 1 merge wait                             Load avg: 10.7, 14.4, 14.9
>>> Completed (168 of 180) kde-plasma/kscreenlocker-6.8.3::gentoo
>>> Jobs: 167 of 180 complete                                           Load avg: 10.7, 14.4, 14.9
>>> Jobs: 168 of 180 complete                                           Load avg: 10.7, 14.4, 14.9
>>> Jobs: 168 of 180 complete, 1 running                                Load avg: 10.7, 14.4, 14.9
>>> Emerging (169 of 180) kde-plasma/kwin-6.8.3::gentoo
>>> Jobs: 168 of 180 complete, 1 running                                Load avg: 10.7, 14.4, 14.9
>>> Jobs: 168 of 180 complete                                           Load avg: 21.0, 19.4, 17.4
>>> Installing (169 of 180) kde-plasma/kwin-6.8.3::gentoo
>>> Jobs: 168 of 180 complete, 1 merge wait                             Load avg: 21.0, 19.4, 17.4
>>> Completed (169 of 180) kde-plasma/kwin-6.8.3::gentoo
>>> Jobs: 168 of 180 complete                                           Load avg: 18.2, 18.9, 17.2
>>> Jobs: 169 of 180 complete                                           Load avg: 18.2, 18.9, 17.2
>>> Jobs: 169 of 180 complete, 1 running                                Load avg: 18.2, 18.9, 17.2
>>> Emerging (170 of 180) kde-plasma/plasma-workspace-6.8.3::gentoo
>>> Jobs: 169 of 180 complete, 1 running                                Load avg: 18.2, 18.9, 17.2
>>> Jobs: 169 of 180 complete                                           Load avg: 20.1, 20.2, 18.7
>>> Installing (170 of 180) kde-plasma/plasma-workspace-6.8.3::gentoo
>>> Jobs: 169 of 180 complete, 1 merge wait                             Load avg: 20.1, 20.2, 18.7
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
