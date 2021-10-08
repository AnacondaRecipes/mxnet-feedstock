set -x

ENABLE_CYTHON=
if [[ $(uname) == Darwin ]]; then
  export MXNET_LIBRARY_PATH=${PREFIX}/lib/libmxnet.dylib
else
  export MXNET_LIBRARY_PATH=${PREFIX}/lib/libmxnet.so
  ENABLE_CYTHON=--with-cython
fi

cd python
${PYTHON} setup.py install $ENABLE_CYTHON --single-version-externally-managed --record=record.txt

if [[ $(uname) == Darwin ]]; then
find ${PREFIX} | grep libmxnet.dylib | grep -v $PREFIX/lib/libmxnet.dylib | xargs rm -f
ln -sf ../../../libmxnet.dylib $SP_DIR/mxnet/libmxnet.dylib

else
# Delete the copied libmxnet.so and create a relative symlink to $PREFIX/lib/
# The build scripts produce .so even on osx
find ${PREFIX} | grep libmxnet.so | grep -v $PREFIX/lib/libmxnet.so | xargs rm -f
ln -sf ../../../libmxnet.so $SP_DIR/mxnet/libmxnet.so
fi
