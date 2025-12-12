#!/usr/bin/env bash

# Fail-fast
set -euo pipefail

readonly RUNNER_IMAGE_VERSION=$1
readonly ARM64=$2
readonly MINIMAL=$3
readonly SLIM=$4

readonly ImageOS=ubuntu22
readonly PATH_ROOT=runner-images-$ImageOS-${RUNNER_IMAGE_VERSION}/images/ubuntu/templates

export IMAGE_VERSION=${RUNNER_IMAGE_VERSION}
export IMAGE_OS=$ImageOS
export DEBIAN_FRONTEND=noninteractive
export SUDO_USER=runner
export IMAGE_FOLDER=/imagegeneration
export IMAGEDATA_FILE=/imagegeneration/imagedata.json
export INSTALLER_SCRIPT_FOLDER=/imagegeneration/installers
export HELPER_SCRIPT_FOLDER=/imagegeneration/helpers
export HELPER_SCRIPTS=${HELPER_SCRIPT_FOLDER}

curl -f -L -o runner-image.tar.gz https://github.com/actions/runner-images/archive/refs/tags/$ImageOS/"${RUNNER_IMAGE_VERSION}".tar.gz \
    && tar xzf ./runner-image.tar.gz \
    && rm runner-image.tar.gz

if [ "$ARM64" = "true" ]; then
  # Patch arch references: amd64|x86_64|x64 -> arm64
  grep -rl --include="*.ps1" --include="*.sh" --include="*.json" 'amd64' . | xargs sed -i 's/amd64/arm64/g'
  grep -rl --include="*.json" 'x86_64' . | xargs sed -i 's/x86_64/aarch64/g'
  grep -rl --include="*.ps1" --include="*.sh" 'x86_64' . | xargs sed -i 's/x86_64/arm64/g'
  grep -rl --include="*.ps1" --include="*.sh" --include="*.json" 'x64' . | xargs sed -i 's/x64/arm64/g'

  # Skip tests due to lack of powershell on Linux arm64
  grep -rl --include="*.sh" 'invoke_tests ' . | xargs sed -i 's,invoke_tests ,echo Skipping tests #invoke_tests ,g'
fi

