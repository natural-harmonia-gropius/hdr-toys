// False color visualization applied to ICtCp

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (false color)

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

vec3 RGB_to_XYZ(vec3 RGB) {
    mat3 M = mat3(
        0.6369580483012914, 0.14461690358620832,  0.1688809751641721,
        0.2627002120112671, 0.6779980715188708,   0.05930171646986196,
        0.000000000000000,  0.028072693049087428, 1.060985057710791);
    return RGB * M;
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    mat3 M = mat3(
         1.716651187971268,  -0.355670783776392, -0.253366281373660,
        -0.666684351832489,   1.616481236634939,  0.0157685458139111,
         0.017639857445311,  -0.042770613257809,  0.942103121235474);
    return XYZ * M;
}

vec3 XYZ_to_LMS(vec3 XYZ) {
    mat3 M = mat3(
         0.3592832590121217,  0.6976051147779502, -0.0358915932320290,
        -0.1920808463704993,  1.1004767970374321,  0.0753748658519118,
         0.0070797844607479,  0.0748396662186362,  0.8433265453898765);
    return XYZ * M;
}

vec3 LMS_to_XYZ(vec3 LMS) {
    mat3 M = mat3(
         2.0701522183894223, -1.3263473389671563,  0.2066510476294053,
         0.3647385209748072,  0.6805660249472273, -0.0453045459220347,
        -0.0497472075358123, -0.0492609666966131,  1.1880659249923042);
    return LMS * M;
}

vec3 LMS_to_ICtCp(vec3 LMS) {
    mat3 M = mat3(
         2048.0 / 4096.0,   2048.0 / 4096.0,    0.0 / 4096.0,
         6610.0 / 4096.0, -13613.0 / 4096.0, 7003.0 / 4096.0,
        17933.0 / 4096.0, -17390.0 / 4096.0, -543.0 / 4096.0);
    return pq_eotf_inv(LMS) * M;
}

vec3 ICtCp_to_LMS(vec3 ICtCp) {
    mat3 M = mat3(
        0.9999999999999998,  0.0086090370379328,  0.1110296250030260,
        0.9999999999999998, -0.0086090370379328, -0.1110296250030259,
        0.9999999999999998,  0.5600313357106791, -0.3206271749873188);
    return pq_eotf(ICtCp * M);
}

vec3 RGB_to_ICtCp(vec3 color) {
    color *= L_sdr;
    color = RGB_to_XYZ(color);
    color = XYZ_to_LMS(color);
    color = LMS_to_ICtCp(color);
    return color;
}

vec3 ICtCp_to_RGB(vec3 color) {
    color = ICtCp_to_LMS(color);
    color = LMS_to_XYZ(color);
    color = XYZ_to_RGB(color);
    color /= L_sdr;
    return color;
}

// BT.2020 to BT.709
mat3 M = mat3(
     1.66049100210843540, -0.58764113878854950,  -0.072849863319884740,
    -0.12455047452159074,  1.13289989712595960,  -0.008349422604369515,
    -0.01815076335490526, -0.10057889800800737,   1.118729661362913000
);

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    vec3 color_dst = color.rgb * M;
    vec3 color_dst_cliped = clamp(color_dst, 0.0, 1.0);

    color.rgb = RGB_to_ICtCp(color.rgb);
    if (color_dst == color_dst_cliped)
        color.yz *= 0.0;
    else
        color.x = 0.5;
    color.rgb = ICtCp_to_RGB(color.rgb);
    color.rgb = color.rgb * M;

    return color;
}
