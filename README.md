This repository contains conda recipes for building MXNet.  MXNet is broken up
into a number of packages to allow components to be shared and different
variants to be built and selected.  

The receipes in the repository are as follows:

* libmxnet : C++ MXNet libraries.  Comes in various variants depending on the BLAS
    implementation and GPU support: openblas, mkl, gpu_openblas, gpu_mkl.  
    OpenBLAS variants are only supported on linux-64 platform.
    GPU variants on linux-64 and win-64.  
    The mkl variants depend on 
    [mkl-dnn](https://github.com/AnacondaRecipes/aggregate/tree/master/mkl-dnn-feedstock)
    and [mklml](https://github.com/AnacondaRecipes/aggregate/tree/master/mklml-feedstock)
    recipes.

* py-mxnet : Python bindings to the MXNet library.  Depends on any variant of libmxnet.

* _mutex_mxnet : Mutex package on which libmxnet packages depend.  Provides a
    means to select a particular variant.
* mxnet : metapackage which installs libmxnet and py-mxnet
* mxnet-variants : metapackages which installs a particular CPU variant (openblas or mkl).
* mxnet-gpu : metapackages which install a particular GPU variant (gpu_openblas or gpu_mkl).

The build order is:
* _mutex_mxnet (although existing packages can be re-used)
* libmxnet 
* py-mxnet
* mxnet
* mxnet-variants
* mxnet-gpu

Only CPU variant packages were created for linux-64 and osx-64 for the 1.5.0
release.  See the [1.2.1](https://github.com/AnacondaRecipes/mxnet_recipes/tree/1.2.1)
recipes for GPU and Windows support.
