#!/bin/bash

if [[ -n "$PCI_DEVICES" ]]; then
	PCI_DEVICES_ARR=($PCI_DEVICES)
	PCI_DRIVERS_ARR=($PCI_DRIVERS)
	for INDEX in $(seq 0 $((${#PCI_DEVICES_ARR[@]}-1))); do
		DEVICE=${PCI_DEVICES_ARR[$INDEX]}
		DRIVER=${PCI_DRIVERS_ARR[$INDEX]}
		bind_device $DEVICE $DRIVER
	done
fi

unset PCI_DEVICES_ARR PCI_DRIVERS_ARR INDEX

attach_console
