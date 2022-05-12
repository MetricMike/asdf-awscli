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
  local os_arch="$(uname -m)"
  local tool_cmd="$(echo "aws --help" | cut -d' ' -f1)"
  local test_path="${install_path}/bin/${tool_cmd}"

  if [ "${install_type}" != "version" ]; then
    fail "asdf-awscli supports release installs only"
  fi

  if [[ "$os_arch" != "x86_64" && "$os_arch" != "aarch64" && "$os_arch" != "arm64" ]]; then
    fail "asdf-awscli only supports x86_64, arm64, and aarch64 system architectures"
  fi

  mkdir -p "${install_path}"

  if [[ "${os_distribution}" == "Darwin" && "${major_version}" == "2" ]]; then
    (
      local release_file="${install_path}/awscli-${version}.pkg"
      local url="https://awscli.amazonaws.com/AWSCLIV2-${version}.pkg"

      curl "${CURL_OPTS[@]}" -o "${release_file}" -C - "${url}" || fail "Could not download ${url}"
      if [[ "${os_arch}" == "arm64" ]]; then
          read -rd '' choices << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <array>
    <dict>
      <key>choiceAttribute</key>
      <string>customLocation</string>
      <key>attributeSetting</key>
      <string>${install_path}</string>
      <key>choiceIdentifier</key>
      <string>default</string>
    </dict>
  </array>
</plist>
EOF
          echo "$choices" > ${install_path}/choices.xml
          installer -pkg $release_file -target CurrentUserHomeDirectory -applyChoiceChangesXML ${install_path}/choices.xml || fail "Could not extract ${release_file}"
      else
          pkgutil --expand-full "${release_file}" ./AWSCLIV2 || fail "Could not extract ${release_file}"
          mv ./AWSCLIV2/aws-cli.pkg/Payload/aws-cli "${install_path}"
      fi
      mkdir "${install_path}/bin"
      ln -s "${install_path}/aws-cli/aws" "${install_path}/bin/aws"
      ln -s "${install_path}/aws-cli/aws_completer" "${install_path}/bin/aws_completer"
      rm -rf "${release_file}" ./AWSCLIV2 "${install_path}"/choices.xml

      test -x "${test_path}" || fail "Expected ${test_path} to be executable."
    ) || (
      rm -rf "${install_path}"
      fail "An error ocurred while installing awscli ${version}."
    )
  elif [[ "${os_distribution}" == "Linux" && "${major_version}" == "2" ]]; then
    (
      local release_file="${install_path}/awscli-${version}.zip"
      local url="https://awscli.amazonaws.com/awscli-exe-linux-${os_arch}-${version}.zip"

      curl "${CURL_OPTS[@]}" -o "${release_file}" -C - "${url}" || fail "Could not download ${url}"

      unzip -q ${release_file} -d ./AWSCLIV2 || fail "Could not extract ${release_file}"
      mkdir "${install_path}/bin"
      ./AWSCLIV2/aws/install -i "${install_path}" -b "${install_path}/bin"
      rm -rf "${release_file}" ./AWSCLIV2

      test -x "${test_path}" || fail "Expected ${test_path} to be executable."
    ) || (
      rm -rf "${install_path}"
      fail "An error ocurred while installing awscli ${version}."
    )
  else
    local release_file="${install_path}/awscli-${version}.tar.gz"
    (
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

      test -x "${test_path}" || fail "Expected ${test_path} to be executable."
    ) || (
      rm -rf "${install_path}"
      fail "An error ocurred while installing awscli ${version}."
    )
  fi

  echo "awscli ${version} installation was successful!"
}
