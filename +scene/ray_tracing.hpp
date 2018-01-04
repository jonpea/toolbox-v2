#ifndef INCLUDED_RAY_TRACING_HPP
#define INCLUDED_RAY_TRACING_HPP

#include <algorithm> // for std::transform etc.
#include <array>
#include <cmath> // for std::isnan
#include <cstddef> // for std::size_t
#include <functional> // for std::minus
#include <numeric> // for std::inner_product
#include <stdexcept> // for std::length_error
#include <utility> // for std::pair

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
/*size_type*/ bool intersect(
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
        const size_type hit_capacity, 
        // State variables
        size_type & face_id, 
        size_type & ray_id, 
        size_type & num_hits)
{
    /*size_type num_hits = 0u;*/
    vector<N> intersection, offset, offset_direction;
    vector<N - 1> face_coordinates;
    
    bool success = true;
    
    for (/*size_type face_id = 0*/; face_id < num_faces; ++face_id)
    {
        if (!face_masks[face_id]) 
            continue; // no hits to compute at masked face
        
        auto const& face_origin = face_origins[face_id];
        auto const& face_normal = face_normals[face_id];
        auto const& face_offset = face_offsets[face_id];
        auto const& face_map = offset_to_local_map[face_id];
       
        for (/*size_type ray_id = 0*/; ray_id < num_rays; ++ray_id)
        {
            auto const& ray_origin = ray_origins[ray_id];
            auto const& ray_direction = ray_directions[ray_id];
            
            //difference(face_origin, ray_origin, offset_direction);
            const auto
                    //numerator = dot_product(face_normal, offset_direction),
                    numerator = face_offset - dot_product(face_normal, ray_origin),
                    denominator = dot_product(face_normal, ray_direction);
            const auto 
                    t = numerator / denominator;
            
            // if (::std::isnan(t))
            //     mexPrintf(
            //             "\n***** [%g / %g = %g] *****\n\n",
            //             numerator, denominator, t);
            
            if (excludes(t_near, t_far, t) || ::std::isnan(t)) 
                continue;
            
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

            if (num_hits == hit_capacity)
            {
                /*throw std::length_error("Output buffer has insufficient capacity");*/
                success = false;
                break;
            }
                           
            face_index_buffer[num_hits] = static_cast<index_type>(face_id);
            ray_index_buffer[num_hits] = static_cast<index_type>(ray_id);
            ray_parameter_buffer[num_hits] = t;
            intersection_buffer[num_hits] = intersection;
            ::std::copy(
                    begin(face_coordinates), 
                    end(face_coordinates),
                    begin(face_coordinates_buffer[num_hits]));            
            ++num_hits;
        }
        
        if (!success) break;
    }
    
    /*return size_type(num_hits);*/
    return success;
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
