#!/usr/bin/env bash

TXT_BOLD=$(tput bold)
TXT_DIM=$(tput setaf 245)
TXT_RESET=$(tput sgr0)

DIRNAME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LH_PRISTINE_ROOT="$DIRNAME/../../../lighthouse-pristine"

set -euxo pipefail

bash "$DIRNAME/publish-prepare-pristine.sh"

cd "$LH_PRISTINE_ROOT"

VERSION=$(node -e "console.log(require('./package.json').version)")

if ! git rev-parse "v$VERSION" ; then
  if ! git --no-pager log -n 1 --oneline | grep "v$VERSION" ; then
    echo "Cannot tag a commit other than the version bump!";
    exit 1;
  fi

  git tag -a "v$VERSION" -m "v$VERSION"
fi


if [[ $(git rev-parse "v$VERSION") != $(git rev-parse HEAD )]]; then
  echo "Cannot package a version other than the tagged version!";
  exit 1;
fi

# Install the dependencies.
yarn install

# Build everything
yarn build-all

# Package the extension
node build/build-extension.js package

# Verify the npm package won't include unncessary files
npm pack --dry-run
npx pkgfiles

echo "Make sure the files above look good!"

