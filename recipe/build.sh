#!/bin/bash

set -ex

CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS" cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DWITH_LLVM=yes \
    -DWITH_XEUS=yes \
    $SRC_DIR

make

make install
