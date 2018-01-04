#ifndef INCLUDED_UTILITY_HPP
#define INCLUDED_UTILITY_HPP

#include <chrono>

namespace utility
{
    
    typedef std::chrono::high_resolution_clock timer_type;
    typedef typename timer_type::time_point time_point_type;
    typedef typename timer_type::duration duration_type;
    
    inline time_point_type now()
    {
        return timer_type::now();
    }
    
    inline double elapsed_seconds(
            time_point_type const& t1,
            time_point_type const& t2 = now())
    {
        return std::chrono::duration<double>(t2 - t1).count();
    }
    
    
} // namespace

#endif // INCLUDED_UTILITY_HPP
