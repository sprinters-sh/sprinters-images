#!/bin/bash

/publish-event.sh runner-boot

# Prefix text with timestamp (Example: 2024-11-19 08:08:03 My command output)
timestamp() {
    echo "$(date -u -Iseconds | tr 'T' ' ' | cut -d'+' -f1)" "$@"
}

# Run command with optional output suppression
run_quiet() {
    if [ -n "${QUIET}" ]; then
        "$@" >/dev/null 2>&1
    else
        "$@"
    fi
}

# Load and export environment variables
set -o allexport && source /etc/environment && set +o allexport

timestamp "Starting dockerd async ..."
/start-docker.sh &

timestamp "Launching Runner with JIT config ..."
trap 'true' SIGTERM
run_quiet ./run.sh --jitconfig "$JITCONFIG" &
wait $!

timestamp "Shutting down ..."
/publish-event.sh runner-shutdown
