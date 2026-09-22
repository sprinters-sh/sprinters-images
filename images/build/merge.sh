#!/usr/bin/env bash

# Adds the tools that were installed by tool.sh in other stages, which are mounted below /leaves, to the image

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
source "${HELPER_SCRIPTS}/etc-environment.sh"

for leaf in /leaves/*/artifacts; do
  [ -f "$leaf/manifest" ] || continue
  echo "Merging $(basename "$(dirname "$leaf")")"

  while IFS= read -r path; do
    sudo mkdir -p "$(dirname "$path")"
    sudo cp -a "$leaf/root$path" "$(dirname "$path")/"
  done < "$leaf/manifest"

  while IFS='=' read -r name value; do
    set_etc_environment_variable "$name" "$value"
  done < "$leaf/environment"
done
