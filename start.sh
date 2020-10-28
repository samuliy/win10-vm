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
			export MEM_AMOUNT=14336
		;;
	esac
done

if [[ -n "$HUGEPAGES" ]]; then
	log "Setting up hugepages."

	# Flush buffers and drop caches
	sync
	echo 1 > /proc/sys/vm/drop_caches

	# Defrag ram
	echo 1 > /proc/sys/vm/compact_memory

	# Assign hugepages
	echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
	sysctl -w vm.nr_hugepages=$((MEM_AMOUNT/2))

	log "Hugepages set up."
fi

# USB
if [[ -n "$USB_PASSTHROUGH" ]]; then
	source $SCRIPT_DIR/prompt/usb.sh
fi

# PCI
if [[ -n "$PCI_PASSTHROUGH" ]]; then
	modprobe vfio || exit 2
	modprobe vfio-pci || exit 2
	modprobe -r kvm_intel
	modprobe kvm_intel nested=1

	source $SCRIPT_DIR/prompt/pci.sh
fi

(
	SECONDS=0
	while ! ps -e | grep -q qemu-system-x86_64 ; do
		sleep 1
		if [[ $SECONDS -gt 60 ]]; then
			echo >&2 "Timed out while waiting for qemu to be up!"
			exit 2
		fi
	done

	QEMU_NICE=-10
	QEMU_CHRT_PRI=1

	PROC_PID=$(ps -o 'pid=' -o 'comm=' | grep qemu-system-x86_64 | awk '{ print $1 }')
	for THREAD_PID in $(ps -T -H -o 'tid=' $PROC_PID | awk '{ print $1 }'); do
		renice -n $QEMU_NICE -p $THREAD_PID
		chrt --rr --pid $QEMU_CHRT_PRI $THREAD_PID
	done
) &

CONF=$( $SCRIPT_DIR/conf/run.sh )
CMD="qemu-system-x86_64 $CONF"
log "$CMD"
$CMD

if [[ -n "$PCI_PASSTHROUGH" ]]; then
	source $SCRIPT_DIR/restore/pci.sh
fi

if [[ -n "$HUGEPAGES" ]]; then
	log "Disabling hugepages."
	sysctl -w vm.nr_hugepages=0
	log "Hugepages disabled."
fi
