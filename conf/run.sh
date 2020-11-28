#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

CD_INDEX=1
CD_DRIVES=""

INSTALL_DISK_BOOT_INDEX=2
if [[ -n "$INSTALL" ]]; then
	INSTALL_DISK_BOOT_INDEX=1
fi

for ISO in $SCRIPT_DIR/../components/cd-drive-install/*.iso ; do
	if [[ -z "$CD_BOOT_DEVICE_CREATED" ]]; then
		CD_DRIVES="
			$CD_DRIVES
			-device ide-cd,bus=ide.0,unit=0,drive=drive-ide0,id=ide0-0-0,bootindex=$INSTALL_DISK_BOOT_INDEX
			-drive file=$ISO,index=$CD_INDEX,id=drive-ide0,if=none,format=raw,readonly=on
		"
		CD_INDEX=$(($CD_INDEX+1))
		CD_BOOT_DEVICE_CREATED=1
	else
		echo >&2 "Found multiple install CDs!"
		exit 2
	fi
done

for ISO in $SCRIPT_DIR/../components/cd-drive/*.iso ; do
	CD_DRIVES="
		$CD_DRIVES
		-drive file=$ISO,index=$CD_INDEX,media=cdrom
	"
	CD_INDEX=$(($CD_INDEX+1))
done

MACHINE="
-machine pc,accel=kvm,kernel_irqchip=on,mem-merge=off
"

OVMF_DIR=/usr/share/ovmf/x64
OVMF_VARS_PATH=$SCRIPT_DIR/../OVMF_VARS.fd
if [[ ! -f $OVMF_VARS_PATH ]]; then
	cp $OVMF_DIR/OVMF_VARS.fd $OVMF_VARS_PATH
fi

CONF="
-k fi
-nodefaults
-no-user-config
-enable-kvm
-name win10,debug-threads=on
-watchdog-action none
-serial none
-parallel none
-drive if=pflash,format=raw,readonly,file=$OVMF_DIR/OVMF_CODE.fd
-drive if=pflash,format=raw,file=$OVMF_VARS_PATH
-rtc base=localtime,driftfix=slew
-no-hpet
-usb
-overcommit mem-lock=on
$MACHINE
$( $SCRIPT_DIR/../components/cpu.sh )
$( $SCRIPT_DIR/../components/hard-drive.sh )
$( $SCRIPT_DIR/../components/memory.sh )
$( $SCRIPT_DIR/../components/usb.sh )
$( $SCRIPT_DIR/../components/pci.sh )
$CD_DRIVES
"

echo $CONF

