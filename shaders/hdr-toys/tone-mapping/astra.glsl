// Astra, a tone mapping operator designed to preserve the creator's intent

// shoulder segment: http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
// toe segment: https://technorgb.blogspot.com/2018/02/hyperbola-tone-mapping.html
// working space: https://doi.org/10.1364/OE.25.015131
// hk effect: https://doi.org/10.1364/OE.534073
// chroma correction: https://www.itu.int/pub/R-REP-BT.2408
// dynamic metadata: https://github.com/mpv-player/mpv/pull/15239
// fast gaussian blur: https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

//!PARAM min_luma
//!TYPE float
0.0

//!PARAM max_luma
//!TYPE float
0.0

//!PARAM max_cll
//!TYPE float
0.0

//!PARAM max_fall
//!TYPE float
0.0

//!PARAM scene_max_r
//!TYPE float
0.0

//!PARAM scene_max_g
//!TYPE float
0.0

//!PARAM scene_max_b
//!TYPE float
0.0

//!PARAM scene_avg
//!TYPE float
0.0

//!PARAM max_pq_y
//!TYPE float
0.0

//!PARAM avg_pq_y
//!TYPE float
0.0

//!PARAM reference_white
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1000.0
203.0

//!PARAM auto_exposure_anchor
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.75

//!PARAM hk_effect_compensate_scaling
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
1.0

//!PARAM chroma_correction_scaling
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
1.0

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

//!PARAM enable_metering
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM preview_metering
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 1
0

//!BUFFER METERED
//!VAR uint metered_max_i
//!STORAGE

//!BUFFER METERED_TEMPORAL
//!VAR uint metered_max_i_t[128]
//!STORAGE

//!HOOK OUTPUT
//!BIND HOOKED
//!SAVE METERING
//!COMPONENTS 1
//!WIDTH 512
//!HEIGHT 288
//!WHEN enable_metering 0 > max_pq_y 0 = * scene_max_r 0 = * scene_max_g 0 = * scene_max_b 0 = *
//!DESC metering (feature map)

const vec3 y_coef = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);

const float m1 = 2610.0 / 4096.0 / 4.0;
const float m2 = 2523.0 / 4096.0 * 128.0;
const float c1 = 3424.0 / 4096.0;
const float c2 = 2413.0 / 4096.0 * 32.0;
const float c3 = 2392.0 / 4096.0 * 32.0;
const float pw = 10000.0;

