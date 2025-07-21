#!/bin/bash
# shellcheck disable=SC2155

readonly url="$SPRINTERS_RUNNER_WEBHOOK"
if [ -z "$url" ]; then
  # Event publishing is disabled
  exit 0
fi

get_env_value_string() {
  local var_name="$1"
  if [[ -n "${!var_name+x}" ]]; then
    echo "\"${!var_name}\""
  else
    echo "null"
  fi
}

get_env_value_number() {
  local var_name="$1"
  if [[ -n "${!var_name+x}" ]]; then
    echo "${!var_name}"
  else
    echo "null"
  fi
}


readonly event="\"event\":\"$1\""
readonly hostname="\"hostname\":\"$(hostname)\""
readonly timestamp="\"timestamp\":\"$(date -u -Ins  | tr ',' '.' | cut -c1-23)Z\""
readonly runner_name="\"runner_name\":$(get_env_value_string RUNNER_NAME)"
readonly repository_id="\"repository_id\":$(get_env_value_number GITHUB_REPOSITORY_ID)"
readonly workflow_run_id="\"workflow_run_id\":$(get_env_value_number GITHUB_RUN_ID)"
readonly workflow_run_attempt="\"workflow_run_attempt\":$(get_env_value_number GITHUB_RUN_ATTEMPT)"

uuid=$(cat /proc/sys/kernel/random/uuid)
payload="{$event,$hostname,$timestamp,$runner_name,$repository_id,$workflow_run_id,$workflow_run_attempt}"
sha256=$(printf "%s" "$payload" | sha256sum | awk '{print $1}')

curl -s -k "$url" --connect-timeout 3 \
  -H "Content-Type: application/json" \
  -H "X-Runner-Delivery: $uuid" \
  -H "X-Runner-Action: event" \
  -H "X-Runner-Sha256: $sha256" \
  -d "$payload" || echo "$event event publishing failed"
