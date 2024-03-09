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
0.2

//!PARAM spatial_stable_iterations
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 8
2

//!PARAM temporal_stable_frames
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 120
8

//!BUFFER MINMAX
//!VAR uint L_max
//!STORAGE

//!BUFFER TEMPORAL_MAX
//!VAR uint L_max_t[128]
//!STORAGE

//!HOOK OUTPUT
//!BIND MINMAX
//!BIND TEMPORAL_MAX
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC metering (initial)

void hook() {
    L_max = 0;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!SAVE METERING
//!WIDTH 512
//!HEIGHT 288
//!DESC metering (spatial stabilization, downscaling)

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

const vec3 RGB_to_Y = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);

vec4 hook() {
    vec4 color = HOOKED_texOff(0);
    color.rgb *= L_sdr;
    color.w = dot(color.rgb, RGB_to_Y);
    return vec4(
        Y_to_ST2084(color.r),
        Y_to_ST2084(color.g),
        Y_to_ST2084(color.b),
        Y_to_ST2084(color.w)
    );
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 0 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 0 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 1 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 1 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 2 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 2 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 3 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 3 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 4 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 4 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 5 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 5 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 6 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 6 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 7 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 7 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 dir    = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];

    for (i = 1; i < 4; i++) {
        c += METERING_texOff( dir * offset[i]) * weight[i];
        c += METERING_texOff(-dir * offset[i]) * weight[i];
    }

    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!BIND MINMAX
//!SAVE EMPTY
//!COMPUTE 32 32
//!DESC metering (max)

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

void hook() {
    vec4 color = texelFetch(METERING_raw, ivec2(gl_GlobalInvocationID.xy), 0);
    float intensity_min = Y_to_ST2084(L_sdr);
    float intensity = max(max(max(max(color.r, color.g), color.b), color.w), intensity_min);
    uint intensity_int = uint(intensity * 4095.0 + 0.5);

    atomicMax(L_max, intensity_int);
}

//!HOOK OUTPUT
//!BIND MINMAX
//!BIND TEMPORAL_MAX
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!WHEN temporal_stable_frames
//!DESC metering (temporal stabilization)

bool sence_changed() {
    // hard transition, black frame insert
    if (L_max_t[0] < 1) {
        return true;
    }

    // hard transition, stops
    float threshold = 1.5;
    float prev_ev = log2(L_max_t[0] / L_sdr);
    float curr_ev = log2(L_max / L_sdr);
    float diff_ev = abs(prev_ev - curr_ev);
    if (diff_ev >= threshold) {
        return true;
    }

    // soft transition, black frame fade in
    // uint sum = 0;
    // for (uint i = 0; i < temporal_stable_frames; i++) {
    //     sum += L_max_t[i];
    // }
    // if (L_sdr * (temporal_stable_frames - 1) > sum) {
    //     return true;
    // }

    return false;
}

uint peak_harmonic_mean() {
    float x = 0.0;
    for (uint i = 0; i <= temporal_stable_frames; i++) {
        float current = float(i == 0 ? L_max : L_max_t[i - 1]);
        current = current / 4095.0;
        current = max(current, 1e-6);
        x += 1.0 / current;
    }
    x = float(temporal_stable_frames + 1) / x;
    return uint(x * 4095.0 + 0.5);
}

void peak_set(uint peak) {
    for (uint i = temporal_stable_frames - 1; i > 0; i--) {
        L_max_t[i] = L_max_t[i - 1];
    }
    L_max_t[0] = L_max;
    L_max = peak;
}

void peak_set_all(uint peak) {
    for (uint i = 0; i < temporal_stable_frames; i++) {
        L_max_t[i] = peak;
    }
}

