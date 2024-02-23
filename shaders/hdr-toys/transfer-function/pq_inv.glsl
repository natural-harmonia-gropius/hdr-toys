// https://ieeexplore.ieee.org/document/7291452
// https://www.itu.int/rec/R-REC-BT.2100

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (pq, inverse)

const float m1 = 2610.0 / 4096.0 / 4.0;
const float m2 = 2523.0 / 4096.0 * 128.0;
const float c1 = 3424.0 / 4096.0;
const float c2 = 2413.0 / 4096.0 * 32.0;
const float c3 = 2392.0 / 4096.0 * 32.0;
const float pw = 10000.0;

float pq_eotf(float N) {
    float M = pow(N, 1.0 / m2);
    float L = pow(max(M - c1, 0.0) / (c2 - c3 * M), 1.0 / m1);
    float C = L * pw;
    return C;
}

vec3 pq_eotf(vec3 color) {
    return vec3(
        pq_eotf(color.r),
        pq_eotf(color.g),
        pq_eotf(color.b)
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = pq_eotf(color.rgb) / L_sdr;

    return color;
}
