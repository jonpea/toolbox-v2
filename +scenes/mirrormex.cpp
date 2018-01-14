#include "mex.hpp"
#include "ray_tracing.hpp"
#include <tuple> // for std::tuple_size

namespace mex = ::matlab::mex;
namespace mx = ::matlab::mx;
namespace rt = ::ray_tracing;

template<int NumDims> inline 
void dispatcher(
        mx::const_array_ptr face_normal,
        mx::const_array_ptr face_offset,
        mx::const_array_ptr original_points,
        mx::array_ptr mirrored_points,
        mx::size_type num_points)
{
    typedef rt::vector<NumDims> spatial_vector;
    rt::mirror<NumDims>(
            *mx::data<spatial_vector>(face_normal),
            mx::scalar<rt::real_type>(face_offset),
            mx::data<spatial_vector>(original_points),
            mx::data<spatial_vector>(mirrored_points),
            num_points);
}

void mexFunction(
        int nlhs, mx::output_array plhs,
        int nrhs, mx::input_array prhs)
{
    mex::num_outputs_check(nlhs, 0);
    mex::num_inputs_check(nrhs, 4);

    const auto
            face_normal = prhs[0],
            face_offset = prhs[1],
            original_points = prhs[2];
    auto mirrored_points = prhs[3];
    
    ASSERT_MX_CLASS(face_normal, rt::real_type);
    ASSERT_MX_CLASS(face_offset, rt::real_type);
    ASSERT_MX_CLASS(original_points, rt::real_type);
    ASSERT_MX_CLASS(mirrored_points, rt::real_type);
    
    ASSERT_MX_MATRIX(face_normal);
    ASSERT_MX_SCALAR(face_offset);
    ASSERT_MX_MATRIX(original_points);
    ASSERT_MX_MATRIX(mirrored_points);
    
    const auto num_dimensions = mx::num_elements(face_normal);
    mxAssert(
            mx::num_rows(original_points) == num_dimensions,
            "Input points array must have one row per spatial dimension");
    mxAssert(
            mx::num_rows(mirrored_points) == num_dimensions,
            "Output points array must have one row per spatial dimension");
    
    const auto num_points = mx::num_columns(original_points);
    mxAssert(num_points <= mx::num_columns(mirrored_points),
            "Output points array must have at least as many columns as input");
    
    mxAssert(2 == num_dimensions || num_dimensions == 3,
            "The number of spatial dimensions must be 2 or 3.");
    const std::function<decltype(dispatcher<2>)> dispatch = 
            (num_dimensions == 2) ? &dispatcher<2> : &dispatcher<3>;
            
	dispatch(face_normal, face_offset, 
            original_points, mirrored_points, num_points);
}
