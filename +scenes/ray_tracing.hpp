#ifndef INCLUDED_RAY_TRACING_HPP
#define INCLUDED_RAY_TRACING_HPP

#include <algorithm> // for std::transform etc.
#include <array>
#include <cmath> // for std::isnan
#include <cstddef> // for std::size_t
#include <functional> // for std::minus
#include <numeric> // for std::inner_product

namespace ray_tracing {
    
template<class Vector, class Scalar> inline 
void add_scaled(
        Vector const& origin,
        Vector const& direction,
        Scalar const& scale, 
        Vector & result)
{
    ::std::transform(
            begin(origin), end(origin),
            begin(direction),
            begin(result),
            [&](auto const& a, auto const& b)
    {
        return a + scale*b;
    });
}

template<class Vector> inline 
void difference(Vector const& left, Vector const& right, Vector & result)
{
    ::std::transform(
            begin(left), end(left),
            begin(right),
            begin(result),
            ::std::minus<>());
}

template<class Vector> inline 
typename Vector::value_type 
dot_product(Vector const& left, Vector const& right)
{
    typedef typename Vector::value_type result_type;
    return ::std::inner_product(
            begin(left), end(left), begin(right), result_type(0));
}

template<class T> inline 
bool excludes(T const& lower, T const& upper, T const& x)
{
    return x < lower || upper < x;
}

typedef double index_type;
typedef double real_type;
typedef ::std::size_t size_type;

template<size_type NumDims>
using vector = ::std::array<real_type, NumDims>;

template<size_type N> inline
bool intersect(
        // Inputs
        vector<N> const* face_origins,
        vector<N> const* face_normals,
        real_type const* face_offsets,
        ::std::array<vector<N>, N - 1> const* offset_to_local_map,
        bool const* face_masks,
        const size_type num_faces,
        vector<N> const* ray_origins,
        vector<N> const* ray_directions,
        real_type const& t_near,
        real_type const& t_far,
        const size_type num_rays,
        // Outputs
        index_type * face_index_buffer,
        index_type * ray_index_buffer,
        real_type * ray_parameter_buffer,
        vector<N> * intersection_buffer,
        vector<N - 1> * face_coordinates_buffer,
        const size_type buffer_capacity, 
        // State variables
        size_type & face_id, 
        size_type & ray_id, 
        size_type & num_hits)
{
    // Work storage
    vector<N> intersection, offset, offset_direction;
    vector<N - 1> face_coordinates;
    
    for (/*face_id = "resume"*/; face_id < num_faces; ++face_id)
    {
        if (!face_masks[face_id]) 
            continue; // no hits to compute at masked face
                
        auto const& face_origin = face_origins[face_id];
        auto const& face_normal = face_normals[face_id];
        auto const& face_offset = face_offsets[face_id];
        auto const& face_map = offset_to_local_map[face_id];
       
        for (/* ray_id = "resume" */; ray_id < num_rays; ++ray_id)
        {
            if (num_hits == buffer_capacity) 
            {
                //mexPrintf("face_id = %u, ray_id = %u [num_hits = %u of %u]--> buffer overflow\n", face_id, ray_id, num_hits, buffer_capacity);
                return false; // "not success: buffer overflow"
            }
            //mexPrintf("face_id = %u, ray_id = %u [num_hits = %u of %u]\n", face_id, ray_id, num_hits, buffer_capacity);
            
            auto const& ray_origin = ray_origins[ray_id];
            auto const& ray_direction = ray_directions[ray_id];
            
            const auto
                    numerator = face_offset - dot_product(face_normal, ray_origin),
                    denominator = dot_product(face_normal, ray_direction);
            const auto 
                    t = numerator / denominator;
            
            //mexPrintf("parameter = %g\n", t);
            
            if (excludes(t_near, t_far, t) || ::std::isnan(t)) continue;
            
            // Cartesian coordinates of intersection points
            add_scaled(ray_origin, ray_direction, t, intersection);
            difference(intersection, face_origin, offset);
                        
            for (size_type i = 0; i < N - 1; ++i)
                face_coordinates[i] = dot_product(face_map[i], offset);

            const auto unit_excludes = [](auto const& s) -> bool
            {
                return excludes<real_type>(0, 1, s);
            };
            if (::std::any_of(
                    begin(face_coordinates),
                    end(face_coordinates),
                    unit_excludes))
                continue;

            /*
            if (num_hits == buffer_capacity) 
                return false; // "not success: buffer overflow"
            */

            // =====>>
            // mexPrintf("        num_hits = %u\n", num_hits);
            // mexPrintf("         face_id = %u\n", static_cast<index_type>(face_id));
            // mexPrintf("          ray_id = %u\n", static_cast<index_type>(ray_id));
            // mexPrintf("   ray_parameter = %g\n", t);
            // mexPrintf("face_coordinates = (%g, %g)\n", face_coordinates[0], face_coordinates[1]);
            // mexPrintf("----------------------------------------\n");
            // <<=====
            
            face_index_buffer[num_hits] = static_cast<index_type>(face_id);
            ray_index_buffer[num_hits] = static_cast<index_type>(ray_id);
            ray_parameter_buffer[num_hits] = t;
            intersection_buffer[num_hits] = intersection;
            ::std::copy(
                    begin(face_coordinates), 
                    end(face_coordinates),
                    begin(face_coordinates_buffer[num_hits]));     
            
            // =====>>
            // mexPrintf("--- Actually stored ---\n");
            // mexPrintf("        num_hits = %u\n", num_hits);
            // mexPrintf("         face_id = %u\n", face_index_buffer[num_hits]);
            // mexPrintf("          ray_id = %u\n", ray_index_buffer[num_hits]);
            // mexPrintf("   ray_parameter = %g\n", ray_parameter_buffer[num_hits]);
            // mexPrintf("face_coordinates = (%g, %g)\n", 
            //         face_coordinates_buffer[num_hits][0], 
            //         face_coordinates_buffer[num_hits][1]);
            // mexPrintf("----------------------------------------\n");
            // <<=====

            ++num_hits;
        }

        // Reset for next trip through inner loop
        ray_id = 0;
    }
    
    return true; // "success"
}

template<size_type N> inline
void mirror(
        vector<N> const& face_normal,
        real_type const& face_offset,
        vector<N> const* original_points,
        vector<N> * mirrored_points, 
        const size_type num_points)
{
    for (size_type point_id = 0; point_id < num_points; ++point_id)
    {
        const real_type two(2);
        auto const& original = original_points[point_id];        
        auto & mirrored = mirrored_points[point_id];
        const auto normal_offset = 
                face_offset - dot_product(face_normal, original);
        add_scaled(original, face_normal, two*normal_offset, mirrored);
    }
}

} // namespace

#endif // INCLUDED_RAY_TRACING_HPP
