# Notes for FRDF Report

## Objectives
 
> The current version of the WyFy tool exists as both a MATLAB and a FORTRAN2008
implementation. The MATLAB implementation is only capable of line-of-sight (LOS)
propagation, but is able to account for any number of intervening wall attenuations. 

The new tool supports propatation through an arbitrary number of reflections.

> It is also capable of *dynamic performance visualization*, in which the users can drag
access point locations on screen and immediately see the effects on system
performance ... 

The new tool also provides an interactive mode for 2D scenes. The speed of the new code might make the interactive mode feasible on 3D configurations of limited size: While this possibility has not been investigated, the static visualization capabilities (discussed [below](#objective-3-dynamic-visualization-capabilities)) are far easier to work with than those of the Fortran implementation, especially because the user develop a visualisation incrementally from the MATLAB command prompt.

> This implementation is however *slow* (especially when large numbers of walls are considered) ...  and for this reason the FORTRAN2008 version was developed. This version can handle up to second-order reflections, is significantly faster than the MATLAB implementation, but lacks dynamic visualization capability.

While the API is implemented in MATLAB, computer-intensive bottleneck routines are implemented in C++ Mex functions, which are comparable with Fortran in speed. While MATLAB does support a Mex gateway for Fortran, only [Intel's Fortran compiler](https://software.intel.com/en-us/fortran-compilers) is [currently supported](https://mathworks.com/support/compilers.html); these compilers are not freely available on the Windows platform. In contrast, high quality Mex-compliant C++ compilers are freely available on all popular platforms.

The new tool exploits the MATLAB [Parallel Computing Toolbox](https://au.mathworks.com/products/parallel-computing.html) -- a high-level message passing interface -- to exploit the independence between distinct ray sequences, and thereby extract maximum benefit from the Radio Systems Group's new server.

### Objective 1: Ability to model 3D geometries

The new framework supports both 2D and 3D geometries, adopting the face-vertex layout already employed by MATLAB for representation of polygonal meshes in 2D and 3D.

### Objective 2: Realistic (complex) wall models

The new framework supports arbitrarily complex wall models.

The system dictates no particular local coordinate systems.
* Known symmetries in gain patterns may be completely exploited by the user i.e. there is no abstraction penalty.
* The user is free to define patterns any any convenient system of coordinates.

### Objective 3: Dynamic visualization capabilities

Users are able to exploit MATLAB's built-in routines to visualize arbitrarily complex scenes and fields. To this end, the new library offers the following specialised routines:

* Visualization of scene geometry and material assignments in 2D or 3D.
* Visualization of antenna patterns in 2D or 3D.
* Visualization of SINR thresholds in 2D or 3D via "oriented" isosurfaces.
* Visualization of reflected rays and transmission points.
* Labelling of arbitrary entities in 2D and 3D.

The system provides several new visualisation functions specific to its domain.

### Objective 4: Open Application Programming Interface (API)
 
At this point, we employ only scenes composed of rectangular facets (embedded in 3D, but not necessarily aligned with global coordinate axes); this reflects our current needs, but is not a restriction: more specialised axis-aligned quadrilaterals or general polygons would not be difficult to incorporate in future releases.
 
> We aim to make WyFy available to anyone in our activity sphere

The source repository, complete with an installation script, datasets, and scripts illustrating usage, is accessible via [GitHub](https://github.com).

_____________________________________________________________________
# Meeting, 24 January

- Extensive refactoring to improve modularity:
  - Code base is simpler, hence easier to understand and navigate
  - Flexible handling of local coordinate systems (penalty-free abstraction)
  - Use of [packages](https://au.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html) consistent with MATLAB's own directory structure
  - Reduced  amount of "boiler-plate" code required to configure a study
  - Any functionality not transferred is accessible in the [old `git` repository](https://github.com/jonpea/toolbox)
  
- Example scripts (in progress) to demonstrate key functionality e.g.

| Script in `examples.*`    | Illustrates                            | 
|---------------------------|----------------------------------------|
| `sceneDemo`      | Complex scene creation                          |
| `antennaDataDemo`, `antennaFormulaDemo`  | Antenna pattern creation and visualization |
| `interactiveSmallDemo`, `interactiveMediumDemo` | Interactive mode |
| `shieldedRoomDemo`   | Complete 2.5-D example (IEEE TAP)           |
| `newmarket2DDemo`, `newmarket2xDDemo` | Replication of `yzg001.f`  |

- Unit tests (in progress) e.g.

```matlab
>> unittest.runsuite(?rayoptics.UnitTests)
Running rayoptics.UnitTests
..........
........
Done rayoptics.UnitTests
```

- Let's please discuss objectives for the coming 10 days e.g.
  - Contributions to FRDF report
  - Additional resources for Part IV project student
  - Access to CST Server after January 31st
  - [Github](https://github.com) account for Michael
  - Time with Yuen and Michael
  - Further development (e.g. Linux/Mac support)
  - Would it be interesting to look at the MathWorks' [Antenna Toolbox](https://au.mathworks.com/help/antenna/index.html)?
  
- Proposed development work:
  - Simple example of optimization with [`bfo`](https://sites.google.com/site/bfocode)
  - Refinement of function to partition grid points between arbitrary rooms over multiple storeys
  - Further work on unit test suites
  - Further work on example scripts
  - Profiling example for [Embree](https://embree.github.io)-backed computation of transmission points

_Thank you!_
_____________________________________________________________________
# Geometric Optics Toolbox

## Overview

## Getting started

### Installation

The toolbox has been developed on Windows: If you are interested in another platform, please do [make contact](#contributors).

1. Clone the source repository.
```matlab
>> !git clone https://github.com/jonpea/toolbox-v2.git
>> cd toolbox-v2
```

2. Compile the relevant Mex-files for your platform.
```matlab
>> compile
```


3. Optionally, save the root folder to your MATLAB path.
```matlab
>> addpath(pwd, '-save')
```

4. Optionally, run the unit tests.
```matlab
>> runUnitTests
```

To test individual modules, use `unittest.runsuite` function e.g.
```matlab
>> unittest.runsuite(?rayoptics.UnitTests)
``` 

### Tutorials & examples

To see the index of supporting scripts:
```matlab
>> help +tutorial
>> help +examples
```

## Dependencies

|        Module | Description                                       |
|---------------|---------------------------------------------------|
| `+contracts`  | Support for `assert`                              |
| `+embree`     | Calculation of transmission points                |
| `+facevertex` | Representation of polygon complexes               |
| `+mex`        | Required for C++ back-end                         |
| `+parallel`   | Parallel reduction with `parreduce`               |
| `+structs`    | Efficient manipulation of tabular data            |
| `+sx`         | Utilities relating to array singleton-expansion   |

## Scene representation

See documentation on [Face-Vertex Companion](#face-vertex-companion).

## Antenna patterns

Within the ray-tracing system, propagation gains are evaluated on 
directions specified in global Cartesian coordinates. 
Any subsequent transformations are left to the client, who is able to 
exploit symmetries in the gain pattern and thereby eliminate the overhead 
that would be imposed by the system if directions were provided in a 
particular local coordinate frame.

## Reflection points

```matlab
[pairindices, pathPoints] = reflections(obj, sourcePoints, sinkPoints, faceIndices)
```

## Transmission points

```matlab
hits = transmissions(origins, directions, faceIndices)
```
|     Argument  | Description                                         |
|---------------|-----------------------------------------------------|
|     `origins` | Coordinates of source locations, one row per source |
|  `directions` | Coordinates of sink locations, one row per sink     |
| `faceIndices` | Indices of scene facets on the ray path of interest |

## Recommended practice

## Contributors

From the Radio Systems Group, Department of Electrical & Computer 
Engineering, at the University of Auckland:
- Yuen Zhuang Goh 
- Michael Neve
- Jon Pearce

## Related software

| Software                                                            |
|---------------------------------------------------------------------|
| [Antenna Toolbox](https://au.mathworks.com/help/antenna/index.html) | 
| [CST MWS Asymptotic Solver](https://www.cst.com/products/cstmws/solvers/asymptoticsolver) | 
| [Embree](https://embree.github.io)                                  |
| [OptiX](https://developer.nvidia.com/optix)                         |


## Feature requests

- [ ] Support for diffration.
- [ ] Support for surface waves.
- [ ] Complete interoperability with the MathWorks' [Antenna Toolbox](https://au.mathworks.com/help/antenna/index.html).

## Infrastructural TODO list

- [ ] Split git repository into modules.
- [ ] Complete set of unit tests.
- [ ] Profiling routines for critical functions.

## Appendix A: Geometric primitives

### Coordinates systems

For further details, see 
[Antenna Coordinate System](http://mathworks.com/help/antenna/gs/antenna-coordinate-system.html) 
of the [Antenna Toolbox](https://au.mathworks.com/help/antenna/index.html)'s 
documentation.

| Tag    | Name                         | Coordinates                     | Notes                                  |
|--------|------------------------------|---------------------------------|----------------------------------------|
| `cart` | Cartesian/Rectangular        | `x`, `y`, `z`                   |                                        |
| `pol`  | Polar                        | `az`, `r`, `z`                  |                                        |
| `sph`  | Spherical (elevation form)   | `az`/`theta`, `el`/`phi`, `r`   | `el`/`phi` is angle from `x`-`y` plane |
| `sphi` | Spherical (inclination form) | `az`/`phi`, `inc`/`theta`, `r`  | `inc`/`theta` is angle from `z` axis   |
| `uv`   | Normalized spherical         | `u`, `v`                        | Note currently supported               |

### Storage formats


#### 2-D grid functions
| Form       | Name         | Description                                |
|------------|--------------|--------------------------------------------|
| `f(X,Y)`   | full grid    | `X` and `Y` are matrices of identical size |
| `f({x,y})` | grid vectors | `x` and `y` are vectors                    |
| `f(xy)`    | unstructured | `xy` is a matrix with two columns          |

#### 3-D grid functions
| Form         | Name         | Description                                    |
|--------------|--------------|------------------------------------------------|
| `f(X,Y,Z)`   | full grid    | `X`, `Y`, `Z` are 3-D arrays of identical size |
| `f({x,y,z})` | grid vectors | `x`, `y`, `z` are vectors                      |
| `f(xyz)`     | unstructured | `xyz` is a matrix with three columns           |



## Appendix B: File formats


## Appendix C: Unit tests

## Appendix D: Directory structure

Functions are stored in whose names are chosen in accordance with those of MATLAB's standard library e.g.
```matlab
>> ls +specfun

.               affine.m        cart2sph.m      cart2usphi.m    dot.m           perp.m          todb.m          wrapcircle.m    
..              cart2circ.m     cart2sphi.m     circ2cart.m     elinc.m         sphi.m          usph2cart.m     wrapinterval.m  
UnitTests.m     cart2pol.m      cart2uqsphi.m   cross.m         fromdb.m        sphi2cart.m     usphi2cart.m    wrapquadrant.m  

>> which cart2sph
C:\Matlab\R2017b\Pro\toolbox\matlab\specfun\cart2sph.m
>> which cross
C:\Matlab\R2017b\Pro\toolbox\matlab\specfun\cross.m
>> which dot
C:\Matlab\R2017b\Pro\toolbox\matlab\specfun\dot.m
```
In cases where function names match those of the standard library, the interface extends that of the standard library e.g. `specfun.dot` supports singleton expansion whereas `dot` does not.

Each package directory contains:

| Name          | Description                                               |
|---------------|-----------------------------------------------------------|
| `UnitTests.m` | Class definition encapsulating a suite of unit tests      |
| `+tutorials`  | Sequence of tutorial scripts demonstrating core functions |


## Appendix E: Building `Embree`

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

_____________________________________________________________________
# Face-Vertex Companion

## Overview

## Face-vertex representation

Scenes are represented in the _face-vertex_ format supported by 
[`patch`](https://au.mathworks.com/help/matlab/ref/patch.html).

| Components | Description                                                       |
|------------|-------------------------------------------------------------------|
| Vertices   | Matrix with one row per vertex, entries are Cartesian coordinates |
| Faces      | Matrix with one row per polygon, entries indexing `Vertices`      |

Most toolbox functions allow `Faces` and `Vertices` to be provided as 
separate arrays or as members of a struct.

## Facet properties

A vector with an entry for each row of `Faces` may be used to join faces 
with a table of arbitrary material properties. See the tutorials for an 
example.

## Visualization

Scenes incorporating multiple material properties may be conveniently 
visualized with `multipatch`.
```matlab
>> help facevertex.multipatch
>> edit facevertex.examples.multipatch
```

## Replication and affine transformations 

```matlab
>> help facevertex.clone
>> edit facevertex.examples.clone
```

Affine transformations (translation, rotation, scaling, or combinations 
thereof) are applied to the scene by appying them to the columns of the 
`Vertices` array.

## Combining groups

```matlab
>> help facevertex.cat
>> help facevertex.compress
```

_____________________________________________________________________
# Parallel Computing Companion

```matlab
>> web(publish('examples.parreducedemo'))
```
