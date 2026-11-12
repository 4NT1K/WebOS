# Build status (auto-updated ~every 5 min) — 2026-11-12 18:21:17 UTC

- Local time: 2026-11-12 18:21:17 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
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
>>> Completed (170 of 180) kde-plasma/plasma-workspace-6.8.3::gentoo
>>> Jobs: 169 of 180 complete                                           Load avg: 17.3, 19.6, 18.5
>>> Jobs: 170 of 180 complete                                           Load avg: 17.3, 19.6, 18.5
>>> Jobs: 170 of 180 complete, 1 running                                Load avg: 17.3, 19.6, 18.5
>>> Emerging (171 of 180) kde-plasma/plasma-desktop-6.8.3::gentoo
>>> Jobs: 170 of 180 complete, 1 running                                Load avg: 17.3, 19.6, 18.5
>>> Jobs: 170 of 180 complete                                           Load avg: 20.7, 20.6, 19.2
>>> Installing (171 of 180) kde-plasma/plasma-desktop-6.8.3::gentoo
>>> Jobs: 170 of 180 complete, 1 merge wait                             Load avg: 20.7, 20.6, 19.2
>>> Completed (171 of 180) kde-plasma/plasma-desktop-6.8.3::gentoo
>>> Jobs: 170 of 180 complete                                           Load avg: 19.2, 20.3, 19.1
>>> Jobs: 171 of 180 complete                                           Load avg: 19.2, 20.3, 19.1
>>> Jobs: 171 of 180 complete, 1 running                                Load avg: 19.2, 20.3, 19.1
>>> Emerging (172 of 180) kde-plasma/powerdevil-6.8.3::gentoo
>>> Jobs: 171 of 180 complete, 1 running                                Load avg: 19.2, 20.3, 19.1
>>> Jobs: 171 of 180 complete                                           Load avg: 18.3, 19.8, 19.0
>>> Installing (172 of 180) kde-plasma/powerdevil-6.8.3::gentoo
>>> Jobs: 171 of 180 complete, 1 merge wait                             Load avg: 18.3, 19.8, 19.0
>>> Completed (172 of 180) kde-plasma/powerdevil-6.8.3::gentoo
>>> Jobs: 171 of 180 complete                                           Load avg: 18.3, 19.8, 19.0
>>> Jobs: 172 of 180 complete                                           Load avg: 18.3, 19.8, 19.0
>>> Jobs: 172 of 180 complete, 1 running                                Load avg: 18.3, 19.8, 19.0
>>> Emerging (173 of 180) kde-plasma/plasma-browser-integration-6.8.3::gentoo
>>> Jobs: 172 of 180 complete, 1 running                                Load avg: 18.3, 19.8, 19.0
>>> Jobs: 172 of 180 complete                                           Load avg: 16.9, 19.4, 18.9
>>> Installing (173 of 180) kde-plasma/plasma-browser-integration-6.8.3::gentoo
>>> Jobs: 172 of 180 complete, 1 merge wait                             Load avg: 16.9, 19.4, 18.9
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
