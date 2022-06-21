<div align="center">

# asdf-awscli ![Build](https://github.com/MetricMike/asdf-awscli/workflows/Build/badge.svg) ![Lint](https://github.com/MetricMike/asdf-awscli/workflows/Lint/badge.svg)

[awscli](https://github.com/MetricMike/asdf-awscli) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `curl`, `git`: Required by [asdf](https://asdf-vm.com/guide/getting-started.html#_1-install-dependencies)
- `bash`, `tar`, `unzip`: generic POSIX utilities. These should be installed by default on most operating systems.

- v1 - Linux/MacOS/Windows || v2 - Windows
  - `Python 3+ w/ current support (3.7.13+ as of 20JUN2022)`: For v1 (and v2 on Windows until https://github.com/MetricMike/asdf-awscli/issues/2 is resolved), this plugin installs awscli from source into a virtualenv on these OS distributions utilizing pip. In theory, most Python 3s will be sufficient, but issues will be closed if the Python is not listed as green on https://endoflife.date/python.

# Install

Plugin:

```shell
asdf plugin add awscli
# or
asdf plugin add https://github.com/MetricMike/asdf-awscli.git
```

awscli:

```shell
# Show all installable versions
asdf list all awscli

# Install specific version
asdf install awscli latest   # 2.1.24
asdf install awscli latest:2 # 2.1.24
asdf install awscli latest:1 # 1.19.4

# Set a version globally (on your ~/.tool-versions file)
asdf global awscli latest

# Now awscli commands are available
aws --help
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/MetricMike/asdf-awscli/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Michael Weigle](https://github.com/MetricMike/)
