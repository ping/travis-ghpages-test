# README

```bash

# Path to gh project folder
GH_SRC_DIR='travis-ghpages-test'

cd "$GH_SRC_DIR"

touch .gitignore && echo -e "deploy_key\ndeploy_key.pub" >> .gitignore

# Generate new ssh key, without a passphrase
ssh-keygen -q -t rsa -b 4096 -C 'travis-ghpages-test' -f deploy_key -N ''

# Copy the contents of public key file to your clipboard
pbcopy < deploy_key.pub

# [TODO]
# 1. Add the ssh key to the project settings: https://github.com/<your name>/<your repo>/settings/keys
#   - remember to allow write access
# 2. Add project to Travis: https://travis-ci.org/profile/
# 3. Install Travis CLI https://github.com/travis-ci/travis.rb#installation

# Login to Travis: https://github.com/travis-ci/travis.rb#login
travis login

# travis encrypt key file
# [TODO]
# Look for encryption label, example: 052ccc0f979b
# ref: https://gist.github.com/domenic/ec8b0fc8ab45f39403dd#get-encrypted-credentials
travis encrypt-file deploy_key .github/deploy_key.enc

# [TODO]
# Put encryption label in .travis.yml

chmod +x .github/build_ghpages.sh
git add .gitignore .travis.yml .github

git commit -m 'Travis setup'

git push
```
