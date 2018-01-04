#ifndef INCLUDED_EMBREEMEX_HPP
#define INCLUDED_EMBREEMEX_HPP

#include <algorithm> // TEMPORARY, for std::min
#include <cstdint>
#include <limits>
#include <string>
#include <vector>
#include <mex.h>

#pragma warning(push)  
#pragma warning(disable: 4324)  
#include <embree2/rtcore.h>
#include <embree2/rtcore_ray.h>
#pragma warning(pop) 

// #define VERBOSE // before including other headers
#include "mex.hpp"

namespace embreemex
{    
    typedef std::uint32_t index_type; // see embree::QuadMesh::Quad::v
    typedef float real_type;
           
    template<class Printer>
    inline void print_hits(
            Printer printf, 
            int * valid, 
            RTCRayN * rays, const RTCHitN * hits, size_t num_hits)
    {
        for (size_t i = 0; i < num_hits; i++)
        {
            printf("      %4u:->%1u = { // of %d in this packet\n", 
                    RTCRayN_mask(rays, num_hits, i),
                    RTCHitN_primID(hits, num_hits, i), 
                    num_hits);
            printf("         valid = %i\n", valid[i]);
            printf("          mask = %u (ray index)\n",
                    RTCRayN_mask(rays, num_hits, i));
            printf("        origin = [%g, %g, %g]\n",
                    RTCRayN_org_x(rays, num_hits, i),
                    RTCRayN_org_y(rays, num_hits, i),
                    RTCRayN_org_z(rays, num_hits, i));
            printf("     direction = [%g, %g, %g]\n",
                    RTCRayN_dir_x(rays, num_hits, i),
                    RTCRayN_dir_y(rays, num_hits, i),
                    RTCRayN_dir_z(rays, num_hits, i));
            printf(" [tnear, tfar] = [%g, %g]\n", 
                    RTCRayN_tnear(rays, num_hits, i),
                    RTCRayN_tfar(rays, num_hits, i));
            printf(" primID@geomID = %u@%u\n", 
                    RTCHitN_primID(hits, num_hits, i),
                    RTCHitN_geomID(hits, num_hits, i));
            printf("     [t, u, v] = [%g, %g, %g]\n", 
                    RTCHitN_t(hits, num_hits, i),
                    RTCHitN_u(hits, num_hits, i),
                    RTCHitN_v(hits, num_hits, i));
            printf("            Ng = [%g, %g, %g] (unnormalized)\n",
                    RTCHitN_Ng_x(hits, num_hits, i),
                    RTCHitN_Ng_y(hits, num_hits, i),
                    RTCHitN_Ng_z(hits, num_hits, i));
            printf("}\n");
        }
    }
    
    template<class Printer>
    inline void print_rtc_ray_np(Printer printf, RTCRayNp rays, index_type num_rays)
    {
        for(index_type i = 0; i < num_rays; ++i)
        {
            printf("ray%u = {\n", i);
            printf("          mask = %u (ray index)\n", rays.mask[i]);
            printf("        origin = [%g, %g, %g]\n", 
                    rays.orgx[i], rays.orgy[i], rays.orgz[i]);
            printf("     direction = [%g, %g, %g]\n", 
                    rays.dirx[i], rays.diry[i], rays.dirz[i]);
            printf(" [tnear, tfar] = [%g, %g]\n", rays.tnear[i], rays.tfar[i]);
            printf("        [u, v] = [%g, %g]\n", rays.u[i], rays.v[i]);
            printf(" geomID@primID = %u@%u\n", rays.geomID[i], rays.primID[i]);
            printf("}\n");
        }
    }
                    
} // namespace

#endif // INCLUDED_EMBREEMEX_HPP
