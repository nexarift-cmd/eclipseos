# EclipseOS top-level build entry points.
#
# The real work lives in scripts/ so it can be reused by CI. `make iso` is the
# single documented build command required by the project contract.

SHELL := /bin/bash
VERSION := $(shell tr -d '\r\n' < VERSION)
ISO_NAME := eclipseos-$(VERSION)-amd64
ISO := $(CURDIR)/$(ISO_NAME).iso
SHA256 := $(ISO).sha256
VM_NAME ?= EclipseOS-$(VERSION)
VM_DIR ?= $(HOME)/VirtualBox VMs

.PHONY: all help doctor iso checksum verify test test-uefi test-bios test-all test-vm clean distclean

all: iso

help:
	@printf '%s\n' \
	  'EclipseOS build targets:' \
	  '  make doctor      Check the build host and required tools' \
	  '  make iso         Build the hybrid ISO, SHA256 and build info' \
	  '  make checksum    Recreate the SHA256 file for the existing ISO' \
	  '  make verify      Verify the existing ISO against its SHA256 file' \
	  '  make test        Alias for test-all' \
	  '  make test-uefi   Boot-test the ISO in QEMU with UEFI/OVMF' \
	  '  make test-bios   Boot-test the ISO in QEMU with legacy BIOS' \
	  '  make test-all    Run both QEMU boot tests' \
	  '  make test-vm     Create and start a VirtualBox VM (VBoxManage required)' \
	  '  make clean       Remove build output and live-build state' \
	  '  make distclean   clean + remove downloaded caches and local artefacts'

doctor:
	@./scripts/check-host.sh --with-tests

iso:
	@./scripts/build.sh

checksum:
	@./scripts/checksum.sh "$(ISO)"

verify:
	@./scripts/checksum.sh --verify "$(ISO)"

test: test-all

test-uefi:
	@./scripts/test-qemu.sh --firmware uefi --iso "$(ISO)"

test-bios:
	@./scripts/test-qemu.sh --firmware bios --iso "$(ISO)"

test-all: test-uefi test-bios

test-vm: iso
	@./scripts/create-vbox-vm.sh --iso "$(ISO)" --name "$(VM_NAME)" --start

clean:
	@if command -v lb >/dev/null 2>&1; then \
		if [ "$$(id -u)" -eq 0 ]; then \
			cd "$(CURDIR)/build" && lb clean --purge || true; \
		else \
			cd "$(CURDIR)/build" && sudo lb clean --purge || true; \
		fi; \
	fi
	@rm -f "$(ISO)" "$(SHA256)" "$(ISO).buildinfo"
	@rm -rf build/.build build/binary build/chroot build/bootstrap build/cache
	@printf 'Removed EclipseOS build output.\n'

distclean: clean
	@rm -rf .cache .tools screenshots
	@printf 'Removed EclipseOS caches and local artefacts.\n'
