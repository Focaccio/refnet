#!/bin/bash

# Paths
DISK="freebsd-24G.raw"
ISO="FreeBSD-14.2-RELEASE-arm64-aarch64-bootonly.iso"
BIOS="QEMU_EFI.fd"

# Create disk image if it doesn't exist
if [ ! -f "$DISK" ]; then
  echo "[*] Creating 24G disk image: $DISK"
  qemu-img create -f raw "$DISK" 24G
fi

# Choose whether to boot installer or OS
if [ -f "$ISO" ] && [ ! -f ".vm_initialized" ]; then
  echo "[*] Booting from FreeBSD installer ISO..."
  BOOT_ISO="-cdrom $ISO"
else
  BOOT_ISO=""
fi

# Launch the VM
qemu-system-aarch64 \
  -machine virt,highmem=off \
  -cpu host \
  -accel hvf \
  -m 4096 \
  -smp 4 \
  -nographic \
  -bios "$BIOS" \
  $BOOT_ISO \
  -drive if=none,file="$DISK",format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0 \
  -netdev vmnet-bridged,id=net0,ifname=en18 \
  -device virtio-net-device,netdev=net0 \
  -no-reboot

# If ISO was used, mark VM as initialized (user removes this file to reinstall)
if [ -f "$ISO" ] && [ ! -f ".vm_initialized" ]; then
  touch .vm_initialized
fi