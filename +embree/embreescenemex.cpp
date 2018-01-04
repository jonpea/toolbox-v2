#include "embree.hpp"
#include "embreemex.hpp"
#include "mexfunction.hpp"
#include "mex.hpp"
#include "interface/class_handle.hpp"

#include <vector>

#pragma warning(disable: 4100)

namespace mx = ::matlab::mx;
namespace mex = ::matlab::mex;
using ::embree::embree_interface_type;

inline bool is_real(mx::const_array_ptr a)
{
    return mx::is_a<::embree::real_type>(a);
};

inline bool is_index(mx::const_array_ptr a)
{
    return mx::is_a<::embree::index_type>(a);
};

template<class T>
inline T & extract(mx::array_ptr wrapped)
{
    return *convertMat2Ptr<T>(wrapped);
}

inline void construct(int, mx::output_array plhs, int, mx::input_array)
{
#ifdef VERBOSE
    mexPrintf("Calling constructor...\n");
#endif
    auto embree = new embree_interface_type;
    plhs[0] = convertPtr2Mat<embree_interface_type>(embree);
#ifdef VERBOSE
    mexPrintf("Created device at %p\n", embree->device);
    mexPrintf(" Created scene at %p\n", embree->scene);
#endif
}

inline void clear(int, mx::output_array, int, mx::input_array prhs)
{
#ifdef VERBOSE
    auto const& embree = extract<embree_interface_type>(prhs[0]);
    mexPrintf(" Deleting scene at %p\n", embree.scene);
    mexPrintf("Deleting device at %p\n", embree.device);
#endif
    destroyObject<embree_interface_type>(prhs[0]);
}

inline void add_quadrilaterals(int, mx::output_array plhs, int, mx::input_array prhs)
{   
    auto & embree = extract<embree_interface_type>(prhs[0]);
    const auto
            faces = prhs[1],
            vertices = prhs[2];
    const auto
            num_faces = mx::size<1>(faces),
            num_vertices = mx::size<1>(vertices);
    
    ASSERT_MX_CLASS(faces, ::embree::index_type);
    ASSERT_MX_CLASS(vertices, ::embree::real_type);
    ASSERT_MX_NUM_ROWS(vertices, (3 + 1));
    ASSERT_MX_NUM_ROWS(faces, 4);
    
#ifdef VERBOSE
    mexPrintf("%u faces\n", num_faces);
    mexPrintf("%u vertices\n", num_vertices);    
    MEX_DISP(faces);
    MEX_DISP(vertices);
#endif
    
    using mx::data;
    typedef ::embree::index_type index_type;
    typedef ::embree::real_type real_type;
   const auto geometry_id = embree.add_quadrilaterals(
            data<index_type>(faces), num_faces,
            data<real_type>(vertices), num_vertices);
    
#ifdef VERBOSE
    mexPrintf("committed model ID %u\n", geometry_id);
#endif
    
    embree.total_num_faces += num_faces;
    plhs[0] = mxCreateDoubleScalar(geometry_id);
}

