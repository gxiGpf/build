rem This file is licensed under the public domain.

@echo off

SETLOCAL EnableDelayedExpansion

set "TARGET=x86_64-windows-gnu"
set "MCPU=native"
set HOST_TARGET=x86_64-windows-msvc
set "TARGET_OS_CMAKE=Windows"

set OUTDIR=out

set ROOTDIR=%~dp0
set "ROOTDIR_CMAKE=%ROOTDIR:\=/%"
set ZIG_VERSION="0.16.0-dev.1354+94e98bfe8"
set JOBS_ARG=

pushd %ROOTDIR%

rem Build zlib for the host
mkdir "%ROOTDIR%%OUTDIR%\build-zlib-host"
cd "%ROOTDIR%%OUTDIR%\build-zlib-host"
cmake "%ROOTDIR%/zlib" ^
  -G "Ninja" ^
  -DCMAKE_INSTALL_PREFIX="%ROOTDIR%/%OUTDIR%/host" ^
  -DCMAKE_PREFIX_PATH="%ROOTDIR%/%OUTDIR%/host" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

cmake --build . %JOBS_ARG% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

rem Build the libraries for Zig to link against, as well as native `llvm-tblgen` using msvc
mkdir "%ROOTDIR%%OUTDIR%\build-llvm-host"
cd "%ROOTDIR%%OUTDIR%\build-llvm-host"
cmake "%ROOTDIR%/llvm" ^
  -G "Ninja" ^
  -DCMAKE_INSTALL_PREFIX="%ROOTDIR%/%OUTDIR%/host" ^
  -DCMAKE_PREFIX_PATH="%ROOTDIR%/%OUTDIR%/host" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded ^
  -DLLVM_ENABLE_BINDINGS=OFF ^
  -DLLVM_ENABLE_LIBEDIT=OFF ^
  -DLLVM_ENABLE_LIBPFM=OFF ^
  -DLLVM_ENABLE_LIBXML2=OFF ^
  -DLLVM_ENABLE_OCAMLDOC=OFF ^
  -DLLVM_ENABLE_PLUGINS=OFF ^
  -DLLVM_ENABLE_PROJECTS="lld;clang" ^
  -DLLVM_ENABLE_Z3_SOLVER=OFF ^
  -DLLVM_ENABLE_ZSTD=OFF ^
  -DLLVM_INCLUDE_UTILS=OFF ^
  -DLLVM_INCLUDE_TESTS=OFF ^
  -DLLVM_INCLUDE_EXAMPLES=OFF ^
  -DLLVM_INCLUDE_BENCHMARKS=OFF ^
  -DLLVM_INCLUDE_DOCS=OFF ^
  -DLLVM_TOOL_LLVM_LTO2_BUILD=OFF ^
  -DLLVM_TOOL_LLVM_LTO_BUILD=OFF ^
  -DLLVM_TOOL_LTO_BUILD=OFF ^
  -DLLVM_TOOL_REMARKS_SHLIB_BUILD=OFF ^
  -DCLANG_BUILD_TOOLS=OFF ^
  -DCLANG_INCLUDE_DOCS=OFF ^
  -DCLANG_INCLUDE_TESTS=OFF ^
  -DCLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF ^
  -DCLANG_TOOL_CLANG_LINKER_WRAPPER_BUILD=OFF ^
  -DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF ^
  -DCLANG_TOOL_LIBCLANG_BUILD=OFF ^
  -DLLVM_BUILD_LLVM_C_DYLIB=NO
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cmake --build . %JOBS_ARG% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

rem Build an x86_64-windows-msvc zig using msvc, linking against LLVM/Clang/LLD/zlib built by msvc
mkdir "%ROOTDIR%%OUTDIR%\build-zig-host"
cd "%ROOTDIR%%OUTDIR%\build-zig-host"
cmake "%ROOTDIR%/zig" ^
  -G "Ninja" ^
  -DCMAKE_INSTALL_PREFIX="%ROOTDIR_CMAKE%%OUTDIR%/host" ^
  -DCMAKE_PREFIX_PATH="%ROOTDIR_CMAKE%%OUTDIR%/host" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DZIG_STATIC=ON ^
  -DZIG_STATIC_ZSTD=OFF ^
  -DZIG_TARGET_TRIPLE="%HOST_TARGET%" ^
  -DZIG_TARGET_MCPU=baseline

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cmake --build . %JOBS_ARG% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

popd