float pq_eotf_inv(float x) {
    float t = pow(x / pw, m1);
    return pow((c1 + c2 * t) / (1.0 + c3 * t), m2);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float l = dot(color.rgb * reference_white, y_coef);
    float i = pq_eotf_inv(l);
    return vec4(i, vec3(0.0));
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WHEN spatial_stable_iterations 0 >
//!DESC metering (spatial stabilization, blur, horizonal)

const vec4 offset = vec4(0.0, 1.411764705882353, 3.2941176470588234, 5.176470588235294);
const vec4 weight = vec4(0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(1.0, 0.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
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
const vec2 direction = vec2(0.0, 1.0);

vec4 hook(){
    uint i = 0;
    vec4 c = METERING_texOff(offset[i]) * weight[i];
    for (i = 1; i < 4; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!BIND METERED
//!SAVE EMPTY
//!COMPUTE 32 32
//!DESC metering (data, max)

shared uint local_max;

void hook() {
    if (gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0) {
        metered_max_i = 0;
    }

    if (gl_LocalInvocationIndex == 0) {
        local_max = 0;
    }

    memoryBarrierShared();
    barrier();

    float value = METERING_tex(METERING_pos).x;
    uint rounded = uint(value * 4095.0 + 0.5);
    atomicMax(local_max, rounded);

    memoryBarrierShared();
    barrier();

    if (gl_LocalInvocationIndex == 0) {
        atomicMax(metered_max_i, local_max);
    }
}

//!HOOK OUTPUT
//!BIND METERING
//!BIND METERED
//!BIND METERED_TEMPORAL
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!WHEN temporal_stable_frames
//!DESC metering (temporal stabilization)

void temporal_prepend() {
    for (uint i = temporal_stable_frames - 1; i > 0; i--) {
        metered_max_i_t[i] = metered_max_i_t[i - 1];
    }
    metered_max_i_t[0] = metered_max_i;
}

float temporal_harmonic_mean() {
    float sum = 0.0;
    for (uint i = 0; i < temporal_stable_frames; i++) {
        float current = float(metered_max_i_t[i]);
        sum += 1.0 / max(current, 1e-6);
    }
    return temporal_stable_frames / sum;
}

void temporal_fill() {
    for (uint i = 0; i < temporal_stable_frames; i++) {
        metered_max_i_t[i] = metered_max_i;
    }
}

float temporal_predict() {
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_x2 = 0.0;
    float sum_xy = 0.0;

    float n = temporal_stable_frames;
    float xp = float(n + 1);

    for (int i = 0; i < n; i++) {
        float x = float(i + 1);
        sum_x += x;
        sum_y += metered_max_i_t[i];
        sum_x2 += x * x;
        sum_xy += x * metered_max_i_t[i];
    }

    float a = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x);
    float b = (sum_y - a * sum_x) / float(n);

    return a * xp + b;
}

bool is_sence_changed(float m, float p) {
    float black = 16.0;
    if (black > metered_max_i)
        return true;

    float tolerance = 36.0;
    float im = float(m) / 4095.0;
    float ip = float(p) / 4095.0;
    float delta = 720 * abs(im - ip);
    return delta > tolerance;
}

void hook() {
    float p = temporal_predict();
    temporal_prepend();
    float m = temporal_harmonic_mean();

    if (is_sence_changed(m, p)) {
        temporal_fill();
        return;
    }

    metered_max_i = uint(m + 0.5);
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND METERING
//!BIND METERED
//!WHEN preview_metering
//!DESC metering (preview)

bool almost_equal(float a, float b, float epsilon) {
    return abs(a - b) < epsilon;
}

vec4 hook() {
    float metering = METERING_tex(METERING_pos).x;
    float lmi = float(metered_max_i) / 4095.0;

    vec3 color = vec3(metering);

    float delta = 720 * abs(metering - lmi);
    if (delta < 4.0)
        color = vec3(1.0, 0.0, 0.0);

    if (almost_equal(1.0 - METERING_pos.y, lmi, 1e-3))
        color = vec3(0.0, 1.0, 0.0);

    return vec4(color, 1.0);
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND METERED
//!DESC tone mapping (astra)

const float m1 = 2610.0 / 4096.0 / 4.0;
const float m2 = 2523.0 / 4096.0 * 128.0;
const float c1 = 3424.0 / 4096.0;
const float c2 = 2413.0 / 4096.0 * 32.0;
const float c3 = 2392.0 / 4096.0 * 32.0;
const float pw = 10000.0;

float pq_eotf_inv(float x) {
    float t = pow(x / pw, m1);
    return pow((c1 + c2 * t) / (1.0 + c3 * t), m2);
}

vec3 pq_eotf_inv(vec3 color) {
    return vec3(
        pq_eotf_inv(color.r),
        pq_eotf_inv(color.g),
        pq_eotf_inv(color.b)
    );
}

float pq_eotf(float x) {
    float t = pow(x, 1.0 / m2);
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), 1.0 / m1) * pw;
}

vec3 pq_eotf(vec3 color) {
    return vec3(
        pq_eotf(color.r),
        pq_eotf(color.g),
        pq_eotf(color.b)
    );
}

vec3 RGB_to_XYZ(vec3 RGB) {
    return RGB * mat3(
        0.6369580483012914, 0.14461690358620832,  0.1688809751641721,
        0.2627002120112671, 0.6779980715188708,   0.05930171646986196,
        0.0               , 0.028072693049087428, 1.060985057710791
    );
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    return XYZ * mat3(
         1.716651187971268, -0.355670783776392, -0.25336628137366,
        -0.666684351832489,  1.616481236634939,  0.0157685458139111,
         0.017639857445311, -0.042770613257809,  0.942103121235474
    );
}

const float b = 1.15;
const float g = 0.66;

vec3 XYZ_to_XYZm(vec3 XYZ) {
    float Xm = (b * XYZ.x) - ((b - 1.0) * XYZ.z);
    float Ym = (g * XYZ.y) - ((g - 1.0) * XYZ.x);
    return vec3(Xm, Ym, XYZ.z);
}

vec3 XYZm_to_XYZ(vec3 XYZm) {
    float Xa = (XYZm.x + ((b - 1.0) * XYZm.z)) / b;
    float Ya = (XYZm.y + ((g - 1.0) * Xa)) / g;
    return vec3(Xa, Ya, XYZm.z);
}

vec3 XYZ_to_LMS(vec3 XYZ) {
    return XYZ * mat3(
         0.41478972, 0.579999, 0.0146480,
        -0.2015100,  1.120649, 0.0531008,
        -0.0166008,  0.264800, 0.6684799
    );
}

vec3 LMS_to_XYZ(vec3 LMS) {
    return LMS * mat3(
         1.9242264357876067,  -1.0047923125953657,  0.037651404030618,
         0.35031676209499907,  0.7264811939316552, -0.06538442294808501,
        -0.09098281098284752, -0.3127282905230739,  1.5227665613052603
    );
}

vec3 LMS_to_Iab(vec3 LMS) {
    return LMS * mat3(
        0.5,       0.5,       0.0,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875
    );
}

vec3 Iab_to_LMS(vec3 Iab) {
    return Iab * mat3(
        1.0,  0.1386050432715393,  0.0580473161561189,
        1.0, -0.1386050432715393, -0.0580473161561189,
        1.0, -0.0960192420263190, -0.8118918960560390
    );
}

const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

float I_to_J(float I) {
    return ((1.0 + d) * I) / (1.0 + (d * I)) - d0;
}

float J_to_I(float J) {
    return (J + d0) / (1.0 + d - d * (J + d0));
}

float hke_fh_hellwig(float h, float a1, float a2, float a3, float a4, float a5) {
    return a1 * cos(h) + a2 * cos(2.0 * h) + a3 * sin(h) + a4 * sin(2.0 * h) + a5;
}

float hke_fh_high(float h, float k1, float k2, float k3, float k4) {
    h = mod(mod(degrees(h), 360.0) + 360.0, 360.0);
    float by = k1 * abs(sin(radians((h - 90.0)/ 2.0))) + k2;
    float r  = h <= 90.0 || h >= 270.0 ? k3 * abs(cos(radians(h))) + k4 : 0.0;
    return by + r;
}

float hke_fh_liao(float h, float k3, float k4, float k5) {
    h = mod(mod(degrees(h), 360.0) + 360.0, 360.0);
    return k3 * abs(log(((h + k4) / (90.0 + k4)))) + k5;
}

float hke_fh(float h) {
    float result = hke_fh_liao(h, 0.3495, 45.0, 0.1567);
    return result * hk_effect_compensate_scaling;
}

float J_to_Jhk(vec3 JCh) {
    float J = JCh.x;
    float C = JCh.y;
    float h = JCh.z;
    return J + C * hke_fh(h);
}

float Jhk_to_J(vec3 JCh) {
    float J = JCh.x;
    float C = JCh.y;
    float h = JCh.z;
    return J - C * hke_fh(h);
}

// https://github.com/color-js/color.js/pull/629
const float epsilon = 0.0002363;

vec3 Lab_to_LCh(vec3 Lab) {
    float L = Lab.x;
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float h = (abs(a) < epsilon && abs(b) < epsilon) ? 0.0 : atan(b, a);

    return vec3(L, C, h);
}

vec3 LCh_to_Lab(vec3 LCh) {
    float L = LCh.x;
    float C = LCh.y;
    float h = LCh.z;

    C = max(C, 0.0);
    float a = C * cos(h);
    float b = C * sin(h);

    return vec3(L, a, b);
}

vec3 RGB_to_Jab(vec3 color) {
    color *= reference_white;
    color = RGB_to_XYZ(color);
    color = XYZ_to_XYZm(color);
    color = XYZ_to_LMS(color);
    color = pq_eotf_inv(color);
    color = LMS_to_Iab(color);
    color.x = I_to_J(color.x);
    color.x = J_to_Jhk(Lab_to_LCh(color));
    return color;
}

vec3 Jab_to_RGB(vec3 color) {
    color.x = Jhk_to_J(Lab_to_LCh(color));
    color.x = J_to_I(color.x);
    color = Iab_to_LMS(color);
    color = pq_eotf(color);
    color = LMS_to_XYZ(color);
    color = XYZm_to_XYZ(color);
    color = XYZ_to_RGB(color);
    color /= reference_white;
    return color;
}

float get_max_i() {
    if (max_pq_y > 0.0)
        return max_pq_y;

    if (scene_max_r > 0.0 || scene_max_g > 0.0 || scene_max_b > 0.0) {
        vec3 scene_max_rgb = vec3(scene_max_r, scene_max_g, scene_max_b);
        return pq_eotf_inv(RGB_to_XYZ(scene_max_rgb).y);
    }

    if (enable_metering > 0)
        return float(metered_max_i) / 4095.0;

    if (max_cll > 0.0)
        return pq_eotf_inv(max_cll);

    if (max_luma > 0.0)
        return pq_eotf_inv(max_luma);

    return pq_eotf_inv(1000.0);
}

float get_min_i() {
    if (min_luma > 0.0)
        return pq_eotf_inv(min_luma);

    return pq_eotf_inv(0.001);
}

float get_avg_i() {
    if (avg_pq_y > 0.0)
        return avg_pq_y;

    if (scene_avg > 0.0)
        return pq_eotf_inv(scene_avg);

    // if (max_fall > 0.0)
    //     return pq_eotf_inv(max_fall);

    return 0.0;
}

float ev = 0.0;

vec3 auto_exposure(vec3 color) {
    if (auto_exposure_anchor <= 0.0)
        return color;

    float avg_i = get_avg_i();

    if (avg_i <= 0.0)
        return color;

    float ach = pq_eotf(J_to_I(
        auto_exposure_anchor *
        I_to_J(pq_eotf_inv(reference_white))
    ));
    float avg = pq_eotf(avg_i);
    float mxx = pq_eotf(get_max_i());
    float ref = reference_white;
    float old = 100.0;

    float ev_min = min(log2(max(ref / mxx, 1e-6)), 0.0);
    float ev_max = max(log2(max(ref / old, 1e-6)), 0.0);

    ev = log2(max(ach / avg, 1e-6));
    ev = clamp(ev, ev_min, ev_max);

    return color * exp2(ev);
}

float f(float x, float iw, float ib, float ow, float ob) {
    float midgray   = 0.5 * ow;
    float shadow    = mix(midgray, ob, 0.66);
    float highlight = mix(midgray, ow, 0.04);

    float x0 = ib;
    float y0 = ob;
    float x1 = shadow;
    float y1 = shadow;
    float x2 = highlight;
    float y2 = highlight;
    float x3 = iw;
    float y3 = ow;

    float al = (y2 - y1) / (x2 - x1);

    if (x < x1) {
        float at = al * (x1 - x0) * (x1 - x0) * (y1 - y0) * (y1 - y0) / ((y1 - y0 - al * (x1 - x0)) * (y1 - y0 - al * (x1 - x0)));
        float bt = al * (x1 - x0) * (x1 - x0) / (y1 - y0 - al * (x1 - x0));
        float ct = (y1 - y0) * (y1 - y0) / (y1 - y0 - al * (x1 - x0));
        x = -at / (x - x0 + bt) + ct + y0;
    } else if (x < x2) {
        float bl = y1 - al * x1;
        x = al * x + bl;
    } else {
        float bs = al * (x3 - x2) / (y3 - y2);
        float as = log(y3 - y2) - bs * log(x3 - x2);
        x = -exp(as + bs * log(max(-(x - x3), 1e-6))) + y3;
    }

    return clamp(x, ob, ow);
}

float curve(float x) {
    float ow = I_to_J(pq_eotf_inv(reference_white));
    float ob = I_to_J(pq_eotf_inv(reference_white / 1000.0));
    float iw = get_max_i();
    float ib = get_min_i();

    if (ev != 0.0) {
        iw = pq_eotf_inv(pq_eotf(iw) * exp2(ev));
        ib = pq_eotf_inv(pq_eotf(ib) * exp2(ev));
    }

    iw = max(I_to_J(iw), ow + 1e-3);
    ib = min(I_to_J(ib), ob - 1e-3);

    return f(x, iw, ib, ow, ob);
}

vec2 chroma_correction(vec2 ab, float i1, float i2) {
    float r1 = i1 / max(i2, 1e-6);
    float r2 = i2 / max(i1, 1e-6);
    return ab * mix(1.0, min(r1, r2), chroma_correction_scaling);
}

vec3 tone_mapping(vec3 iab) {
    float i2 = curve(iab.x);
    vec2 ab2 = chroma_correction(iab.yz, iab.x, i2);
    return vec3(i2, ab2);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    color.rgb = auto_exposure(color.rgb);
    color.rgb = RGB_to_Jab(color.rgb);
    color.rgb = tone_mapping(color.rgb);
    color.rgb = Jab_to_RGB(color.rgb);

    return color;
}
