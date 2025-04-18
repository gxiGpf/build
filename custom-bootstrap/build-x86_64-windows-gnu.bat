rem This file is licensed under the public domain.

@echo off

SETLOCAL EnableDelayedExpansion

set "TARGET=x86_64-windows-gnu"
set "MCPU=skylake"
set HOST_TARGET=x86_64-windows-msvc
set "TARGET_OS_CMAKE=Windows"

set OUTDIR=out

set ROOTDIR=%~dp0
set "ROOTDIR_CMAKE=%ROOTDIR:\=/%"
set ZIG_VERSION="0.15.0-dev.317+fa5915389"
set JOBS_ARG=

set ZIG=C:\zig-bootstrap-host\bin\zig.exe

mkdir "%ROOTDIR%%OUTDIR%\build-zlib-%TARGET%-%MCPU%"
cd "%ROOTDIR%%OUTDIR%\build-zlib-%TARGET%-%MCPU%"
cmake "%ROOTDIR%/zlib" ^
  -G "Ninja" ^
  -DCMAKE_INSTALL_PREFIX="%ROOTDIR_CMAKE%%OUTDIR%/%TARGET%-%MCPU%" ^
  -DCMAKE_PREFIX_PATH="%ROOTDIR_CMAKE%%OUTDIR%/%TARGET%-%MCPU%" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_CROSSCOMPILING=True ^
  -DCMAKE_SYSTEM_NAME="%TARGET_OS_CMAKE%" ^
  -DCMAKE_C_COMPILER="%ZIG%;cc;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_CXX_COMPILER="%ZIG%;c++;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_ASM_COMPILER="%ZIG%;cc;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_RC_COMPILER="C:/zig-bootstrap-host/bin/llvm-rc.exe" ^
  -DCMAKE_AR="C:/zig-bootstrap-host/bin/llvm-ar.exe" ^
  -DCMAKE_RANLIB="C:/zig-bootstrap-host/bin/llvm-ranlib.exe" ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded ^
  -DCMAKE_POLICY_DEFAULT_CMP0091=NEW
cmake --build . %JOBS_ARG% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

rem Cross compile zstd for the target
mkdir "%ROOTDIR%%OUTDIR%\%TARGET%-%MCPU%\lib"
copy "%ROOTDIR%\zstd\lib\zstd.h" "%ROOTDIR%%OUTDIR%\%TARGET%-%MCPU%\include\zstd.h"
cd "%ROOTDIR%%OUTDIR%\%TARGET%-%MCPU%\lib"
%ZIG% build-lib ^
  --name zstd ^
  -target %TARGET% ^
  -mcpu=%MCPU% ^
  -fstrip ^
  -OReleaseFast ^
  -lc ^
  "%ROOTDIR%\zstd\lib\decompress\zstd_ddict.c" ^
  "%ROOTDIR%\zstd\lib\decompress\zstd_decompress.c" ^
  "%ROOTDIR%\zstd\lib\decompress\huf_decompress.c" ^
  "%ROOTDIR%\zstd\lib\decompress\huf_decompress_amd64.S" ^
  "%ROOTDIR%\zstd\lib\decompress\zstd_decompress_block.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstdmt_compress.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_opt.c" ^
  "%ROOTDIR%\zstd\lib\compress\hist.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_ldm.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_fast.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_compress_literals.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_double_fast.c" ^
  "%ROOTDIR%\zstd\lib\compress\huf_compress.c" ^
  "%ROOTDIR%\zstd\lib\compress\fse_compress.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_lazy.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_compress.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_compress_sequences.c" ^
  "%ROOTDIR%\zstd\lib\compress\zstd_compress_superblock.c" ^
  "%ROOTDIR%\zstd\lib\deprecated\zbuff_compress.c" ^
  "%ROOTDIR%\zstd\lib\deprecated\zbuff_decompress.c" ^
  "%ROOTDIR%\zstd\lib\deprecated\zbuff_common.c" ^
  "%ROOTDIR%\zstd\lib\common\entropy_common.c" ^
  "%ROOTDIR%\zstd\lib\common\pool.c" ^
  "%ROOTDIR%\zstd\lib\common\threading.c" ^
  "%ROOTDIR%\zstd\lib\common\zstd_common.c" ^
  "%ROOTDIR%\zstd\lib\common\xxhash.c" ^
  "%ROOTDIR%\zstd\lib\common\debug.c" ^
  "%ROOTDIR%\zstd\lib\common\fse_decompress.c" ^
  "%ROOTDIR%\zstd\lib\common\error_private.c" ^
  "%ROOTDIR%\zstd\lib\dictBuilder\zdict.c" ^
  "%ROOTDIR%\zstd\lib\dictBuilder\divsufsort.c" ^
  "%ROOTDIR%\zstd\lib\dictBuilder\fastcover.c" ^
  "%ROOTDIR%\zstd\lib\dictBuilder\cover.c"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

