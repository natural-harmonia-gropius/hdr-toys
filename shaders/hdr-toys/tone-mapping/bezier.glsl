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
1.0

//!TEXTURE TONE
//!SIZE 1024 1
//!FORMAT rgba16f
//!FILTER LINEAR
//!BORDER REPEAT
//!STORAGE

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND TONE
//!SAVE GARB
//!WIDTH 2048
//!HEIGHT 1
//!COMPUTE 32 32
//!DESC bake lut

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

float bezier(float t, float a, float b, float c, float d, float e) {
    a = mix(a, b, t);
    b = mix(b, c, t);
    c = mix(c, d, t);
    d = mix(d, e, t);

    a = mix(a, b, t);
    b = mix(b, c, t);
    c = mix(c, d, t);

    a = mix(a, b, t);
    b = mix(b, c, t);

    a = mix(a, b, t);

    return a;
}

vec2 bezier(float t, vec2 a, vec2 b, vec2 c, vec2 d, vec2 e) {
    return vec2(
        bezier(t, a.x, b.x, c.x, d.x, e.x),
        bezier(t, a.y, b.y, c.y, d.y, e.y)
    );
}

vec2 curve(float x) {
    float iw = pq_eotf_inv(L_hdr);
    float ib = pq_eotf_inv(0.0);
    float ow = pq_eotf_inv(L_sdr);
    float ob = pq_eotf_inv(L_sdr / CONTRAST_sdr);

    return bezier(x,
        vec2(0.0, ib),
        vec2(ib, ob),
        vec2((ow - ib) / 3.0, ow),
        vec2(iw, ow),
        vec2(1.0, ow)
    );
}

void hook() {
    float x = HOOKED_pos.x * HOOKED_size.x / (HOOKED_size.x - 1.0);
    vec2 p = curve(x);
    imageStore(TONE, ivec2(int(1023.0 * p.x), 0), vec4(vec3(p.y), 1.0));
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND TONE
//!DESC tone-mapping

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

float curve(float x) {
    float i = 1023.0 * clamp(x, 0.0, 1.0);
    float l = ceil(i);
    float h = floor(i);
    float lv = imageLoad(TONE, ivec2(l, 0)).x;
    float hv = imageLoad(TONE, ivec2(h, 0)).x;
    return mix(lv, hv, i - float(l));
}

vec3 tone_mapping_ictcp(vec3 ICtCp) {
    float I2  = curve(ICtCp.x);
    ICtCp.yz *= mix(1.0, min(ICtCp.x / I2, I2 / ICtCp.x), sigma);
    ICtCp.x   = I2;
    return ICtCp;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_ICtCp(color.rgb);
    color.rgb = tone_mapping_ictcp(color.rgb);
    color.rgb = ICtCp_to_RGB(color.rgb);

    float v = imageLoad(TONE, ivec2(int(1023.0 * HOOKED_pos.x), 0)).x;
    float y = (1.0 - HOOKED_pos.y * HOOKED_size.y / (HOOKED_size.y - 1.0));
    color.rgb += (abs(v - y) < 1e-3 ? vec3(1.0, 0.0, 0.0) : vec3(0.0));

    return color;
}
