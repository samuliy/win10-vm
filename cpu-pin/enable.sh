#!/bin/bash

MEM=0
QEMU_NICE=-10
QEMU_CHRT_PRI=1

if [[ -z "$QEMU_PROC_PID" ]]; then
	echo >&2 "Qemu proc pid not set!"
	exit 2
fi

for CPUSET in "system" "qemu" ; do
	if [[ ! -d "/sys/fs/cgroup/cpuset/$CPUSET" ]]; then
		mkdir "/sys/fs/cgroup/cpuset/$CPUSET"
	fi
	echo $MEM > "/sys/fs/cgroup/cpuset/$CPUSET/cpuset.mems"
done

echo 0,4 > "/sys/fs/cgroup/cpuset/system/cpuset.cpus"

echo 1,2,3,5,6,7 > "/sys/fs/cgroup/cpuset/qemu/cpuset.cpus"

# Move all tasks to system cgroup
cat /sys/fs/cgroup/cpuset/tasks | xargs -I % bash -c 'echo % > /sys/fs/cgroup/cpuset/system/tasks'

# Set QEMU CPU threads to QEMU cgroup
CPUS=(1 2 3 5 6 7)
for THREAD_PID in $(ps -T -H -o 'tid=' -o 'comm=' $QEMU_PROC_PID | grep "CPU" | awk '{ print $1 }'); do
	# Assign thread to QEMU cgroup
	echo $THREAD_PID > /sys/fs/cgroup/cpuset/qemu/tasks
	renice -n $QEMU_NICE -p $THREAD_PID
	chrt --fifo --pid $QEMU_CHRT_PRI $THREAD_PID

	# Shift last CPU from the array
	CPU=${CPUS[${#CPUS[@]}-1]}
	CPUS=("${CPUS[@]:0:${#CPUS[@]}-1}")

	# Pin task to a CPU
	taskset -pc $CPU $THREAD_PID
done

# Set other QEMU threads to system cgroup
for THREAD_PID in $(ps -T -H -o 'tid=' -o 'comm=' $QEMU_PROC_PID | grep -v "CPU" | awk '{ print $1 }'); do
	echo $THREAD_PID > /sys/fs/cgroup/cpuset/system/tasks
done
