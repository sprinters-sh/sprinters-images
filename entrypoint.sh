#!/bin/bash

# Function to start a process and wait for a specific message
# Arguments:
# 1. Command to run the process
# 2. Specific message to wait for
wait_for_message_and_background() {
    local process_command="$1"
    local success_message="$2"
    local failure_message="$3"
    local log=background_output.log

    echo "Starting '$process_command' ..."

    # Precreate log file and ensure it exists with readable permissions
    touch $log

    # Start the process in the background
    $process_command > >(tee $log) 2>&1 &

    # Capture the PID of the process
    local pid=$!

    # Use tail -f to monitor the output and look for the specific message
    tail -f $log | while read -r line; do
        # Check for the specific message
        if echo "$line" | grep -q "$success_message"; then
            echo "Success message detected: '$success_message'."
            break
        fi

        # Check for the failure message
        if echo "$line" | grep -q "$failure_message"; then
            echo "Failure message detected: '$failure_message'. Exiting with failure."
            exit 1
        fi
    done || exit 1

    # If the process is still running (detached), move it to the background
    echo "Successfully started '$process_command'. Moving process to the background."
    disown $pid
}

wait_for_message_and_background "sudo dockerd" "API listen on /var/run/docker.sock" "exit status"
./config.sh --url https://github.com/$REPO \
            --token $TOKEN \
            --labels $LABELS \
            --ephemeral --disableupdate --unattended \
  && ./run.sh
