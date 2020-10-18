#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

DRIVER_CD=/home/samuliy/ISO/virtio-win-0.1.141.iso

BOOT="
-boot order=c
"

CD_DRIVE="
-drive file=$DRIVER_CD,index=2,media=cdrom
"

MACHINE="
-machine q35,accel=kvm,kernel_irqchip=on,mem-merge=off
"

CONF="
-enable-kvm
-watchdog-action none
-serial none
-parallel none
-bios /usr/share/ovmf/x64/OVMF_CODE.fd
-rtc base=localtime,driftfix=slew
-no-hpet
-usb
$MACHINE
$( $SCRIPT_DIR/../components/cpu.sh )
$( $SCRIPT_DIR/../components/hard-drive.sh )
$( $SCRIPT_DIR/../components/memory.sh )
$( $SCRIPT_DIR/../components/usb.sh )
$( $SCRIPT_DIR/../components/pci.sh )
$CD_DRIVE
$BOOT
"

echo $CONF
