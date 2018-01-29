//
// embree.hpp
// Part of a MATLAB Mex interface to Intel's Embree
//      https://embree.github.io/api.html
// ray-tracing library.
//

#ifndef INCLUDED_EMBREE_HPP
#define INCLUDED_EMBREE_HPP

#ifdef VERBOSE
#include <mex.h> // for mexPrintf
#endif

#pragma warning(push)
#pragma warning(disable: 4290)
#pragma warning(disable: 4324)
#include <embree2/rtcore.h>
#include <embree2/rtcore_ray.h>
#pragma warning(pop)

#include <algorithm> // for std::fill_n etc.
#include <cstdint> // for std::uint32_t
#include <stdexcept> // for std::length_error

namespace embree {

// Common types.
typedef ::std::size_t size_type;
typedef ::std::uint32_t index_type; // see embree::QuadMesh::Quad::v
typedef float real_type;

// See section "Filter Functions" in Embree documentation:
// "For the callback RTCFilterFuncN ... (0 means invalid and -1 means valid)."
enum ray_state: int { invalid = 0, valid = -1 };

// Augments Embree's internal ray data structure with its current size.
struct ray_buffers_container
{
    RTCRayNp pointers;
    size_type size;
};

// Initializes Embree's internal buffers.
inline ray_buffers_container set_ray_buffers(
        // Ray data
        real_type * origins,    // 0 (3 columns)
        real_type * directions, // 1 (3 columns)
        real_type * tnear,      // 2
        real_type * tfar,       // 3
        index_type * mask,      // 4
        real_type * time,       // 5
        // Hit data
        real_type * uv,         // 6 (2 columns)
        index_type * inst_id,   // 7
        index_type * geom_id,   // 8
        index_type * prim_id,   // 9
        const std::size_t num_rays)
{
    ray_buffers_container buffers;
    buffers.size = num_rays;
    RTCRayNp & pointers = buffers.pointers;

    // Ray data
    pointers.orgx = origins + 0*num_rays;
    pointers.orgy = origins + 1*num_rays;
    pointers.orgz = origins + 2*num_rays;

    pointers.dirx = directions + 0*num_rays;
    pointers.diry = directions + 1*num_rays;
    pointers.dirz = directions + 2*num_rays;

    pointers.tnear = tnear;
    pointers.tfar = tfar;

    pointers.mask = mask; // ray index
    pointers.time = time; // intersection distance

    // Hit data
    pointers.u = uv + 0*num_rays;
    pointers.v = uv + 1*num_rays;
    pointers.instID = inst_id;
    pointers.geomID = geom_id;
    pointers.primID = prim_id;

    // Initialize buffers
    {
        // Fill mask array with integer identifiers
        index_type count = 1u; // NB: Never use zero mask as ray index
        std::generate_n(pointers.mask, num_rays, [&count]
        {   // Embree's use of "mask" is a perhaps misleading:
            // In fact, these are indices, not boolean values.
            return count++;
        });
        const auto fill = [num_rays](auto begin, auto value) -> void
        {
            ::std::fill_n(begin, num_rays, value);
        };
        const auto infinity =
                std::numeric_limits<real_type>::infinity();
        fill(pointers.time, infinity);
        fill(pointers.u, infinity);
        fill(pointers.v, infinity);
        fill(pointers.instID, RTC_INVALID_GEOMETRY_ID);
        fill(pointers.geomID, RTC_INVALID_GEOMETRY_ID);
        fill(pointers.primID, RTC_INVALID_GEOMETRY_ID);
    }

    return buffers;
}

// Encapsulates a stream of ray-facet hits.
struct hit_buffers_container
{
    typedef index_type * index_pointer;
    typedef real_type * real_pointer;
    index_pointer
            face_index,
            ray_index,
            mesh_index;
    real_pointer
            ray_parameter,
            face_coordinates,
            face_normals;
    size_type
            capacity,
            size;
};

inline hit_buffers_container set_hit_buffers(
        index_type * face_index,
        index_type * ray_index,
        index_type * mesh_index,
        real_type * ray_parameter,
        real_type * face_coordinates,
        real_type * face_normal,
        size_type const& capacity, // hits/rows cf. elements
        size_type const& offset) 
{
    hit_buffers_container pointers;
    pointers.size = offset; // index_type(0u); // "initially empty"
    pointers.face_index = face_index;
    pointers.ray_index = ray_index;
    pointers.mesh_index = mesh_index;
    pointers.ray_parameter = ray_parameter;
    pointers.face_coordinates = face_coordinates;
    pointers.face_normals = face_normal;
    pointers.capacity = capacity;
    return pointers;
}

// Encapsulates filter function user-data, 
// extracted via RTCIntersectContext::userRayExt.
struct filter_data_container
{
    hit_buffers_container & hit_buffers;
    bool const* face_masks;
    bool * face_ray_register;
    size_type num_faces;
    explicit filter_data_container(
            hit_buffers_container & hit_buffers,
            bool const* face_masks,
            bool * face_ray_register,
            size_type const& num_faces): 
        hit_buffers(hit_buffers), 
        face_masks(face_masks), 
        face_ray_register(face_ray_register),
        num_faces(num_faces)
    { }
};

// Embree-compatible filter function 
inline void filter_function(
        int * valid,
        void * /*userDataPtr*/, // using context->userRayExt instead
        const RTCIntersectContext * context,
        RTCRayN * rays, // not required for "any-hit" (cf. "all-hit" or "any")
        const RTCHitN * hits,
        const size_t num_hits) /* throw(std::runtime_error) */
{
	// Retrieve user-data
    auto & filter_data = 
            *static_cast<filter_data_container *>(context->userRayExt);
    const auto num_faces = filter_data.num_faces;
    auto & buffer = filter_data.hit_buffers;
            
	// Check buffer capacity		
    if (buffer.capacity < buffer.size + num_hits)
        throw ::std::length_error("Embree output buffer has insufficient capacity");
    
	// Returns true if a hit (face-ray pairing) has already 
	// been registered, so as to filter out duplicate hits.
    const auto registered = 
            [&filter_data](auto face_index, auto ray_index) -> bool
    {
        // Convert subscripts [face, ray] to linear index
        const auto
                column = ray_index - 1, // convert to base-0
                row = face_index; // already base-0
        const auto num_rows = filter_data.num_faces;
        if (column < 0) throw ::std::runtime_error("Bad index");
        const auto index = row + num_rows*column;
        
        // Reference to element of face-ray registry
        bool & entry = filter_data.face_ray_register[index];        
        const bool old_value = entry; // copy of current value
        entry = true; // register this hit (no change if already registered)
        
        return old_value;
    };
    
#ifdef VERBOSE
    mexPrintf("======== Filtering %u hits ========\n", num_hits);
    mexPrintf("Initial buffer size %u\n", buffer.size);
#endif    
    size_t valid_hit_counter = 0;
    for (size_t hit_index = 0; hit_index < num_hits; hit_index++)
    {
#ifdef VERBOSE
        mexPrintf("Checking Hit %u@%u...\n", 
                RTCRayN_mask(rays, num_hits, hit_index), 
                RTCHitN_primID(hits, num_hits, hit_index));
        mexPrintf("     valid = %i\n", valid[hit_index] == ray_state::valid);
        mexPrintf("ray_parameter = %g\n", RTCHitN_t(hits, num_hits, hit_index));
        mexPrintf("face_coordinates[0] = %g\n", RTCHitN_u(hits, num_hits, hit_index));
        mexPrintf("face_coordinates[1] = %g\n", RTCHitN_v(hits, num_hits, hit_index));
#endif
		// Skip hits marked "invalid"
        if (valid[hit_index] != ray_state::valid) continue;
        
        const auto face_index = RTCHitN_primID(hits, num_hits, hit_index);
        const auto ray_index = RTCRayN_mask(rays, num_hits, hit_index);
        
		// Skip hits on marked facets
		// e.g. some hits might be known reflection points.
        if (!filter_data.face_masks[face_index]) 
        {
#ifdef VERBOSE
            mexPrintf("skipping embree face_index %u...\n", face_index);
#endif
            continue; // hits on this face are to be ignored
        }
        
		// Ignore hits that have already been registered
		// since Embree doesn't guaranteed uniqueness
        if (registered(face_index, ray_index)) 
        {
#ifdef VERBOSE
            mexPrintf("Skipping duplicate RayIndex = %u, FaceIndex = %u...\n", ray_index, face_index);
#endif
            continue; // this hit/pairing has already been registered
        }
        
        // For "all-hits" userRayExt
        valid[hit_index] = ray_state::invalid;

        const size_t
                buffer_index = buffer.size + valid_hit_counter,
                stride = buffer.capacity;

#ifdef VERBOSE
        mexPrintf("       buffer_index = %u\n", buffer_index); 
#endif
                
		// Record/register the current hit		
        buffer.face_index[buffer_index] = face_index + 1; // convert base-0 to base-1
        buffer.ray_index[buffer_index] = ray_index; // already base-1
        buffer.mesh_index[buffer_index] = RTCHitN_geomID(hits, num_hits, hit_index);
        buffer.ray_parameter[buffer_index] = RTCHitN_t(hits, num_hits, hit_index);
        buffer.face_coordinates[buffer_index + 0*stride] = RTCHitN_u(hits, num_hits, hit_index);
        buffer.face_coordinates[buffer_index + 1*stride] = RTCHitN_v(hits, num_hits, hit_index);
        buffer.face_normals[buffer_index + 0*stride] = RTCHitN_Ng_x(hits, num_hits, hit_index);
        buffer.face_normals[buffer_index + 1*stride] = RTCHitN_Ng_y(hits, num_hits, hit_index);
        buffer.face_normals[buffer_index + 2*stride] = RTCHitN_Ng_z(hits, num_hits, hit_index);
        ++valid_hit_counter;
    }

	// Record the number of new hits added to the buffer
    buffer.size += valid_hit_counter;
#ifdef VERBOSE
    mexPrintf("Increased buffer size by %d to %d\n", 
            valid_hit_counter, buffer.size);
#endif
}

// Returns the name of the enumeration associated an Embree error code.
inline std::string error_string(const RTCError code)
{
    switch (code)
    {
        case RTC_UNKNOWN_ERROR: return "RTC_UNKNOWN_ERROR";
        case RTC_INVALID_ARGUMENT: return "RTC_INVALID_ARGUMENT";
        case RTC_INVALID_OPERATION: return "RTC_INVALID_OPERATION";
        case RTC_OUT_OF_MEMORY: return "RTC_OUT_OF_MEMORY";
        case RTC_UNSUPPORTED_CPU: return "RTC_UNSUPPORTED_CPU";
        case RTC_CANCELLED: return "RTC_CANCELLED";
        default: return "invalid error code";
    }
}

// Embree-compatible error handling call-back: 
// Throws an exception whose message points to the 
// appropriate part of Embree's documentation.
inline void error_handler(
        void * /*userPtr*/,
        const RTCError code,
        const char * /*str*/ = nullptr)  /* throw(std::runtime_error) */
{
    if (code == RTC_NO_ERROR) return;
    using std::string;
    const string message =
            string("Please search for ") +
            error_string(code) +
            string(" in Embree documentation");
    throw std::runtime_error(message.c_str());
}

class embree_interface_type
{
public:
    RTCDevice device;
    RTCScene scene;
    size_type total_num_faces;
    bool is_scene_committed;

public:
    embree_interface_type() /* throw(std::runtime_error) */
    : total_num_faces(0u), is_scene_committed(false)
    {
		// Instantiate Embree device
        this->device = rtcNewDevice(nullptr); // "verbose = 1"

		// Register compatible error handler
        error_handler(nullptr, rtcDeviceGetError(this->device));
        rtcDeviceSetErrorFunction2(
                this->device,
                error_handler,
                nullptr);

	    // Ensure that Embree was not build with back-face culling enabled:
		// In that case intersections would only be registered on rays
		// impinging on one side of a given facet.
        if (rtcDeviceGetParameter1i(this->device, RTC_CONFIG_BACKFACE_CULLING))
            throw std::runtime_error("Embree was built with EMBREE_BACKFACE_CULLING");

		// Instantiate Embree scene
        this->scene = rtcDeviceNewScene(
                this->device,
                RTC_SCENE_STATIC | RTC_SCENE_INCOHERENT,
                RTC_INTERSECT_STREAM);
    }

