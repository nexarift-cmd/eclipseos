# Experimental hobby kernel

This directory is reserved for the optional Phase 8 learning project: a small
x86_64 UEFI application that obtains a GOP framebuffer and prints:

```text
Hello from EclipseOS kernel
```

It is **not** the EclipseOS product kernel, is not included in the main ISO,
and must build independently. Planned tooling: Rust (`x86_64-unknown-uefi`) or
C with a GNU-EFI/EDK2 toolchain, tested under QEMU with OVMF.

This directory stays empty until the main release phases are complete.
