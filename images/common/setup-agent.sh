#!/bin/bash

# Fail-fast
set -euo pipefail

readonly agent_version=2112
if [ "$ARM64" = "true" ]; then
    agent_arch="arm64"
else
    agent_arch="x64"
fi
readonly agent_download_url=https://github.com/sprinters-sh/sprinters-agent/releases/download/$agent_version/sprinters-agent-$agent_version-$agent_arch.tar.gz

sudo mkdir -p /sprinters-agent
sudo wget "$agent_download_url" -O /sprinters-agent.tar.gz
sudo tar -xvzf /sprinters-agent.tar.gz -C /sprinters-agent
