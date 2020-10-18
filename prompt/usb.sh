#!/bin/bash

USB_CONF="
	-device qemu-xhci,id=xhci
"
USB_DEVICES_ARR=()

clear
ia_log "Picked devices: ${USB_DEVICES_ARR[@]}"
while read -r DEVICE <<< $(prompt_usb_device_list) ; do
	if [[ -z "$DEVICE" ]]; then
		break
	fi
	USB_DEVICES_ARR+=($DEVICE)
	VENDOR_ID=$(echo $DEVICE | cut -d ':' -f 1)
	PRODUCT_ID=$(echo $DEVICE | cut -d ':' -f 2)
	USB_CONF="
		$USB_CONF
		-device usb-host,bus=xhci.0,vendorid=0x$VENDOR_ID,productid=0x$PRODUCT_ID
	"
	clear
	ia_log "Picked devices: ${USB_DEVICES_ARR[@]}"
done
clear

unset VENDOR_ID PRODUCT_ID USB_DEVICES_ARR

export USB_CONF=$USB_CONF
