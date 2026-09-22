#!/usr/bin/env bash

# Downloads GitHub's runner-images scripts and installs what every other step builds on

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

curl -f -L -o runner-image.tar.gz "https://github.com/actions/runner-images/archive/refs/tags/${IMAGE_TAG}/${RUNNER_IMAGE_VERSION}.tar.gz"
tar xzf ./runner-image.tar.gz
rm runner-image.tar.gz

chmod +x "${SCRIPTS}"/*.sh

cp -r "${SCRIPTS}"/../helpers ${HELPER_SCRIPT_FOLDER}

upstream configure-apt-mock.sh

if [ "$MINIMAL" != "true" ]; then
  upstream install-ms-repos.sh
  upstream configure-apt-sources.sh
fi

upstream configure-apt.sh
upstream configure-limits.sh

cp -r "${SCRIPTS}" ${INSTALLER_SCRIPT_FOLDER}
cp -r "${PATH_ROOT}"/../assets/post-gen ${IMAGE_FOLDER}
cp -r "${SCRIPTS}"/../tests ${IMAGE_FOLDER}

if [ "$MINIMAL" != "true" ]; then
  cp -r "${SCRIPTS}"/../docs-gen ${IMAGE_FOLDER}
  cp -r "${PATH_ROOT}"/../../../helpers/software-report-base ${IMAGE_FOLDER}/docs-gen/
fi

if [ "$SLIM" = "true" ]; then
  # Remove Android and CodeQL from toolset as they aren't included in the slim images
  jq -M -C 'del(.android) | .toolcache = (.toolcache | map(select(.name != "CodeQL")))' "${PATH_ROOT}/../toolsets/${TOOLSET}" > ${INSTALLER_SCRIPT_FOLDER}/toolset.json
else
  cp "${PATH_ROOT}/../toolsets/${TOOLSET}" ${INSTALLER_SCRIPT_FOLDER}/toolset.json
fi

if [ "$MINIMAL" != "true" ]; then
  mv ${IMAGE_FOLDER}/docs-gen ${IMAGE_FOLDER}/SoftwareReport
fi

mv ${IMAGE_FOLDER}/post-gen ${IMAGE_FOLDER}/post-generation

upstream configure-image-data.sh

# Adjust environment for Docker <-> VM differences
# 1. Create a dummy Azure Linux VM Agent config file
# 2. Create a dummy MOTD config file
# 3. Avoid modifying the real /etc/hosts as Docker prohibits this
# 4. No need to disable man-db as it is not installed
sudo touch /etc/waagent.conf \
    && sudo touch /etc/default/motd-news \
    && sed -i 's,/etc/hosts,/etc/hosts0,g' "${SCRIPTS}"/configure-environment.sh \
    && sudo touch /etc/hosts0 \
    && sed -i 's,echo "set man-db/auto-update false",#echo "set man-db/auto-update false",g' "${SCRIPTS}"/configure-environment.sh \
    && sed -i 's,dpkg-reconfigure man-db,#dpkg-reconfigure man-db,g' "${SCRIPTS}"/configure-environment.sh \
    && upstream configure-environment.sh

upstream install-apt-vital.sh

if [ "$MINIMAL" = "true" ]; then
  # Disable tests as they require powershell
  sed -i 's,invoke_tests,echo Disabled tests #invoke_tests,g' "${SCRIPTS}"/*.sh
else
  upstream install-powershell.sh
  sudo -E pwsh -f "${SCRIPTS}/Install-PowerShellModules.ps1"
  sudo -E pwsh -f "${SCRIPTS}/Install-PowerShellAzModules.ps1"
  upstream install-actions-cache.sh
  upstream install-apt-common.sh
fi
