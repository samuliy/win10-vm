#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

INSTALL_CD=/home/samuliy/sdc1/ISO/Win10_1809Oct_EnglishInternational_x64.iso
DRIVER_CD=/home/samuliy/sdc1/ISO/virtio-win-0.1.141.iso

BOOT="
-boot order=dc
"

CD_DRIVE="
-drive file=$DRIVER_CD,index=2,media=cdrom
-drive file=$INSTALL_CD,index=2,id=drive-ide0,if=none,format=raw,readonly=on
-device ide-cd,bus=ide.0,unit=0,drive=drive-ide0,id=ide0-0-0,bootindex=1
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
