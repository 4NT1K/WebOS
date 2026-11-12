# Build status (auto-updated ~every 5 min) — 2026-11-12 17:51:03 UTC

- Local time: 2026-11-12 17:51:03 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 152 of 180 complete                                           Load avg: 18.1, 16.4, 15.0
>>> Jobs: 152 of 180 complete, 1 running                                Load avg: 18.1, 16.4, 15.0
>>> Emerging (153 of 180) kde-plasma/plasma-pa-6.8.3::gentoo
>>> Jobs: 152 of 180 complete, 1 running                                Load avg: 18.1, 16.4, 15.0
>>> Jobs: 152 of 180 complete                                           Load avg: 17.0, 16.3, 15.0
>>> Installing (153 of 180) kde-plasma/plasma-pa-6.8.3::gentoo
>>> Jobs: 152 of 180 complete, 1 merge wait                             Load avg: 17.0, 16.3, 15.0
>>> Completed (153 of 180) kde-plasma/plasma-pa-6.8.3::gentoo
>>> Jobs: 152 of 180 complete                                           Load avg: 15.8, 16.1, 14.9
>>> Jobs: 153 of 180 complete                                           Load avg: 15.8, 16.1, 14.9
>>> Jobs: 153 of 180 complete, 1 running                                Load avg: 15.8, 16.1, 14.9
>>> Emerging (154 of 180) kde-plasma/plasma-integration-6.8.3::gentoo
>>> Jobs: 153 of 180 complete, 1 running                                Load avg: 15.8, 16.1, 14.9
>>> Jobs: 153 of 180 complete                                           Load avg: 17.8, 16.6, 15.2
>>> Installing (154 of 180) kde-plasma/plasma-integration-6.8.3::gentoo
>>> Jobs: 153 of 180 complete, 1 merge wait                             Load avg: 17.8, 16.6, 15.2
>>> Completed (154 of 180) kde-plasma/plasma-integration-6.8.3::gentoo
>>> Jobs: 153 of 180 complete                                           Load avg: 17.8, 16.6, 15.2
>>> Jobs: 154 of 180 complete                                           Load avg: 17.8, 16.6, 15.2
>>> Jobs: 154 of 180 complete, 1 running                                Load avg: 17.8, 16.6, 15.2
>>> Emerging (155 of 180) kde-plasma/ksystemstats-6.8.3::gentoo
>>> Jobs: 154 of 180 complete, 1 running                                Load avg: 17.8, 16.6, 15.2
>>> Jobs: 154 of 180 complete                                           Load avg: 16.1, 16.3, 15.1
>>> Installing (155 of 180) kde-plasma/ksystemstats-6.8.3::gentoo
>>> Jobs: 154 of 180 complete, 1 merge wait                             Load avg: 16.1, 16.3, 15.1
>>> Completed (155 of 180) kde-plasma/ksystemstats-6.8.3::gentoo
>>> Jobs: 154 of 180 complete                                           Load avg: 16.1, 16.3, 15.1
>>> Jobs: 155 of 180 complete                                           Load avg: 16.1, 16.3, 15.1
>>> Jobs: 155 of 180 complete, 1 running                                Load avg: 16.1, 16.3, 15.1
>>> Emerging (156 of 180) kde-plasma/breeze-6.8.3::gentoo
>>> Jobs: 155 of 180 complete, 1 running                                Load avg: 16.1, 16.3, 15.1
>>> Jobs: 155 of 180 complete                                           Load avg: 15.6, 16.3, 15.2
>>> Installing (156 of 180) kde-plasma/breeze-6.8.3::gentoo
>>> Jobs: 155 of 180 complete, 1 merge wait                             Load avg: 15.6, 16.3, 15.2
>>> Completed (156 of 180) kde-plasma/breeze-6.8.3::gentoo
>>> Jobs: 155 of 180 complete                                           Load avg: 14.7, 16.1, 15.1
>>> Jobs: 156 of 180 complete                                           Load avg: 14.7, 16.1, 15.1
>>> Jobs: 156 of 180 complete, 1 running                                Load avg: 14.7, 16.1, 15.1
>>> Emerging (157 of 180) kde-plasma/plasma-vault-6.8.3::gentoo
>>> Jobs: 156 of 180 complete, 1 running                                Load avg: 14.7, 16.1, 15.1
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
