#!/bin/bash

VCPU_COUNT=$(lscpu | grep -P "^CPU\(s\):\s+" | awk '{ print $2 }')
VCPU_COUNT=$(($VCPU_COUNT-1))

CPU="
	-smp $VCPU_COUNT,sockets=1,cores=$VCPU_COUNT,threads=1
	-cpu host,kvm=off,hv_vendor_id=1234567890ab,hv_vapic,hv_time,hv_relaxed,hv_spinlocks=0x1fff,+vmx
"

echo $CPU

unset CPU VCPU_COUNT
