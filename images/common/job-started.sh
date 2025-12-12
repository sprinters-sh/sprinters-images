#!/bin/bash

/publish-event.sh job-started

# shellcheck disable=SC2155
readonly privileged=$( [ -b /dev/loop0 ] && echo "true" || echo "false" )
if [ "$privileged" = "true" ]; then
  until docker info >/dev/null 2>&1; do
    echo "Waiting for Docker daemon to be ready..."
    sleep 1
  done
fi

echo
echo "Runner powered by Sprinters"
echo "---------------------------"
echo "Name     : $RUNNER_NAME"
echo "Instance : $(hostname)"
echo "vCPUs    : $(nproc)"
echo "RAM      : $(sudo lshw -short -C memory | grep -i "system memory" | awk '{print $3}' | sed 's/GiB//') GiB"
echo "Root     : $(lsblk -n -d -o SIZE,MOUNTPOINTS,TYPE --bytes | grep disk | grep -v -e SWAP -e / | tail -n 1 | awk '{print $1/1024^3}') GiB"
echo "Swap     : $(lsblk -n -d -o SIZE,MOUNTPOINTS --bytes | grep SWAP | awk '{print $1/1024^3}') GiB"
echo "Temp     : $(lsblk -n -d -o SIZE,MOUNTPOINTS,TYPE --bytes | grep disk | grep / | awk '{print $1/1024^3}') GiB"
echo
echo "Environment Variables"
echo "---------------------"
env | sort
