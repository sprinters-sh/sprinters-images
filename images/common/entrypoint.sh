#!/bin/bash
# shellcheck disable=SC2155

if [[ -z "$JITCONFIG" ]]; then
  echo "Error: Missing JITCONFIG"
  exit 1
fi
readonly jit_config=$JITCONFIG
unset JITCONFIG

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

cleanup_and_exit() {
  timestamp "Shutting down ..."
  /publish-event.sh runner-shutdown
  exit 1
}
trap cleanup_and_exit SIGTERM SIGINT EXIT
set -e

# Load and export environment variables
set -o allexport && source /etc/environment && set +o allexport

readonly privileged=$( [ -b /dev/loop0 ] && echo "true" || echo "false" )
if [ "$privileged" = "true" ]; then
  timestamp "Starting dockerd async ..."
  /start-docker.sh &
else
  timestamp "Unprivileged mode: disabled Docker support"
fi

if [ "$SPRINTERS_AGENT" = "true" ]; then
  timestamp "Starting Sprinters Agent ..."
  # Start within same shell to ensure exported vars are visible
  . /start-agent.sh
fi

timestamp "Launching Runner with JIT config ..."
run_quiet ./run.sh --jitconfig "$jit_config" &
wait $!
