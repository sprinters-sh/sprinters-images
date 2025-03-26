#!/bin/bash

/publish-event.sh job-started

until docker info >/dev/null 2>&1; do
    echo "Waiting for Docker daemon to be ready..."
    sleep 1
done
echo "Runner powered by Sprinters"
echo "Instance : $(hostname)"
echo "vCPUs    : $(nproc)"
echo "RAM      : $(grep MemTotal /proc/meminfo | awk '{value=$2/1024/1024; if(value!=int(value)) value=int(value)+1; print value}') GiB"
echo "Root     : $(lsblk -n -d -o SIZE,MOUNTPOINTS,TYPE --bytes | grep disk | grep -v -e SWAP -e /var | awk '{print $1/1024^3}') GiB"
echo "Swap     : $(lsblk -n -d -o SIZE,MOUNTPOINTS --bytes | grep SWAP | awk '{print $1/1024^3}') GiB"
echo "Temp     : $(lsblk -n -d -o SIZE,MOUNTPOINTS --bytes | grep disk | grep /var | awk '{print $1/1024^3}') GiB"
echo "Disks    :"
lsblk --bytes -d -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
