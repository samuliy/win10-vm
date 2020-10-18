#!/bin/bash

source lib/helpers

PCI_DEVICES_ARR=()
PCI_DRIVERS_ARR=()
PCI_DEVICES=""
PCI_DRIVERS=""

clear
ia_log "Picked devices: ${PCI_DEVICES_ARR[@]}"
while read -r DEVICE <<< $(prompt_pci_device_list) ; do
	if [[ -z "$DEVICE" ]]; then
		break
	fi

	DRIVER=$(get_device_driver $DEVICE)
	if [[ -z "$DRIVER" ]]; then
		echo >&2 "Failed to get driver for device: $DEVICE!"
		exit 2
	fi

	PCI_DEVICES_ARR+=($DEVICE)
	PCI_DRIVERS_ARR+=($DRIVER)

	clear
	ia_log "Picked devices: ${PCI_DEVICES_ARR[@]}"
done
clear

log "PCI Devices: ${PCI_DEVICES_ARR[@]}"
log "PCI Drivers: ${PCI_DRIVERS_ARR[@]}"

export PCI_DEVICES="${PCI_DEVICES_ARR[@]}"
export PCI_DRIVERS="${PCI_DRIVERS_ARR[@]}"

unset DRIVER DEVICE PCI_DEVICES_ARR PCI_DRIVERS_ARR
