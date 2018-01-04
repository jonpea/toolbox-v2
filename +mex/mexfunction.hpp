#ifndef INCLUDED_MEXFUNCTION_HPP
#define INCLUDED_MEXFUNCTION_HPP

#include "mex.hpp"
#include <map>
#include <stdexcept>

namespace matlab {
namespace mex {
namespace function {
    
typedef void (*mex_function_type)(
        int, ::matlab::mx::output_array, 
        int, ::matlab::mx::input_array);
    
typedef std::pair<int, int> range_type;

template<class T> inline range_type range(T from, T to)
{
    return range_type(from, to);
}

template<class T> inline range_type exactly(T point)
{
    return range(point, point);
}

template<class T>
        inline bool contains(range_type range, T value)
{
    return range.first <= value && value <= range.second;
}

struct command_type
{
    range_type num_outputs, num_inputs; // inclusive ranges
    mex_function_type function;
};

inline std::string join(std::string const& name, std::string const& message)
{
    return name + ": " + message;
}

typedef std::map<std::string, command_type> command_map_type;

inline void dispatch_unsafe(
        int nlhs, mxArray * plhs[],
        int nrhs, mxArray * prhs[],
        command_map_type const& commands)
{
    using ::matlab::mex::error_unless;
    error_unless(1 <= nrhs, "Expected at least one input argument");

    // Extract command string
    char command[64];
    error_unless(
            0 == mxGetString(prhs[0], command, sizeof(command)),
            "First input must be a valid command string");
    --nrhs; ++prhs; // drop command string after extraction

    auto found = commands.find(command);

    error_unless(
            found != commands.end(),
            std::string("Unrecognized command string: ") + command);

    const auto name = found->first;
    const auto action = found->second;

    error_unless(
            contains(action.num_inputs, nrhs),
            join(name, "Unexpected number of input arguments"));

    error_unless(
            contains(action.num_outputs, nlhs),
            join(name, "Unexpected number of output arguments"));

#ifdef VERBOSE
    mexPrintf("Invoking %s...\n", name);
#endif

    action.function(nlhs, plhs, nrhs, prhs);
}

inline void dispatch(
        int nlhs, mxArray * plhs[],
        int nrhs, mxArray * prhs[],
        command_map_type const& commands)
{
    try
    {
        dispatch_unsafe(nlhs, plhs, nrhs, prhs, commands);
    }
    catch (::std::exception const& error)
    {
        mexErrMsgTxt(error.what());
    }
    catch (...)
    {
        mexErrMsgTxt("Unhandled exception");
    }
}

} // namespace
} // namespace
} // namespace

#endif // INCLUDED_MEXFUNCTION_HPP
