#!/usr/bin/env bash
echo "Building ${PKG_NAME}."

set -ex

# Use the OpenMP library already in the environment
rm -rf 3rdparty/openmp/

# Use the MKL-DNN library already in the environment
rm -rf 3rdparty/mkldnn
rm -rf include/mkldnn

export OPENMP_OPT=ON
#export JEMALLOC_OPT=ON

if [[ ${HOST} =~ .*darwin.* ]]; then
  export OPENMP_OPT=OFF
  # On macOS, jemalloc defaults to JEMALLOC_PREFIX: 'je_'
  # for which mxnet source code isn't ready yet.
#  export JEMALLOC_OPT=OFF
fi


# Set target specific options
declare -a anaconda_build_opts
case "${target_platform}" in
    linux-aarch64)
        anaconda_build_opts+=(-DUSE_SSE=OFF)
        anaconda_build_opts+=(-DUSE_OPENCV=ON)
        ;;
    linux-ppc64le)
        anaconda_build_opts+=(-DUSE_SSE=OFF)
        ;;
    linux-s390x)
        anaconda_build_opts+=(-DUSE_SSE=OFF)
        ;;
    linux-64)
        anaconda_build_opts+=(-DUSE_OPENCV=ON)
        ;;
    osx-64)
        anaconda_build_opts+=(-DUSE_OPENCV=ON)
        AR=${BUILD_PREFIX}/bin/${AR}
        RANLIB=${BUILD_PREFIX}/bin/${RANLIB}
        ;;
    osx-arm64)
        anaconda_build_opts+=(-DUSE_OPENCV=ON)
        anaconda_build_opts+=(-DUSE_SSE=OFF)
        AR=${BUILD_PREFIX}/bin/${AR}
        RANLIB=${BUILD_PREFIX}/bin/${RANLIB}
        ;;
esac

declare -a _blas_opts
if [[ "${mxnet_blas_impl}" == "mkl" ]]; then
  _blas_opts+=(-DBLAS="mkl")
  _blas_opts+=(-DUSE_BLAS="mkl")
  _blas_opts+=(-DUSE_MKL_IF_AVAILABLE=ON)
  _blas_opts+=(-DUSE_MKLDNN=ON)
  _blas_opts+=(-DUSE_MKLML_MKL=ON)
else
  _blas_opts+=(-DBLAS="open")
  _blas_opts+=(-DUSE_BLAS="Open")
  _blas_opts+=(-DUSE_MKL_IF_AVAILABLE=OFF)
  _blas_opts+=(-DUSE_MKLDNN=OFF)
  _blas_opts+=(-DUSE_MKLML_MKL=OFF)
fi

declare -a _gpu_opts
if [[ ${mxnet_variant_str} =~ .*gpu.* ]]; then
  _gpu_opts+=(-DUSE_CUDA=ON)
  _gpu_opts+=(-DUSE_CUDNN=ON)
  _gpu_opts+=(-DUSE_CUDA_PATH=/usr/local/cuda-${cudatoolkit_version})
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64/stubs
else
  _gpu_opts+=(-DUSE_CUDA=OFF)
  _gpu_opts+=(-DUSE_CUDNN=OFF)
fi


# Isolate the build.
  # rm -rf Build-${PKG_NAME}  # We could clean it up... But there really is no need.
mkdir -p Build-${PKG_NAME}
cd Build-${PKG_NAME} || exit 1


cmake .. ${CMAKE_ARGS} \
    -GNinja \
    -LAH \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR="lib" \
    -DCMAKE_AR=${AR} \
    -DCMAKE_LINKER=${LD} \
    -DCMAKE_NM=${NM} \
    -DCMAKE_OBJCOPY=${OBJCOPY} \
    -DCMAKE_OBJDUMP=${OBJDUMP} \
    -DCMAKE_RANLIB=${RANLIB} \
    -DCMAKE_STRIP=${STRIP} \
    -DCMAKE_CXX_COMPILER_AR=${CC} \
    -DCMAKE_CXX_COMPILER_RANLIB=${RANLIB} \
    -DCMAKE_C_COMPILER_AR=${CC} \
    -DCMAKE_C_COMPILER_RANLIB=${RANLIB} \
    -DUSE_F16C=OFF \
    -DUSE_PROFILER=ON \
    -DUSE_CPP_PACKAGE=ON \
    -DUSE_SIGNAL_HANDLER=ON \
    -DUSE_OPENMP="$OPENMP_OPT" \
    -DUSE_JEMALLOC="$JEMALLOC_OPT" \
    -DBUILD_CPP_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF \
    \
    "${_blas_opts[@]}" \
    "${_gpu_opts[@]}" \
    "${anaconda_build_opts[@]}" \


ninja -j${CPU_COUNT}
ninja install

# make install misses this file
mkdir -p ${PREFIX}/bin
cp im2rec ${PREFIX}/bin/

# remove static libs
rm -f ${PREFIX}/lib/libdmlc.a
rm -f ${PREFIX}/lib/libmxnet.a

# remove cmake cruft
rm -rf ${PREFIX}/lib/cmake/dmlc
