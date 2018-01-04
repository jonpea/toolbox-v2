#ifndef INCLUDED_MEX_HELPERS_HPP
#define INCLUDED_MEX_HELPERS_HPP

inline bool is_real_double(const mxArray * x)
{
    return mxIsDouble(x) && !mxIsComplex(x);
}

#endif // INCLUDED_MEX_HELPERS_HPP