    ~embree_interface_type()
    {
        // NB: Using rtcDeleteGeometry seems to cause Embree to crash.
        // for (auto id: geometry_ids) rtcDeleteGeometry(scene, id);
        rtcDeleteScene(this->scene);
        rtcDeleteDevice(this->device);
    }

	// Default copy constructor
    embree_interface_type(embree_interface_type &&) = default;

	// Add quadrilateral facets to Embree scene
    index_type add_quadrilaterals(
            index_type const* quads,
            const size_type num_faces,
            real_type const* vertices,
            const size_type num_vertices)
    {
        index_type geometry_id = rtcNewQuadMesh2(
                this->scene,
                RTC_GEOMETRY_STATIC,
                num_faces,
                num_vertices);

        // Register array of vertex coordinates
        {
            auto vertex_buffer =
                    static_cast<real_type *>(rtcMapBuffer(
                    this->scene, geometry_id, RTC_VERTEX_BUFFER));
            for (index_type j = 0u; j < num_vertices; ++j)
            {
                for (index_type i = 0u; i < 3u; ++i)
                    *vertex_buffer++ = vertices[i + (3u + 1u)*j];
                // Embree requires padding so array is "four-byte-aligned"
                *vertex_buffer++ = std::numeric_limits<real_type>::signaling_NaN();
            }
            rtcUnmapBuffer(this->scene, geometry_id, RTC_VERTEX_BUFFER);
        }

        // Register array of connection indices
        {
            auto index_buffer = static_cast<index_type *>(
                    rtcMapBuffer(this->scene, geometry_id, RTC_INDEX_BUFFER));
            for (index_type j = 0u; j < num_faces; ++j)
                for (index_type i = 0u; i < 4u; ++i)
                    *index_buffer++ = quads[i + 4*j];
            rtcUnmapBuffer(this->scene, geometry_id, RTC_INDEX_BUFFER);
        }

        // Filter function must be registered *before* committing scene
        rtcSetIntersectionFilterFunctionN(
                this->scene, geometry_id, filter_function);

        // Build bounding volume hierarchy (BVH) tree
        rtcCommit(this->scene);
        this->is_scene_committed = true;

        return geometry_id;
    }

	// Calculate all intersections of given rays with scene facets.
    size_type intersect(
            ray_buffers_container & rays,
            hit_buffers_container & hits, 
            bool const* face_masks,
            bool * face_ray_register,
            size_type const& num_faces)
    {
        filter_data_container filter_data(
                hits, face_masks, face_ray_register, num_faces);
        RTCIntersectContext context;
        context.flags = RTC_INTERSECT_INCOHERENT;
        context.userRayExt = &filter_data;
#ifdef VERBOSE
        mexPrintf("Intersecting %u rays...\n", rays.size);
#endif
        rtcIntersectNp(this->scene, &context, rays.pointers, rays.size);
#ifdef VERBOSE
        mexPrintf("Embree recorded %u hits\n", hits.size);
#endif
        return hits.size;
    }

};

} // namespace

#endif // INCLUDED_EMBREE_HPP
