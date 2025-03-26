#!/bin/bash

/publish-event.sh job-started

until docker info >/dev/null 2>&1; do
    echo "Waiting for Docker daemon to be ready..."
    sleep 1
done
echo ""
echo "Instance : $(hostname)"
echo "vCPUs    : $(nproc)"
echo "RAM      : $(grep MemTotal /proc/meminfo | awk '{value=$2/1024/1024; if(value!=int(value)) value=int(value)+1; print value}') GiB"
echo "Swap     : $(lsblk -n -d -o NAME,SIZE,FSTYPE --bytes | grep swap | awk '{print $2/1024^3}') GiB"
echo "Disks    :"
lsblk -n -d -o NAME,SIZE,FSTYPE --bytes | awk '{printf "  %s (%s)\t%.0f GiB\n", $1, $3, $2/(1024^3)}'
