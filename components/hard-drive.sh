#!/bin/bash

HARD_DRIVE_IMG_FILE=/home/samuliy/sdc1/win10.img

if [[ ! -f $HARD_DRIVE_IMG_FILE ]]; then
	qemu-img create -f raw -o preallocation=full $HARD_DRIVE_IMG_FILE 40G > /dev/null
fi

HARD_DRIVE="
	-drive id=disk0,if=virtio,cache=none,format=raw,file=$HARD_DRIVE_IMG_FILE
"

echo $HARD_DRIVE

unset HARD_DRIVE HARD_DRIVE_IMG_FILE
