#!/bin/bash

# Prefix text with timestamp (Example: 2024-11-19 08:08:03 My command output)
timestamp() {
    echo "$(date -u -Iseconds | tr 'T' ' ' | cut -d'+' -f1)" "$@"
}

timestamp "Sprinters Job Starting..."

until docker info >/dev/null 2>&1; do
    timestamp "Waiting for Docker daemon to be ready..."
    sleep 1
done
timestamp "Docker daemon is ready!"
timestamp "Sprinters Job Started."
echo ""
echo "Instance: $(hostname)"
echo "vCPUs   : $(nproc)"
echo "RAM     : $(grep MemTotal /proc/meminfo | awk '{value=$2/1024/1024; if(value!=int(value)) value=int(value)+1; print value}') GiB"
echo "Disks   :"
lsblk -d -o NAME,SIZE --bytes | awk 'NR>1 {printf "%s\t%.0f GiB\n", $1, $2/(1024^3)}'
