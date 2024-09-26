#!/bin/bash

# Function to start a process and wait for a specific message
# Arguments:
# 1. Command to run the process
# 2. Specific message to wait for
wait_for_message_and_background() {
    local process_log="$1"
    local process_command="$2"
    local success_message="$3"
    local failure_expr="$4"

    echo "Starting '$process_command' ..."

    # Precreate log file and ensure it exists with readable permissions
    touch "$process_log"

    # Start the process in the background
    $process_command > >(tee "$process_log") 2>&1 &

    # Capture the PID of the process
    local pid=$!

    # Use tail -f to monitor the output and look for the specific message
    tail -s 0.1 -f "$process_log" | while read -r line; do
        # Check for the specific message
        if echo "$line" | grep -q "$success_message"; then
            break
        fi

        # Check for the failure message
        if echo "$line" | grep -q "$failure_expr"; then
            echo "Failure message detected. Exiting with failure."
            exit 1
        fi
    done || exit 1

    # If the process is still running (detached), move it to the background
    echo "Successfully started '$process_command' (pid: $pid) -> moving process to the background."
    disown $pid
}

wait_for_message_and_background "containerd.log" "sudo containerd" "containerd successfully booted" "failed to start containerd"
wait_for_message_and_background "dockerd.log" "sudo dockerd -D --containerd /run/containerd/containerd.sock" "API listen on /var/run/docker.sock" "exit status\|failed to start containerd"

echo "Configuring Runner ..."
./config.sh --url https://github.com/$REPO \
            --token $TOKEN \
            --labels $LABELS \
            --ephemeral --disableupdate --unattended || exit 1

echo "Launching Runner ..."
./run.sh
