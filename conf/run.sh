#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

BOOT="
-boot order=c
"

CD_INDEX=1
CD_DRIVES=""

if [[ -n "$INSTALL" ]]; then
	for ISO in $SCRIPT_DIR/../cd-drive-install/*.iso ; do
		if [[ -z "$CD_BOOT_DEVICE_CREATED" ]]; then
			CD_DRIVES="
				$CD_DRIVES
				-device ide-cd,bus=ide.0,unit=0,drive=drive-ide0,id=ide0-0-0,bootindex=1
				-drive file=$ISO,index=$CD_INDEX,id=drive-ide0,if=none,format=raw,readonly=on
			"
			CD_INDEX=$(($CD_INDEX+1))
		else
			echo >&2 "Found multiple install CDs!"
			exit 2
		fi
	done
fi

for ISO in $SCRIPT_DIR/../cd-drive/*.iso ; do
	CD_DRIVES="
		$CD_DRIVES
		-drive file=$ISO,index=$CD_INDEX,media=cdrom
	"
	CD_INDEX=$(($CD_INDEX+1))
done

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
$CD_DRIVES
"

echo $CONF
