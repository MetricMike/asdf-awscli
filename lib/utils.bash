#!/usr/bin/env bash
# shellcheck disable=SC2034

set -euo pipefail

fail() {
	printfn "$*"
	exit 1
}

printfn() {
	printf "asdf-awscli: %s\\n" "$*"
}

OS_INFO="$(uname -sm)"
OS_NAME="${OS_INFO% *}"
OS_ARCH="${OS_INFO#* }"