void hook() {
    if (sence_changed()) {
        peak_set_all(L_max);
        return;
    }

    peak_set(peak_harmonic_mean());
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND MINMAX
//!DESC tone mapping (dynamic)

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

vec3 XYZ_to_Cone(vec3 XYZ) {
    mat3 M = mat3(
         0.41478972, 0.579999,  0.0146480,
        -0.2015100,  1.120649,  0.0531008,
        -0.0166008,  0.264800,  0.6684799);
    return XYZ * M;
}

vec3 Cone_to_XYZ(vec3 LMS) {
    mat3 M = mat3(
         1.9242264357876067,  -1.0047923125953657,  0.037651404030618,
         0.35031676209499907,  0.7264811939316552, -0.06538442294808501,
        -0.09098281098284752, -0.3127282905230739,  1.5227665613052603);
    return LMS * M;
}

vec3 Cone_to_Iab(vec3 LMS) {
    mat3 M = mat3(
        0.5,       0.5,       0.0,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875);
    return LMS * M;
}

vec3 Iab_to_Cone(vec3 Iab) {
    mat3 M = mat3(
        1.0,                 0.1386050432715393,   0.05804731615611886,
        0.9999999999999999, -0.1386050432715393,  -0.05804731615611886,
        0.9999999999999998, -0.09601924202631895, -0.8118918960560388);
    return Iab * M;
}

const float b = 1.15;
const float g = 0.66;

const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

vec3 RGB_to_Jzazbz(vec3 color) {
    color *= L_sdr;

    color = RGB_to_XYZ(color);

    float Xm = (b * color.x) - ((b - 1.0) * color.z);
    float Ym = (g * color.y) - ((g - 1.0) * color.x);

    color = XYZ_to_Cone(vec3(Xm, Ym, color.z));

    color.r = Y_to_ST2084(color.r);
    color.g = Y_to_ST2084(color.g);
    color.b = Y_to_ST2084(color.b);

    color = Cone_to_Iab(color);

    color.r = ((1.0 + d) * color.r) / (1.0 + (d * color.r)) - d0;

    return color;
}

vec3 Jzazbz_to_RGB(vec3 color) {
    color.r = (color.r + d0) / (1.0 + d - d * (color.r + d0));

    color = Iab_to_Cone(color);

    color.r = ST2084_to_Y(color.r);
    color.g = ST2084_to_Y(color.g);
    color.b = ST2084_to_Y(color.b);

    color = Cone_to_XYZ(color);

    float Xa = (color.x + ((b - 1.0) * color.z)) / b;
    float Ya = (color.y + ((g - 1.0) * Xa)) / g;

    color = XYZ_to_RGB(vec3(Xa, Ya, color.z));

    color /= L_sdr;

    return color;
}

const float epsilon = 1e-6;

vec3 Lab_to_LCH(vec3 Lab) {
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float H = 0.0;

    if (!(abs(a) < epsilon && abs(b) < epsilon))
        H = atan(b, a);

    return vec3(Lab.x, C, H);
}

vec3 LCH_to_Lab(vec3 LCH) {
    float C = max(LCH.y, 0.0);
    float H = LCH.z;

    float a = C * cos(H);
    float b = C * sin(H);

    return vec3(LCH.x, a, b);
}

float toeLength = 0.0;
float toeStrength = 0.5;
float shoulderAngle = 1.0;
float shoulderLength = 0.5;
float shoulderStrength = 0.0;

float x0 = 0.0;
float y0 = 0.0;
float x1 = 0.0;
float y1 = 0.0;
float W  = 0.0;
float overshootX = 0.0;
float overshootY = 0.0;

float curve_segment_eval(float x, float lnA, float B, float offsetX, float offsetY, float scaleX, float scaleY) {
    float x0 = (x - offsetX) * scaleX;
    float y0 = 0.0;

    // log(0) is undefined but our function should evaluate to 0. There are better ways to handle this,
    // but it's doing it the slow way here for clarity.
    if (x0 > 0.0) {
        y0 = exp(lnA + B * log(x0));
    }

    return y0 * scaleY + offsetY;
}

float curve_segment_eval_inv(float y, float lnA, float B, float offsetX, float offsetY, float scaleX, float scaleY) {
    float y0 = (y - offsetY) / scaleY;
    float x0 = 0.0;

    // watch out for log(0) again
    if (y0 > 0.0) {
        x0 = exp((log(y0) - lnA) / B);
    }
    float x = x0 / scaleX + offsetX;

    return x;
}

// find a function of the form:
//   f(x) = e^(lnA + Bln(x))
// where
//   f(0)   = 0; not really a constraint
//   f(x0)  = y0
//   f'(x0) = m
vec2 solve_AB(float x0, float y0, float m) {
    float B   = (m * x0) / y0;
    float lnA = log(y0) - B * log(x0);
    return vec2(lnA, B);
}

// convert to y=mx+b
vec2 as_slope_intercept(float x0, float x1, float y0, float y1) {
    float dy = (y1 - y0);
    float dx = (x1 - x0);
    float m  = dx == 0.0 ? 1.0 : dy / dx;
    float b  = y0 - x0 * m;
    return vec2(m, b);
}

// f(x) = (mx+b)^g
// f'(x) = gm(mx+b)^(g-1)
float eval_derivative_linear_gamma(float m, float b, float g, float x) {
    return g * m * pow(m * x + b, g - 1.0);
}

// CreateCurve
float curve(float x) {
    // normalize params to 1.0 range
    float invW = 1.0 / W;
    float x0 = x0 / W;
    float x1 = x1 / W;
    float overshootX = overshootX / W;
    float W = 1.0;

    // Precompute information for all three segments (mid, toe, shoulder)
    const vec2  tmp = as_slope_intercept(x0, x1, y0, y1);
    const float m = tmp.x,
                b = tmp.y,
                g = 1.0; // gamma

    // base function of linear section plus gamma is
    // y = (mx+b)^g

    // which we can rewrite as
    // y = exp(g*ln(m) + g*ln(x+b/m))

    // and our evaluation function is (skipping the if parts):
    /*
        float x0 = (x - m_offsetX)*m_scaleX;
        y0 = expf(m_lnA + m_B*logf(x0));
        return y0*m_scaleY + m_offsetY;
    */

    float   midOffsetX = -(b / m),
            midOffsetY = 0.0,
            midScaleX  = 1.0,
            midScaleY  = 1.0,
            midLnA     = g * log(m),
            midB       = g;

    const float toeM = eval_derivative_linear_gamma(m, b, g, x0);
    const float shoulderM = eval_derivative_linear_gamma(m, b, g, x1);

    float y0 = max(pow(y0, g), 1e-6);
    float y1 = max(pow(y1, g), 1e-6);
    float overshootY = pow(1.0 + overshootY, g) - 1.0;

    const vec2  toeAB  = solve_AB(x0, y0, m);
    float   toeOffsetX = 0.0,
            toeOffsetY = 1.0 / CONTRAST_sdr,
            toeScaleX  = 1.0,
            toeScaleY  = 1.0,
            toeLnA     = toeAB.x,
            toeB       = toeAB.y;

    const float shoulderX0  = (1.0 + overshootX) - x1;
    const float shoulderY0  = (1.0 + overshootY) - y1;

    const vec2  shoulderAB  = solve_AB(shoulderX0, shoulderY0, m);
    float   shoulderOffsetX = 1.0 + overshootX,
            shoulderOffsetY = 1.0 + overshootY,
            shoulderScaleX  = -1.0,
            shoulderScaleY  = -1.0,
            shoulderLnA     = shoulderAB.x,
            shoulderB       = shoulderAB.y;

    // Normalize (correct for overshooting)
    const float scale = curve_segment_eval(1.0,
        shoulderLnA, shoulderB,
        shoulderOffsetX, shoulderOffsetY,
        shoulderScaleX, shoulderScaleY);
    const float invScale = 1.0 / scale;

    toeOffsetY *= invScale;
    toeScaleY  *= invScale;

    midOffsetY *= invScale;
    midScaleY  *= invScale;

    shoulderOffsetY *= invScale;
    shoulderScaleY  *= invScale;

    // FullCurve::Eval
    float normX = x * invW;
    if (normX < x0) {
        return curve_segment_eval(normX,
            toeLnA, toeB,
            toeOffsetX, toeOffsetY,
            toeScaleX, toeScaleY);
    } else if (normX < x1) {
        return curve_segment_eval(normX,
            midLnA, midB,
            midOffsetX, midOffsetY,
            midScaleX, midScaleY);
    } else {
        return curve_segment_eval(normX,
            shoulderLnA, shoulderB,
            shoulderOffsetX, shoulderOffsetY,
            shoulderScaleX, shoulderScaleY);
    }
}

// Convert from "user" to "direct" parameters
void calc_direct_params_from_user() {
    // constraints
    toeLength = clamp(toeLength, 0.0, 1.0);
    toeStrength = clamp(toeStrength, 0.0, 1.0);
    shoulderAngle = clamp(shoulderAngle, 0.0, 1.0);
    shoulderLength = clamp(shoulderLength, 1e-5, 0.999 - 0.5 * toeLength);
    shoulderStrength = clamp(shoulderStrength, 0.0, 10.0);

    // apply base params
    x0 = toeLength * 0.5; // toe goes from 0 to 0.5
    y0 = (1.0 - toeStrength) * x0; // lerp from 0 to x0

    float remainingY = 1.0 - y0;

    float initialW = x0 + remainingY;

    float y1_offset = (1.0 - shoulderLength) * remainingY;
    x1 = x0 + y1_offset;
    y1 = y0 + y1_offset;

    // filmic shoulder strength is in F stops
    float extraW = exp2(shoulderStrength) - 1.0;

    W = initialW + extraW;

    overshootX = (W * 2.0) * shoulderAngle * shoulderStrength;
    overshootY = 0.5 * shoulderAngle * shoulderStrength;
}

void calc_user_params_from_metered() {
    float L_max_i = float(L_max) / 4095.0;
    float L_max_y = ST2084_to_Y(L_max_i);
    float L_max_ev = log2(L_max_y / L_sdr);
    float L_hdr_ev = log2(L_hdr / L_sdr);

    shoulderLength = L_max_ev / L_hdr_ev;
    shoulderStrength = L_max_ev;
    shoulderAngle = 1.0;
    toeLength = 0.18;
    toeStrength = 0.0;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    calc_user_params_from_metered();
    calc_direct_params_from_user();

    vec3 S_jab = RGB_to_Jzazbz(color.rgb);
    vec3 S_jch = Lab_to_LCH(S_jab);

    float Y = RGB_to_XYZ(color.rgb).y;
    vec3 Y_tm = color.rgb * curve(Y) / max(Y, 1e-6);
    vec3 Y_jab = RGB_to_Jzazbz(Y_tm);

    float M = max(max(color.r, color.g), color.b);
    vec3 M_tm = color.rgb * curve(M) / max(M, 1e-6);
    vec3 M_jab = RGB_to_Jzazbz(M_tm);

    float N_j = mix(Y_jab.x, M_jab.x, S_jab.x * S_jch.y);

    S_jab.yz *= mix(1.0, min(S_jab.x / N_j, N_j / S_jab.x), sigma);
    S_jab.x = N_j;

    color.rgb = Jzazbz_to_RGB(S_jab);

    return color;
}
