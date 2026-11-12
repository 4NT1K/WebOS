# Build status (auto-updated ~every 3 min) — 2026-11-12 16:57:37 UTC

- Local time: 2026-11-12 16:57:37 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 68 of 180 complete                                            Load avg: 9.4, 12.2, 11.2
>>> Jobs: 68 of 180 complete, 1 running                                 Load avg: 9.4, 12.2, 11.2
>>> Emerging (69 of 180) kde-frameworks/kfilemetadata-6.31.0::gentoo
>>> Jobs: 68 of 180 complete, 1 running                                 Load avg: 9.4, 12.2, 11.2
>>> Jobs: 68 of 180 complete                                            Load avg: 10.7, 12.3, 11.3
>>> Installing (69 of 180) kde-frameworks/kfilemetadata-6.31.0::gentoo
>>> Jobs: 68 of 180 complete, 1 merge wait                              Load avg: 10.7, 12.3, 11.3
>>> Completed (69 of 180) kde-frameworks/kfilemetadata-6.31.0::gentoo
>>> Jobs: 68 of 180 complete                                            Load avg: 10.7, 12.3, 11.3
>>> Jobs: 69 of 180 complete                                            Load avg: 10.7, 12.3, 11.3
>>> Jobs: 69 of 180 complete, 1 running                                 Load avg: 10.7, 12.3, 11.3
>>> Emerging (70 of 180) media-libs/pcaudiolib-1.2-r2::gentoo
>>> Jobs: 69 of 180 complete, 1 running                                 Load avg: 10.7, 12.3, 11.3
>>> Jobs: 69 of 180 complete                                            Load avg: 9.3, 12.0, 11.2
>>> Installing (70 of 180) media-libs/pcaudiolib-1.2-r2::gentoo
>>> Jobs: 69 of 180 complete, 1 merge wait                              Load avg: 9.3, 12.0, 11.2
>>> Completed (70 of 180) media-libs/pcaudiolib-1.2-r2::gentoo
>>> Jobs: 69 of 180 complete                                            Load avg: 9.3, 12.0, 11.2
>>> Jobs: 70 of 180 complete                                            Load avg: 9.3, 12.0, 11.2
>>> Jobs: 70 of 180 complete, 1 running                                 Load avg: 9.3, 12.0, 11.2
>>> Emerging (71 of 180) media-sound/sox-14.7.0.9::gentoo
>>> Jobs: 70 of 180 complete, 1 running                                 Load avg: 9.3, 12.0, 11.2
>>> Jobs: 70 of 180 complete                                            Load avg: 10.0, 12.0, 11.2
>>> Installing (71 of 180) media-sound/sox-14.7.0.9::gentoo
>>> Jobs: 70 of 180 complete, 1 merge wait                              Load avg: 10.0, 12.0, 11.2
>>> Completed (71 of 180) media-sound/sox-14.7.0.9::gentoo
>>> Jobs: 70 of 180 complete                                            Load avg: 10.0, 12.0, 11.2
>>> Jobs: 71 of 180 complete                                            Load avg: 10.0, 12.0, 11.2
>>> Jobs: 71 of 180 complete, 1 running                                 Load avg: 10.0, 12.0, 11.2
>>> Emerging (72 of 180) media-libs/pulseaudio-qt-1.9.0::gentoo
>>> Jobs: 71 of 180 complete, 1 running                                 Load avg: 10.0, 12.0, 11.2
>>> Jobs: 71 of 180 complete                                            Load avg: 10.4, 12.0, 11.2
>>> Installing (72 of 180) media-libs/pulseaudio-qt-1.9.0::gentoo
>>> Jobs: 71 of 180 complete, 1 merge wait                              Load avg: 10.4, 12.0, 11.2
>>> Completed (72 of 180) media-libs/pulseaudio-qt-1.9.0::gentoo
>>> Jobs: 71 of 180 complete                                            Load avg: 9.6, 11.8, 11.1
>>> Jobs: 72 of 180 complete                                            Load avg: 9.6, 11.8, 11.1
>>> Jobs: 72 of 180 complete, 1 running                                 Load avg: 9.6, 11.8, 11.1
>>> Emerging (73 of 180) media-libs/libheif-1.23.7::gentoo
>>> Jobs: 72 of 180 complete, 1 running                                 Load avg: 9.6, 11.8, 11.1
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
