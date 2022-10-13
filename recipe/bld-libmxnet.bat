@echo ON

:: cmd
echo "Building %PKG_NAME%."

set MKL_ROOT=%LIBRARY_PREFIX%

:: Isolate the build.
mkdir Build-%PKG_NAME%
cd Build-%PKG_NAME%
if errorlevel 1 exit /b 1


REM TODO: Add mkldnn and mklml when
REM https://github.com/apache/incubator-mxnet/pull/10629 is released

set IS_GPU_BUILD=0
set "BUILD_CPP_PACKAGE=ON"
echo %mxnet_variant_str% | findstr /C:"gpu"

REM Make sure only one CUDA installation is active
if "%errorlevel%" == "0" (
  set IS_GPU_BUILD=1
  set "CUDA_PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%cudatoolkit_version%"
  REM set "CUDA_PATH_V%cudatoolkit_version:.=_%=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%cudatoolkit_version%"
  REM set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%cudatoolkit_version%\bin:%PATH%"
  REM set "CUDACXX=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v%cudatoolkit_version%\bin\nvcc.exe"
  set "CUDNN_ROOT=%LIBRARY_PREFIX%"
  set "BUILD_CPP_PACKAGE=OFF"
)

cmake .. ${CMAKE_ARGS} ^
  -GNinja ^
  -Wno-dev ^
  -DUSE_F16C=OFF ^
  -DUSE_CUDA=%IS_GPU_BUILD% ^
  -DUSE_CUDNN=%IS_GPU_BUILD% ^
  -DUSE_OPENMP=ON ^
  -DUSE_OPENCV=ON ^
  -DUSE_JEMALLOC=OFF ^
  -DBLAS=%mxnet_blas_impl% ^
  -DUSE_CPP_PACKAGE=%BUILD_CPP_PACKAGE% ^
  -DBUILD_CPP_EXAMPLES=%BUILD_CPP_PACKAGE% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
  -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
  -DUSE_CXX14_IF_AVAILABLE=ON


if errorlevel 1 exit 1

cmake --build . --target INSTALL --config Release -- /maxcpucount:%CPU_COUNT%
if errorlevel 1 exit 1

if "%BUILD_CPP_PACKAGE%" == "ON" (
  REM https://github.com/apache/incubator-mxnet/tree/1.0.0/cpp-package
  xcopy /s /y %SRC_DIR%\cpp-package\include %LIBRARY_INC%\
  if errorlevel 1 exit 1
)
