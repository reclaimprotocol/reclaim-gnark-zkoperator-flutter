#!/usr/bin/env sh

set -e;

export GOOS=ios
export CGO_ENABLED=1
# export CGO_CFLAGS="-fembed-bitcode"
# export MIN_VERSION=15

SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)

if [ "$GOARCH" = "amd64" ]; then
    CARCH="x86_64"
elif [ "$GOARCH" = "arm64" ]; then
    CARCH="arm64"
fi

if [ "$SDK" = "iphoneos" ]; then
  export TARGET="$CARCH-apple-ios$MIN_VERSION"
elif [ "$SDK" = "iphonesimulator" ]; then
  export TARGET="$CARCH-apple-ios$MIN_VERSION-simulator"
fi

CLANG=$(xcrun --sdk "$SDK" --find clang)
CC="$CLANG -target $TARGET -isysroot $SDK_PATH $@"
export CC

BUILD_OUTPUT_DIR="${BUILD_DIR}/${GOARCH}_${SDK}"
mkdir -p ${BUILD_OUTPUT_DIR}

go build -C $GO_GNARKPROVER_DIR -trimpath ${GOX_TAGS} -buildmode=c-archive -o ${BUILD_OUTPUT_DIR}/${LIB_NAME}.a ${GO_TARGET_LIB}
