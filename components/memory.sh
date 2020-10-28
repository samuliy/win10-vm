#!/bin/bash

MEMORY_CONF="
	-m 2048
"
if [[ -n "$HUGEPAGES" ]]; then
	if [[ -z "$MEM_AMOUNT" ]]; then
		MEM_AMOUNT=2048
	fi
	MEMORY_CONF="
		-m $MEM_AMOUNT
	"
	MEMORY_CONF="
		$MEMORY_CONF
		-mem-prealloc
		-mem-path /dev/hugepages
	"
fi

echo $MEMORY_CONF

unset MEMORY_CONF
