// https://ieeexplore.ieee.org/document/7291452
// https://www.itu.int/rec/R-REC-BT.2100

// https://www.itu.int/pub/R-REP-BT.2390
// pq ootf: 100.0 * bt1886_eotf(bt709_oetf(59.5208 * x), 2.4, 1.0, 0.0)

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (pq)

const float m1 = 2610.0 / 4096.0 / 4.0;
const float m2 = 2523.0 / 4096.0 * 128.0;
const float c1 = 3424.0 / 4096.0;
const float c2 = 2413.0 / 4096.0 * 32.0;
const float c3 = 2392.0 / 4096.0 * 32.0;
const float pw = 10000.0;

float pq_eotf_inv(float C) {
    float L = C / pw;
    float M = pow(L, m1);
    float N = pow((c1 + c2 * M) / (1.0 + c3 * M), m2);
    return N;
}

vec3 pq_eotf_inv(vec3 color) {
    return vec3(
        pq_eotf_inv(color.r),
        pq_eotf_inv(color.g),
        pq_eotf_inv(color.b)
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = pq_eotf_inv(color.rgb * L_sdr);

    return color;
}
