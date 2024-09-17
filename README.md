notegrid
-----------

[![tests](https://github.com/evnp/notegrid/workflows/tests/badge.svg)](https://github.com/evnp/notegrid/actions)
[![shellcheck](https://github.com/evnp/notegrid/workflows/shellcheck/badge.svg)](https://github.com/evnp/notegrid/actions)
[![latest release](https://img.shields.io/github/release/evnp/notegrid.svg)](https://github.com/evnp/notegrid/releases/latest)
[![npm package](https://img.shields.io/npm/v/notegrid.svg)](https://www.npmjs.com/package/notegrid)
[![license](https://img.shields.io/badge/license-MIT-blue)](https://github.com/evnp/notegrid/blob/master/LICENSE.md)

**Contents** - [Usage](https://github.com/evnp/notegrid#usage) | [Install](https://github.com/evnp/notegrid#install) | [Tests](https://github.com/evnp/notegrid#tests) | [License](https://github.com/evnp/notegrid#license)

If you'd like to jump straight in, try one of these or go to the [Install](https://github.com/evnp/notegrid#install) section for more (curl, install man page, etc.):
```sh
brew tap evnp/notegrid && brew install notegrid
```
```sh
npm install -g notegrid
```

Usage
-----

Work in progress.

Install
-------
Homebrew:
```sh
brew tap evnp/notegrid && brew install notegrid
```
NPM:
```sh
npm install -g notegrid
```
Curl:
```sh
read -rp $'\n'"Current directories in \$PATH:"$'\n'"$(echo $PATH|sed 's/:/\n/g'|sort)"$'\n\n'"Enter a directory from the list above: " && [[ -z "${REPLY}" ]] && echo "Cancelled (no directory entered)" || ( curl -L -o "${REPLY/\~/$HOME}/notegrid" https://github.com/evnp/notegrid/raw/main/notegrid && chmod +x "${REPLY/\~/$HOME}/notegrid" )
```
notegrid has no external dependencies, but it's good practice to audit code before downnotegrid onto your system to ensure it contains nothing unexpected. Please view the full source code for notegrid here: https://github.com/evnp/notegrid/blob/master/notegrid

If you also want to install notegrid's man page:
```sh
read -rp $'\n'"Current directories in \$(manpath):"$'\n'"$(manpath|sed 's/:/\n/g'|sort)"$'\n\n'"Enter a directory from the list above: " && [[ -z "${REPLY}" ]] && echo "Cancelled (no directory entered)" || curl -L -o "${REPLY/\~/$HOME}/man1/notegrid.1" https://github.com/evnp/notegrid/raw/main/man/notegrid.1
```
Verify installation:
```sh
notegrid -v
==> notegrid 2.0.2

brew test notegrid
==> Testing notegrid
==> /opt/homebrew/Cellar/notegrid/2.0.2/bin/notegrid test --print 1234 hello world
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
