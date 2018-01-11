# Face-Vertex Toolbox

## Overview

## Face-vertex representation

## Visualization

## Affine transformations

## Combining groups

## Facet properties


# Geometric Optics Toolbox

## Overview

## Dependencies

|        Module | Description                                       |
|---------------|---------------------------------------------------|
| `+embree`     | Calculation of transmission points                |
| `+facevertex` | Representation of polygon complexes               |
| `+mex`        | Required for C++ back-end                         |
| `+parallel`   | Parallel reduction with `parreduce`               |
| `+structs`    | Efficient manipulation of tabular data            |
| `+sx`         | Utilities relating to array singleton-expansion   |

## Antenna patterns

## Reflection points

## Transmission points

## Contributors

From the Department of Electrical & Computer Engineering at the University of Auckland:
- Jon Pearce
- Yuen Zhuang Goh 
- Michael Neve

## Appendix A: Coordinate systems

### `cart`

### `pol`

### `sph`

### `sphi`

### `uv`


## Appendix B: File formats


## Appendix C: Unit tests


## Appendix D: Building `Embree`

See `mex` settings in `embree/embreebuild.m`.

Essential libraries:
- `embree.lib`
- `embree_sse42.lib`
- `embree_avx.lib`
- `embree_avx2.lib`
- `lexers.lib`
- `scenegraph.lib`
- `simd.lib`
- `sys.lib`
- `tasking.lib`

NB: `scenegraph.lib` is apparently unnecessary

### Building with Visual Studio

* Use `VS2015 x64 Native Command Prompt` rather than `Developer Command Prompt for VS2015`

In `cmake-gui`:
- Ensure that `EMBREE_BACKFACE_CULLING` is unchecked (i.e. *not* set)
- Set `EMBREE_STATIC_LIB`
- Set `EMBREE_STATIC_RUNTIME`
- Add `/D_DEBUG` to `CMAKE_CXX_FLAGS_DEBUG` and `CMAKE_C_FLAGS_DEBUG`
- Set `EMBREE_TASKING_SYSTEM` to `TBB`
- ... but clear `EMBREE_TBB_ROOT` (otherwise cmake may select EMBREE_TBB_LIBRARY and EMBREE_TBB_LIBRARY_MALLOC for VC12 rather than VC14)
- ... and set `EMBREE_TBB_LIBRARY` to e.g. "C:\path\to\tbb2018_20170726oss\lib\intel64\vc14\tbb.lib" (i.e. appropriate for your version of Visual Studio - here vc14 rather than vc12)
- Similarly, set `EMBREE_TBB_LIBRARY_MALLOC` to e.g. "C:\path\to\tbb2018_20170726oss\lib\intel64\vc14\tbbmalloc.lib"


