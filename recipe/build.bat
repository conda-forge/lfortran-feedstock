REM Install and activate Emscripten SDK for the WASM target.
REM Keep the version in sync with recipe.yaml (emsdk rev) and recipe/build.sh.
pushd emsdk
call emsdk.bat install 6.0.9
if errorlevel 1 exit 1
call emsdk.bat activate 6.0.9
if errorlevel 1 exit 1
call emsdk_env.bat
if errorlevel 1 exit 1
set "EMSDK_PATH=%EMSDK%"
set "EMSDK_PYTHON=%BUILD_PREFIX%\python.exe"
popd

cmake ^
    -G "NMake Makefiles" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DXJUPYTER_DATA_DIR=%PREFIX%\\share\\jupyter ^
    -DCMAKE_PREFIX_PATH=%PREFIX% ^
    -DWITH_LLVM=yes ^
    -DWITH_LSP=yes ^
    -DWITH_XEUS=yes ^
    -DWITH_TARGET_WASM=yes ^
    %SRC_DIR%
if errorlevel 1 exit 1

cmake --build . --target install
if errorlevel 1 exit 1
