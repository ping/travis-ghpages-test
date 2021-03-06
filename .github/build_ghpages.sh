#!/bin/bash

# Adapted from https://gist.github.com/domenic/ec8b0fc8ab45f39403dd

set -e

CWD=$(pwd)
SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"

BUILD_DIR="$HOME/.build"

echo "Publishing to Github Pages..."

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

git clone --quiet $REPO $BUILD_DIR

cd $BUILD_DIR

(git checkout --quiet $TARGET_BRANCH && echo "... Existing $TARGET_BRANCH branch.") \
|| (git checkout --quiet --orphan $TARGET_BRANCH && echo "... New $TARGET_BRANCH branch." && cd "$BUILD_DIR" && git rm -qrf .)

cd "$CWD"

# Prep docs folders
mkdir -p "$BUILD_DIR/docs"
if [ -d "$BUILD_DIR/docs/$TRAVIS_BRANCH" ]; then
    # remove last build
    rm -rf "$BUILD_DIR/docs/$TRAVIS_BRANCH"
fi

if [[ "$DOC_GENERATOR" == 'phpdoc' ]]; then
    # --------- PHPDOC ---------
    # Grab latest phpDoc
    curl -sOL 'https://phpdoc.org/phpDocumentor.phar'
    # Generate phpdoc output
    php phpDocumentor.phar -q -n --template="responsive" --title="A TEST" --defaultpackagename="test" -d ./src -t $BUILD_DIR/docs/$TRAVIS_BRANCH
    # Clear cache folders
    rm -rf $BUILD_DIR/docs/$TRAVIS_BRANCH/phpdoc-cache-*

elif [[ "$DOC_GENERATOR" == 'apigen' ]]; then
    # --------- APIGEN ---------
    # Grab latest apigen
    curl -sL -o 'apigen.phar' 'https://github.com/ApiGen/ApiGen/releases/download/v4.1.0/apigen-4.1.0.phar'
    php apigen.phar generate -q -s ./src -d $BUILD_DIR/docs/$TRAVIS_BRANCH
fi

echo "... Generated docs."

cd $BUILD_DIR
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

git add -A "docs/$TRAVIS_BRANCH"

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if git diff --quiet --cached; then
    echo "No changes to the docs on this push; exiting."
    exit 0
fi

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git commit --quiet -m "Deploy to GitHub Pages: ${SHA} (Travis Build: $TRAVIS_BUILD_NUMBER)"

echo "... Added changes."

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}

eval `ssh-agent -s`
# Use stdin/stdout instead of key writing to disk
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in "$CWD/.github/deploy_key.enc" -d | ssh-add -

echo "... Added ssh key."

# Now that we're all set up, we can push.
git push --quiet $SSH_REPO $TARGET_BRANCH

REPO_USER=$(echo "$TRAVIS_REPO_SLUG" | grep -Eo '^([^/]+)')
REPO_NAME=$(echo "$TRAVIS_REPO_SLUG" | grep -Eo '([^/]+)$')
echo "Published to GitHub Pages https://$REPO_USER.github.io/$REPO_NAME/docs/$TRAVIS_BRANCH/"