chmod +x "${PATH_ROOT}"/../scripts/build/*.sh

cp -r "${PATH_ROOT}"/../scripts/helpers ${HELPER_SCRIPT_FOLDER}

sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-apt-mock.sh

if [ "$MINIMAL" != "true" ]; then
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-ms-repos.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-apt-sources.sh
fi

sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-apt.sh
sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-limits.sh

cp -r "${PATH_ROOT}"/../scripts/build ${INSTALLER_SCRIPT_FOLDER}
cp -r "${PATH_ROOT}"/../assets/post-gen ${IMAGE_FOLDER}
cp -r "${PATH_ROOT}"/../scripts/tests ${IMAGE_FOLDER}

if [ "$MINIMAL" != "true" ]; then
  cp -r "${PATH_ROOT}"/../scripts/docs-gen ${IMAGE_FOLDER}
  cp -r "${PATH_ROOT}"/../../../helpers/software-report-base ${IMAGE_FOLDER}/docs-gen/
fi

if [ "$SLIM" = "true" ]; then
  # Remove Android and CodeQL from toolset as they aren't included in the slim images
  jq -M -C 'del(.android) | .toolcache = (.toolcache | map(select(.name != "CodeQL")))' "${PATH_ROOT}"/../toolsets/toolset-2204.json > ${INSTALLER_SCRIPT_FOLDER}/toolset.json
else
  cp "${PATH_ROOT}"/../toolsets/toolset-2204.json ${INSTALLER_SCRIPT_FOLDER}/toolset.json
fi

if [ "$MINIMAL" != "true" ]; then
  mv ${IMAGE_FOLDER}/docs-gen ${IMAGE_FOLDER}/SoftwareReport
fi

mv ${IMAGE_FOLDER}/post-gen ${IMAGE_FOLDER}/post-generation

sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-image-data.sh

# Adjust environment for Docker <-> VM differences
# 1. Create a dummy Azure Linux VM Agent config file
# 2. Create a dummy MOTD config file
# 3. Avoid modifying the real /etc/hosts as Docker prohibits this
# 4. No need to disable man-db as it is not installed
sudo touch /etc/waagent.conf \
    && sudo touch /etc/default/motd-news \
    && sed -i 's,/etc/hosts,/etc/hosts0,g' "${PATH_ROOT}"/../scripts/build/configure-environment.sh \
    && sudo touch /etc/hosts0 \
    && sed -i 's,echo "set man-db/auto-update false",#echo "set man-db/auto-update false",g' "${PATH_ROOT}"/../scripts/build/configure-environment.sh \
    && sed -i 's,dpkg-reconfigure man-db,#dpkg-reconfigure man-db,g' "${PATH_ROOT}"/../scripts/build/configure-environment.sh \
    && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-environment.sh

sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-apt-vital.sh

if [ "$MINIMAL" = "true" ]; then
  # Disable tests as they require powershell
  sed -i 's,invoke_tests,echo Disabled tests #invoke_tests,g' "${PATH_ROOT}"/../scripts/build/*.sh
else
  if [ "$ARM64" = "true" ]; then
    # https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-on-arm
    echo "Disabled powershell as it isn't officially supported by Microsoft on Linux arm64"
  else
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-powershell.sh
    sudo -E sh -c "pwsh -f ${PATH_ROOT}/../scripts/build/Install-PowerShellModules.ps1"
    sudo -E sh -c "pwsh -f ${PATH_ROOT}/../scripts/build/Install-PowerShellAzModules.ps1"
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-actions-cache.sh
fi

if [ "$MINIMAL" != "true" ]; then
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-apt-common.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-azcopy.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-azure-cli.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-azure-devops-cli.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-bicep.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-aliyun-cli.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-apache.sh

  if [ "$ARM64" = "true" ]; then
    # Fix arm64 arch name
    sed -i 's,awscli-exe-linux-arm64,awscli-exe-linux-aarch64,g' "${PATH_ROOT}"/../scripts/build/install-aws-tools.sh
  fi
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-aws-tools.sh

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-clang.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-swift.sh

  if [ "$ARM64" = "true" ]; then
    # Fix arm64 arch name
    sed -i 's,arm64,aarch64,g' "${PATH_ROOT}"/../scripts/build/install-cmake.sh
  fi
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-cmake.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    if [ "$SLIM" != "true" ]; then
        sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-codeql-bundle.sh
    fi
  fi

  # Skip tests due to Docker <-> VM differences
  sed -i 's,invoke_tests,#invoke_tests,g' "${PATH_ROOT}"/../scripts/build/install-container-tools.sh
  if [ "$ARM64" = "true" ]; then
    # Disable container networking plugins as there is no arm64 package
    sed -i 's,if is_ubuntu22; then,if is_ubuntu99; then,g' "${PATH_ROOT}"/../scripts/build/install-container-tools.sh
  fi
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-container-tools.sh

  # Make list of extracted sdk archives more specific to prevent accidentally picking up tar.gz files from other tools
  sed -i 's,*.tar.gz,dotnet-*.tar.gz,g' "${PATH_ROOT}"/../scripts/build/install-dotnetcore-sdk.sh \
      && sudo mkdir -p /usr/share/dotnet/shared \
      && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-dotnetcore-sdk.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-microsoft-edge.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-gcc-compilers.sh

  if [ "$ARM64" = "true" ]; then
    # Fix arm64 arch name
    sed -i 's,linuarm64,linux-aarch64,g' "${PATH_ROOT}"/../scripts/build/install-firefox.sh
  fi
  # Skip tests due to Docker <-> VM differences
  sed -i 's,invoke_tests,#invoke_tests,g' "${PATH_ROOT}"/../scripts/build/install-firefox.sh \
      && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-firefox.sh

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-gfortran.sh
fi

sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-git.sh
sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-git-lfs.sh
sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-github-cli.sh

if [ "$MINIMAL" != "true" ]; then
  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-google-chrome.sh
    if [ "$SLIM" != "true" ]; then
      sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-haskell.sh
    fi
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-heroku.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-java-tools.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-kubernetes-tools.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-oc-cli.sh
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-leiningen.sh
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-miniconda.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-mono.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-kotlin.sh

  # Skip tests due to lack of systemd
  sed -i 's,invoke_tests,#invoke_tests,g' "${PATH_ROOT}"/../scripts/build/install-mysql.sh \
      && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-mysql.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-mssql-tools.sh
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-sqlpackage.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-nginx.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-nvm.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-nodejs.sh

  # Fix permissions in home directory
  sudo chown -R runner:runner /home/runner \
      && "${PATH_ROOT}"/../scripts/build/install-bazel.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-oras-cli.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-php.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    # Skip tests due to lack of systemd
    sed -i 's,invoke_tests,#invoke_tests,g' "${PATH_ROOT}"/../scripts/build/install-postgresql.sh \
        && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-postgresql.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-pulumi.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-ruby.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-rlang.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-rust.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    if [ "$SLIM" != "true" ]; then
      sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-julia.sh
    fi
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-sbt.sh
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-selenium.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-terraform.sh

  # Prevent LICENSE.txt collision when unzipping
  sed -i 's,unzip,unzip -n ,g' "${PATH_ROOT}"/../scripts/build/install-packer.sh \
      && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-packer.sh

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-vcpkg.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-dpkg.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-yq.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    if [ "$SLIM" != "true" ]; then
      sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-android-sdk.sh
    fi
  fi

  if [ "$ARM64" = "true" ]; then
    # Fix arm64 arch name
    sed -i 's,arm64,aarch64,g' "${PATH_ROOT}"/../scripts/build/install-pypy.sh
  fi
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-pypy.sh

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-python.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-zstd.sh
  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-ninja.sh
fi

# Prevent Docker startup and skip tests due to Docker <-> VM differences
sed -i 's,docker info,#docker info,g' "${PATH_ROOT}"/../scripts/build/install-docker.sh \
    && sed -i 's,invoke_tests,echo Skipping tests #invoke_tests,g' "${PATH_ROOT}"/../scripts/build/install-docker.sh \
    && DOCKERHUB_PULL_IMAGES=no sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-docker.sh

# Add runner user to Docker Group
sudo -E sh -c "usermod -aG docker runner"

if [ "$MINIMAL" != "true" ]; then
  if [ "$ARM64" != "true" ]; then
    # Disabled powershell as it isn't officially supported by Microsoft on Linux arm64
    # https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-on-arm
    sudo -E sh -c "pwsh -f ${PATH_ROOT}/../scripts/build/Install-Toolset.ps1"
    sudo -E sh -c "pwsh -f ${PATH_ROOT}/../scripts/build/Configure-Toolset.ps1"
  fi

  sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-pipx-packages.sh

  if [ "$ARM64" != "true" ]; then
    # Not in arm images
    sudo -E sh -c "${PATH_ROOT}"/../scripts/build/install-homebrew.sh
  fi

  ## Skip tests due to lack of systemd
  sed -i 's,snap set,#snap set,g' "${PATH_ROOT}"/../scripts/build/configure-snap.sh \
      && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-snap.sh

  # Skip due to Docker <-> VM differences
  # echo 'Reboot VM
  # sudo reboot

  # Skip due to Docker <-> VM differences
  # pwsh -File ${IMAGE_FOLDER}/SoftwareReport/Generate-SoftwareReport.ps1 -OutputDirectory ${IMAGE_FOLDER}
  # pwsh -File ${IMAGE_FOLDER}/tests/RunAll-Tests.ps1 -OutputDirectory ${IMAGE_FOLDER}
fi

sed -i 's,sed -i,echo disabled #sed -i,g' "${PATH_ROOT}"/../scripts/build/configure-system.sh \
    && sudo -E sh -c "${PATH_ROOT}"/../scripts/build/configure-system.sh

cp "${PATH_ROOT}"/../assets/ubuntu2204.conf /tmp/

sudo -E sh -c "mkdir -p /etc/vsts"
sudo -E sh -c "cp /tmp/ubuntu2204.conf /etc/vsts/machine_instance.conf"

# Extract runner to get it ready to use
sudo -E tar xzf /opt/runner-cache/actions-runner-linux-*.tar.gz -C /home/runner \
    && sudo -E sh -c "rm -Rf /opt/runner-cache"

sudo -E sh -c "${PATH_ROOT}"/../scripts/build/cleanup.sh

sudo -E sh -c "rm -Rf ${PATH_ROOT}"
sudo -E sh -c "rm -Rf /tmp/*"
