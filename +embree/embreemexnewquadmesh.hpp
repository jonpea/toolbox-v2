#ifndef INCLUDED_EMBREEMEXNEWQUADMESH_HPP
#define INCLUDED_EMBREEMEXNEWQUADMESH_HPP

#include "embreemex.hpp"

#define SHARED_GEOMETRY
#undef SHARED_GEOMETRY // to enable shared geometry, comment out this line

namespace embreemex
{

    inline index_type commit_quad_model(
            RTCScene scene, 
            index_type const* shared_quad_buffer,
            const index_type num_faces,
            real_type const* shared_vertex_buffer,
            const index_type num_vertices)
    {        
        const index_type zero_offset(0u);
        
#ifdef VERBOSE
        mexPrintf("registering new quad mesh: %u faces, %u vertices...\n",
                num_faces, num_vertices);
#endif
        index_type geometry_id = rtcNewQuadMesh2(
                scene, RTC_GEOMETRY_STATIC, num_faces, num_vertices,
                1 /* RTC_INVALID_GEOMETRY_ID */);
        
#ifdef VERBOSE
        mexPrintf("assigning vertex buffer: %u vertices...\n",
                num_vertices);
        mexPrintf("vertices = [\n");
        for (index_type j = 0; j < num_vertices; ++j)
        {
            for (index_type i = 0; i < (3u + 1u); ++i)
                mexPrintf("%g ", shared_vertex_buffer[i + (3 + 1)*j]);
            mexPrintf(" // vertex %u\n", j);
        }
        mexPrintf("]\n");
#endif
        
#ifdef SHARED_GEOMETRY
        rtcSetBuffer2(
                scene, geometry_id, RTC_VERTEX_BUFFER,
                shared_vertex_buffer,
                zero_offset,
                sizeof(real_type)*(3 + 1), // three coordinates + padding
                num_vertices);
#else
        real_type * vertices = static_cast<real_type *>(
                rtcMapBuffer(scene, geometry_id, RTC_VERTEX_BUFFER));
        for (index_type j = 0; j < num_vertices; ++j)
        {
            for (index_type i = 0; i < 3u; ++i)
                *vertices++ = shared_vertex_buffer[i + (3u + 1u)*j];
            // Embree requires padding so array is "four-byte-aligned"
            *vertices++ = std::numeric_limits<real_type>::signaling_NaN();
        }
        rtcUnmapBuffer(scene, geometry_id, RTC_VERTEX_BUFFER);
#endif
        
#ifdef VERBOSE
        mexPrintf("assigning connection buffer: %u faces...\n", 
                num_faces);
        mexPrintf("faces = [\n");
        for (index_type j = 0; j < num_faces; ++j)
        {
            for (index_type i = 0; i < 4u; ++i)
                mexPrintf("%u ", shared_quad_buffer[i + 4*j]);        
            mexPrintf(" // face %u\n", j);
        }
        mexPrintf("]\n");
#endif

#ifdef SHARED_GEOMETRY        
        rtcSetBuffer2(
                scene, geometry_id, RTC_INDEX_BUFFER,
                shared_quad_buffer,
                zero_offset,
                sizeof(index_type)*4, // four vertex indices per quad
                num_faces);
#else
        index_type * quads = static_cast<index_type *>(
                rtcMapBuffer(scene, geometry_id, RTC_INDEX_BUFFER));
        for (index_type j = 0; j < num_faces; ++j)
            for (index_type i = 0; i < 4u; ++i)
                *quads++ = shared_quad_buffer[i + 4*j];
        rtcUnmapBuffer(scene, geometry_id, RTC_INDEX_BUFFER);        
#endif

#ifdef VERBOSE
        mexPrintf("assigning filter function...\n");
#endif
        // Filter function must be registered *before* committing scene
        rtcSetIntersectionFilterFunctionN(
                scene, geometry_id, embreemex::filter_function);
        
#ifdef VERBOSE
        mexPrintf("creating BVH tree...\n");
#endif
        // Build bounding volume hierarchy (BVH) tree 
        rtcCommit(scene); 
        
#ifdef VERBOSE
        mexPrintf("returning geometry ID...\n");
#endif        
        return geometry_id;
    }
    
} // namespace

#endif // INCLUDED_EMBREEMEXNEWQUADMESH_HPP
