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

- `bash`, `curl`, `tar`, `unzip`: generic POSIX utilities. These should be installed by default on most operating systems.

- v1 - Linux/MacOS/Windows || v2 - Windows
  - `Python 3.7.5+`: This plugin installs awscli from source into a virtualenv on these OS distributions. A currently maintained version of Python is required to do this.

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
asdf list-all awscli

# Install specific version
asdf install awscli latest   # 2.1.24
asdf install awscli latest 2 # 2.1.24
asdf install awscli latest 1 # 1.19.4

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
