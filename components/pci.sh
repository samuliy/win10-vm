#!/bin/bash

if [[ -z "$PCI_DEVICES" ]]; then
	# Use Spice
	VGA_CONF="
		-display spice-app
		-vga qxl
		-device virtio-serial-pci
		-spice port=5930,disable-ticketing
		-device virtserialport,chardev=spicechannel0,name=com.redhat.spice.0
		-chardev spicevmc,id=spicechannel0,name=vdagent
	"
	NET_CONF="
		-net nic -net user
	"
	SOUND_CONF="
		-device intel-hda -device hda-duplex
	"
	echo $VGA_CONF
	echo $NET_CONF
	echo $SOUND_CONF

	unset VGA_CONF NET_CONF SOUND_CONF
else
	# VFIO passthrough

	if [[ -z "$PCI_DRIVERS" ]]; then
		echo >&2 "PCI drivers variable is not set!"
		exit 2
	fi

	detach_console # For GPU passthrough

	for DEVICE in $PCI_DEVICES; do
		bind_device $DEVICE vfio-pci
		echo "-device vfio-pci,host=$DEVICE"
	done

	for DRIVER in $PCI_DRIVERS; do
		unbind_driver $DRIVER
	done
fi
