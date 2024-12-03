#!/usr/bin/env bash

set -e;

if [ -z "$GO_GNARKPROVER_DIR" ]
then
    GO_GNARKPROVER_REPO_URL="https://github.com/reclaimprotocol/zk-symmetric-crypto";
    mkdir -p vendor;
    git clone $GO_GNARKPROVER_REPO_URL vendor/gnark-symmetric-crypto;
    export GO_GNARKPROVER_DIR="$(pwd)/vendor/gnark-symmetric-crypto/gnark";
fi

get_timestamp() {
    date "+%Y%m%d%H%M"
}

BUILD_BRANCH="build-$(get_timestamp)"
git checkout -b $BUILD_BRANCH;

./scripts/build_ios.sh
./scripts/build_android.sh

# cleanup
rm -rf $GO_GNARKPROVER_DIR;

echo "Updating repository with new native libraries";

bash ./scripts/update_version.sh;

git add pubspec.yaml;

git commit -m "Update [CI] native libraries for Android & iOS";
git push --set-upstream origin $BUILD_BRANCH;
git push;
