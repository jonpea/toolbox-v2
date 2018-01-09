#include "mex.hpp"
#include "ray_tracing.hpp"

namespace mex = ::matlab::mex;
namespace mx = ::matlab::mx;
namespace rt = ::ray_tracing;

template<int NumDims> inline
        bool dispatcher(
        // Inputs
        mx::const_array_ptr face_origins,
        mx::const_array_ptr face_normals,
        mx::const_array_ptr face_offsets,
        mx::const_array_ptr offset_to_local_map,
        mx::const_array_ptr face_masks,
        const mx::size_type num_faces,
        mx::const_array_ptr ray_origins,
        mx::const_array_ptr ray_directions,
        mx::const_array_ptr t_near,
        mx::const_array_ptr t_far,
        const mx::size_type num_rays,
        // Outputs
        mx::array_ptr face_index_buffer,
        mx::array_ptr ray_index_buffer,
        mx::array_ptr ray_parameter_buffer,
        mx::array_ptr point_buffer,
        mx::array_ptr face_coordinates_buffer,
        // State variables
        rt::size_type & face_id,
        rt::size_type & ray_id,
        mx::size_type & buffer_offset)
{
    typedef rt::vector<NumDims - 1> facet_vector;
    typedef rt::vector<NumDims> spatial_vector;
    typedef ::std::array<spatial_vector, NumDims - 1> coordinate_map;
    
    using mx::data;
    using mx::scalar;
    
    const auto hit_capacity = mx::num_columns(face_index_buffer);
    
    /*rt::size_type num_hits = 0;*/
    
    const bool success = rt::intersect<NumDims>(
            // Inputs
            data<spatial_vector>(face_origins),
            data<spatial_vector>(face_normals),
            data<rt::real_type>(face_offsets),
            data<coordinate_map>(offset_to_local_map),
            data<bool>(face_masks),
            num_faces,
            data<spatial_vector>(ray_origins),
            data<spatial_vector>(ray_directions),
            scalar<rt::real_type>(t_near),
            scalar<rt::real_type>(t_far),
            num_rays,
            // Outputs
            data<rt::index_type>(face_index_buffer) /*+ buffer_offset*/,
            data<rt::index_type>(ray_index_buffer) /*+ buffer_offset*/,
            data<rt::real_type>(ray_parameter_buffer) /*+ buffer_offset*/,
            data<spatial_vector>(point_buffer) /*+ buffer_offset*/,
            data<facet_vector>(face_coordinates_buffer) /*+ buffer_offset*/,
            hit_capacity,
            // State variables
            face_id,
            ray_id,
            buffer_offset /*num_hits*/);
    
    /*buffer_offset += num_hits;*/
    
    // =====>>
    // mexPrintf("--- All %u recorded hits ---\n", buffer_offset);
    // for (mx::size_type num_hits = 0; num_hits < buffer_offset; ++num_hits)
    // {
    //     mexPrintf("        num_hits = %u\n", num_hits);
    //     mexPrintf("         face_id = %u\n", data<rt::index_type>(face_index_buffer)[num_hits]);
    //     mexPrintf("          ray_id = %u\n", data<rt::index_type>(ray_index_buffer)[num_hits]);
    //     mexPrintf("   ray_parameter = %g\n", data<rt::real_type>(ray_parameter_buffer)[num_hits]);
    //     // mexPrintf("face_coordinates = (%g, %g)\n",
    //     //         face_coordinates_buffer[num_hits][0],
    //     //         face_coordinates_buffer[num_hits][1]);
    //     mexPrintf("----------------------------------------\n");
    // }
    // <<=====
    
    return success;
}

