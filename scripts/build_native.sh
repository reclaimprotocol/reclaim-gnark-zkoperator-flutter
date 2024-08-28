#!/usr/bin/env bash

set -e;

GO_GNARKPROVER_REPO_URL="https://$PACKAGE_CLONE_USER:$PACkAGE_CLONE_PASSWD@gitlab.reclaimprotocol.org/reclaim/gnark-symmetric-crypto";

mkdir -p vendor;

git clone $GO_GNARKPROVER_REPO_URL vendor/gnark-symmetric-crypto;

export GO_GNARKPROVER_DIR="$(pwd)/vendor/gnark-symmetric-crypto";

BUILD_BRANCH="build-$(uuidgen)"
git checkout -b $BUILD_BRANCH;

./scripts/build_ios.sh
./scripts/build_android.sh

# cleanup
rm -rf $GO_GNARKPROVER_DIR;

echo "Updating repository with new native libraries";

./scripts/update_version.sh;
git add pubspec.yaml;

git commit -m "Update [CI] ios native library";
git push --set-upstream origin $BUILD_BRANCH;
git push;
