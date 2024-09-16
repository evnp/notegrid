vimdexcards
-----------

[![tests](https://github.com/evnp/vimdexcards/workflows/tests/badge.svg)](https://github.com/evnp/vimdexcards/actions)
[![shellcheck](https://github.com/evnp/vimdexcards/workflows/shellcheck/badge.svg)](https://github.com/evnp/vimdexcards/actions)
[![latest release](https://img.shields.io/github/release/evnp/vimdexcards.svg)](https://github.com/evnp/vimdexcards/releases/latest)
[![npm package](https://img.shields.io/npm/v/vimdexcards.svg)](https://www.npmjs.com/package/vimdexcards)
[![license](https://img.shields.io/badge/license-MIT-blue)](https://github.com/evnp/vimdexcards/blob/master/LICENSE.md)

**Contents** - [What?](https://github.com/evnp/vimdexcards#what) | [Usage](https://github.com/evnp/vimdexcards#usage) | [Install](https://github.com/evnp/vimdexcards#install) | [Tests](https://github.com/evnp/vimdexcards#tests) | [License](https://github.com/evnp/vimdexcards#license)

If you'd like to jump straight in, try one of these or go to the [Install](https://github.com/evnp/vimdexcards#install) section for more (curl, install man page, etc.):
```sh
brew tap evnp/vimdexcards && brew install vimdexcards
```
```sh
npm install -g vimdexcards
```

Install
-------
Homebrew:
```sh
brew tap evnp/vimdexcards && brew install vimdexcards
```
NPM:
```sh
npm install -g vimdexcards
```
Curl:
```sh
read -rp $'\n'"Current directories in \$PATH:"$'\n'"$(echo $PATH|sed 's/:/\n/g'|sort)"$'\n\n'"Enter a directory from the list above: " && [[ -z "${REPLY}" ]] && echo "Cancelled (no directory entered)" || ( curl -L -o "${REPLY/\~/$HOME}/vimdexcards" https://github.com/evnp/vimdexcards/raw/main/vimdexcards && chmod +x "${REPLY/\~/$HOME}/vimdexcards" )
```
vimdexcards has no external dependencies, but it's good practice to audit code before downvimdexcards onto your system to ensure it contains nothing unexpected. Please view the full source code for vimdexcards here: https://github.com/evnp/vimdexcards/blob/master/vimdexcards

If you also want to install vimdexcards's man page:
```sh
read -rp $'\n'"Current directories in \$(manpath):"$'\n'"$(manpath|sed 's/:/\n/g'|sort)"$'\n\n'"Enter a directory from the list above: " && [[ -z "${REPLY}" ]] && echo "Cancelled (no directory entered)" || curl -L -o "${REPLY/\~/$HOME}/man1/vimdexcards.1" https://github.com/evnp/vimdexcards/raw/main/man/vimdexcards.1
```
Verify installation:
```sh
vimdexcards -v
==> vimdexcards 2.0.2

brew test vimdexcards
==> Testing vimdexcards
==> /opt/homebrew/Cellar/vimdexcards/2.0.2/bin/vimdexcards test --print 1234 hello world
```

Tests
-------------
Run once:
```sh
npm install
npm test
```
Use `fswatch` to re-run tests on file changes:
```sh
brew install fswatch
npm install
npm run testw
```
Non-OSX: replace `brew install fswatch` with package manager of choice (see [fswatch docs](https://github.com/emcrisostomo/fswatch#getting-fswatch))
