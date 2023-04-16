#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/aws/aws-cli"
TOOL_NAME="awscli"
TOOL_TEST="aws --version"

fail() {
	echo -e "asdf-awscli: $*"
	exit 1
}

CURL_OPTS=(-fsSL)

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

# TODO: Make this actually use the source distribution
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-source-install.html
download_source() {
	local version filename url
	version="$1"
	filename="$2"

	url="${GH_REPO}/archive/${version}.tar.gz"

	echo "* Downloading awscli release ${version}..."
	curl "${CURL_OPTS[@]}" -o "${filename}" -C - "${url}" || fail "Could not download ${url}"
}

download_release() {
	local version download_path major_version os_distribution os_arch
	version="$1"
	download_path="$2"
	major_version="${version:0:1}"

	if [[ "${major_version}" == "1" ]]; then
		release_url="https://s3.amazonaws.com/aws-cli/awscli-bundle-${version}.zip"
		filename="awscli-bundle.zip"
	elif [[ "${major_version}" == "2" ]]; then
		os_distribution="$(uname -s)"
		os_arch="$(uname -m)"

		if [[ "${os_distribution}" == "Linux" ]]; then
			if [[ "${os_arch}" == "x86_64" || "${os_arch}" == "aarch64" ]]; then
				release_url="https://awscli.amazonaws.com/awscli-exe-linux-${os_arch}-${version}.zip"
				filename="awscliv2.zip"
			else
				fail "asdf-${TOOL_NAME} does not support ${os_arch} on ${os_distribution}"
			fi
		elif [[ "${os_distribution}" == "Darwin" ]]; then
			release_url="https://awscli.amazonaws.com/AWSCLIV2-${version}.pkg"
			filename="AWSCLIV2.pkg"
		elif [[ "${os_distribution}" == "Windows_NT" ]]; then
			release_url="https://awscli.amazonaws.com/AWSCLIV2-${version}.msi"
			filename="AWSCLIV2.msi"
		else
			fail "asdf-${TOOL_NAME} does not support OS distribution ${os_distribution}"
		fi
	else
		fail "asdf-${TOOL_NAME} does not support major version v${version}"
	fi

	release_file="${download_path}/${filename}"
	curl "${CURL_OPTS[@]}" -o "${release_file}" -C - "${release_url}" || fail "Could not download ${release_url}"
	if [[ "${release_file: -3}" == "zip" ]]; then
		unzip "${release_file}" -d "${download_path}"
		rm "${release_file}"
	fi
}

install_release() {
	local version download_path install_path major_version os_distribution os_arch
	version="$1"
	download_path="$2"
	install_path="$3"
	major_version="${version:0:1}"

	(
		if [[ "${major_version}" == "1" ]]; then
			install_v1_bundled_installer "${download_path}" "${install_path}"
		elif [[ "${major_version}" == "2" ]]; then
			os_distribution="$(uname -s)"
			os_arch="$(uname -m)"

			if [[ "${os_distribution}" == "Linux" ]]; then
				if [[ "${os_arch}" == "x86_64" || "${os_arch}" == "aarch64" ]]; then
					install_v2_linux_bundled_installer "${download_path}" "${install_path}"
				else
					fail "asdf-${TOOL_NAME} does not support ${os_arch} on ${os_distribution}"
				fi
			elif [[ "${os_distribution}" == "Darwin" ]]; then
				install_v2_macos_bundled_installer "${download_path}" "${install_path}"
			elif [[ "${os_distribution}" == "Windows_NT" ]]; then
				install_v2_windows_bundled_installer "${download_path}" "${install_path}"
			else
				fail "asdf-${TOOL_NAME} does not support OS distribution ${os_distribution}"
			fi
		else
			fail "asdf-${TOOL_NAME} does not support major version v${major_version}"
		fi

		local tool_cmd
		tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)"
		test -x "${install_path}/${tool_cmd}" || fail "Expected ${install_path}/aws to be executable."
		echo "asdf-${TOOL_NAME} ${version} installation was successful!"
	) || (
		rm -rf "${install_path}"
		fail "An error ocurred while installing awscli ${version}."
	)
}

install_v1_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"
	# requires curl, unzip, and python 3.7+ https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html#cli-chap-install-python
	"${download_path}"/awscli-bundle/install --install-dir "${install_path}" --bin-location "${install_path}/bin"
}

install_v2_linux_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"
	# requires curl, unzip
	# requires glibc, groff, less
	"${download_path}"/aws/install --install-dir "${install_path}" --bin-dir "${install_path}/bin"
}

install_v2_macos_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"

	# requires curl
	cat <<EOF >"${download_path}/choices.xml"
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
	installer -pkg "${download_path}/AWSCLIV2.pkg" -target CurrentUserHomeDirectory -applyChoiceChangesXML "${download_path}/choices.xml"
	mkdir "${install_path}/bin"
	ln -s "${install_path}/aws-cli/aws" "${install_path}/bin/aws"
	ln -s "${install_path}/aws-cli/aws_completer" "${install_path}/bin/aws_completer"
	rm -rf "${download_path}/choices.xml"
}

install_v2_windows_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"

	# requires curl, msiexec
	msiexec.exe /i "${download_path}/AWSCLIV2.msi" "INSTALLDIR=${ASDF_INSTALL_PATH}" MSIINSTALLPERUSER=1
}
