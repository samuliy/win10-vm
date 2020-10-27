#!/bin/bash

MEMORY_CONF="
	-m 2048
"
if [[ -n "$HUGEPAGES" ]]; then
	MEMORY_CONF="
		-m 12288
	"
	MEMORY_CONF="
		$MEMORY_CONF
		-mem-prealloc
		-mem-path /dev/hugepages
	"
fi

echo $MEMORY_CONF

unset MEMORY_CONF
