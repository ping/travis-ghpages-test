#!/bin/bash

# Adapted from https://gist.github.com/domenic/ec8b0fc8ab45f39403dd

set -e

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"

BUILD_DIR="$HOME/build"

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Skipping gh-pages build."
    exit 0
fi

echo "Publishing to Github Pages...";

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

git clone $REPO $BUILD_DIR
cd $BUILD_DIR
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH

# Clean out existing build
rm -rf $BUILD_DIR/docs/$TRAVIS_BRANCH || exit 0
mkdir -p $BUILD_DIR/docs

cd $HOME

# Grab latest phpDoc
curl -sOL 'https://phpdoc.org/phpDocumentor.phar'
# Generate phpdoc output
php phpDocumentor.phar -q -n --template="responsive" --title="A TEST" --defaultpackagename="test" -d ./src -t $BUILD_DIR/docs/$TRAVIS_BRANCH
# Clear cache folders
rm -rf $BUILD_DIR/docs/$TRAVIS_BRANCH/phpdoc-cache-*

cd $BUILD_DIR
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if git diff --quiet; then
    echo "No changes to the docs on this push; exiting."
    exit 0
fi

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add -A .
git commit -m "Deploy to GitHub Pages: ${SHA} (Travis Build: $TRAVIS_BUILD_NUMBER)"

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}

eval `ssh-agent -s`
# Use stdin/stdout instead of key writing to disk
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in $HOME/.github/deploy_key.enc -d | ssh-add -

# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH

echo "Published to GitHub Pages."
