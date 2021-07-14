#!/bin/bash

set -ex

export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS -D_LIBCPP_DISABLE_AVAILABILITY"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
  (
    export CC=${CC_FOR_BUILD}
    export CXX=${CXX_FOR_BUILD}
    export NM=$($CC_FOR_BUILD -print-prog-name=nm)
    export AR=$($CC_FOR_BUILD -print-prog-name=ar)
    export OBJCOPY=$($CC_FOR_BUILD -print-prog-name=objcopy)
    export STRIP=$($CC_FOR_BUILD -print-prog-name=strip)

    # CFLAGS and CXXFLAGS are intentionally empty
    unset CFLAGS
    unset CXXFLAGS
    unset CPPFLAGS

    export LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX}

    mkdir build-native
    cd build-native
    cmake ${CMAKE_ARGS} \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -O3 -funroll-loops -DNDEBUG" \
        -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX \
        -DCMAKE_PREFIX_PATH=$BUILD_PREFIX \
        -DWITH_LLVM=yes \
        -DWITH_XEUS=yes \
        $SRC_DIR
  )
fi

mkdir build
cd build
cmake ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -O3 -funroll-loops -DNDEBUG" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DWITH_LLVM=yes \
    -DWITH_XEUS=yes \
    $SRC_DIR

make -j${CPU_COUNT}
make install
