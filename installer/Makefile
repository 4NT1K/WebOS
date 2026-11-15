# WebOS installer — convenience targets.
#
#   make release    optimised binary in target/release/webos-installer
#   make debug      debug binary
#   make vendor     refresh vendor/ for offline builds (needs network)
#   make lint       clippy, warnings are errors
#   make test       unit tests
#   make clean      remove target/ and vendor/

CARGO  ?= cargo
VENDOR := vendor

.PHONY: all release debug vendor lint test clean

all: release

release:
	$(CARGO) build --release --locked

debug:
	$(CARGO) build --locked

vendor:
	./vendor.sh

lint:
	$(CARGO) clippy --all-targets -- -D warnings

test:
	$(CARGO) test --locked

clean:
	$(CARGO) clean
	rm -rf $(VENDOR)
