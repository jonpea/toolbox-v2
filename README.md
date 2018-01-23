# Meeting, 24 January

- Extensive refactoring to improve modularity 
  - Code base is simpler, hence easier to understand and navigate 
  - Flexible handling of local coordinate systems (penalty-free abstraction)
  - Use of [packages](https://au.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html) consistent with MATLAB's own directory structure
  - Reduced  amount of "boiler-plate" code required to configure a study

- Example scripts (in progress) to demonstrate key functionality e.g.

| Script                                  | Illustrates                        |
|-----------------------------------------|------------------------------------|
| `examples.sceneDemo`                    | Complex scene creation             |
| `examples.antennaDemo`                  | Antenna creation and visualization |
| `examples.interactive2`, `interactive3` | Interactive mode                   |
| `examples.shieldedRoomDemo`             | Complete 2.5-D example (paper)     |

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
  - Time with Yuen and Michael.
  
- Proposed development work:
  - Simple example of optimization with [`bfo`](https://sites.google.com/site/bfocode).
  - Refinement of function to partition grid points between arbitrary rooms over multiple storeys.
  - Further work on unit test suites.
  - Further work on example scripts.
  - Profiling example for [Embree](https://embree.github.io)-backed computation of transmission points.

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

## Feature requests

- [ ] Split git repository into modules.
- [ ] Complete set of unit tests.
- [ ] Profiling routines for critical functions.
- [ ] Complete interoperability with the MathWorks' [Antenna Toolbox](https://au.mathworks.com/help/antenna/index.html).


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
