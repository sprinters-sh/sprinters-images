#!/usr/bin/env bash

# Installs the rest of the packages that change shared state. See system-1.sh.

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

readonly UBUNTU22=$([ "$ImageOS" = "ubuntu22" ] && echo "true" || echo "false")

if [ "$MINIMAL" != "true" ]; then
  upstream install-kubernetes-tools.sh

  if [ "$UBUNTU22" = "true" ] && [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-oc-cli.sh
    upstream install-leiningen.sh
  fi

  if [ "$UBUNTU22" = "true" ]; then
    upstream install-mono.sh
  fi

  # Skip tests due to lack of systemd
  skip_tests install-mysql.sh
  upstream install-mysql.sh

  if [ "$UBUNTU22" = "true" ] && [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-mssql-tools.sh
    upstream install-sqlpackage.sh
  fi

  upstream install-nginx.sh

  if [ "$UBUNTU22" = "true" ] && [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-nvm.sh
  fi

  upstream install-nodejs.sh

  # Fix permissions in home directory
  sudo chown -R runner:runner /home/runner \
      && "${SCRIPTS}"/install-bazel.sh

  upstream install-php.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    # Skip tests due to lack of systemd
    skip_tests install-postgresql.sh
    upstream install-postgresql.sh
  fi

  upstream install-ruby.sh

  if [ "$UBUNTU22" = "true" ] && [ "$ARM64" != "true" ]; then
    # Not in arm images
    upstream install-rlang.sh
  fi

  upstream install-rust.sh

  upstream install-vcpkg.sh
  upstream configure-dpkg.sh

  upstream install-python.sh
  upstream install-zstd.sh
fi

# Prevent Docker startup and skip tests due to Docker <-> VM differences
sed -i 's,docker info,#docker info,g' "${SCRIPTS}"/install-docker.sh \
    && sed -i 's,docker pull,echo docker pull,g' "${SCRIPTS}"/install-docker.sh \
    && sed -i 's,invoke_tests,echo Skipping tests #invoke_tests,g' "${SCRIPTS}"/install-docker.sh \
    && DOCKERHUB_PULL_IMAGES=no upstream install-docker.sh

# Add runner user to Docker Group
sudo usermod -aG docker runner
