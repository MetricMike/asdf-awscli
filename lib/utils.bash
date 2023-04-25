#!/usr/bin/env bash
# shellcheck disable=SC2034

set -euo pipefail

fail() {
	echo -e "asdf-awscli: $*"
	exit 1
}

IFS=" " read -r -a OS_INFO <<<"$(uname --kernel-name --machine)"
OS_NAME="${OS_INFO[0]}"
OS_ARCH="${OS_INFO[1]}"
