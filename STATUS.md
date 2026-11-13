# WebOS build status

## Progress

- **Overall:** 95% complete (estimated)
- **Phase:** Rebuilding after install fixes (kernel + ISO)
- **ETA:** ~45–60 min
- **Detail:** Fixed two installer aborts (missing `/etc/sudoers.d`, Plasma writing to a
  non-existent `/etc/greetd`) and replaced the non-existent `greetd` service with
  SDDM via OpenRC's `display-manager`. Kernel is rebuilding with
  `CONFIG_LOCALVERSION="-webos"`; a QEMU end-to-end install test is running
  (no KVM, so TCG and slow).
