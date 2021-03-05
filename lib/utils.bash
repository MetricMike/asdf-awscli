#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/aws/aws-cli"

fail() {
  echo -e "asdf-awscli: $*"
  exit 1
}

CURL_OPTS=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  CURL_OPTS=("${CURL_OPTS[@]}" -H "Authorization: token ${GITHUB_API_TOKEN}")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "${GH_REPO}" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//'
}

list_all_versions() {
  list_github_tags
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  url="${GH_REPO}/archive/${version}.tar.gz"

  echo "* Downloading awscli release ${version}..."
  curl "${CURL_OPTS[@]}" -o "${filename}" -C - "${url}" || fail "Could not download ${url}"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local major_version="${version:0:1}"
  local install_path="$3"
  local os_distribution="$(uname -s)"

  if [ "${install_type}" != "version" ]; then
    fail "asdf-awscli supports release installs only"
  fi

  if [[ "${os_distribution}" == "Darwin" && "${major_version}" == "2" ]]; then
    (
      local release_file="${install_path}/awscli-${version}.pkg"
      local url="https://awscli.amazonaws.com/AWSCLIV2-${version}.pkg"

      mkdir -p "${install_path}"
      curl "${CURL_OPTS[@]}" -o "${release_file}" -C - "${url}" || fail "Could not download ${url}"
      xar -xf "${release_file}" -C "${install_path}" || fail "Could not extract ${release_file}"
      pushd "${install_path}"
        gunzip -dc aws-cli.pkg/Payload | cpio -i
      popd

      rm "${release_file}"

      local tool_cmd
      tool_cmd="$(echo "aws --help" | cut -d' ' -f1)"
      test -x "${install_path}/bin/${tool_cmd}" || fail "Expected ${install_path}/bin/${tool_cmd} to be executable."

      echo "awscli ${version} installation was successful!"
    ) || (
      rm -rf "${install_path}"
      fail "An error ocurred while installing awscli ${version}."
    )
  else
    local release_file="${install_path}/awscli-${version}.tar.gz"
    (
      mkdir -p "${install_path}"
      download_release "${version}" "${release_file}"
      tar -xzf "${release_file}" -C "${install_path}" --strip-components=1 || fail "Could not extract ${release_file}"

      #extract to install_version and rename this block download_version?
      pushd "${install_path}"
      python -m venv ./venv
      source ./venv/bin/activate
      pip install -U pip setuptools wheel
      pip install -r requirements.txt
      pip install -e .
      deactivate
      popd

      rm "${release_file}"

      local tool_cmd
      tool_cmd="$(echo "aws --help" | cut -d' ' -f1)"
      test -x "${install_path}/bin/${tool_cmd}" || fail "Expected ${install_path}/bin/${tool_cmd} to be executable."

      echo "awscli ${version} installation was successful!"
    ) || (
      rm -rf "${install_path}"
      fail "An error ocurred while installing awscli ${version}."
    )
  fi
}
