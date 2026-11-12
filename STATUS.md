# Build status (auto-updated ~every 5 min) — 2026-11-12 17:10:45 UTC

- Local time: 2026-11-12 17:10:45 GMT
- Host: brah

## desktop-fix (corrective @desktop emerge)
```
>>> Jobs: 91 of 180 complete                                            Load avg: 14.3, 15.3, 13.4
>>> Jobs: 91 of 180 complete, 1 running                                 Load avg: 14.3, 15.3, 13.4
>>> Emerging (92 of 180) gui-libs/gtk-layer-shell-0.10.1::gentoo
>>> Jobs: 91 of 180 complete, 1 running                                 Load avg: 14.3, 15.3, 13.4
>>> Jobs: 91 of 180 complete                                            Load avg: 13.3, 15.0, 13.3
>>> Installing (92 of 180) gui-libs/gtk-layer-shell-0.10.1::gentoo
>>> Jobs: 91 of 180 complete, 1 merge wait                              Load avg: 13.3, 15.0, 13.3
>>> Completed (92 of 180) gui-libs/gtk-layer-shell-0.10.1::gentoo
>>> Jobs: 91 of 180 complete                                            Load avg: 12.4, 14.8, 13.2
>>> Jobs: 92 of 180 complete                                            Load avg: 12.4, 14.8, 13.2
>>> Jobs: 92 of 180 complete, 1 running                                 Load avg: 12.4, 14.8, 13.2
>>> Emerging (93 of 180) dev-cpp/gtkmm-3.24.11::gentoo
>>> Jobs: 92 of 180 complete, 1 running                                 Load avg: 12.4, 14.8, 13.2
>>> Jobs: 92 of 180 complete                                            Load avg: 15.2, 15.2, 13.5
>>> Installing (93 of 180) dev-cpp/gtkmm-3.24.11::gentoo
>>> Jobs: 92 of 180 complete, 1 merge wait                              Load avg: 15.2, 15.2, 13.5
>>> Completed (93 of 180) dev-cpp/gtkmm-3.24.11::gentoo
>>> Jobs: 92 of 180 complete                                            Load avg: 15.2, 15.2, 13.5
>>> Jobs: 93 of 180 complete                                            Load avg: 15.2, 15.2, 13.5
>>> Jobs: 93 of 180 complete, 1 running                                 Load avg: 15.2, 15.2, 13.5
>>> Emerging (94 of 180) kde-frameworks/kwallet-6.31.0::gentoo
>>> Jobs: 93 of 180 complete, 1 running                                 Load avg: 15.2, 15.2, 13.5
>>> Jobs: 93 of 180 complete                                            Load avg: 13.3, 14.8, 13.4
>>> Installing (94 of 180) kde-frameworks/kwallet-6.31.0::gentoo
>>> Jobs: 93 of 180 complete, 1 merge wait                              Load avg: 13.3, 14.8, 13.4
>>> Completed (94 of 180) kde-frameworks/kwallet-6.31.0::gentoo
>>> Jobs: 93 of 180 complete                                            Load avg: 13.3, 14.8, 13.4
>>> Jobs: 94 of 180 complete                                            Load avg: 13.3, 14.8, 13.4
>>> Jobs: 94 of 180 complete, 1 running                                 Load avg: 13.3, 14.8, 13.4
>>> Emerging (95 of 180) app-crypt/libsecret-0.21.8.2-r1::gentoo
>>> Jobs: 94 of 180 complete, 1 running                                 Load avg: 13.3, 14.8, 13.4
>>> Jobs: 94 of 180 complete                                            Load avg: 11.6, 14.4, 13.2
>>> Installing (95 of 180) app-crypt/libsecret-0.21.8.2-r1::gentoo
>>> Jobs: 94 of 180 complete, 1 merge wait                              Load avg: 11.6, 14.4, 13.2
>>> Completed (95 of 180) app-crypt/libsecret-0.21.8.2-r1::gentoo
>>> Jobs: 94 of 180 complete                                            Load avg: 11.6, 14.4, 13.2
>>> Jobs: 95 of 180 complete                                            Load avg: 11.6, 14.4, 13.2
>>> Jobs: 95 of 180 complete, 1 running                                 Load avg: 11.6, 14.4, 13.2
>>> Emerging (96 of 180) kde-frameworks/kwallet-runtime-6.31.0::gentoo
>>> Jobs: 95 of 180 complete, 1 running                                 Load avg: 11.6, 14.4, 13.2
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
