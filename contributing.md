# Contributing

Fork this repository, and make your changes in your fork. Once the code has been linted and tested, open a pull request using the [provided PR template](.github/PULL_REQUEST/pull_request_template.md).

Testing Locally:

- Code should pass shellcheck (on linux)
- Code should pass shfmt
- Fork should install and run help with `asdf plugin` test

```shell
# Install shellcheck linter
asdf plugin add shellcheck
asdf install shellcheck latest
asdf global shellcheck latest
# Install shfmt linter
asdf plugin add shfmt
asdf install shfmt latest
asdf global shfmt latest

# Run both linters from fork root (no output means linters passed)
# These matches the lint GitHub Action
shellcheck -x bin/* -P lib/
shfmt -d -i 2 -ci .

# asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]
asdf plugin test awscli https://github.com/MetricMike/asdf-awscli.git "awscli --help"
```

Tests are automatically run in GitHub Actions on push and PR. [Use this PR template](.github/PULL_REQUEST/pull_request_template.md) when submitting your pull request.
