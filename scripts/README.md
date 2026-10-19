# Helper scripts

| Script | Purpose |
| --- | --- |
| `check-host.sh` | Validate OS, tools, disk, RAM and optional QEMU/OVMF test dependencies. |
| `build.sh` | One-command live-build wrapper used by `make iso`; renders assets, stages docs/firmware/GRUB font, elevates with sudo, writes the SHA256/build-info and supports `STRICT_FOSS=1`. |
| `checksum.sh` | Create or verify the ISO's SHA256 file. |
| `create-vbox-vm.sh` | Create a 4 GiB / 2 vCPU / EFI / 25 GiB VirtualBox VM and attach the ISO. |
| `static-check.sh` | Shell syntax, ShellCheck, Python/JSON syntax and desktop-entry checks. |
| `test-qemu.sh` | Headless UEFI/BIOS boot test wrapper. |

`tests/qemu_boot_test.py` is the QEMU/QMP driver, serial-marker check and
screenshot capture. All scripts are Bash 5.x and target Debian 13
(`create-vbox-vm.sh` also works under Git Bash on Windows when `VBoxManage` is
on `PATH`; path conversion is handled with `cygpath` when available).

No script in this directory has been executed against a built ISO in the
current sandbox. Static checks are not a substitute for a boot test.
