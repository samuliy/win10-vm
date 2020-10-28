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

	VGA_DEVICE=""
	NET_DEVICE=""
	for DEVICE in $PCI_DEVICES; do
		if lspci | grep $DEVICE | grep -q VGA ; then
			# GPU passthrough
			VGA_DEVICE=$DEVICE
			detach_console
		elif lspci | grep $DEVICE | grep -q Ethernet ; then
			# Net device passthrough
			# Disable net device emulation
			echo "-net none"
		fi
	done

	ADDT_VGA_DEVICES=()
	if [[ -n "$VGA_DEVICE" ]]; then
		# Check if there are other functions in the same device.
		for DEVICE in $PCI_DEVICES; do
			if [[ $DEVICE = "$(echo $VGA_DEVICE | cut -d '.' -f 1)"* ]] && [[ $DEVICE != $VGA_DEVICE ]]; then
				ADDT_VGA_DEVICES+=($DEVICE)
			fi
		done

		# Add PCIe root bus device for GPU passthrough
		echo "-device ioh3420,id=root_port1,chassis=0,slot=0,bus=pcie.0"
		# Disable VGA and graphical UI
		echo "-vga none -nographic"
	fi

	for DEVICE in $PCI_DEVICES; do
		DEVICE_CONFIG="-device vfio-pci,host=$DEVICE"

		bind_device $DEVICE vfio-pci

		if [[ $DEVICE = $VGA_DEVICE ]]; then
			# GPU passthrough
			DEVICE_CONFIG="
				$DEVICE_CONFIG,multifunction=on,bus=root_port1,addr=0x00
			"
		fi

		ADDT_VGA_DEVICE_ADDR=1
		for ADDT_VGA_DEVICE in "${ADDT_VGA_DEVICES[@]}"; do
			if [[ $DEVICE = $ADDT_VGA_DEVICE ]]; then
				# Add all the GPU functions to the same root bus device
				DEVICE_CONFIG="
					$DEVICE_CONFIG,bus=root_port1,addr=0x00.$ADDT_VGA_DEVICE_ADDR
				"
			fi
			ADDT_VGA_DEVICE_ADDR=$(($ADDT_VGA_DEVICE_ADDR+1))
		done

		echo $DEVICE_CONFIG

		unset DEVICE_CONFIG ADDT_VGA_DEVICE ADDT_VGA_DEVICE_ADDR
	done

	unset VGA_DEVICE ADDT_VGA_DEVICES

	for DRIVER in $PCI_DRIVERS; do
		unbind_driver $DRIVER
	done
fi
