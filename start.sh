#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
source $SCRIPT_DIR/lib/helpers

init_log
redirect_log win10.log
redirect_stderr win10.log

log ""
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
		;;
	esac
done

if [[ -n "$HUGEPAGES" ]]; then
	log "Setting up hugepages."

	sync
	echo 1 > /proc/sys/vm/drop_caches
	# defrag ram
	echo 1 > /proc/sys/vm/compact_memory
	# assign hugepages
	sysctl -w vm.nr_hugepages=6144

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

	source $SCRIPT_DIR/prompt/pci.sh
fi

CONF=$( $SCRIPT_DIR/conf/run.sh )
if [[ -n "$INSTALL" ]]; then
	CONF="$CONF -boot order=dc"
else
	CONF="$CONF -boot order=c"
fi

CMD="qemu-system-x86_64 $CONF"
log "$CMD"
eval "$CMD"

if [[ -n "$PCI_PASSTHROUGH" ]]; then
	source $SCRIPT_DIR/restore/pci.sh
fi

if [[ -n "$HUGEPAGES" ]]; then
	log "Disabling hugepages."
	sysctl -w vm.nr_hugepages=0
	log "Hugepages disabled."
fi
