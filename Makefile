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

.PHONY: all help assets doctor iso iso-strict checksum verify static-check test test-uefi test-bios test-all test-vm clean distclean

all: iso

help:
	@printf '%s\n' \
	  'EclipseOS build targets:' \
	  '  make assets      Render brand PNGs into branding/assets/' \
	  '  make doctor      Check the build host and required tools' \
	  '  make iso         Build the hybrid ISO, SHA256 and build info' \
	  '  make iso STRICT_FOSS=1  Build without non-free firmware' \
	  '  make iso-strict  Alias for STRICT_FOSS=1 make iso' \
	  '  make checksum    Recreate the SHA256 file for the existing ISO' \
	  '  make verify      Verify the existing ISO against its SHA256 file' \
	  '  make static-check  Shell/Python/JSON/desktop-entry checks' \
	  '  make test        Alias for test-all' \
	  '  make test-uefi   Boot-test the ISO in QEMU with UEFI/OVMF' \
	  '  make test-bios   Boot-test the ISO in QEMU with legacy BIOS' \
	  '  make test-all    Run both QEMU boot tests' \
	  '  make test-vm     Create and start a VirtualBox VM (VBoxManage required)' \
	  '  make clean       Remove build output and generated assets' \
	  '  make distclean   clean + remove downloaded caches and local artefacts'

assets:
	@python3 branding/render.py --out branding/assets

doctor:
	@./scripts/check-host.sh --with-tests

iso:
	@./scripts/build.sh

iso-strict:
	@STRICT_FOSS=1 ./scripts/build.sh

checksum:
	@./scripts/checksum.sh "$(ISO)"

verify:
	@./scripts/checksum.sh --verify "$(ISO)"

static-check:
	@./scripts/static-check.sh

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
	@rm -rf branding/assets build/config/includes.chroot/usr/share/doc/eclipseos
	@rm -rf build/config/includes.chroot/usr/share/backgrounds/eclipseos
	@rm -rf build/config/includes.chroot/usr/share/pixmaps/eclipseos
	@rm -f build/config/includes.chroot/usr/share/plymouth/themes/eclipseos/logo.png
	@rm -f build/config/includes.chroot/usr/share/plymouth/themes/eclipseos/splash.png
	@rm -f build/config/includes.chroot/usr/share/plymouth/themes/eclipseos/eclipseos-progress-track.png
	@rm -f build/config/includes.chroot/usr/share/plymouth/themes/eclipseos/eclipseos-progress-fill.png
	@rm -f build/config/bootloaders/grub-pc/splash.png
	@rm -f build/config/bootloaders/grub-pc/unicode.pf2
	@rm -f build/config/package-lists/eclipse-firmware.list.chroot
	@rm -f build/config/hooks/normal/*.hook.chroot
	@rm -f build/config/hooks/live/*.hook.chroot
	@printf 'Removed EclipseOS build output and generated assets.\n'

distclean: clean
	@rm -rf .cache .tools screenshots
	@printf 'Removed EclipseOS caches and local artefacts.\n'
