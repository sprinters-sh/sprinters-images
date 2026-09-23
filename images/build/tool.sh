#!/usr/bin/env bash

# Installs a single tool from tools.txt and exports what it added to /artifacts, so that merge.sh can add it to the
# image later. This allows tools to be installed in parallel, in separate build stages.
#
# The export is based on what the installer changed on the file system. To be safe to merge, it must only add files
# below /usr and /opt, and only set environment variables in /etc/environment. Anything else, like installing
# packages, fails the build. Such installers belong in the system stages.

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

readonly tool=$1
read -r _ installer skip < <(grep -E "^${tool}[[:space:]]" "$(dirname "${BASH_SOURCE[0]}")/tools.txt") || true
if [ -z "${installer:-}" ]; then
  echo "Unknown tool: $tool"
  exit 1
fi

# Always present so that it can be mounted from stages of tools that are not installed in this variant
sudo mkdir -p /artifacts

declare -A variant=([minimal]=$MINIMAL [slim]=$SLIM [arm64]=$ARM64)
for condition in $skip; do
  if [ "${variant[$condition]}" = "true" ]; then
    echo "Skipping $tool in $condition images"
    exit 0
  fi
done

readonly work=$(mktemp -d)

# Changes to these are noise, not part of the tool
readonly noise=(/artifacts /build /leaves /tmp /var/tmp /var/cache /var/log /root /home/runner /imagegeneration /etc/environment)

scan() {
  local prune=()
  for path in "${noise[@]}"; do
    prune+=(-path "$path" -o)
  done
  sudo find / -xdev \( "${prune[@]}" -false \) -prune -o \( "$@" \) -print | LC_ALL=C sort
}

scan -type d > "$work/directories.before"
cp /etc/environment "$work/environment.before"
touch "$work/marker"

upstream "$installer"

scan -type d > "$work/directories.after"
# Archives preserve modification times, so use the time of the last status change to find new and moved files
scan ! -type d -cnewer "$work/marker" > "$work/files.changed"
comm -13 "$work/directories.before" "$work/directories.after" > "$work/directories.new"

# The new directories and changed files that sit in directories which already existed. Anything else is part of those.
awk -v added_file="$work/directories.new" \
    'function parent(path) { sub(/\/[^\/]*$/, "", path); return path == "" ? "/" : path }
     BEGIN { while ((getline path < added_file) > 0) added[path] }
     !(parent($0) in added)' \
  "$work/directories.new" "$work/files.changed" > "$work/exports"

unsupported=$(grep -vE '^/(usr|opt)/' "$work/exports" || true)
if [ -n "$unsupported" ]; then
  echo "$tool modified paths that cannot be merged, install it in the system stages instead:"
  echo "$unsupported"
  exit 1
fi

grep -vxFf "$work/environment.before" /etc/environment > "$work/environment.new" || true
if grep -q '^PATH=' "$work/environment.new"; then
  echo "$tool modified PATH, which cannot be merged, install it in the system stages instead"
  exit 1
fi

# Moving the files avoids storing them twice in the layer
while IFS= read -r path; do
  sudo mkdir -p "/artifacts/root$(dirname "$path")"
  sudo mv "$path" "/artifacts/root$path"
done < "$work/exports"
sudo cp "$work/exports" /artifacts/manifest
sudo cp "$work/environment.new" /artifacts/environment

echo "Exported $(wc -l < "$work/exports") paths of $tool:"
sed 's/^/  /' "$work/exports"

# Installers don't always clean up their own scratch downloads (e.g. install-codeql-bundle.sh leaves
# the multi-GB bundle archive in /tmp after extracting it). That's dead weight for this stage's whole
# lifetime, since nothing under /tmp or /var/tmp is ever exported (see $noise above) - safe to wipe.
sudo rm -rf /tmp/* /var/tmp/* 2>/dev/null || true
