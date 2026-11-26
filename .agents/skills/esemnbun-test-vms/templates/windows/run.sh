#!/bin/bash
# Windows 11 ARM64 test VM (eSemnBun). SSH: ssh -p 2223 user@127.0.0.1  RDP: 127.0.0.1:33389  Console VNC: 127.0.0.1:5902
# INSTALL=1 attaches the Windows ISO + unattend ISO.
cd "$(dirname "$0")"
inst=()
if [[ -n "$INSTALL" ]]; then
  inst=(-drive if=none,id=inst,file=../images/Win11_ARM64_Pro_en-US.iso,media=cdrom,readonly=on -device usb-storage,drive=inst,bootindex=1
        -drive if=none,id=unatt,file=unattend.iso,media=cdrom,readonly=on -device usb-storage,drive=unatt)
fi
exec /opt/homebrew/bin/qemu-system-aarch64 -name "Windows 11 eSemnBun" \
  -machine virt,highmem=on -accel hvf -cpu host -smp 4 -m 8192 \
  -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=pflash,format=raw,file=efivars.fd \
  -device virtio-gpu-pci,xres=1600,yres=1000 -display cocoa,show-cursor=on -vnc 127.0.0.1:2 \
  -device qemu-xhci,id=xhci -device usb-kbd -device usb-tablet \
  -drive if=none,id=disk,file=windows.qcow2,format=qcow2,discard=unmap -device nvme,drive=disk,serial=esemnbun0,bootindex=0 \
  "${inst[@]}" \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2223-:22,hostfwd=tcp:127.0.0.1:33389-:3389 -device virtio-net-pci,netdev=net0 \
  -rtc base=localtime -audiodev none,id=snd0 \
  -qmp unix:qmp.sock,server=on,wait=off -pidfile qemu.pid "$@"