rem Ideally we could use ZLIB_USE_STATIC_LIBS here (which would detect zlib correctly),
rem but this was added in 3.24 and the MSVC-bundled CMake is 3.20. Instead, for the msvc
rem ABI the zlib path is specified explicitly.

set ZLIB_LIBRARY=

rem Cross compile LLVM for the target
mkdir "%ROOTDIR%%OUTDIR%\build-llvm-%TARGET%-%MCPU%"
cd "%ROOTDIR%%OUTDIR%\build-llvm-%TARGET%-%MCPU%"
cmake "%ROOTDIR%/llvm" ^
  -G "Ninja" ^
  -DCMAKE_INSTALL_PREFIX="%ROOTDIR_CMAKE%%OUTDIR%/%TARGET%-%MCPU%" ^
  -DCMAKE_PREFIX_PATH="%ROOTDIR_CMAKE%%OUTDIR%/%TARGET%-%MCPU%" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded ^
  -DCMAKE_CROSSCOMPILING=True ^
  -DCMAKE_SYSTEM_NAME="%TARGET_OS_CMAKE%" ^
  -DCMAKE_C_COMPILER="%ZIG%;cc;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_CXX_COMPILER="%ZIG%;c++;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_ASM_COMPILER="%ZIG%;cc;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_RC_COMPILER="C:/zig-bootstrap-host/bin/llvm-rc.exe" ^
  -DCMAKE_AR="C:/zig-bootstrap-host/bin/llvm-ar.exe" ^
  -DCMAKE_RANLIB="C:/zig-bootstrap-host/bin/llvm-ranlib.exe" ^
  -DLLVM_ENABLE_BACKTRACES=OFF ^
  -DLLVM_ENABLE_BINDINGS=OFF ^
  -DLLVM_ENABLE_CRASH_OVERRIDES=OFF ^
  -DLLVM_ENABLE_LIBEDIT=OFF ^
  -DLLVM_ENABLE_LIBPFM=OFF ^
  -DLLVM_ENABLE_LIBXML2=OFF ^
  -DLLVM_ENABLE_OCAMLDOC=OFF ^
  -DLLVM_ENABLE_PLUGINS=OFF ^
  -DLLVM_ENABLE_PROJECTS="lld;clang" ^
  -DLLVM_ENABLE_Z3_SOLVER=OFF ^
  -DLLVM_ENABLE_ZLIB=FORCE_ON ^
  -DLLVM_ENABLE_ZSTD=FORCE_ON ^
  -DLLVM_USE_STATIC_ZSTD=ON ^
  -DLLVM_TABLEGEN="C:/zig-bootstrap-host/bin/llvm-tblgen.exe" ^
  -DLLVM_BUILD_TOOLS=OFF ^
  -DLLVM_BUILD_STATIC=ON ^
  -DLLVM_INCLUDE_UTILS=OFF ^
  -DLLVM_INCLUDE_TESTS=OFF ^
  -DLLVM_INCLUDE_EXAMPLES=OFF ^
  -DLLVM_INCLUDE_BENCHMARKS=OFF ^
  -DLLVM_INCLUDE_DOCS=OFF ^
  -DLLVM_DEFAULT_TARGET_TRIPLE=%TARGET% ^
  -DLLVM_TOOL_LLVM_LTO2_BUILD=OFF ^
  -DLLVM_TOOL_LLVM_LTO_BUILD=OFF ^
  -DLLVM_TOOL_LTO_BUILD=OFF ^
  -DLLVM_TOOL_REMARKS_SHLIB_BUILD=OFF ^
  -DCLANG_TABLEGEN="C:/zig-bootstrap-host/bin/clang-tblgen.exe" ^
  -DCLANG_BUILD_TOOLS=OFF ^
  -DCLANG_INCLUDE_DOCS=OFF ^
  -DCLANG_INCLUDE_TESTS=OFF ^
  -DCLANG_ENABLE_ARCMT=ON ^
  -DCLANG_TOOL_CLANG_IMPORT_TEST_BUILD=OFF ^
  -DCLANG_TOOL_CLANG_LINKER_WRAPPER_BUILD=OFF ^
  -DCLANG_TOOL_C_INDEX_TEST_BUILD=OFF ^
  -DCLANG_TOOL_ARCMT_TEST_BUILD=OFF ^
  -DCLANG_TOOL_C_ARCMT_TEST_BUILD=OFF ^
  -DCLANG_TOOL_LIBCLANG_BUILD=OFF ^
  %ZLIB_LIBRARY%
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cmake --build . %JOBS_ARG% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

