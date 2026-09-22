#!/usr/bin/env bash

# Configures the system and cleans up. Must run after all tools have been installed and merged.

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if [ "$MINIMAL" = "true" ]; then
  # Create Ruby directory as configure-system.sh needs it
  mkdir /opt/hostedtoolcache/Ruby
fi
sed -i 's,sed -i,echo disabled #sed -i,g' "${SCRIPTS}"/configure-system.sh \
    && upstream configure-system.sh

if [ "$ImageOS" = "ubuntu22" ]; then
  cp "${PATH_ROOT}"/../assets/ubuntu2204.conf /tmp/
  sudo mkdir -p /etc/vsts
  sudo cp /tmp/ubuntu2204.conf /etc/vsts/machine_instance.conf
fi

upstream cleanup.sh

# Ensure correct permissions in /home/runner
sudo chown -hR runner:runner /home/runner
