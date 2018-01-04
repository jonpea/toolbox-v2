#ifndef INCLUDED_MEX_HPP
#define INCLUDED_MEX_HPP

#include <mex.h>
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <string>

namespace matlab 
{

namespace mx
{   
    typedef mxArray * array_ptr;
    typedef mxArray const* const_array_ptr;
    typedef array_ptr * output_array;
    typedef array_ptr * input_array; // could use const_array_ptr
    typedef mwSize size_type;

    template<class T> struct class_id;
    template<class T> struct print_format;
    template<mxClassID ID> struct class_of;

#define MAKE_TRAITS(TYPE, ID, FORMAT)                 \
    template<> struct class_id<TYPE> {                \
        static constexpr mxClassID value = ID;        \
    };                                                \
    template<> struct print_format<TYPE> {            \
        static constexpr const char value[] = FORMAT; \
    };                                                \
            
    MAKE_TRAITS(bool, mxLOGICAL_CLASS, "%u")
    MAKE_TRAITS(char, mxCHAR_CLASS, "%c")
    MAKE_TRAITS(double, mxDOUBLE_CLASS, "%g")
    MAKE_TRAITS(float, mxSINGLE_CLASS, "%g")
    MAKE_TRAITS(std::int8_t, mxINT8_CLASS, "%i")
    MAKE_TRAITS(std::uint8_t, mxUINT8_CLASS, "%u")
    MAKE_TRAITS(std::int16_t, mxINT16_CLASS, "%i")
    MAKE_TRAITS(std::uint16_t, mxUINT16_CLASS, "%u")
    MAKE_TRAITS(std::int32_t, mxINT32_CLASS, "%i")
    MAKE_TRAITS(std::uint32_t, mxUINT32_CLASS, "%u")
    MAKE_TRAITS(std::int64_t, mxINT64_CLASS, "%i")
    MAKE_TRAITS(std::uint64_t, mxUINT64_CLASS, "%u")

} // namespace

namespace mex
{
    using mx::array_ptr;
    using mx::const_array_ptr;
    
    inline void call(std::string const& command, const_array_ptr arg)
    {
        array_ptr arguments[] = {
            const_cast<array_ptr>(arg)
        };
        mexCallMATLAB(0, nullptr, 1, arguments, command.c_str());
    }

    inline void call(std::string const& command, 
            const_array_ptr arg1, const_array_ptr arg2)
    {
        array_ptr arguments[] = {
            const_cast<array_ptr>(arg1),
            const_cast<array_ptr>(arg2)
        };
        mexCallMATLAB(0, nullptr, 1, arguments, command.c_str());
    }

    inline void disp(const_array_ptr arg)
    {
        call("disp", arg);
    }
    
#define MEX_DISP_SIZE(A)                                \
    {                                                   \
        const auto n = mxGetNumberOfDimensions(A) - 1u; \
        const auto dimensions = mxGetDimensions(A);     \
        for (auto i = 0; i < n; ++i)                    \
            mexPrintf("%ux", dimensions[i]);            \
        mexPrintf("%u\n", dimensions[n]);               \
    }                                                   \

#define MEX_DISP(A)                 \
    {                               \
        mexPrintf("%s = %% ", #A);  \
        MEX_DISP_SIZE(A);           \
        ::matlab::mex::disp(A);     \
    }
    
    inline void error_unless(bool predicate, std::string const& message)
    {
        // Unlike mxAssert, this method works even in debug builds
        if (!predicate) mexErrMsgTxt(message.c_str());
    }

    inline void warning_unless(bool predicate, std::string const& message)
    {
        // Unlike mxAssert, this method works even in debug builds
        if (!predicate) mexWarnMsgTxt(message.c_str());
    }

    inline void num_inputs_check(int nrhs, int lower, int upper)
    {
        mex::error_unless(lower <= nrhs && nrhs <= upper, 
                "Unexpected number of input arguments");
    }

    inline void num_inputs_check(int nrhs, int expected)
    {
        mex::num_inputs_check(nrhs, expected, expected);
    }
        
    inline void num_outputs_check(int nlhs, int lower, int upper)
    {
        mex::error_unless(lower <= nlhs && nlhs <= upper, 
                "Unexpected number of output arguments");
    }

    inline void num_outputs_check(int nlhs, int expected)
    {
        mex::num_outputs_check(nlhs, expected, expected);
    }

    struct ostream { };
    
    template<class T> inline 
    ostream const& operator<<(ostream const& os, T const& value)
    {
        auto format = mx::print_format<T>::value;
        mexPrintf(format, value);
        return os;
    }

    inline ostream const& 
            operator<<(ostream const& os, char const* s)
    {
        mexPrintf("%s", s);
        return os;
    }

    inline ostream const& 
            operator<<(ostream const& os, std::string const& s)
    {
        return os << s.c_str();
    }

    template<class T> inline 
    ostream const& operator<<(ostream const& os, const_array_ptr a)
    {
        disp(a);
        return os;
    }
       
} // namespace

namespace mx
{
    template<class T> inline 
    bool is_a(const_array_ptr a)
    {
        return mxGetClassID(a) == class_id<T>::value;
    }