inline void intersect(
        int nlhs, mx::output_array plhs, 
        int nrhs, mx::input_array prhs)
{
    namespace mx = ::matlab::mx;
    namespace mex = ::matlab::mex;
    
    mex::num_outputs_check(nlhs, 1);
    mex::num_inputs_check(nrhs, 20);
    
    auto & embree = extract<embree_interface_type>(prhs[0]);
    const auto 
            origins = prhs[1],
            directions = prhs[2],
            tnear = prhs[3],
            tfar = prhs[4],
            mask = prhs[5],
            time = prhs[6],
            uv = prhs[7],
            inst_id = prhs[8],
            geom_id = prhs[9],
            prim_id = prhs[10];
    auto
            face_ray_register = prhs[11],
            face_index_buffer = prhs[12],
            ray_index_buffer = prhs[13],
            mesh_index_buffer = prhs[14],
            ray_parameter_buffer = prhs[15],
            face_coordinates_buffer = prhs[16], 
            face_normal_buffer = prhs[17], 
            hit_buffers_offset = prhs[18];
    const auto 
            face_masks = prhs[19];

    const auto num_faces = embree.total_num_faces;
    const auto 
            num_rays = mx::size<0>(origins),
            hit_capacity = mx::size<0>(face_index_buffer);
    
    auto check_ray_row_size = [&](auto const& a) -> bool
    {
        return mx::size<0>(a) == num_rays;
    };
    
    auto check_ray_buffer_row_size = [&](auto const& a) -> bool
    {
        return mx::size<0>(a) >= num_rays;
    };

    auto check_hit_buffer_row_size = [&](auto const& a) -> bool
    {
        return mx::size<0>(a) == hit_capacity;
    };

    using ::embree::index_type;
    using ::embree::real_type;
    
    ASSERT_MX_CLASS(origins, real_type);
    ASSERT_MX_CLASS(directions, real_type);
    ASSERT_MX_CLASS(tnear, real_type);
    ASSERT_MX_CLASS(tfar, real_type);
    ASSERT_MX_CLASS(mask, index_type);
    ASSERT_MX_CLASS(time, real_type);
    ASSERT_MX_CLASS(uv, real_type);
    ASSERT_MX_CLASS(inst_id, index_type);
    ASSERT_MX_CLASS(geom_id, index_type);
    ASSERT_MX_CLASS(prim_id, index_type);    
    ASSERT_MX_CLASS(face_ray_register, bool);
    ASSERT_MX_CLASS(face_index_buffer, index_type);
    ASSERT_MX_CLASS(ray_index_buffer, index_type);
    ASSERT_MX_CLASS(mesh_index_buffer, index_type);
    ASSERT_MX_CLASS(ray_parameter_buffer, real_type);
    ASSERT_MX_CLASS(face_coordinates_buffer, real_type);
    ASSERT_MX_CLASS(face_normal_buffer, real_type);    
    ASSERT_MX_CLASS(hit_buffers_offset, index_type);
    ASSERT_MX_CLASS(face_masks, bool);
    
    ASSERT_MX_MATRIX(origins);
    ASSERT_MX_MATRIX(directions);
    ASSERT_MX_MATRIX(tnear);
    ASSERT_MX_MATRIX(tfar);
    ASSERT_MX_MATRIX(mask);
    ASSERT_MX_MATRIX(time);
    ASSERT_MX_MATRIX(uv);
    ASSERT_MX_MATRIX(inst_id);
    ASSERT_MX_MATRIX(geom_id);
    ASSERT_MX_MATRIX(prim_id);    
    ASSERT_MX_MATRIX(face_ray_register);
    ASSERT_MX_MATRIX(face_index_buffer);
    ASSERT_MX_MATRIX(ray_index_buffer);
    ASSERT_MX_MATRIX(mesh_index_buffer);
    ASSERT_MX_MATRIX(ray_parameter_buffer);
    ASSERT_MX_MATRIX(face_coordinates_buffer);
    ASSERT_MX_MATRIX(face_normal_buffer);
    ASSERT_MX_SCALAR(hit_buffers_offset);
    ASSERT_MX_MATRIX(face_masks);
    
    ASSERT_MX_NUM_COLS(origins, 3);
    ASSERT_MX_NUM_COLS(directions, 3);
    
    mxAssert(
            mx::num_rows(face_ray_register) == num_faces &&
            mx::num_columns(face_ray_register) >= num_rays,
            "Face-ray register must accommodate every face-ray pairing");    
    mxAssert(
            check_ray_row_size(origins) &&
            check_ray_row_size(directions) &&
            check_ray_row_size(tnear) &&
            check_ray_row_size(tfar),
            "Ray data arrays should have indentical row dimensions");    
    mxAssert(
            check_ray_buffer_row_size(mask) &&
            check_ray_buffer_row_size(time) &&
            check_ray_buffer_row_size(uv) &&
            check_ray_buffer_row_size(inst_id) &&
            check_ray_buffer_row_size(geom_id) &&
            check_ray_buffer_row_size(prim_id),
            "Ray buffer should have at least as many rows as ray data arrays");    
    mxAssert(
            check_hit_buffer_row_size(face_index_buffer) &&
            check_hit_buffer_row_size(ray_index_buffer) && 
            check_hit_buffer_row_size(mesh_index_buffer) &&
            check_hit_buffer_row_size(ray_parameter_buffer) &&
            check_hit_buffer_row_size(face_coordinates_buffer) &&
            check_hit_buffer_row_size(face_normal_buffer),
            "Hit buffers should have identical row dimensions");    
    mxAssert(
            mx::num_elements(face_masks) == embree.total_num_faces,
            "Face mask array should have one element per scene facet");
    
#ifdef VERBOSE
    mexPrintf("Registering %u rays...\n", num_rays);
    MEX_DISP(origins);
    MEX_DISP(directions);
    MEX_DISP(hit_buffers_offset);
#endif
    
    const auto hit_offset = mx::scalar<index_type>(hit_buffers_offset);
    
    using mx::data;
    typedef ::embree::index_type index_type;
    typedef ::embree::real_type real_type;
    auto ray_data_and_buffers = ::embree::set_ray_buffers(
            data<real_type>(origins),
            data<real_type>(directions),
            data<real_type>(tnear),
            data<real_type>(tfar),
            data<index_type>(mask),
            data<real_type>(time),
            data<real_type>(uv),
            data<index_type>(inst_id),
            data<index_type>(geom_id),
            data<index_type>(prim_id),
            num_rays);
    
    auto hit_buffer = ::embree::set_hit_buffers(
        data<index_type>(face_index_buffer),
        data<index_type>(ray_index_buffer),
        data<index_type>(mesh_index_buffer),
        data<real_type>(ray_parameter_buffer),
        data<real_type>(face_coordinates_buffer),
        data<real_type>(face_normal_buffer),
        hit_capacity, 
        hit_offset);

    try
    {
        // Compute ray-facet intersections
        embree.intersect(
                ray_data_and_buffers,
                hit_buffer,
                data<bool>(face_masks), 
                data<bool>(face_ray_register),
                num_faces);
    }
    catch (::std::exception const& error)
    {
        mexErrMsgIdAndTxt(
                "EmbreeSceneMex:KnownException", 
                error.what());
    }
    catch (...)
    {
        mexErrMsgIdAndTxt(
                "EmbreeSceneMex:UnhandledException", 
                "Unhandled exception in Embree");
    }
    
    const auto num_hits = hit_buffer.size - hit_offset;
    
#ifdef VERBOSE
    mexPrintf("Computed %u intersections\n", num_hits);
    //for(auto interaction: embree.interactions.buffer) interaction.print();
#endif
            
    plhs[0] = mx::new_scalar(double(num_hits));    
}

void mexFunction(
        int nlhs, mx::output_array plhs,
        int nrhs, mx::input_array prhs)
{
    using namespace ::matlab::mex::function;
    dispatch(nlhs, plhs, nrhs, prhs,
    {
        {"new", {exactly(1), exactly(0), construct}},
        {"delete", {exactly(0), exactly(1), clear}},
        {"addmesh", {exactly(1), exactly(1 + 2), add_quadrilaterals}},
        {"intersect", {exactly(1 /*6*/), exactly(1 + 4 + 7 + 7 + 1), intersect}}
    });
}
