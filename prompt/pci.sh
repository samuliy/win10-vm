#!/bin/bash

PCI_DEVICES=()
PCI_DRIVERS=()

while read -r DEVICE <<< $(prompt_pci_device_list) ; do
	if [[ -z "$DEVICE" ]]; then
		break
	fi

	DRIVER=$(get_device_driver $DEVICE)
	if [[ -z "$DRIVER" ]]; then
		echo >&2 "Failed to get driver for device: $DEVICE!"
		exit 2
	fi

	PCI_DEVICES+=($DEVICE)
	PCI_DRIVERS+=($DRIVER)
done

unset DRIVER DEVICE

export PCI_DEVICES=$PCI_DEVICES
export PCI_DRIVERS=$PCI_DRIVERS
