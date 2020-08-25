#!/bin/bash

set -ex

CXXFLAGS="" cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -D__STDC_FORMAT_MACROS -DNDEBUG" \
    -DCMAKE_CXX_STANDARD=14 \
    -DWITH_LLVM=yes \
    -DWITH_XEUS=yes \
    $SRC_DIR

make VERBOSE=1

make install
