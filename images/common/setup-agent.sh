#!/bin/bash

# Fail-fast
set -euo pipefail

readonly agent_version=2113
if [ "$ARM64" = "true" ]; then
    agent_arch="arm64"
else
    agent_arch="x64"
fi
readonly agent_download_url=https://github.com/sprinters-sh/sprinters-agent/releases/download/$agent_version/sprinters-agent-$agent_version-$agent_arch.tar.gz

readonly dest=/sprinters-agent
readonly archive=/sprinters-agent.tar.gz

sudo mkdir -p $dest
sudo wget "$agent_download_url" -O $archive
sudo tar -xvzf $archive -C $dest
sudo rm $archive
