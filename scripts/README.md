# Helper scripts

| Script | Purpose |
| --- | --- |
| `check-host.sh` | Validate OS, tools, disk, RAM and optional QEMU/OVMF test dependencies. |
| `build.sh` | One-command live-build wrapper used by `make iso`; elevates with sudo and writes the SHA256/build-info. |
| `checksum.sh` | Create or verify the ISO's SHA256 file. |
| `create-vbox-vm.sh` | Create a 4 GiB / 2 vCPU / EFI / 25 GiB VirtualBox VM and attach the ISO. |
| `test-qemu.sh` | Headless UEFI/BIOS boot test wrapper. |
| `qemu_boot_test.py` | QEMU/QMP driver, serial-marker check and screenshot capture. |

All scripts are Bash 5.x and target Debian 13. `create-vbox-vm.sh` also works
under Git Bash on Windows when `VBoxManage` is on `PATH`; path conversion is
handled with `cygpath` when available.

No script in this directory has been executed against a built ISO in the
current sandbox. Syntax checks are not a substitute for a boot test.
