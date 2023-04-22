#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/aws/aws-cli"
TOOL_NAME="awscli"
TOOL_TEST="aws --version"
CURL_OPTS=(-fsSL)

fail() {
	echo -e "asdf-awscli: $*"
	exit 1
}

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

download_source() {
	local version download_path major_version os_distribution
	version="$1"
	download_path="$2"
	major_version="${version:0:1}"

	if [[ "${major_version}" = "2" ]]; then
		source_url="https://awscli.amazonaws.com/awscli-${version}.tar.gz"
		filename="awscli.tar.gz"
		source_file="${download_path}/${filename}"
		curl "${CURL_OPTS[@]}" -o "${source_file}" -C - "${source_url}" || fail "Could not download ${source_url}"
		tar -xzf "${source_file}" -C "${download_path}" --strip-components=1 || fail "Could not extract ${source_file}"
		rm "${source_file}"
	else
		fail "asdf-${TOOL_NAME} does not support downloading from source for major version v${major_version}"
	fi
}

install_source() {
	local version download_path install_path major_version os_distribution make_concurrency tool_cmd
	version="$1"
	download_path="$2"
	install_path="$3"
	make_concurrency="$4"
	major_version="${version:0:1}"
	tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)"

	(
		if [[ "${major_version}" = "2" ]]; then
			os_distribution="$(uname -s)"

			if [[ "${os_distribution}" = "Linux" || "${os_distribution}" = "Darwin" ]]; then
				pushd "${download_path}"
				./configure --prefix="${install_path}" --with-download-deps --with-install-type=portable-exe
				make --jobs "${make_concurrency}"
				make install
				popd
			else
				fail "asdf-${TOOL_NAME} does not support installing from source for OS distribution ${os_distribution}"
			fi
		else
			fail "asdf-${TOOL_NAME} does not support installing from source for major version v${major_version}"
		fi

		test -x "${install_path}/bin/${tool_cmd}" || fail "Expected ${install_path}/bin/${tool_cmd} to be executable."
		echo "asdf-${TOOL_NAME} ${version} installation was successful!"
	) || (
		rm -rf "${install_path}"
		fail "An error ocurred while installing awscli ${version}."
	)
}

download_release() {
	local version download_path major_version os_distribution os_arch
	version="$1"
	download_path="$2"
	major_version="${version:0:1}"

	if [[ "${major_version}" = "1" ]]; then
		release_url="https://s3.amazonaws.com/aws-cli/awscli-bundle-${version}.zip"
		filename="awscli-bundle.zip"
	elif [[ "${major_version}" = "2" ]]; then
		os_distribution="$(uname -s)"
		os_arch="$(uname -m)"

		if [[ "${os_distribution}" = "Linux" ]]; then
			if [[ "${os_arch}" = "x86_64" || "${os_arch}" = "aarch64" ]]; then
				release_url="https://awscli.amazonaws.com/awscli-exe-linux-${os_arch}-${version}.zip"
				filename="awscliv2.zip"
			else
				fail "asdf-${TOOL_NAME} does not support ${os_arch} on ${os_distribution}"
			fi
		elif [[ "${os_distribution}" = "Darwin" ]]; then
			release_url="https://awscli.amazonaws.com/AWSCLIV2-${version}.pkg"
			filename="AWSCLIV2.pkg"
		# elif [[ "${os_distribution}" = "Windows_NT" ]]; then
		# 	release_url="https://awscli.amazonaws.com/AWSCLIV2-${version}.msi"
		# 	filename="AWSCLIV2.msi"
		else
			fail "asdf-${TOOL_NAME} does not support OS distribution ${os_distribution}"
		fi
	else
		fail "asdf-${TOOL_NAME} does not support major version v${version}"
	fi

	release_file="${download_path}/${filename}"
	curl "${CURL_OPTS[@]}" -o "${release_file}" -C - "${release_url}" || fail "Could not download ${release_url}"
	if [[ "${release_file: -3}" = "zip" ]]; then
		unzip -oq "${release_file}" -d "${download_path}"
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
		if [[ "${major_version}" = "1" ]]; then
			install_v1_bundled_installer "${download_path}" "${install_path}"
		elif [[ "${major_version}" = "2" ]]; then
			os_distribution="$(uname -s)"
			os_arch="$(uname -m)"

			if [[ "${os_distribution}" = "Linux" ]]; then
				if [[ "${os_arch}" = "x86_64" || "${os_arch}" = "aarch64" ]]; then
					install_v2_linux_bundled_installer "${download_path}" "${install_path}"
				else
					fail "asdf-${TOOL_NAME} does not support ${os_arch} on ${os_distribution}"
				fi
			elif [[ "${os_distribution}" = "Darwin" ]]; then
				install_v2_macos_bundled_installer "${download_path}" "${install_path}"
			elif [[ "${os_distribution}" = "Windows_NT" ]]; then
				install_v2_windows_bundled_installer "${download_path}" "${install_path}"
			else
				fail "asdf-${TOOL_NAME} does not support OS distribution ${os_distribution}"
			fi
		else
			fail "asdf-${TOOL_NAME} does not support major version v${major_version}"
		fi

		local tool_cmd
		tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)"
		test -x "${install_path}/bin/${tool_cmd}" || fail "Expected ${install_path}/bin/${tool_cmd} to be executable."
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
	# requires python 3.7+ https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html#cli-chap-install-python
	"${download_path}"/awscli-bundle/install --install-dir "${install_path}"
}

install_v2_linux_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"
	# requires glibc, groff, less
	"${download_path}"/aws/install --install-dir "${install_path}" --bin-dir "${install_path}/bin"
}

# The official AWS CLI directions suggest using installer and a choices.xml
# but I was unable to find a deterministic way to make that work
# so copypasta
install_v2_macos_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"

	pkgutil --expand-full "${download_path}/AWSCLIV2.pkg" "${download_path}/tmp-awscliv2"
	mv "${download_path}/tmp-awscliv2/aws-cli.pkg/Payload/aws-cli" "${install_path}"
	mkdir -p "${install_path}/bin"
	ln -snf "${install_path}/aws" "${install_path}/bin/aws"
	ln -snf "${install_path}/aws_completer" "${install_path}/bin/aws_completer"
	rm -rf "${download_path}/tmp-awscliv2"
}

install_v2_windows_bundled_installer() {
	local download_path install_path
	download_path="$1"
	install_path="$2"

	# requires curl, msiexec
	msiexec.exe /i "${download_path}/AWSCLIV2.msi" "INSTALLDIR=${ASDF_INSTALL_PATH}" MSIINSTALLPERUSER=1
}
