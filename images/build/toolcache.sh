#!/usr/bin/env bash

# Installs the tools that rely on the ones that were installed before

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if [ "$MINIMAL" != "true" ]; then
  sudo -E pwsh -f "${SCRIPTS}/Install-Toolset.ps1"
  if [ "$ARM64" != "true" ]; then
    sudo -E pwsh -f "${SCRIPTS}/Configure-Toolset.ps1"
  fi
  upstream install-pipx-packages.sh
  upstream install-homebrew.sh

  ## Skip tests due to lack of systemd
  sed -i 's,snap set,#snap set,g' "${SCRIPTS}"/configure-snap.sh \
      && upstream configure-snap.sh

  # Skip due to Docker <-> VM differences
  # echo 'Reboot VM
  # sudo reboot

  # Skip due to Docker <-> VM differences
  # pwsh -File ${IMAGE_FOLDER}/SoftwareReport/Generate-SoftwareReport.ps1 -OutputDirectory ${IMAGE_FOLDER}
  # pwsh -File ${IMAGE_FOLDER}/tests/RunAll-Tests.ps1 -OutputDirectory ${IMAGE_FOLDER}
fi
