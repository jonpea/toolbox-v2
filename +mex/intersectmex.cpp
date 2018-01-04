#include <mex.h>
#include <omp.h>
#include <cassert>

#include "array_helpers.hpp"
#include "mex_helpers.hpp"

template<class T>
inline T intersect_body(
        T const* face_normals,
        T const* face_origins,
        T const* ray_directions,
        T const* ray_origins,
        size_t num_rays,
        size_t num_faces,
        size_t num_dimensions,
        size_t ray_id,
        size_t face_id)
{
    // Advice from MATLAB Central Answers (reference
    // 237411-can-i-make-use-of-openmp-in-my-matlab-mex-files):
    // "If you need to use API functions that allocate memory,
    //  do it outside of your parallel threads!"
    assert(num_dimensions <= 3);
    T difference[3];
    for (size_t dim = 0; dim < num_dimensions; ++dim)
        difference[dim] =
                get(face_origins, num_faces, face_id, dim) -
                get(ray_origins, num_rays, ray_id, dim);
    
    const T numerator = dot(
            getrow(face_normals, face_id), num_faces,
            difference, static_cast<size_t>(1),
            num_dimensions);
    
    const T denominator = dot(
            getrow(face_normals, face_id), num_faces,
            getrow(ray_directions, ray_id), num_rays,
            num_dimensions);
    
    return numerator / denominator;
}

template<class T>
inline void intersect(
        T const* face_normals,
        T const* face_origins,
        T const* ray_directions,
        T const* ray_origins,
        size_t num_rays,
        size_t num_faces,
        size_t num_dimensions,
        T * ratio)
{
#pragma omp parallel for collapse(2)
    for (size_t ray_id = 0; ray_id < num_rays; ++ray_id)
        for (size_t face_id = 0; face_id < num_faces; ++face_id)
        {
            // mexPrintf("thread %d of %d: (%d, %d)\n",
            //   omp_get_thread_num(), omp_get_num_threads(), ray_id, face_id);
            // if (ray_id == 0 && face_id == 0)
            // {
            //     size_t numthreads = omp_get_num_threads();
            //     size_t maxnumthreads = omp_get_max_threads();
            //     mexPrintf("** Using %d threads of %d **\n", numthreads, maxnumthreads);
            // }
            get(ratio, num_rays, ray_id, face_id) = intersect_body(
                    face_normals, face_origins, 
                    ray_directions, ray_origins,
                    num_rays, num_faces, num_dimensions, 
                    ray_id, face_id);
        }
}

/* The computational routine */
template<class T, class B>
        inline void select(
        T const* t,
        T const& tnear,
        T const& tfar,
        size_t num_rays,
        size_t num_faces,
        B * mask)
{
#pragma omp parallel for collapse(2)
    for (size_t face_id = 0; face_id < num_faces; ++face_id)
        for (size_t ray_id = 0; ray_id < num_rays; ++ray_id)
        {
            T const& element = get(t, num_rays, ray_id, face_id);
            get(mask, num_rays, ray_id, face_id) = 
                    (tnear <= element && element <= tfar);
        }
}

/* The gateway function */
void mexFunction(
        int nlhs, mxArray * plhs[],
        int nrhs, const mxArray * prhs[])
{
    typedef double real_type;
    
    mxAssert(nrhs == 6, "Six inputs required.");
    mxAssert(nlhs == 2, "Two outputs required.");
    
    const mxArray * face_normals = prhs[0];
    const mxArray * face_origins = prhs[1];
    const mxArray * ray_directions = prhs[2];
    const mxArray * ray_origins = prhs[3];
    const mxArray * tnear = prhs[4];
    const mxArray * tfar = prhs[5];
    
    mxAssert(is_real_double(face_normals), "First input must be real");
    mxAssert(is_real_double(face_origins), "Second input must be real");
    mxAssert(is_real_double(ray_directions), "Third input must be real");
    mxAssert(is_real_double(ray_origins), "Fourth input must be real");
    mxAssert(is_real_double(tnear), "Fifth input must be real");
    mxAssert(is_real_double(tfar), "Sixth input must be real");
    
    const size_t
            num_rays = static_cast<size_t>(mxGetM(ray_directions)),
            num_faces = static_cast<size_t>(mxGetM(face_normals)),
            num_dimensions = static_cast<size_t>(mxGetN(face_normals));
    
    mxAssert(
            mxGetM(face_normals) == num_faces &&
            mxGetM(face_origins) == num_faces, 
            "Row sizes on face origins & normals must match");
    mxAssert(
            mxGetM(ray_directions) == num_rays &&
            mxGetM(ray_origins) == num_rays &&
            mxGetM(tnear) == num_rays &&
            mxGetM(tfar) == num_rays,
            "Row sizes on ray origins & directions must match");
    
    mxAssert(
            mxGetN(face_origins) == num_dimensions &&
            mxGetN(ray_directions) == num_dimensions &&
            mxGetN(ray_origins) == num_dimensions, 
            "Column sizes on all inputs must match");
    
    mxArray * t = plhs[0] = mxCreateDoubleMatrix(
            static_cast<mwSize>(num_rays),
            static_cast<mwSize>(num_faces),
            mxREAL);
    
    mxArray * mask = plhs[1] = mxCreateLogicalMatrix(
            static_cast<mwSize>(num_rays),
            static_cast<mwSize>(num_faces));
    
    // For portability, don't explicitly fix the number of OpenMP threads
    //omp_set_num_threads(4);
    //mexPrintf("Using %d omp threads...\n", omp_get_num_threads());
    
    intersect(
            static_cast<real_type const*>(mxGetPr(face_normals)),
            static_cast<real_type const*>(mxGetPr(face_origins)),
            static_cast<real_type const*>(mxGetPr(ray_directions)),
            static_cast<real_type const*>(mxGetPr(ray_origins)),
            num_rays, num_faces, num_dimensions,
            static_cast<real_type *>(mxGetPr(t)));
    
    select(
            static_cast<real_type const*>(mxGetPr(t)),
            *static_cast<real_type const*>(mxGetPr(tnear)),
            *static_cast<real_type const*>(mxGetPr(tfar)),
            num_rays,
            num_faces,
            static_cast<mxLogical *>(mxGetData(mask)));
}
