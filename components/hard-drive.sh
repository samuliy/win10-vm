#!/bin/bash

HARD_DRIVE_IMG_FILE=/home/samuliy/sdc1/win10.img

if [[ ! -f $HARD_DRIVE_IMG_FILE ]]; then
	qemu-img create -f raw -o preallocation=full $HARD_DRIVE_IMG_FILE 80G > /dev/null
fi

HARD_DRIVE_BOOT_INDEX=1
if [[ -n "$INSTALL" ]]; then
	HARD_DRIVE_BOOT_INDEX=2
fi

HARD_DRIVE_ID=disk0
HARD_DRIVE="
	-drive id=$HARD_DRIVE_ID,if=none,cache=none,format=raw,file=$HARD_DRIVE_IMG_FILE
	-device virtio-blk-pci,drive=$HARD_DRIVE_ID,bootindex=$HARD_DRIVE_BOOT_INDEX
"

echo $HARD_DRIVE

unset HARD_DRIVE HARD_DRIVE_IMG_FILE
