#!/bin/bash
# Fedora 44 aarch64 test VM (eSemnBun). SSH: ssh -p 2222 user@127.0.0.1  Console VNC: 127.0.0.1:5901
cd "$(dirname "$0")"
exec /opt/homebrew/bin/qemu-system-aarch64 -name "Fedora 44 eSemnBun" \
  -machine virt,highmem=on -accel hvf -cpu host -smp 4 -m 6144 \
  -drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-aarch64-code.fd \
  -drive if=pflash,format=raw,file=efivars.fd \
  -device qemu-xhci,id=xhci -device usb-kbd -device usb-tablet \
  -device virtio-gpu-pci,xres=1600,yres=1000 -display cocoa,show-cursor=on -vnc 127.0.0.1:1 \
  -drive if=none,id=disk,file=fedora.qcow2,format=qcow2,discard=unmap -device virtio-blk-pci,drive=disk,bootindex=0 \
  ${SEED:+-drive if=none,id=seed,file=seed.iso,format=raw,readonly=on -device virtio-blk-pci,drive=seed} \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 -device virtio-net-pci,netdev=net0 \
  -device virtio-rng-pci -audiodev none,id=snd0 \
  -qmp unix:qmp.sock,server=on,wait=off -pidfile qemu.pid "$@"
