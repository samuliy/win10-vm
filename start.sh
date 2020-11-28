#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $SCRIPT_DIR/lib/helpers

init_log
redirect_log win10.log
redirect_stderr win10.log

log "Windows 10 VM"
log ""

for ARG; do
	case $ARG in
		--install)
			log "Installing Windows 10."
			export INSTALL=1
		;;
		--pci-passthrough)
			log "Using PCI passthrough."
			export PCI_PASSTHROUGH=1
		;;
		--usb-passthrough)
			log "Using USB passthrough."
			export USB_PASSTHROUGH=1
		;;
		--hugepages)
			log "Using Hugepages."
			export HUGEPAGES=1
			export MEM_AMOUNT=$((12*1024))
			export MEM_AMOUNT_B=$((MEM_AMOUNT*1024))
		;;
		--cpu-pinning)
			log "Using CPU pinning."
			export CPU_PINNING=1
		;;
	esac
done

if [[ -n "$HUGEPAGES" ]]; then
	log "Setting up hugepages."

	export DIRTY_RATIO=$(cat /proc/sys/vm/dirty_ratio)
	export DIRTY_BG_RATIO=$(cat /proc/sys/vm/dirty_background_ratio)
	export SWAPPINESS=$(cat /proc/sys/vm/swappiness)

	log "Dirty ratio was set to $DIRTY_RATIO."
	log "Dirty background ratio was set to $DIRTY_BG_RATIO."
	log "Swappiness was set to $SWAPPINESS."

	echo "5" > /proc/sys/vm/dirty_background_ratio
	echo "8" > /proc/sys/vm/dirty_ratio
	echo "5" > /proc/sys/vm/swappiness

	log "Dirty ratio is now set to $(cat /proc/sys/vm/dirty_ratio)."
	log "Dirty background ratio is now set to $(cat /proc/sys/vm/dirty_background_ratio)."
	log "Swappiness is now set to $(cat /proc/sys/vm/swappiness)."

	# Flush buffers and drop caches
	sync
	echo 1 > /proc/sys/vm/drop_caches

	# Defrag ram
	echo 1 > /proc/sys/vm/compact_memory

	# Assign hugepages
	echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
	sysctl -w vm.nr_hugepages=$((MEM_AMOUNT/2))
	sysctl -w kernel.shmmax=$((MEM_AMOUNT_B/2))

	log "Hugepages set up."
fi

# USB
if [[ -n "$USB_PASSTHROUGH" ]]; then
	source $SCRIPT_DIR/prompt/usb.sh
fi

# PCI
if [[ -n "$PCI_PASSTHROUGH" ]]; then
	modprobe -r vfio-pci
	modprobe -r vfio_iommu_type1
	modprobe -r vfio_virqfd
	modprobe -r vfio
	modprobe -r vhost-net

	modprobe vfio || exit 2
	modprobe vfio-pci || exit 2
	modprobe vfio_iommu_type1 allow_unsafe_interrupts=1 || exit 2
	modprobe vfio_virqfd || exit 2
	modprobe vhost-net || exit 2

	modprobe -r kvm_intel
	modprobe -r kvm
	modprobe kvm ignore_msrs=1
	modprobe kvm_intel nested=1

	source $SCRIPT_DIR/prompt/pci.sh
fi

CONF=$( $SCRIPT_DIR/conf/run.sh )
CMD="qemu-system-x86_64 $CONF"
log "$CMD"

cpupower frequency-set -g performance

$CMD &
export QEMU_PROC_PID=$!

if [[ -n "$CPU_PINNING" ]]; then
	# Give QEMU some time to start up.
	SECONDS=0
	while ps -p $QEMU_PROC_PID > /dev/null; do
		sleep 1
		if [[ $SECONDS -gt 20 ]]; then
			# Set thread priorities
			log "Enabling CPU pinning."
			$SCRIPT_DIR/cpu-pin/enable.sh
			break
		fi
	done
fi

wait $QEMU_PROC_PID

cpupower frequency-set -g powersave

if [[ -n "$PCI_PASSTHROUGH" ]]; then
	source $SCRIPT_DIR/restore/pci.sh
fi

if [[ -n "$HUGEPAGES" ]]; then
	log "Disabling hugepages."
	sysctl -w vm.nr_hugepages=0
	log "Hugepages disabled."

	echo $DIRTY_RATIO > /proc/sys/vm/dirty_ratio
	echo $DIRTY_BG_RATIO > /proc/sys/vm/dirty_background_ratio
	echo $SWAPPINESS > /proc/sys/vm/swappiness

	log "Dirty ratio set to $(cat /proc/sys/vm/dirty_ratio)."
	log "Dirty background ratio set to $(cat /proc/sys/vm/dirty_background_ratio)."
	log "Swappiness is now set to $(cat /proc/sys/vm/swappiness)."
fi

if [[ -n "$CPU_PINNING" ]]; then
	log "Disabling CPU pinning."
	$SCRIPT_DIR/cpu-pin/disable.sh
fi
