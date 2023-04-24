#!/usr/bin/env bash

set -euo pipefail

fail() {
	echo -e "asdf-awscli: $*"
	exit 1
}
