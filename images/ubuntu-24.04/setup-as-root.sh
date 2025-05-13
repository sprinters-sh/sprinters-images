#!/usr/bin/env bash

# Fail-fast
set -euo pipefail

readonly IMAGE_FOLDER=/imagegeneration

# Install base packages required by GitHub's Runner Image scripts
apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git curl wget sudo gnupg lsb-release openssl software-properties-common apt-utils snap netcat-traditional bc lshw gawk ssh

# Disable systemctl and journalctl by aliasing them to a dummy echo
rm /usr/bin/systemctl \
    && ln -s /usr/bin/echo /usr/bin/systemctl \
    && rm /usr/bin/journalctl \
    && ln -s /usr/bin/echo /usr/bin/journalctl

# Fine-tune environment to match GitHub image
mkdir /etc/cloud/templates && touch /.dockerenv

mkdir ${IMAGE_FOLDER} && chmod 777 ${IMAGE_FOLDER}

# Define user and grant sudo rights
adduser --disabled-password --gecos "" --uid 1001 runner \
    && usermod -aG sudo runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers
