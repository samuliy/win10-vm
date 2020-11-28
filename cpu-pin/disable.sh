#!/bin/bash

cat /sys/fs/cgroup/cpuset/system/tasks | xargs -I % bash -c 'echo % > /sys/fs/cgroup/cpuset/tasks'
cat /sys/fs/cgroup/cpuset/qemu/tasks | xargs -I % bash -c 'echo % > /sys/fs/cgroup/cpuset/tasks'

rmdir /sys/fs/cgroup/cpuset/system
rmdir /sys/fs/cgroup/cpuset/qemu
