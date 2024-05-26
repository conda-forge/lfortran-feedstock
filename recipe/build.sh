#!/bin/bash

set -ex


CUR_DIR=`pwd`
cd $HOME
curl -o wasi-sdk.tar.gz -L https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-21/wasi-sdk-21.0-macos.tar.gz
tar -xvf wasi-sdk.tar.gz
export WASI_SDK_PATH=$HOME/wasi-sdk-21.0
echo $WASI_SDK_PATH
$WASI_SDK_PATH/bin/clang --version

cd $CUR_DIR

export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS -D_LIBCPP_DISABLE_AVAILABILITY"

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
  WRT=no
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
        -DWITH_RUNTIME_LIBRARY=yes \
        -DWITH_RUNTIME_STACKTRACE=yes \
        -DCMAKE_INSTALL_LIBDIR=share/lfortran/lib \
        -DWITH_TARGET_WASM=yes \
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
    -DWITH_XEUS=yes \
    -DWITH_RUNTIME_LIBRARY=$WRT \
    -DWITH_RUNTIME_STACKTRACE=yes \
    -DCMAKE_INSTALL_LIBDIR=share/lfortran/lib \
    -DWITH_TARGET_WASM=yes \
    $SRC_DIR

make -j${CPU_COUNT}
make install
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == 1 ]]; then
    cp ../build-native/src/runtime/*.mod $PREFIX/share/lfortran/lib/
fi
