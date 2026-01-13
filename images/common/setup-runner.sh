#!/bin/bash

# Fail-fast
set -euo pipefail

readonly runner_version=%1
if [ "$ARM64" = "true" ]; then
    runner_arch="arm64"
else
    runner_arch="x64"
fi
readonly agent_download_url=https://github.com/actions/runner/releases/download/v$runner_version/actions-runner-linux-$runner_arch-$runner_version.tar.gz

readonly dest=/home/runner
readonly archive=/runner.tar.gz

sudo mkdir -p $dest
sudo wget "$agent_download_url" -O $archive
sudo tar -xvzf $archive -C $dest
sudo rm $archive