void mexFunction(
        int nlhs, mx::output_array plhs,
        int nrhs, mx::input_array prhs)
{
    mex::num_outputs_check(nlhs, 4);
    mex::num_inputs_check(nrhs, 17);
    
    const auto
            face_origins = prhs[0],
            face_normals = prhs[1],
            face_offsets = prhs[2],
            offset_to_local_map = prhs[3],
            face_masks = prhs[4],
            ray_origins = prhs[5],
            ray_directions = prhs[6],
            t_near = prhs[7],
            t_far = prhs[8];
    auto
            face_index_buffer = prhs[9],
            ray_index_buffer = prhs[10],
            ray_parameter_buffer = prhs[11],
            point_buffer = prhs[12],
            face_coordinates_buffer = prhs[13],
            buffer_row_offset = prhs[14];
    
    auto
            face_id_ptr = prhs[15],
            ray_id_ptr = prhs[16];
    
    const auto
            num_dimensions = mx::num_rows(face_normals),
            num_faces = mx::num_columns(face_normals),
            num_rays = mx::num_columns(ray_origins);
    
    auto has_ray_size = [&](auto const& a) -> bool
    {
        return mx::num_rows(a) == num_dimensions
                && mx::num_columns(a) == num_rays;
    };
    
    auto has_buffer_size = [&](auto const& a) -> bool
    {
        return mx::num_columns(a) == hit_capacity;
    };
    
    ASSERT_MX_CLASS(face_origins, rt::real_type);
    ASSERT_MX_CLASS(face_normals, rt::real_type);
    ASSERT_MX_CLASS(face_offsets, rt::real_type);
    ASSERT_MX_CLASS(offset_to_local_map, rt::real_type);
    ASSERT_MX_CLASS(face_masks, bool);
    ASSERT_MX_CLASS(ray_origins, rt::real_type);
    ASSERT_MX_CLASS(ray_directions, rt::real_type);
    ASSERT_MX_CLASS(t_near, rt::real_type);
    ASSERT_MX_CLASS(t_far, rt::real_type);
    
    ASSERT_MX_CLASS(face_index_buffer, rt::index_type);
    ASSERT_MX_CLASS(ray_index_buffer, rt::index_type);
    ASSERT_MX_CLASS(ray_parameter_buffer, rt::real_type);
    ASSERT_MX_CLASS(point_buffer, rt::real_type);
    ASSERT_MX_CLASS(face_coordinates_buffer, rt::real_type);
    
    ASSERT_MX_CLASS(face_id_ptr, rt::size_type);
    ASSERT_MX_CLASS(ray_id_ptr, rt::size_type);
    
    ASSERT_MX_MATRIX(face_origins);
    ASSERT_MX_MATRIX(face_normals);
    ASSERT_MX_MATRIX(face_offsets);
    
    // The following assertion is *not* used because MATLAB regards
    // MxNx1 arrays as 2D, which introduces an exceptional case.
    //ASSERT_MX_TRIPLE(offset_to_local_map);
    
    ASSERT_MX_MATRIX(face_masks);
    ASSERT_MX_MATRIX(ray_origins);
    ASSERT_MX_MATRIX(ray_directions);
    ASSERT_MX_SCALAR(t_near);
    ASSERT_MX_SCALAR(t_far);
    
    ASSERT_MX_MATRIX(face_index_buffer);
    ASSERT_MX_MATRIX(ray_index_buffer);
    ASSERT_MX_MATRIX(ray_parameter_buffer);
    ASSERT_MX_MATRIX(point_buffer);
    ASSERT_MX_MATRIX(face_coordinates_buffer);
    
    ASSERT_MX_SCALAR(face_id_ptr);
    ASSERT_MX_SCALAR(ray_id_ptr);
    
    ASSERT_MX_NUM_ROWS(face_origins, num_dimensions);
    ASSERT_MX_NUM_ROWS(face_normals, num_dimensions);
    ASSERT_MX_NUM_ROWS(face_offsets, 1);
    ASSERT_MX_NUM_ROWS(face_masks, 1);
    ASSERT_MX_NUM_COLS(face_origins, num_faces);
    ASSERT_MX_NUM_COLS(face_normals, num_faces);
    ASSERT_MX_NUM_COLS(face_offsets, num_faces);
    ASSERT_MX_NUM_COLS(face_masks, num_faces);
    
    mxAssert(
            mx::size<0>(offset_to_local_map) == num_dimensions &&
            mx::size<1>(offset_to_local_map) == num_dimensions - 1 &&
            mx::size<2>(offset_to_local_map) == num_faces,
            "Unexpected size in array of offset-to-facet coeffcients");
    mxAssert(
            has_ray_size(ray_origins) &&
            has_ray_size(ray_directions),
            "Unexpected size in ray array");
    mxAssert(
            has_buffer_size(face_index_buffer) &&
            has_buffer_size(ray_index_buffer) &&
            has_buffer_size(ray_parameter_buffer) &&
            has_buffer_size(point_buffer) &&
            has_buffer_size(face_coordinates_buffer),
            "Unexpected size in buffer array");
    
    mxAssert(2 == num_dimensions || num_dimensions == 3,
            "The number of spatial dimensions must be 2 or 3.");
    const std::function<decltype(dispatcher<2>)> dispatch =
            (num_dimensions == 2) ? &dispatcher<2> : &dispatcher<3>;
            
    auto & buffer_offset = *mx::data<mx::size_type>(buffer_row_offset);

    rt::size_type
            & face_id = *mx::data<rt::size_type>(face_id_ptr),
            & ray_id = *mx::data<rt::size_type>(ray_id_ptr);

    bool success = false; // to be assigned within try block

    try
    {
        success = dispatch(
                // Inputs: Faces
                face_origins,
                face_normals,
                face_offsets,
                offset_to_local_map,
                face_masks,
                num_faces,
                // Inputs: Rays
                ray_origins,
                ray_directions,
                t_near,
                t_far,
                num_rays,
                // Outputs: Hits
                face_index_buffer,
                ray_index_buffer,
                ray_parameter_buffer,
                point_buffer,
                face_coordinates_buffer,
                // State variables
                face_id,
                ray_id,
                buffer_offset);
    }
    catch (::std::exception const& error)
    {
        mexErrMsgIdAndTxt(
                "PlanarIntersectionMex:KnownException",
                error.what());
    }
    catch (...)
    {
        mexErrMsgIdAndTxt(
                "PlanarIntersectionMex:UnhandledException",
                "Unhandled exception");
    }

    plhs[0] = mx::new_scalar(success);
    plhs[1] = mx::new_scalar(face_id);
    plhs[2] = mx::new_scalar(ray_id);
    plhs[3] = mx::new_scalar(buffer_offset);
}
