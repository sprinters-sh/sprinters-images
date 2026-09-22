#!/usr/bin/env bash

# Fail-fast
set -euo pipefail
trap 'echo "Error in ${BASH_SOURCE[0]}:${LINENO} -> $BASH_COMMAND"' ERR

readonly IMAGE_FOLDER=/imagegeneration

# Install base packages required by GitHub's Runner Image scripts
apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git curl wget sudo gnupg lsb-release openssl software-properties-common apt-utils snap netcat-traditional bc lshw gawk iptables ssh pigz

# Disable systemctl and journalctl by replacing them with a no-op script. A symlink to /usr/bin/echo
# doesn't work on Ubuntu 26.04+, where echo is a multi-call uutils-coreutils binary that dispatches
# on argv[0] and doesn't recognize being invoked as systemctl/journalctl.
for cmd in systemctl journalctl; do
  rm /usr/bin/$cmd
  printf '#!/bin/sh\nexit 0\n' > /usr/bin/$cmd
  chmod +x /usr/bin/$cmd
done

# Fine-tune environment to match GitHub image
mkdir /etc/cloud/templates && touch /.dockerenv

mkdir ${IMAGE_FOLDER} && chmod 777 ${IMAGE_FOLDER}

# Define user and grant sudo rights
adduser --disabled-password --gecos "" --uid 1001 runner \
    && usermod -aG sudo runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers
