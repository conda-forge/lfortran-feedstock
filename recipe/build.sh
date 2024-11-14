#!/bin/bash

set -ex

export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS -D_LIBCPP_DISABLE_AVAILABILITY"

# Install emsdk
pushd emsdk
  ./emsdk install 3.1.59
  ./emsdk activate 3.1.59
  source ./emsdk_env.sh
  rm ./node/18.20.3_64bit/bin/node
  ln -s $(which node) ./node/18.20.3_64bit/bin/node
  export EMSDK_PATH=${EMSDK}
popd

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
  WRT=no
  (
    export CC=${CC_FOR_BUILD}
    export CXX=${CXX_FOR_BUILD}
    export NM=$($CC_FOR_BUILD -print-prog-name=nm)
    export AR=$($CC_FOR_BUILD -print-prog-name=ar)
    export OBJCOPY=$($CC_FOR_BUILD -print-prog-name=objcopy)
    export STRIP=$($CC_FOR_BUILD -print-prog-name=strip)
    export LFORTRAN_CC=${CC}

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
        -DWITH_LLVM_STACKTRACE=no \
        -DWITH_XEUS=yes \
        -DWITH_RUNTIME_LIBRARY=yes \
        -DWITH_RUNTIME_STACKTRACE=yes \
        -DWITH_TARGET_WASM=yes \
        -DCMAKE_INSTALL_LIBDIR=share/lfortran/lib \
        $SRC_DIR
    make
  )
else
  WRT=yes
fi

mkdir build
cd build
export LFORTRAN_CC=${CC}
cmake ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -O3 -funroll-loops -DNDEBUG" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DWITH_LLVM=yes \
    -DWITH_LLVM_STACKTRACE=no \
    -DWITH_XEUS=yes \
    -DWITH_RUNTIME_LIBRARY=$WRT \
    -DWITH_RUNTIME_STACKTRACE=yes \
    -DWITH_TARGET_WASM=yes \
    -DCMAKE_INSTALL_LIBDIR=share/lfortran/lib \
    $SRC_DIR

echo "FIND CONFIG FILE"
find . -iname "*config.h"

make -j${CPU_COUNT}
make install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
    cp ../build-native/src/runtime/*.mod $PREFIX/share/lfortran/lib/
fi
