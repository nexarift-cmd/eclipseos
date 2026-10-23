# Phase 2 real VirtualBox boot: 3000 MiB, BIOS, `768a4f9`

Status: **manual pass for the reported BIOS configuration**, with no
framebuffer or serial capture. This is **not** a final-ISO acceptance record
and it is **not** a VirtualBox UEFI result.

## Image

- Build: GitHub Actions run
  [39842389588](https://github.com/nexarift-cmd/eclipseos/actions/runs/39842389588),
  commit `768a4f9`.
- ISO: `eclipseos-26.10-amd64.iso`
- SHA-256:
  `98cbee632c0647ba033d5ba5dc0454528d1de7688eca2e0a02a2d6a9834ba36a`
- Size: `1,503,238,144` bytes.
- VirtualBox: 7.2.20r175154.
- VM: `UltraSigmaEclipseOS`.
- Guest RAM: 3000 MiB.
- Firmware: **BIOS** (`EFI off`).
- Graphics: VMSVGA, 128 MiB VRAM.
- Storage: IDE optical drive with the ISO above.

`VBoxManage showvminfo UltraSigmaEclipseOS --machinereadable` confirmed
`memory=3000`, `firmware="BIOS"`, `graphicscontroller="vmsvga"`,
`vram=128`, and the IDE ISO attachment after the run. The latest `VBox.log`
records a 26:49 VM session. The log helps confirm the VM configuration and
lifetime, not the guest desktop contents.

## Reported by the project owner

- Desktop reached: **yes**; the exact time was not recorded.
- Input/desktop lag: **improved** compared with the earlier 2048 MiB report.
- Firefox start page: **working**.
- Power menu: **visible**.
- Live light-theme switch: **working**.
- Problems: **none reported**.

The owner did not report a screenshot, serial log, Start-menu power-off
action, tray-control clicks or a greeter login. Those remain unverified.

## Scope and limitations

- This report is for `768a4f9`, not the final `0dd6f0f` ISO. The final ISO has
  additional light-theme and boot-check fixes and is covered by QEMU run
  39903705903.
- Only BIOS firmware was tested. Real VirtualBox UEFI remains open.
- 3000 MiB is above the 2048 MiB minimum but is not the recommended 4096 MiB.
  4096 MiB could not be tested on this host.
- No framebuffer screenshot or serial marker was captured, so the desktop
  observation is manual evidence. The QEMU captures in
  [`README.md`](README.md) provide the machine-visible framebuffer evidence.
- Runtime theme switching was reported working by the owner; the separate
  QEMU light boot validates the one-shot light path on the final ISO.

The earlier 2048 MiB report for `78474f5` is in
[`virtualbox-2048-manual.md`](virtualbox-2048-manual.md).
