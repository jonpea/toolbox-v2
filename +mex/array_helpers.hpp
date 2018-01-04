#ifndef INCLUDED_ARRAY_HELPERS_HPP
#define INCLUDED_ARRAY_HELPERS_HPP

template<class T>
inline T const* getrow(T const* a, size_t i)
{
    return a + i;
}

template<class T>
inline T const& get(T const* a, size_t lda, size_t i, size_t j)
{
    return a[i + lda*j];
}

template<class T>
inline T & get(T * a, size_t lda, size_t i, size_t j)
{
    return a[i + lda*j];
}

template<class T>
inline T dot(
        const T * a, size_t lda,
        const T * b, size_t ldb,
        size_t n)
{
    T result(0);
    for (size_t i = 0; i < n; ++i)
        result += a[lda*i] * b[ldb*i];
    return result;
}

#endif // INCLUDED_ARRAY_HELPERS_HPP