@REM rem Finally, we can cross compile Zig itself, with Zig.
@REM cd "%ROOTDIR%\zig"
@REM %ZIG% build ^
@REM   --prefix "%ROOTDIR%%OUTDIR%\zig-%TARGET%-%MCPU%" ^
@REM   --search-prefix "%ROOTDIR%%OUTDIR%\%TARGET%-%MCPU%" ^
@REM   -Dflat ^
@REM   -Dstatic-llvm ^
@REM   -Doptimize=ReleaseFast ^
@REM   -Dstrip ^
@REM   -Dtarget="%TARGET%" ^
@REM   -Dcpu="%MCPU%" ^
@REM   -Dversion-string="%ZIG_VERSION%"
@REM if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

mkdir "%ROOTDIR%%OUTDIR%\build-zig-host"
cd "%ROOTDIR%%OUTDIR%\build-zig-host"
cmake "%ROOTDIR%/zig" ^
  -G "Ninja" ^
  -DCMAKE_INSTALL_PREFIX="%ROOTDIR%%OUTDIR%\zig-%TARGET%-%MCPU%" ^
  -DCMAKE_PREFIX_PATH="%ROOTDIR%%OUTDIR%\zig-%TARGET%-%MCPU%" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded ^
  -DCMAKE_CROSSCOMPILING=True ^
  -DCMAKE_SYSTEM_NAME="%TARGET_OS_CMAKE%" ^
  -DCMAKE_C_COMPILER="%ZIG%;cc;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_CXX_COMPILER="%ZIG%;c++;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_ASM_COMPILER="%ZIG%;cc;-fno-sanitize=all;-fno-stack-protector;-s;-target;%TARGET%;-mcpu=%MCPU%" ^
  -DCMAKE_RC_COMPILER="C:/zig-bootstrap-host/bin/llvm-rc.exe" ^
  -DCMAKE_AR="C:/zig-bootstrap-host/bin/llvm-ar.exe" ^
  -DCMAKE_RANLIB="C:/zig-bootstrap-host/bin/llvm-ranlib.exe" ^
  -DZIG_STATIC=ON ^
  -DZIG_STATIC_ZSTD=OFF ^
  -DZIG_TARGET_TRIPLE="%HOST_TARGET%" ^
  -DZIG_TARGET_MCPU=baseline

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
cmake --build . %JOBS_ARG% --target install
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

popd