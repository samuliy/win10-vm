#!/bin/bash

HARD_DRIVE_DEV=/dev/sdd
HARD_DRIVE_BOOT_INDEX=1
if [[ -n "$INSTALL" ]]; then
	HARD_DRIVE_BOOT_INDEX=2
fi

HARD_DRIVE="
	-drive file=$HARD_DRIVE_DEV,format=raw,if=none,id=drive-virtio-disk0,cache=none,aio=native
	-device virtio-blk-pci,scsi=off,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=$HARD_DRIVE_BOOT_INDEX
"

echo $HARD_DRIVE

unset HARD_DRIVE HARD_DRIVE_DEV
