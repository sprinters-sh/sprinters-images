#!/bin/bash

# Prefix text with timestamp (Example: 2024-11-19 08:08:03 My command output)
timestamp() {
    echo "$(date -u -Iseconds | tr 'T' ' ' | cut -d'+' -f1)" "$@"
}

timestamp "===> Sprinters Job Starting..."

until docker info >/dev/null 2>&1; do
    timestamp "Waiting for Docker daemon to be ready..."
    sleep 1
done
timestamp "Docker daemon is ready!"

timestamp "Instance: $(hostname)"

timestamp "===> Sprinters Job Started."
