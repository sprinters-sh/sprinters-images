#!/bin/bash

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

if [ -n "${DOCKERD_ASYNC}" ]; then
    timestamp "Starting dockerd async ..."
    /start-docker.sh &
else
    /start-docker.sh
fi

if [ -n "${JITCONFIG}" ]; then
    timestamp "Launching Runner with JIT config ..."
    run_quiet ./run.sh --jitconfig "$JITCONFIG"
else
    timestamp "Configuring Runner ..."
    (run_quiet ./config.sh --url https://github.com/$REPO \
               --token $TOKEN \
               --labels $LABELS \
               --ephemeral --disableupdate --unattended) || exit 1

    timestamp "Launching Runner ..."
    run_quiet ./run.sh
fi
