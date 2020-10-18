#!/bin/bash

VCPU_NUM=8

CPU="
	-smp $VCPU_NUM,sockets=1,cores=$VCPU_NUM,threads=1
	-cpu host,kvm=off,hv_vendor_id=1234567890ab,hv_vapic,hv_time,hv_relaxed,hv_spinlocks=0x1fff,+vmx
"

echo $CPU

unset CPU VCPU_NUM
