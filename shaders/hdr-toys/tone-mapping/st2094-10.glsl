// ST 2094-10:2021 - SMPTE Standard - Dynamic Metadata for Color Volume Transform - Application #1
// https://ieeexplore.ieee.org/document/9405553

//!PARAM L_hdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 10000
1000.0

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!PARAM sigma
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!HOOK OUTPUT
//!BIND HOOKED
//!SAVE AVG
//!WIDTH 1024
//!HEIGHT 1024
//!COMPONENTS 1
//!DESC tone mapping (st2094-10, average, 1024)

const vec3 RGB_to_Y = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);

vec4 hook() {
    vec4 color = HOOKED_texOff(0);
    float y = dot(color.rgb, RGB_to_Y);
    return vec4(y, 0.0, 0.0, 0.0);
}

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 512)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 256)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 128)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 64)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 32)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 16)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 8)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 4)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC tone mapping (st2094-10, average, 2)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH 1
//!HEIGHT 1
//!DESC tone mapping (st2094-10, average, 1)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND AVG
//!DESC tone mapping (st2094-10)

const float pq_m1 = 0.1593017578125;
const float pq_m2 = 78.84375;
const float pq_c1 = 0.8359375;
const float pq_c2 = 18.8515625;
const float pq_c3 = 18.6875;

const float pq_C  = 10000.0;

float Y_to_ST2084(float C) {
    float L = C / pq_C;
    float Lm = pow(L, pq_m1);
    float N = (pq_c1 + pq_c2 * Lm) / (1.0 + pq_c3 * Lm);
    N = pow(N, pq_m2);
    return N;
}

float ST2084_to_Y(float N) {
    float Np = pow(N, 1.0 / pq_m2);
    float L = Np - pq_c1;
    if (L < 0.0 ) L = 0.0;
    L = L / (pq_c2 - pq_c3 * Np);
    L = pow(L, 1.0 / pq_m1);
    return L * pq_C;
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
    LMS.x = Y_to_ST2084(LMS.x);
    LMS.y = Y_to_ST2084(LMS.y);
    LMS.z = Y_to_ST2084(LMS.z);
    mat3 M = mat3(
         2048.0 / 4096.0,   2048.0 / 4096.0,    0.0 / 4096.0,
         6610.0 / 4096.0, -13613.0 / 4096.0, 7003.0 / 4096.0,
        17933.0 / 4096.0, -17390.0 / 4096.0, -543.0 / 4096.0);
    return LMS * M;
}

vec3 ICtCp_to_LMS(vec3 ICtCp) {
    mat3 M = mat3(
        0.9999999999999998,  0.0086090370379328,  0.1110296250030260,
        0.9999999999999998, -0.0086090370379328, -0.1110296250030259,
        0.9999999999999998,  0.5600313357106791, -0.3206271749873188);
    ICtCp *= M;
    ICtCp.x = ST2084_to_Y(ICtCp.x);
    ICtCp.y = ST2084_to_Y(ICtCp.y);
    ICtCp.z = ST2084_to_Y(ICtCp.z);
    return ICtCp;
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

float curve(float x) {
    float n = 1.0;  // contrast [0.5, 1.5]
    float o = 0.0;  // offset   [-0.5, 0.5]
    float g = 1.0;  // gain     [0.5, 1.5]
    float p = 1.0;  // gamma    [0.5, 1.5]

    float avg = AVG_tex(vec2(0.0)).x;

    float x1 = 0.0;
    float y1 = 1.0 / CONTRAST_sdr;

    float x3 = L_hdr / L_sdr;
    float y3 = 1.0;

    float x2 = clamp(avg, x1 + 0.001, 0.9 * x3);
    float y2 = clamp(sqrt(x2 * sqrt(y3 * y1)), y1, 0.8 * y3);

    float a = x3 * y3 * (x1 - x2) + x2 * y2 * (x3 - x1) + x1 * y1 * (x2 - x3);

    mat3 cmat = mat3(
        x2 * x3 * (y2 - y3), x1 * x3 * (y3 - y1), x1 * x2 * (y1 - y2),
        x3 * y3 - x2 * y2  , x1 * y1 - x3 * y3  , x2 * y2 - x1 * y1  ,
        x3 - x2            , x1 - x3            , x2 - x1
    );

    vec3 coeffs = vec3(y1, y2, y3) * cmat / a;

    float c1 = coeffs.r;
    float c2 = coeffs.g;
    float c3 = coeffs.b;

    x = clamp(x, x1, x3);
    x = (c1 + c2 * pow(x, n)) / (1.0 + c3 * pow(x, n));
    x = pow(min(max(((x / y3) * g) + o, 0.0), 1.0), p) * y3;
    x = clamp(x, y1, y3);

    return x;
}

vec3 tone_mapping_ictcp(vec3 ICtCp) {
    float I2  = Y_to_ST2084(curve(ST2084_to_Y(ICtCp.x) / L_sdr) * L_sdr);
    ICtCp.yz *= mix(1.0, min(ICtCp.x / I2, I2 / ICtCp.x), sigma);
    ICtCp.x   = I2;
    return ICtCp;
}

vec3 gamut_adjustment(vec3 f) {
    float c = 0.0;  // chroma compensation weight   [-0.5, 0.5]
    float s = 0.0;  // saturation gain              [-0.5, 0.5]
    float y = RGB_to_XYZ(f).y;
    return f * pow((1.0 + c) * f / y, vec3(s));
}

vec3 detail_managenment(vec3 p) {
    float t = 0.0;  // tone detail factor [0, 1];
    vec3 q = p;     // TODO: do what???
    return mix(p, q, t);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_ICtCp(color.rgb);
    color.rgb = tone_mapping_ictcp(color.rgb);
    color.rgb = ICtCp_to_RGB(color.rgb);
    color.rgb = gamut_adjustment(color.rgb);
    color.rgb = detail_managenment(color.rgb);

    return color;
}
