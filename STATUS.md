# Build status (auto-updated ~every 5 min) — 2026-11-12 18:36:21 UTC

- Local time: 2026-11-12 18:36:21 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Installing (177 of 180) x11-themes/murrine-themes-0.98.11-r1::gentoo
>>> Jobs: 176 of 180 complete, 1 merge wait                             Load avg: 9.6, 16.6, 18.0
>>> Completed (177 of 180) x11-themes/murrine-themes-0.98.11-r1::gentoo
>>> Jobs: 176 of 180 complete                                           Load avg: 8.9, 16.3, 17.9
>>> Jobs: 177 of 180 complete                                           Load avg: 8.9, 16.3, 17.9
>>> Jobs: 177 of 180 complete, 1 running                                Load avg: 8.9, 16.3, 17.9
>>> Emerging (178 of 180) x11-themes/arc-theme-20221218-r1::gentoo
>>> Jobs: 177 of 180 complete, 1 running                                Load avg: 8.9, 16.3, 17.9
>>> Jobs: 177 of 180 complete                                           Load avg: 8.3, 16.1, 17.8
>>> Installing (178 of 180) x11-themes/arc-theme-20221218-r1::gentoo
>>> Jobs: 177 of 180 complete, 1 merge wait                             Load avg: 8.3, 16.1, 17.8
>>> Completed (178 of 180) x11-themes/arc-theme-20221218-r1::gentoo
>>> Jobs: 177 of 180 complete                                           Load avg: 8.3, 16.1, 17.8
>>> Jobs: 178 of 180 complete                                           Load avg: 8.3, 16.1, 17.8
>>> Jobs: 178 of 180 complete, 1 running                                Load avg: 8.3, 16.1, 17.8
>>> Emerging (179 of 180) virtual/jack-2::gentoo
>>> Jobs: 178 of 180 complete, 1 running                                Load avg: 8.3, 16.1, 17.8
>>> Jobs: 178 of 180 complete                                           Load avg: 8.3, 16.1, 17.8
>>> Installing (179 of 180) virtual/jack-2::gentoo
>>> Jobs: 178 of 180 complete, 1 merge wait                             Load avg: 8.3, 16.1, 17.8
>>> Completed (179 of 180) virtual/jack-2::gentoo
>>> Jobs: 178 of 180 complete                                           Load avg: 7.8, 15.9, 17.7
>>> Jobs: 179 of 180 complete                                           Load avg: 7.8, 15.9, 17.7
>>> Jobs: 179 of 180 complete, 1 running                                Load avg: 7.8, 15.9, 17.7
>>> Emerging (180 of 180) media-sound/jack-example-tools-4::gentoo
>>> Jobs: 179 of 180 complete, 1 running                                Load avg: 7.8, 15.9, 17.7
>>> Jobs: 179 of 180 complete                                           Load avg: 7.8, 15.9, 17.7
>>> Installing (180 of 180) media-sound/jack-example-tools-4::gentoo
>>> Jobs: 179 of 180 complete, 1 merge wait                             Load avg: 7.8, 15.9, 17.7
>>> Completed (180 of 180) media-sound/jack-example-tools-4::gentoo
>>> Jobs: 179 of 180 complete                                           Load avg: 7.5, 15.7, 17.6
>>> Jobs: 180 of 180 complete                                           Load avg: 7.5, 15.7, 17.6
 * Regenerating GNU info directory index...
 * Processed 134 info files.
 * IMPORTANT: config file '/etc/gtk-3.0/settings.ini' needs updating.
 * See the CONFIGURATION FILES and CONFIGURATION FILES UPDATE TOOLS
 * sections of the emerge man page to learn how to update config files.
 * IMPORTANT: 4 news items need reading for repository 'gentoo'.
 * Use eselect news read to view new items.
rc=0
```
- Result: rc=0

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

## iso-build
```
==> iso: building live medium
fail missing host tool: mksquashfs
rc=1
```
- Result: rc=1

## Artifacts
```
total 20K
-rwxr-xr-x 1 root root 6.4M Nov 12 18:30 build/chroot/usr/bin/sanus-installer
iso: (none)
checksums: (none)
```
