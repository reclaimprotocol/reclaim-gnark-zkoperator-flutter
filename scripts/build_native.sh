#!/usr/bin/env bash

set -e;

GO_GNARKPROVER_REPO_URL="https://$PACKAGE_CLONE_USER:$PACkAGE_CLONE_PASSWD@gitlab.reclaimprotocol.org/reclaim/gnark-symmetric-crypto";

mkdir -p vendor;

git clone $GO_GNARKPROVER_REPO_URL vendor/gnark-symmetric-crypto;

export GO_GNARKPROVER_DIR="$(pwd)/vendor/gnark-symmetric-crypto";

echo "Starting build for iOS"

cd src;
make ios;
cd ../;

# cleanup
rm -rf $GO_GNARKPROVER_DIR;

echo "Updating repository with new native libraries";
git checkout -b "build-$(uuidgen)";
git add ios;
git commit -m "Update [CI] ios native library";
git push;
echo "Starting build for iOS"