    template<class T> inline
    T const* data(mxArray const* a)
    {
        // NB: A type check like
        //      "error_unless(is_a<T>(a), "Type mismatch")"
        // is not used here because this routine may be used to
        // extract to aggregates like "std::array<double>" for
        // which specializations of class_id<> do not (yet) exist.
        return reinterpret_cast<T const*>(mxGetData(a));
    }
    
    template<class T> inline
    T * data(array_ptr a)
    {
        return reinterpret_cast<T *>(mxGetData(a));
    }
    
    template<class T> inline
    T const& scalar(const_array_ptr a)
    {
        using mex::error_unless;
        error_unless(mxIsScalar(a), "Argument must be scalar");
        error_unless(is_a<T>(a), "Type mismatch");
        return *data<T>(a);
    }   
    
    template<class T> inline
    T & scalar(array_ptr a)
    {
        using mex::error_unless;
        error_unless(mxIsScalar(a), "Argument must be scalar");
        error_unless(is_a<T>(a), "Type mismatch");
        return *data<T>(a);
    }   

    // template<class SizeT>
    // inline array_ptr resize(array_ptr a, SizeT m, SizeT n)
    // {
    //     auto data = mxRealloc(mxGetPr(a), sizeof(T)*m*n);
    //     mxSetPr(a, data);
    //     mxSetM(a, static_cast<mwSize>(m));
    //     mxSetN(a, static_cast<mwSize>(n));
    //     return a;
    // }
    
    template<class T, class SizeT> inline 
    array_ptr new_matrix(SizeT num_rows, SizeT num_columns)
    {
        return mxCreateNumericMatrix(
                static_cast<mwSize>(num_rows), 
                static_cast<mwSize>(num_columns), 
                class_id<T>::value, 
                mxREAL);
    }

    template<class T, class SizeT> inline 
    array_ptr new_matrix(T const* data, SizeT num_rows, SizeT num_columns)
    {
        auto array = new_matrix<T>(num_rows, num_columns);
        T * array_data = static_cast<T *>(mxGetData(array));
        std::copy_n(data, num_rows*num_columns, array_data);
        return array;
    }

    template<class T> inline 
    array_ptr new_scalar(T const& value)
    {
        return new_matrix<T>(&value, 1, 1);
    }   
        
    typedef std::uint64_t pointer_type; // TODO: Ripe for refactoring
#define EMBREEMEX_POINTER_TYPE mxUINT64_CLASS
    
    inline array_ptr encode_pointer(void * p)
    {
#ifdef VERBOSE
        mexPrintf("encoding... %p\n", p);
#endif
        const pointer_type address(reinterpret_cast<pointer_type>(p));
        array_ptr a = mxCreateNumericMatrix(1, 1, EMBREEMEX_POINTER_TYPE, mxREAL);
        pointer_type * data = reinterpret_cast<pointer_type *>(mxGetData(a));
        *data = address;
        return a;
    }
    
    template<typename T> inline
    T decode_pointer(array_ptr a)
    {
        mxAssert(mxIsScalar(a), "Argument must be scalar");
        mxAssert(mxGetClassID(a) == EMBREEMEX_POINTER_TYPE,
                "Argument has unexpected type");
        const pointer_type address(
                *reinterpret_cast<pointer_type *>(mxGetData(a)));
        T result(reinterpret_cast<T>(address));
#ifdef VERBOSE
        mexPrintf("decoded... %p to %p\n", address, result);
#endif
        return result;
    }

