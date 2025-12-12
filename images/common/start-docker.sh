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

# Start a process and wait for a specific message
# Arguments:
# 1. Log file for output
# 2. Command to run the process
# 3. Regex indicating success when matched in output
# 3. Regex indicating failure when matched in output
wait_for_message_and_background() {
    local process_log="$1"
    local process_command="$2"
    local success_regex="$3"
    local failure_regex="$4"

    timestamp "Starting '$process_command' ..."
    touch "$process_log"

    # Start process with timestamp
    (set -e; timestamp "Process starting"; $process_command) > >(run_quiet tee "$process_log") 2>&1 &
    local pid=$!

    timestamp "Waiting for '$process_command' success message..."
    while true; do
        if grep -q "$success_regex" "$process_log"; then
            break
        fi
        if grep -q "$failure_regex" "$process_log"; then
            timestamp "'$process_command' failure message detected. Exiting with failure."
            exit 1
        fi
        if ! kill -0 "$pid" 2>/dev/null; then
            timestamp "'$process_command' died. Exiting with failure."
            exit 1
        fi
        sleep 0.1
    done

    # If the process is still running (detached), move it to the background
    timestamp "Successfully started '$process_command' (pid: $pid) -> moving process to the background."
    disown $pid
}

wait_for_message_and_background "containerd.log" "sudo -n containerd" "containerd successfully booted" "failed to start containerd"
wait_for_message_and_background "dockerd.log" "sudo -n dockerd -D --containerd /run/containerd/containerd.sock" "API listen on /var/run/docker.sock" "exit status\|failed to start containerd"

# Ensure Docker can be used without sudo and without CAP_DAC_OVERRIDE
sudo -n chmod 666 /var/run/docker.sock
