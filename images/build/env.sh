#!/usr/bin/env bash

# Sourced by every build step. Sets up fail-fast and the environment that GitHub's runner-images scripts expect.
set -euo pipefail
trap 'echo "Error in ${BASH_SOURCE[0]}:${LINENO} -> $BASH_COMMAND"' ERR

# Provided by the ENV instructions in the Dockerfile
readonly RUNNER_IMAGE_VERSION=${RUNNER_IMAGE_VERSION:?}
readonly MINIMAL=${MINIMAL:?}
readonly SLIM=${SLIM:?}
readonly ARM64=$([ "$(uname -m)" = "aarch64" ] && echo "true" || echo "false")

readonly UBUNTU_VERSION=$(. /etc/os-release && echo "$VERSION_ID")
readonly ImageOS=ubuntu${UBUNTU_VERSION%%.*}
readonly ARCH_SUFFIX=$([ "$ARM64" = "true" ] && echo "-arm64" || echo "")
readonly IMAGE_TAG=${ImageOS}${ARCH_SUFFIX}
readonly TOOLSET=toolset-${UBUNTU_VERSION//./}${ARCH_SUFFIX}.json
readonly PATH_ROOT=/tmp/runner-images-${IMAGE_TAG}-${RUNNER_IMAGE_VERSION}/images/ubuntu/templates
readonly SCRIPTS=${PATH_ROOT}/../scripts/build

export IMAGE_VERSION=${RUNNER_IMAGE_VERSION}
export IMAGE_OS=$ImageOS
export DEBIAN_FRONTEND=noninteractive
export SUDO_USER=runner
export IMAGE_FOLDER=/imagegeneration
export IMAGEDATA_FILE=/imagegeneration/imagedata.json
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/installers
export HELPER_SCRIPT_FOLDER=/imagegeneration/helpers
export HELPER_SCRIPTS=${HELPER_SCRIPT_FOLDER}

# Runs a script from GitHub's runner-images repository as root
upstream() {
  local script=$1
  shift
  sudo -E "${SCRIPTS}/${script}" "$@"
}

# Comments out the invoke_tests calls of an upstream script
skip_tests() {
  sed -i 's,invoke_tests,#invoke_tests,g' "${SCRIPTS}/$1"
}
