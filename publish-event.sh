#!/bin/bash

url="$SPRINTERS_RUNNER_WEBHOOK"
if [ -z "$url" ]; then
  # Event publishing is disabled
  exit 0
fi

event=$1
hostname=$(hostname)
timestamp="$(date -u -Ins  | tr ',' '.' | cut -c1-23)Z"

uuid=$(cat /proc/sys/kernel/random/uuid)
payload="{\"event\":\"$event\",\"hostname\":\"$hostname\",\"timestamp\":\"$timestamp\"}"
sha256=$(printf "%s" "$payload" | sha256sum | awk '{print $1}')

curl -s -k "$url" \
  -H "Content-Type: application/json" \
  -H "X-Runner-Delivery: $uuid" \
  -H "X-Runner-Action: event" \
  -H "X-Runner-Sha256: $sha256" \
  -d "$payload" > /dev/null

echo "$timestamp $hostname -> $event"