    template<size_type Dim>
    inline size_type size(const_array_ptr ref)
    {
        static_assert(0u <= Dim, "Dimension must be non-negative");
        return (Dim < mxGetNumberOfDimensions(ref)) ?
            mxGetDimensions(ref)[Dim] :
            1; // MATLAB automatically squeezes trailing unit dimensions 
    }

    template<class Array> inline 
    size_type num_rows(Array const& ref)
    {
        return size<0>(ref);
    }
    
    template<class Array> inline 
	size_type num_columns(Array const& ref)
    {
        return size<1>(ref);
    }
    
    template<class Array> inline 
    size_type num_layers(Array const& ref)
    {
        return size<2>(ref);
    }

    inline size_type num_elements(const_array_ptr ref)
    {
        return mxGetNumberOfElements(ref);
    }
    
    template<class T, class SizeT> inline 
    void print(T const* a, SizeT m, SizeT n)
    {
        using std::string;
        const string separator(print_format<T>::value + string(" "));
        for (SizeT i = 0; i < m; ++i)
        {
            mexPrintf("\t");
            for (SizeT j = 0; j < n; ++j)
                mexPrintf(separator.c_str(), a[i + j*m]);
            mexPrintf(" // row %u\n", i);
        }
    }    
        
    template<class T> inline 
    void print(mxArray const* a)
    {
        print(data<T>(a), mxGetM(a), mxGetN(a));
    }    
    
    template <class T>
    struct allocator 
    {
        typedef T value_type;
        allocator() = default;
        
        template <class U> 
        constexpr allocator(const allocator<U>&) noexcept 
        { }
        
        T * allocate(size_type num_elements) 
        {
            const auto num_bytes = num_elements * sizeof(T);
            auto p = static_cast<T *>(mxMalloc(num_bytes));
            if (p == 0) mexErrMsgTxt("Memory allocation error");
            return p;            
        }
        
        void deallocate(T * p, size_type) noexcept 
        { 
            mxFree(p); 
        }
    };
    
    template <class T, class U>
    bool operator==(allocator<T> const&, allocator<U> const&) 
    { 
        return true; 
    }
    
    template <class T, class U>
    bool operator!=(allocator<T> const&, allocator<U> const&) 
    { 
        return false; 
    }

} // namespace

} // namespace

namespace detail {
    template<class I> inline 
    bool is_inclusive(I x, I a, I b)
    {
        return (a <= x) && (x <= b);
    }

    template<class I> inline 
    bool is_inclusive(I x, I a)
    {
        return x == a;
    }    
} // namespace

// Helper macros
#define ASSERT_MX_CLASS(VARIABLE, TYPE)                   \
mxAssert(                                                 \
        ::matlab::mx::is_a<TYPE>(VARIABLE),               \
        "Variable has illegal type")
        //"'" ## #VARIABLE ## "' must have type " ## #TYPE)
        
#define ASSERT_MX_SIZE(VARIABLE, DIM, ...)                \
        mxAssert(                                         \
        ::detail::is_inclusive<std::size_t>(::matlab::mx::size<DIM>(VARIABLE), __VA_ARGS__),  \
        "'" ## #VARIABLE ## "' must have size " ## #__VA_ARGS__ ## " in dimension " ## #DIM)
        
#define ASSERT_MX_NUM_ROWS(VARIABLE, ...) \
        ASSERT_MX_SIZE(VARIABLE, 0, __VA_ARGS__)
#define ASSERT_MX_NUM_COLS(VARIABLE, ...) \
        ASSERT_MX_SIZE(VARIABLE, 1, __VA_ARGS__)

#define ASSERT_MX_SCALAR(VARIABLE)             \
        mxAssert(                              \
        mxIsScalar(VARIABLE),                  \
        "Variable must be scalar")
        //"'" ## #VARIABLE ## "' must be scalar")
        
#define ASSERT_MX_DIMENSION(VARIABLE, DIM)                           \
        mxAssert(                                                    \
        mxGetNumberOfDimensions(VARIABLE) == (DIM),                  \
        "Illegal number of dimensions")
        //"'" ## #VARIABLE ## "' must have " ## #DIM ## " dimensions")

#define ASSERT_MX_MATRIX(VARIABLE)       \
        ASSERT_MX_DIMENSION(VARIABLE, 2)

#define ASSERT_MX_TRIPLE(VARIABLE)       \
        ASSERT_MX_DIMENSION(VARIABLE, 3)

#endif // INCLUDED_MEX_HPP
