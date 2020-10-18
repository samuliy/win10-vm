#!/bin/bash

if [[ -n "$PCI_DEVICES" ]]; then
	for INDEX in 1.."${#PCI_DEVICES[@]}"; do
		DEVICE=$PCI_DEVICES[$INDEX]
		DRIVER=$PCI_DRIVERS[$INDEX]
		bind_device $DEVICE $DRIVER
	done
fi

attach_console
