<div align="center">

# asdf-awscli ![Build](https://github.com/MetricMike/asdf-awscli/workflows/Build/badge.svg) ![Lint](https://github.com/MetricMike/asdf-awscli/workflows/Lint/badge.svg)

[awscli](https://github.com/MetricMike/asdf-awscli) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Build History
[![Build history](https://buildstats.info/github/chart/MetricMike/asdf-awscli?branch=main)](https://github.com/MetricMike/asdf-awscli/actions)

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `curl`, `git`: Required by [asdf](https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)
- `bash`, `tar`, `unzip`, `coreutils`: generic POSIX utilities. These should be installed by default on most operating systems.
- Python 3.8+ (v1, v2 when building from source) https://aws.amazon.com/blogs/developer/python-support-policy-updates-for-aws-sdks-and-tools/
- `make/autotools` (v2 when building from source)
- `Rosetta 2` (v2 when using the pre-built installers on Apple Silicon)

# Install

Plugin:

```shell
asdf plugin add awscli
# or
asdf plugin add awscli https://github.com/MetricMike/asdf-awscli.git
```

awscli:

```shell
# Show all installable versions
asdf list all awscli

# Install the latest version (optionally with a version prefix)
asdf install awscli latest   # 2.11.15
asdf install awscli latest:2 # 2.11.15
asdf install awscli latest:1 # 1.27.119

# Install a specific version
asdf install awscli 2.11.15
asdf install awscli 1.27.119

# Build and install v2 from from source
asdf install awscli ref:2.11.15
asdf install awscli "ref:$(asdf latest awscli 2)" # 2.11.15

# Set a version globally (on your ~/.tool-versions file)
(cd ~; asdf set awscli latest)

# Now awscli commands are available
aws --version
```

### v1 - Linux/MacOS/Windows

Only the pre-built installer is supported by this plugin for AWS CLI v1. If you need to build from source, install via `pip`.

Note: The pre-built installers require a Python 3.8+ distribution at install-time **and this Python must remain installed** as they're just creating an isolated virtualenv and copying their site-packages over. Refer to the [AWS CLI v1 Python version support matrix](https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html#cli-chap-install-python) for which Pythons support which AWS CLI versions. If you remove the Python distribution used at install-time, **you must reinstall AWS CLI**.

### v2 - [Pre-built Installers](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html)

The macOS flavor only provides an x86_64 binary. You *must* install Rosetta 2 if using Apple Silicon (M1/M2/arm64).

The Linux flavor provides both x86_64 and aarch64 binaries, but has dependencies on glibc, groff, and less. Alpine/musl users should build from source.

The Windows flavor technically works, but ASDF's support for Windows isn't 100% yet.

### v2 - [Build and install from source](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-source-install.html)

This is only supported starting from [v2.10.0 / 2023-02-15](https://github.com/aws/aws-cli/pull/7668)

Building and installing from source requires a Python 3.8+ distribution at build-time. This plugin uses the `--with-install-type=portable-exe` and `--with-download-deps` flags to download all required Python dependencies and freeze a static copy of the build-time Python distribution. After a successful installation, there are no dependencies to your build time environment, and the ASDF installs folder could be shared with another air-gapped system that did not have a Python installation.

---

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/MetricMike/asdf-awscli/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Michael Weigle](https://github.com/MetricMike/)
