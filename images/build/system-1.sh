#!/usr/bin/env bash

# Installs the packages that change shared state, such as packages, users, services and profiles, up to Java. They must
# be installed one after another, in the order of GitHub's runner images: Java's packages resolve their dependencies
# differently depending on what is installed already (for example libasound2 versus liboss4-salsa-asound2).
# Self-contained tools are installed in parallel by tool.sh instead, unless their position matters:
# - install-nodejs.sh makes /usr/local/bin world-writable, which includes the binaries installed before it
# - the packages installed after cmake put their icons and other files below /usr/local/share

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

readonly UBUNTU22=$([ "$ImageOS" = "ubuntu22" ] && echo "true" || echo "false")

if [ "$MINIMAL" != "true" ]; then
  upstream install-azcopy.sh
  upstream install-azure-cli.sh
  upstream install-azure-devops-cli.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-bicep.sh
  fi

  if [ "$UBUNTU22" = "true" ]; then
    upstream install-aliyun-cli.sh
  fi

  upstream install-apache.sh
  upstream install-aws-tools.sh
  upstream install-clang.sh
  upstream install-cmake.sh

  # Skip tests due to Docker <-> VM differences
  skip_tests install-container-tools.sh
  upstream install-container-tools.sh

  # Make list of extracted sdk archives more specific to prevent accidentally picking up tar.gz files from other tools
  sed -i 's,*.tar.gz,dotnet-*.tar.gz,g' "${SCRIPTS}"/install-dotnetcore-sdk.sh \
      && sudo mkdir -p /usr/share/dotnet/shared \
      && upstream install-dotnetcore-sdk.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-microsoft-edge.sh
  fi

  upstream install-gcc-compilers.sh

  # Skip tests due to Docker <-> VM differences
  skip_tests install-firefox.sh
  upstream install-firefox.sh

  upstream install-gfortran.sh
fi

upstream install-git.sh
upstream install-git-lfs.sh
upstream install-github-cli.sh

if [ "$MINIMAL" != "true" ]; then
  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-google-chrome.sh
  fi

  upstream install-google-cloud-cli.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    if [ "$SLIM" != "true" ]; then
      upstream install-haskell.sh
    fi
    if [ "$UBUNTU22" = "true" ]; then
      upstream install-heroku.sh
    fi
  fi
fi
