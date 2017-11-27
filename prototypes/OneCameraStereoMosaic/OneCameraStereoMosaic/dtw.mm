#include <math.h>
#include "dtw.h"

template <class T> inline T min(const T a, const T b) { return a < b ? a : b; };
template <class T> inline T min(const T a, const T b, const T c) { return min<T>(a, min<T>(b, c)); };
template <class T> inline T abs(const T a) { return abs((float)a); }

inline int min(int x, int y) { return y ^ ((x ^ y) & -(x < y)); }
inline int min(int x, int y, int z) { return min(x, min(y, z)); }
inline int abs(int x) { int const m = x >> (sizeof(int)*8 - 1); return (x+m)^m; }

inline unsigned int min(unsigned int x, unsigned int y) { return y ^ ((x ^ y) & -(x < y)); }
inline unsigned int min(unsigned int x, unsigned int y, unsigned int z) { return min(x, min(y, z)); }
inline unsigned int max(unsigned int x, unsigned int y) { return x ^ ((x ^ y) & -(x < y)); }
inline unsigned int max(unsigned int x, unsigned int y, unsigned int z) { return max(x, max(y, z)); }
inline unsigned int abs(unsigned int x) { unsigned int const m = x >> (sizeof(unsigned int)*8 - 1); return (x+m)^m; }

inline unsigned char abs(unsigned char x) { unsigned char const m = x >> 7; return (x+m)^m; }

static inline int L1(unsigned *a, unsigned *b) {
    static_assert(sizeof(unsigned) == 4, "Unexpected size");
    int             d  = 0;
    unsigned char   *x = (unsigned char*)a,
                    *y = (unsigned char*)b;
    for(int i = 0; i < 4; i++)
        d += abs(x[i] - y[i]);
    return d;
}

static inline int L2(unsigned *a, unsigned *b) {
    static_assert(sizeof(unsigned) == 4, "Unexpected size");
    int             d  = 0;
    unsigned char   *x = (unsigned char*)a,
    *y = (unsigned char*)b;
    for(int i = 0; i < 4; i++) {
        auto t = x[i] - y[i];
        d += (t*t);
    }
    return d;
}

int dtw_distance(unsigned n, unsigned *x, unsigned *y, unsigned b) {
    if (b == 0) b = n;  // Sakoe-Chiba band limit.

    float *A = new float[n+1],
          *B = new float[n+1];
    float *D = B, *P = A;

    P[0] = 0;
    for (int i = 1; i <= n; i++) P[i] = INFINITY;

    for (int i = 0; i <= n; i++) {
        D[0] = P[0] + L1(&x[i], &y[0]);
        for (int j = max(1,i-b); j <= min(n,i+b); j++)
            D[j] = L1(&x[i], &y[j]) + min(P[j-1],
                                          P[j  ],
                                          D[j-1]);
        auto T = P;
        P = D;
        D = T;
    }
    float d = P[n];
    delete[] A;
    delete[] B;
    return d;
}
