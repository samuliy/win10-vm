#!/bin/bash

BOOT_PARTITION_UUID=8428-AFC9
HARD_DRIVE_DEV=$(readlink -f /dev/disk/by-uuid/$BOOT_PARTITION_UUID | grep -Po "[a-z/]+")
HARD_DRIVE_BOOT_INDEX=1
HARD_DRIVE_INDEX=2
if [[ -n "$INSTALL" ]]; then
	HARD_DRIVE_BOOT_INDEX=2
fi

HARD_DRIVE="
	-drive file=$HARD_DRIVE_DEV,index=$HARD_DRIVE_INDEX,format=raw,if=none,id=drive0,cache=none,aio=native
	-device virtio-scsi-pci,id=scsi0,num_queues=1
	-device scsi-hd,drive=drive0,bootindex=$HARD_DRIVE_BOOT_INDEX
"

HARD_DRIVE="
	-device pcie-root-port,multifunction=on,id=hd_pcie_root_port
	-object iothread,id=io1
	-drive file=$HARD_DRIVE_DEV,index=$HARD_DRIVE_INDEX,format=raw,if=none,id=drive0,cache=none,aio=threads
	-device virtio-scsi-pci,id=scsi0,num_queues=1,bus=hd_pcie_root_port,iothread=io1,num_queues=4
	-device scsi-hd,drive=drive0,bootindex=$HARD_DRIVE_BOOT_INDEX
"

# Standard BLK:
#
# -drive file=$HARD_DRIVE_DEV,index=$HARD_DRIVE_INDEX,format=raw,if=none,id=drive0,cache=none,aio=native
# -device virtio-blk-pci,scsi=off,drive=drive0,id=virtio-disk0,bootindex=$HARD_DRIVE_BOOT_INDEX

# Standard BLK with IOThread:
#
#-drive file=$HARD_DRIVE_DEV,index=$HARD_DRIVE_INDEX,id=drive-hd0,if=none,format=raw,cache=none,aio=native
#-object iothread,id=iothread0
#-device virtio-blk-pci,iothread=iothread0,drive=drive-hd0,bootindex=$HARD_DRIVE_BOOT_INDEX

# SCSI with IOThread:
#
#-object iothread,id=iothread0
#-drive file=$INSTALLDRIVE,index=1,id=drive-hd0,if=none,format=raw,cache=none,aio=threads
#-device virtio-scsi-pci,id=scsi0,iothread=iothread0,num_queues=$CPU_COUNT
#-device scsi-hd,drive=drive-hd0

# SCSI without IOThread:
#
#-drive file=$INSTALLDRIVE,index=1,id=drive-hd0,if=none,format=raw,cache=none,aio=native
#-device virtio-scsi-pci,id=scsi0,num_queues=$VCPU_NUM
#-device scsi-hd,drive=drive-hd0

echo $HARD_DRIVE

unset HARD_DRIVE HARD_DRIVE_DEV HARD_DRIVE_INDEX HARD_DRIVE_BOOT_INDEX BOOT_PARTITION_UUID
