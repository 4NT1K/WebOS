# SanusOS — convenience wrappers over build.sh
#
#   make iso        build the full release ISO
#   make kernel     build only sys-kernel/sanus-kernel
#   make rootfs     build only the system rootfs
#   make installer  build only the Rust installer
#   make lint       shellcheck + pkgcheck + cargo clippy
#   make clean      remove build artifacts
#   make distclean  remove build artifacts AND the chroot

SHELL := /bin/bash
ROOT  := $(CURDIR)
JOBS  ?= $(shell nproc 2>/dev/null || echo 4)

.PHONY: all fetch bootstrap kernel rootfs iso installer lint check clean distclean help

all: iso

fetch bootstrap kernel rootfs iso:
	@SANUS_JOBS=$(JOBS) ./build.sh $@

installer:
	@$(MAKE) -C installer release

lint: check

check:
	@echo ">> shellcheck"
	@command -v shellcheck >/dev/null && shellcheck -x -e SC1091 scripts/*.sh scripts/lib/*.sh build.sh || echo "   (shellcheck not installed, skipped)"
	@echo ">> cargo clippy"
	@command -v cargo >/dev/null && cargo clippy --manifest-path installer/Cargo.toml -- -D warnings || echo "   (cargo not installed, skipped)"
	@echo ">> ebuild syntax"
	@command -v pkgcheck >/dev/null && pkgcheck scan --net overlay/ || echo "   (pkgcheck not installed, skipped)"
	@echo ">> manifest check"
	@find overlay -mindepth 3 -maxdepth 3 -name '*.ebuild' -printf '%h\n' | sort -u | while read -r d; do \
		[ -f "$$d/Manifest" ] || echo "   WARN: missing Manifest in $$d"; \
		[ -f "$$d/metadata.xml" ] || echo "   WARN: missing metadata.xml in $$d"; \
	done

clean:
	@./build.sh clean

distclean:
	@./build.sh distclean

help:
	@awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' Makefile
