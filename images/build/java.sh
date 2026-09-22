#!/usr/bin/env bash

# Java is a prerequisite of several tools that are installed in parallel, so it gets its own stage

source "$(dirname "${BASH_SOURCE[0]}")/env.sh"

if [ "$MINIMAL" != "true" ]; then
  upstream install-java-tools.sh
fi
