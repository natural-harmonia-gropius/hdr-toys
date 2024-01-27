// ITU-R BT.2390 EETF
// https://www.itu.int/pub/R-REP-BT.2390

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

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (bt.2390)

const float DISPGAMMA = 2.4;
const float L_W = 1.0;
const float L_B = 0.0;

float bt1886_r(float L, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float V = pow(max(L / a, 0.0), 1.0 / gamma) - b;
    return V;
}

float bt1886_f(float V, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float L = a * pow(max(V + b, 0.0), gamma);
    return L;
}

float curve_clip(float x) {
    x = bt1886_r(x, DISPGAMMA, L_W, L_W / CONTRAST_sdr);
    x = bt1886_f(x, DISPGAMMA, L_W, L_B);
    return x;
}

vec3 tone_mapping_rgb(vec3 RGB) {
    return vec3(curve_clip(RGB.r), curve_clip(RGB.g), curve_clip(RGB.b));
}

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
         2048,   2048,    0,
         6610, -13613, 7003,
        17933, -17390, -543) / 4096;
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
    const float iw = Y_to_ST2084(L_hdr);
    const float ib = Y_to_ST2084(0.0);
    const float ow = Y_to_ST2084(L_sdr);
    const float ob = Y_to_ST2084(L_sdr / CONTRAST_sdr);

    const float maxLum = (ow - ib) / (iw - ib);
    const float minLum = (ob - ib) / (iw - ib);

    const float KS = 1.5 * maxLum - 0.5;
    const float b = minLum;

    // E1
    x = (x - ib) / (iw - ib);

    // E2
    if (KS <= x) {
        const float TB  = (x - KS) / (1.0 - KS);
        const float TB2 = TB * TB;
        const float TB3 = TB * TB2;

        const float PB  = (2.0 * TB3 - 3.0 * TB2 + 1.0) * KS  +
                          (TB3 - 2.0 * TB2 + TB) * (1.0 - KS) +
                          (-2.0 * TB3 + 3.0 * TB2) * maxLum;

        x = PB;
    }

    // E3
    if (0.0 <= x) {
        x = x + b * pow((1 - x), 4.0);
    }

    // E4
    x = x * (iw - ib) + ib;

    return x;
}

vec3 tone_mapping_ictcp(vec3 ICtCp) {
    float I2  = curve(ICtCp.x);
    ICtCp.yz *= min(ICtCp.x / I2, I2 / ICtCp.x);
    ICtCp.x   = I2;

    return ICtCp;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_ICtCp(color.rgb);
    color.rgb = tone_mapping_ictcp(color.rgb);
    color.rgb = ICtCp_to_RGB(color.rgb);
    color.rgb = tone_mapping_rgb(color.rgb);

    return color;
}