// Astra, a tone mapping operator designed to preserve the creator's intent

//!PARAM PTS
//!TYPE float
0.0

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

//!PARAM contrast_ratio
//!TYPE float
//!MINIMUM 10.0
//!MAXIMUM 100000000.0
1000.0

//!PARAM auto_exposure_anchor
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.6

//!PARAM auto_exposure_limit_negative
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
2.3

//!PARAM auto_exposure_limit_positive
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
0.0

//!PARAM auto_exposure_limit_input
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM exposure_value
//!TYPE float
//!MINIMUM -64
//!MAXIMUM  64
0.0

//!PARAM shadow_weight
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.4

//!PARAM highlight_weight
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.1

//!PARAM highlight_overshoot
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
1.0

//!PARAM contrast_bias
//!TYPE float
//!MINIMUM -1.0
//!MAXIMUM  1.0
0.0

//!PARAM hk_effect_compensate_scaling
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
1.0

//!PARAM chroma_correction_scaling
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
1.0

//!PARAM chroma_correction_rate
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
1.0

//!PARAM chroma_correction_threshold
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.0

//!PARAM spatial_stable_iterations
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 8
2

//!PARAM temporal_stable_window
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 2.0
0.33

//!PARAM temporal_stable_scene_change
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 1
1

//!PARAM enable_metering
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 2
2

//!PARAM preview_metering
//!TYPE uint
//!MINIMUM 0
//!MAXIMUM 1
0

//!BUFFER METERED
//!VAR uint metered_max_i
//!VAR uint metered_min_i
//!VAR uint metered_avg_i
//!STORAGE

//!BUFFER METERED_TEMPORAL
//!VAR uint metered_max_i_t[256]
//!VAR uint metered_min_i_t[256]
//!VAR uint metered_avg_i_t[256]
//!VAR uint metered_pts_t[256]
//!VAR uint metered_history_head
//!VAR uint metered_history_valid
//!STORAGE

//!BUFFER METERED_SMOOTHED
//!VAR float smoothed_max_i
//!VAR float smoothed_min_i
//!VAR float smoothed_avg_i
//!STORAGE

//!BUFFER METADATA
//!VAR float max_i
//!VAR float min_i
//!VAR float avg_i
//!VAR float ev
//!STORAGE

//!HOOK OUTPUT
//!BIND HOOKED
//!SAVE METERING
//!COMPONENTS 1
//!WHEN enable_metering 0 > max_pq_y 0 = * scene_max_r 0 = * scene_max_g 0 = * scene_max_b 0 = *
//!DESC metering (intensity map)

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

float RGB_to_Y(vec3 rgb) {
    const vec3 coefficients = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);
    return dot(rgb, coefficients);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    float y = RGB_to_Y(color.rgb);
    float y_abs = clamp(y * reference_white, 0.0, pw);
    float intensity = pq_eotf_inv(y_abs);
    return vec4(vec3(intensity), 1.0);
}

// The metering map used to be reduced to 512x288 in a single step. At 4K that
// is a factor of 7.5 per axis taken with one bilinear tap, i.e. point sampling
// with aliasing: which pixels survive depends on the subpixel alignment, so a
// small moving highlight makes metered_max_i jump while nothing in the scene
// changes. Halving repeatedly instead averages exactly 2x2 per step, the same
// way the average chain below already does it. The passes are conditional, so
// only as many run as the source resolution needs: two at 4K, one at 1080p.

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w 2 /
//!HEIGHT METERING.h 2 /
//!WHEN OUTPUT.w 1024 > OUTPUT.h 576 > +
//!DESC metering (spatial stabilization, halve 1)
vec4 hook() { return METERING_tex(METERING_pos); }

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w 2 /
//!HEIGHT METERING.h 2 /
//!WHEN OUTPUT.w 2048 > OUTPUT.h 1152 > +
//!DESC metering (spatial stabilization, halve 2)
vec4 hook() { return METERING_tex(METERING_pos); }

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w 2 /
//!HEIGHT METERING.h 2 /
//!WHEN OUTPUT.w 4096 > OUTPUT.h 2304 > +
//!DESC metering (spatial stabilization, halve 3)
vec4 hook() { return METERING_tex(METERING_pos); }

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w 2 /
//!HEIGHT METERING.h 2 /
//!WHEN OUTPUT.w 8192 > OUTPUT.h 4608 > +
//!DESC metering (spatial stabilization, halve 4)
vec4 hook() { return METERING_tex(METERING_pos); }

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH 512
//!HEIGHT 288
//!DESC metering (spatial stabilization, downscaling)

vec4 hook() {
    const vec2 target_size = vec2(512.0, 288.0);
    vec2 scale = METERING_size / target_size;

    if (all(lessThanEqual(scale, vec2(1.0)))) {
        return METERING_tex(METERING_pos);
    }

    // Extend the bilinear footprint to approximate an area average. At 2x
    // downscaling the four taps land at the centers of the source 2x2 block.
    vec2 offset = 0.5 * max(scale - vec2(1.0), vec2(0.0));
    vec4 sum = METERING_texOff(vec2(-offset.x, -offset.y))
             + METERING_texOff(vec2( offset.x, -offset.y))
             + METERING_texOff(vec2(-offset.x,  offset.y))
             + METERING_texOff(vec2( offset.x,  offset.y));
    return sum * 0.25;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 0 >
//!DESC metering (spatial stabilization, blur, horizontal)

// Efficient Gaussian blur with linear sampling
// by Daniel Rákos
// https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 0 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 1 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 1 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 2 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 2 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 3 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 3 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 4 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 4 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 5 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 5 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 6 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 6 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 7 >
//!DESC metering (spatial stabilization, blur, horizontal)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(1.0, 0.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!WHEN spatial_stable_iterations 7 >
//!DESC metering (spatial stabilization, blur, vertical)

const vec3 offset = vec3(0.0000000000, 1.3846153846, 3.2307692308);
const vec3 weight = vec3(0.2270270270, 0.3162162162, 0.0702702703);
const vec2 direction = vec2(0.0, 1.0);

vec4 hook() {
    vec4 c = METERING_tex(METERING_pos) * weight[0];
    for (uint i = 1; i < 3; i++) {
        c += METERING_texOff( direction * offset[i]) * weight[i];
        c += METERING_texOff(-direction * offset[i]) * weight[i];
    }
    return c;
}

//!HOOK OUTPUT
//!BIND METERING
//!BIND METERED
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC metering (max, min, init)

void hook() {
    metered_max_i = 0;
    metered_min_i = 4095;
}

//!HOOK OUTPUT
//!BIND METERING
//!BIND METERED
//!SAVE EMPTY
//!WIDTH METERING.w
//!HEIGHT METERING.h
//!COMPUTE 32 32 16 16
//!DESC metering (max, min)

shared uint smax[256];
shared uint smin[256];

uint to_uint(float x) {
    return uint(x * 4095.0 + 0.5);
}

float fetch_metering(ivec2 position) {
    return (METERING_mul * texelFetch(METERING_raw, position, 0)).x;
}

void hook() {
    ivec2 block_base = ivec2(gl_WorkGroupID.xy) * 32;
    ivec2 position = block_base + ivec2(gl_LocalInvocationID.xy) * 2;

    float value00 = fetch_metering(position);
    float value10 = fetch_metering(position + ivec2(1, 0));
    float value01 = fetch_metering(position + ivec2(0, 1));
    float value11 = fetch_metering(position + ivec2(1, 1));
    float local_max = max(max(value00, value10), max(value01, value11));
    float local_min = min(min(value00, value10), min(value01, value11));

    uint tid = gl_LocalInvocationIndex;
    smax[tid] = to_uint(local_max);
    smin[tid] = to_uint(local_min);

    barrier();

    for (uint s = 128; s > 0; s >>= 1) {
        if (tid < s) {
            smax[tid] = max(smax[tid], smax[tid + s]);
            smin[tid] = min(smin[tid], smin[tid + s]);
        }
        barrier();
    }

    if (tid == 0) {
        atomicMax(metered_max_i, smax[0]);
        atomicMin(metered_min_i, smin[0]);
    }
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE AVG
//!COMPONENTS 1
//!WIDTH 256
//!HEIGHT 256
//!WHEN auto_exposure_anchor 0 > enable_metering 1 > * avg_pq_y 0 = * scene_avg 0 = *
//!DESC metering (avg, 256, center-weighted)

vec2 map_coords(vec2 uv, float strength) {
    if (strength < 0.001) {
        return uv;
    }

    vec2 centered_uv = uv - vec2(0.5);
    float radius = length(centered_uv);

    if (radius == 0.0) {
        return vec2(0.5);
    }

    float distorted_radius  = tan(radius * strength) / strength;
    vec2 distorted_centered_uv  = normalize(centered_uv ) * distorted_radius;

    distorted_centered_uv = distorted_centered_uv / max(strength, 1.0);

    vec2 distorted_uv = distorted_centered_uv + vec2(0.5);

    vec2 kaleidoscope_uv = 1.0 - abs(fract(distorted_uv * 0.5) * 2.0 - 1.0);

    return kaleidoscope_uv;
}

vec2 map_coords(vec2 uv) {
    return map_coords(uv, 2.0);
}

vec4 hook() {
    return METERING_tex(map_coords(METERING_pos));
}

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 16 /
//!HEIGHT AVG.h 16 /
//!DESC metering (avg, 16)
// Sixty-four bilinear taps, each averaging 2x2, tile the 16x16 source block.
vec4 hook() {
    float sum = 0.0;
    for (int y = -7; y <= 7; y += 2) {
        for (int x = -7; x <= 7; x += 2) {
            sum += AVG_texOff(vec2(float(x), float(y))).x;
        }
    }
    return vec4(sum / 64.0, 0.0, 0.0, 1.0);
}

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 16 /
//!HEIGHT AVG.h 16 /
//!DESC metering (avg, 1)
// Sixty-four bilinear taps, each averaging 2x2, tile the 16x16 source block.
vec4 hook() {
    float sum = 0.0;
    for (int y = -7; y <= 7; y += 2) {
        for (int x = -7; x <= 7; x += 2) {
            sum += AVG_texOff(vec2(float(x), float(y))).x;
        }
    }
    return vec4(sum / 64.0, 0.0, 0.0, 1.0);
}

//!HOOK OUTPUT
//!BIND AVG
//!BIND METERED
//!SAVE AVG
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC metering (avg)

uint to_uint(float x) {
    return uint(x * 4095.0 + 0.5);
}

void hook() {
    metered_avg_i = to_uint(AVG_tex(AVG_pos).x);
}

//!HOOK OUTPUT
//!BIND METERING
//!BIND METERED
//!BIND METERED_TEMPORAL
//!BIND METERED_SMOOTHED
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!WHEN temporal_stable_window 0.0 >
//!DESC metering (temporal stabilization)

// ============================================================================
// TEMPORAL STABILIZATION - Configuration Parameters
// ============================================================================
// These parameters control the temporal smoothing behavior to reduce flicker
// while maintaining responsiveness to actual scene changes.

// Historical-weight half-life relative to the configured temporal window.
// At the default 0.33 s window this yields a half-life of about 0.178 s.
const float TEMPORAL_WEIGHT_HALF_LIFE_SCALE = 0.54;
const float TEMPORAL_MIN_TIME_CONSTANT = 1.0 / 240.0;
const float TEMPORAL_FAST_TIME_SCALE = 0.125;
const float TEMPORAL_AVERAGE_TIME_SCALE = 0.25;
const float TEMPORAL_SLOW_TIME_SCALE = 0.5;
// Re-arm cut detection after history covers this fraction of the window.
const float TEMPORAL_SCENE_MIN_HISTORY_SCALE = 0.25;
const float TEMPORAL_PTS_EPSILON = 1e-6;

// Scene change blend factor (applied when cut is detected)
// Range: 0.2-0.5. Lower = smoother but may blur real scene changes
// Default: 0.3 maintains some smoothness during cuts
const float TEMPORAL_CUT_BLEND = 0.3;

// Base tolerance for scene change detection (in ΔE units)
// Range: 20.0-50.0. Higher = fewer false detections but may miss real cuts
// Default: 36.0 provides good balance for most content
const float TEMPORAL_BASE_TOLERANCE = 36.0;

// Adaptive tolerance scaling based on brightness
// Range: 0.3-0.7. Higher = more tolerance for bright scenes
// Default: 0.5 adapts well to various brightness levels
const float TEMPORAL_ADAPTIVE_SCALE = 0.5;

// Black scene threshold (below this is considered pure black)
// Range: ~0.002-0.008 (normalized). Higher = more aggressive black detection
// Default: 16/4095 catches most black frames without false positives
const float TEMPORAL_BLACK_THRESHOLD = 16.0 / 4095.0;

// Metric weights for scene change detection
// These weights determine the relative importance of each metric
// Total should sum to 1.0 for balanced detection
const float TEMPORAL_WEIGHT_AVG = 0.50; // Average is most reliable
const float TEMPORAL_WEIGHT_MAX = 0.35; // Maximum is important for highlights
const float TEMPORAL_WEIGHT_MIN = 0.15; // Minimum is least reliable (noise)

// Delta scale for converting normalized differences to perceptual units
// This converts [0,1] differences to ΔE-like perceptual differences
const float TEMPORAL_DELTA_SCALE = 720.0;

float to_float(uint x) {
    return float(x) / 4095.0;
}

uint to_uint(float x) {
    return uint(x * 4095.0 + 0.5);
}

float pts_to_float(uint x) {
    return uintBitsToFloat(x);
}

uint pts_to_uint(float x) {
    return floatBitsToUint(x);
}

// ============================================================================
// TEMPORAL STABILIZATION - Core Functions
// ============================================================================

// Must remain a power of two for the ring-buffer mask below.
const uint TEMPORAL_BUFFER_SIZE = 256u;

uint temporal_history_index(uint age) {
    return (metered_history_head + age) & (TEMPORAL_BUFFER_SIZE - 1u);
}

void temporal_store_sample(uint index, uvec3 value) {
    metered_max_i_t[index] = value.x;
    metered_min_i_t[index] = value.y;
    metered_avg_i_t[index] = value.z;
    metered_pts_t[index] = pts_to_uint(PTS);
}

/** Inserts the current frame at the front of the temporal ring buffer. */
void temporal_prepend(uvec3 current) {
    metered_history_head = (metered_history_head + TEMPORAL_BUFFER_SIZE - 1u)
                         & (TEMPORAL_BUFFER_SIZE - 1u);
    temporal_store_sample(metered_history_head, current);
    metered_history_valid = min(metered_history_valid + 1u, TEMPORAL_BUFFER_SIZE);
}

struct TemporalPredictionStatistics {
    vec3 weighted_value_sum;
    vec3 weighted_time_value_sum;
    vec3 newest;
    float weight_sum;
    float weighted_time_sum;
    float weighted_time_squared_sum;
};

struct TemporalMeanStatistics {
    vec3 weighted_reciprocal_sum;
    float weight_sum;
};

struct TemporalStatistics {
    TemporalPredictionStatistics prediction;
    TemporalMeanStatistics mean;
    uint count;
    float history_span;
};

void temporal_add_prediction_sample(
    inout TemporalPredictionStatistics statistics,
    vec3 value,
    float time,
    float weight
) {
    statistics.weighted_value_sum += weight * value;
    statistics.weighted_time_value_sum += weight * time * value;
    statistics.weight_sum += weight;
    statistics.weighted_time_sum += weight * time;
    statistics.weighted_time_squared_sum += weight * time * time;
}

void temporal_add_mean_sample(
    inout TemporalMeanStatistics statistics,
    vec3 value,
    float weight
) {
    statistics.weighted_reciprocal_sum += weight / max(value, vec3(1e-6));
    statistics.weight_sum += weight;
}

/** Traverses the active history once and accumulates all temporal statistics. */
TemporalStatistics temporal_collect_statistics(
    uint valid,
    vec3 current,
    float newest_age
) {
    TemporalStatistics statistics;
    statistics.prediction.weighted_value_sum = vec3(0.0);
    statistics.prediction.weighted_time_value_sum = vec3(0.0);
    statistics.prediction.newest = current;
    statistics.prediction.weight_sum = 0.0;
    statistics.prediction.weighted_time_sum = 0.0;
    statistics.prediction.weighted_time_squared_sum = 0.0;
    statistics.mean.weighted_reciprocal_sum = vec3(0.0);
    statistics.mean.weight_sum = 0.0;
    statistics.count = 0u;
    statistics.history_span = 0.0;
    float half_life = max(
        temporal_stable_window * TEMPORAL_WEIGHT_HALF_LIFE_SCALE,
        TEMPORAL_MIN_TIME_CONSTANT
    );

    // Treat samples as points on a continuous time axis. Midpoints between
    // adjacent PTS values bound each sample's interval, and integrating the
    // exponential kernel over those intervals removes sample-rate bias.
    float boundary_decay = exp2(-0.5 * newest_age / half_life);
    float current_weight = 1.0 - boundary_decay;
    temporal_add_mean_sample(statistics.mean, current, current_weight);

    float age = newest_age;
    float sample_age = newest_age;

    for (uint i = 0u; i < valid; i++) {
        uint index = temporal_history_index(i);
        float time = -age;
        float interval_end = temporal_stable_window;
        float next_age = age;
        float next_sample_age = sample_age;
        bool has_next = false;

        if (i + 1u < valid) {
            uint next_index = temporal_history_index(i + 1u);
            next_sample_age = PTS - pts_to_float(metered_pts_t[next_index]);

            if (next_sample_age >= 0.0 &&
                next_sample_age <= temporal_stable_window) {
                next_age = max(next_sample_age, age);
                interval_end = 0.5 * (age + next_age);
                has_next = true;
            }
        }

        float next_boundary_decay = exp2(-interval_end / half_life);
        float weight = max(boundary_decay - next_boundary_decay, 0.0);
        vec3 value = vec3(
            to_float(metered_max_i_t[index]),
            to_float(metered_min_i_t[index]),
            to_float(metered_avg_i_t[index])
        );

        if (i == 0u)
            statistics.prediction.newest = value;

        temporal_add_prediction_sample(
            statistics.prediction,
            value,
            time,
            weight
        );
        temporal_add_mean_sample(statistics.mean, value, weight);
        statistics.count = i + 1u;
        statistics.history_span = sample_age;
        boundary_decay = next_boundary_decay;

        if (!has_next)
            break;

        age = next_age;
        sample_age = next_sample_age;
    }

    return statistics;
}

/**
 * Predicts maximum, minimum, and average intensity with a weighted regression.
 * Each sample receives the integrated temporal-kernel weight of its PTS
 * interval, so denser sampling does not receive more influence.
 */
vec3 temporal_predict(uint count, TemporalPredictionStatistics statistics) {
    if (count < 2u) {
        return statistics.newest;
    }

    float weight_sum = statistics.weight_sum;
    float denominator = weight_sum * statistics.weighted_time_squared_sum
                      - statistics.weighted_time_sum
                      * statistics.weighted_time_sum;

    if (weight_sum < 1e-6 || abs(denominator) < 1e-10) {
        return statistics.newest;
    }

    vec3 slope = (weight_sum * statistics.weighted_time_value_sum
               - statistics.weighted_time_sum
               * statistics.weighted_value_sum)
               / denominator;
    vec3 intercept = (statistics.weighted_value_sum
                   - slope * statistics.weighted_time_sum)
                   / weight_sum;

    // Historical sample times are negative relative to the current frame, so
    // the prediction at the current frame (t = 0) is the intercept.
    return clamp(intercept, vec3(0.0), vec3(1.0));
}

/**
 * Calculates the weighted harmonic mean including the current frame.
 * Recent frames receive more weight through exponential decay, while harmonic
 * averaging reduces the influence of bright outliers.
 * H = sum(w) / sum(w / x)
 */
vec3 temporal_weighted_mean(TemporalMeanStatistics statistics) {
    return vec3(statistics.weight_sum)
         / max(statistics.weighted_reciprocal_sum, vec3(1e-6));
}

/** Calculates a frame-rate-independent EMA coefficient. */
float temporal_alpha(float delta_time, float time_constant) {
    return 1.0 - exp(-delta_time / max(time_constant, TEMPORAL_MIN_TIME_CONSTANT));
}

vec3 apply_temporal_smoothing(vec3 current, vec3 previous, float delta_time) {
    float fast_time = temporal_stable_window * TEMPORAL_FAST_TIME_SCALE;
    float average_time = temporal_stable_window * TEMPORAL_AVERAGE_TIME_SCALE;
    float slow_time = temporal_stable_window * TEMPORAL_SLOW_TIME_SCALE;

    vec3 time_constant = vec3(
        current.x > previous.x ? fast_time : slow_time,
        current.y < previous.y ? fast_time : slow_time,
        average_time
    );
    vec3 alpha = vec3(
        temporal_alpha(delta_time, time_constant.x),
        temporal_alpha(delta_time, time_constant.y),
        temporal_alpha(delta_time, time_constant.z)
    );
    return mix(previous, current, alpha);
}

bool temporal_scene_history_ready(uint count, float history_span) {
    if (count < 2u) {
        return false;
    }

    float required_span = max(
        temporal_stable_window * TEMPORAL_SCENE_MIN_HISTORY_SCALE,
        TEMPORAL_MIN_TIME_CONSTANT
    );
    return history_span >= required_span;
}

void temporal_reset_history(uvec3 current) {
    metered_history_head = 0u;
    metered_history_valid = 1u;
    temporal_store_sample(0u, current);
}

void temporal_publish(vec3 smoothed) {
    metered_max_i = to_uint(smoothed.x);
    metered_min_i = to_uint(smoothed.y);
    metered_avg_i = to_uint(smoothed.z);
    smoothed_max_i = smoothed.x;
    smoothed_min_i = smoothed.y;
    smoothed_avg_i = smoothed.z;
}

float temporal_scene_change_score(vec3 current, vec3 predicted) {
    // Metric layout is (max, min, avg).
    vec3 delta = TEMPORAL_DELTA_SCALE * abs(current - predicted);
    return dot(delta, vec3(
        TEMPORAL_WEIGHT_MAX,
        TEMPORAL_WEIGHT_MIN,
        TEMPORAL_WEIGHT_AVG
    ));
}

/** Detects scene changes by comparing current values with their prediction. */
bool temporal_is_scene_changed(vec3 current, vec3 predicted) {
    // Entering black is a cut, but a sustained black scene is not.
    if (current.x < TEMPORAL_BLACK_THRESHOLD) {
        return predicted.x >= TEMPORAL_BLACK_THRESHOLD;
    }

    // Calculate adaptive tolerance based on current brightness
    // Brighter scenes get higher tolerance to reduce false positives
    float adaptive_tolerance = TEMPORAL_BASE_TOLERANCE *
                               (1.0 + current.x * TEMPORAL_ADAPTIVE_SCALE);

    return temporal_scene_change_score(current, predicted) > adaptive_tolerance;
}

/**
 * Main temporal stabilization hook
 * Processes max, min, and avg metrics with multi-stage smoothing
 * and intelligent scene change detection
 * Uses PTS-based time window instead of fixed frame count
 */
void hook() {
    // Cache current frame raw values before any processing
    uvec3 current_quantized = uvec3(
        metered_max_i,
        metered_min_i,
        metered_avg_i
    );
    vec3 current = vec3(current_quantized) / 4095.0;

    // Get previous frame's smoothed values from persistent buffer
    vec3 previous = vec3(smoothed_max_i, smoothed_min_i, smoothed_avg_i);
    uint valid = min(metered_history_valid, TEMPORAL_BUFFER_SIZE);

    if (valid == 0u) {
        temporal_reset_history(current_quantized);
        temporal_publish(current);
        return;
    }

    float newest_pts = pts_to_float(
        metered_pts_t[temporal_history_index(0u)]
    );
    float delta_time = PTS - newest_pts;

    // Redrawing the same video frame must not advance temporal state.
    if (abs(delta_time) <= TEMPORAL_PTS_EPSILON) {
        temporal_publish(previous);
        return;
    }

    // Reset on seeks, timestamp discontinuities, or gaps outside the active
    // history window instead of mixing unrelated temporal segments.
    if (delta_time < 0.0 || delta_time > temporal_stable_window) {
        temporal_reset_history(current_quantized);
        temporal_publish(current);
        return;
    }

    TemporalStatistics statistics = temporal_collect_statistics(
        valid,
        current,
        delta_time
    );
    uint count = statistics.count;

    if (count == 0u) {
        temporal_reset_history(current_quantized);
        temporal_publish(current);
        return;
    }

    vec3 predicted = temporal_predict(count, statistics.prediction);
    vec3 weighted = temporal_weighted_mean(statistics.mean);

    // Detect scene changes by comparing current raw values against predictions
    bool scene_changed = false;

    if (temporal_stable_scene_change > 0 &&
        temporal_scene_history_ready(count, statistics.history_span)) {
        scene_changed = temporal_is_scene_changed(current, predicted);
    }

    if (scene_changed) {
        temporal_reset_history(current_quantized);
        temporal_publish(mix(previous, current, TEMPORAL_CUT_BLEND));
        return;
    }

    temporal_prepend(current_quantized);
    temporal_publish(apply_temporal_smoothing(weighted, previous, delta_time));
}

//!HOOK OUTPUT
//!BIND METERED
//!BIND METADATA
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC metering (metadata)

// For content with dynamic metadata, it will be provided by mpv
// https://github.com/mpv-player/mpv/pull/15239

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

float pq_eotf(float x) {
    float t = pow(x, 1.0 / m2);
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), 1.0 / m1) * pw;
}

const float m2_z = 1.7 * m2;

float iz_eotf_inv(float x) {
    float t = pow(x / pw, m1);
    return pow((c1 + c2 * t) / (1.0 + c3 * t), m2_z);
}

float iz_eotf(float x) {
    float t = pow(x, 1.0 / m2_z);
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), 1.0 / m1) * pw;
}

const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

float I_to_J(float I) {
    return ((1.0 + d) * I) / (1.0 + (d * I)) - d0;
}

float J_to_I(float J) {
    return (J + d0) / (1.0 + d - d * (J + d0));
}

float RGB_to_Y(vec3 rgb) {
    const vec3 coefficients = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);
    return dot(rgb, coefficients);
}

float to_float(uint x) {
    return float(x) / 4095.0;
}

struct MeteringMetrics {
    float maximum;
    float minimum;
    float average;
};

MeteringMetrics resolve_metering_metrics() {
    MeteringMetrics metrics;
    vec3 scene_max_rgb = vec3(scene_max_r, scene_max_g, scene_max_b);
    bool has_pq_peak = max_pq_y > 0.0;
    bool has_scene_peak = any(greaterThan(scene_max_rgb, vec3(0.0)));

    // This must match the peak-metadata conditions on the intensity-map pass.
    // A skipped pass leaves METERED unchanged, so its values are not current.
    bool use_measured = enable_metering > 0 &&
                        !has_pq_peak && !has_scene_peak;

    if (has_pq_peak)
        metrics.maximum = max_pq_y;
    else if (has_scene_peak)
        metrics.maximum = pq_eotf_inv(RGB_to_Y(scene_max_rgb));
    else if (use_measured)
        metrics.maximum = to_float(metered_max_i);
    else if (max_cll > 0.0)
        metrics.maximum = pq_eotf_inv(max_cll);
    else if (max_luma > 0.0)
        metrics.maximum = pq_eotf_inv(max_luma);
    else
        metrics.maximum = pq_eotf_inv(1000.0);

    if (use_measured)
        metrics.minimum = to_float(metered_min_i);
    else if (min_luma > 0.0)
        metrics.minimum = pq_eotf_inv(min_luma);
    else
        metrics.minimum = 0.0;

    if (avg_pq_y > 0.0)
        metrics.average = avg_pq_y;
    else if (scene_avg > 0.0)
        metrics.average = pq_eotf_inv(scene_avg);
    else if (use_measured && enable_metering > 1)
        metrics.average = to_float(metered_avg_i);
    // MaxFALL is the static-metadata fallback for average luminance, but using
    // it as the exposure anchor produced poor results in practice.
    // else if (max_fall > 0.0)
    //     metrics.average = pq_eotf_inv(max_fall);
    else
        metrics.average = 0.0;

    return metrics;
}

float calculate_auto_exposure(MeteringMetrics metrics) {
    float reference_iz = iz_eotf_inv(reference_white);
    float reference_j = I_to_J(reference_iz);
    float anchor_j = auto_exposure_anchor * reference_j;
    float anchor_iz = J_to_I(anchor_j);
    float anchor = iz_eotf(anchor_iz);

    float average = max(pq_eotf(metrics.average), 1e-6);
    float maximum = max(pq_eotf(metrics.maximum), 1e-6);
    float minimum = max(pq_eotf(metrics.minimum), 1e-6);

    float exposure = log2(anchor / average);

    float ev_limit_neg = auto_exposure_limit_negative;
    float ev_limit_pos = auto_exposure_limit_positive;

    if (auto_exposure_limit_input > 0) {
        ev_limit_neg = min(ev_limit_neg, log2(maximum / average));
        ev_limit_pos = min(ev_limit_pos, log2(average / minimum));
    }

    return clamp(exposure, -ev_limit_neg, ev_limit_pos);
}

float resolve_exposure(MeteringMetrics metrics) {
    // A non-zero external value replaces automatic exposure entirely.
    if (exposure_value != 0.0)
        return exposure_value;

    if (metrics.average <= 0.0 || auto_exposure_anchor <= 0.0)
        return 0.0;

    return calculate_auto_exposure(metrics);
}

void apply_exposure_to_range(inout MeteringMetrics metrics, float exposure) {
    if (exposure == 0.0)
        return;

    float scale = exp2(exposure);
    metrics.maximum = pq_eotf_inv(pq_eotf(metrics.maximum) * scale);
    metrics.minimum = pq_eotf_inv(pq_eotf(metrics.minimum) * scale);
}

void hook() {
    MeteringMetrics metrics = resolve_metering_metrics();

    ev = resolve_exposure(metrics);
    apply_exposure_to_range(metrics, ev);

    max_i = metrics.maximum;
    min_i = metrics.minimum;
    avg_i = metrics.average;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND METERING
//!BIND METERED
//!BIND METADATA
//!WHEN preview_metering
//!DESC metering (metadata, preview)

const float JND = 1.0 / 720.0;

float to_float(uint x) {
    return float(x) / 4095.0;
}

vec4 draw_highlights(float value) {
    vec3 metrics = vec3(
        to_float(metered_max_i),
        to_float(metered_avg_i),
        to_float(metered_min_i)
    );
    vec3 matches = 1.0 - step(vec3(5.0 * JND), abs(metrics - value));

    if (enable_metering <= 1)
        matches.y = 0.0;

    float opacity = 0.75 * max(max(matches.x, matches.y), matches.z);
    return vec4(matches, opacity);
}

const float m1 = 2610.0 / 4096.0 / 4.0;
const float m2 = 2523.0 / 4096.0 * 128.0;
const float c1 = 3424.0 / 4096.0;
const float c2 = 2413.0 / 4096.0 * 32.0;
const float c3 = 2392.0 / 4096.0 * 32.0;
const float pw = 10000.0;

float pq_eotf(float x) {
    float t = pow(x, 1.0 / m2);
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), 1.0 / m1) * pw;
}

// 3x5 bitmap font rendering
const float CHAR_W = 3.0;
const float CHAR_H = 5.0;
const float SPACING = 1.0;
const float MARGIN = 8.0;
const float PAD = 2.0;
const float SCALE = 4.0;
const float LINE_H = CHAR_H + 2.0;

const uint FONT_DIGITS[10] = uint[10](
    0x7B6Fu, 0x749Au, 0x73E7u, 0x79E7u, 0x49EDu,
    0x79CFu, 0x7BCFu, 0x4927u, 0x7BEFu, 0x79EFu
);
const uint FONT_LETTERS[26] = uint[26](
    0x5BEFu, 0x3AEBu, 0x724Fu, 0x3B6Bu, 0x72CFu, 0x12CFu, 0x7B4Fu,
    0x5BEDu, 0x7497u, 0x7B24u, 0x5AEDu, 0x7249u, 0x5BFDu, 0x5B6Fu,
    0x7B6Fu, 0x13EFu, 0x49EFu, 0x5AEFu, 0x388Eu, 0x2497u, 0x7B6Du,
    0x256Du, 0x5FEDu, 0x5AADu, 0x24ADu, 0x72A7u
);
const uint FONT_COLON = 0x0410u;
const uint FONT_DOT   = 0x2000u;
const uint FONT_MINUS = 0x01C0u;
const uint FONT_SPACE = 0x0000u;
const uint FONT_TOFU  = 0x7FFFu;

const int CH_SPACE = 32;
const int CH_MINUS = 45;
const int CH_DOT   = 46;
const int CH_0 = 48;
const int CH_9 = 57;
const int CH_COLON = 58;
const int CH_A = 65;
const int CH_E = 69;
const int CH_G = 71;
const int CH_I = 73;
const int CH_M = 77;
const int CH_N = 78;
const int CH_V = 86;
const int CH_X = 88;
const int CH_Z = 90;

uint get_glyph(int ch) {
    if (ch >= CH_0 && ch <= CH_9)
        return FONT_DIGITS[ch - CH_0];
    if (ch >= CH_A && ch <= CH_Z)
        return FONT_LETTERS[ch - CH_A];

    if (ch == CH_SPACE) return FONT_SPACE;
    if (ch == CH_MINUS) return FONT_MINUS;
    if (ch == CH_DOT)   return FONT_DOT;
    if (ch == CH_COLON) return FONT_COLON;
    return FONT_TOFU;
}

bool glyph_pixel(uint glyph, vec2 p) {
    if (p.x < 0.0 || p.x >= CHAR_W || p.y < 0.0 || p.y >= CHAR_H) return false;
    uint bit = uint(p.y) * 3u + uint(p.x);
    return (glyph & (1u << bit)) != 0u;
}

vec4 draw_char(int ch, vec2 local, inout float cx) {
    vec2 cp = local - vec2(cx, 0.0);
    cx += CHAR_W + SPACING;
    if (cp.x >= 0.0 && cp.x < CHAR_W && cp.y >= 0.0 && cp.y < CHAR_H) {
        if (glyph_pixel(get_glyph(ch), cp))
            return vec4(1.0, 1.0, 1.0, 1.0);
    }
    return vec4(0.0);
}

float number_width(float value) {
    float abs_val = min(abs(value), 99999.99);
    uint int_part = uint(abs_val * 100.0 + 0.5) / 100u;

    uint digits = 1u;
    if      (int_part >= 10000u) digits = 5u;
    else if (int_part >= 1000u)  digits = 4u;
    else if (int_part >= 100u)   digits = 3u;
    else if (int_part >= 10u)    digits = 2u;

    float characters = float(digits + 3u) + (value < 0.0 ? 1.0 : 0.0);
    return characters * (CHAR_W + SPACING);
}

float pq_number_width(float value) {
    // PQ codes where two-decimal formatting rounds up to 10, 100, 1000,
    // and 10000 nits respectively.
    const vec4 digit_thresholds = vec4(
        0.299659661,
        0.508073403,
        0.751826551,
        0.999999948
    );
    float digits = 1.0 + dot(step(digit_thresholds, vec4(value)), vec4(1.0));
    return (digits + 3.0) * (CHAR_W + SPACING);
}

vec4 draw_number(float value, vec2 local, inout float cx) {
    bool negative = value < 0.0;
    float abs_val = min(abs(value), 99999.99);

    uint fixed_value = uint(abs_val * 100.0 + 0.5);
    uint int_part = fixed_value / 100u;
    uint dec_part = fixed_value - int_part * 100u;

    uint d0 = (int_part / 10000u) % 10u;
    uint d1 = (int_part / 1000u) % 10u;
    uint d2 = (int_part / 100u) % 10u;
    uint d3 = (int_part / 10u) % 10u;
    uint d4 = int_part % 10u;
    uint d5 = dec_part / 10u;
    uint d6 = dec_part % 10u;

    uint first = 4u;
    if (d0 > 0u) first = 0u;
    else if (d1 > 0u) first = 1u;
    else if (d2 > 0u) first = 2u;
    else if (d3 > 0u) first = 3u;

    vec4 r = vec4(0.0);

    if (negative)    r = max(r, draw_char(CH_MINUS, local, cx));
    if (first <= 0u) r = max(r, draw_char(int(d0) + CH_0, local, cx));
    if (first <= 1u) r = max(r, draw_char(int(d1) + CH_0, local, cx));
    if (first <= 2u) r = max(r, draw_char(int(d2) + CH_0, local, cx));
    if (first <= 3u) r = max(r, draw_char(int(d3) + CH_0, local, cx));
    r = max(r, draw_char(int(d4) + CH_0, local, cx));
    r = max(r, draw_char(CH_DOT, local, cx));
    r = max(r, draw_char(int(d5) + CH_0, local, cx));
    r = max(r, draw_char(int(d6) + CH_0, local, cx));

    return r;
}

// Draw a labeled row: "LABEL:value"
// Returns max cx across all rows for background width.
vec4 draw_row(float value, vec2 origin, vec2 px, int c0, int c1, int c2, inout float cx) {
    float label_width = 4.0 * (CHAR_W + SPACING);
    float width = label_width + number_width(value);
    vec2 local = (px - origin) / SCALE;

    if (local.x < 0.0 || local.x >= width ||
        local.y < 0.0 || local.y >= CHAR_H) {
        cx = width;
        return vec4(0.0);
    }

    vec4 r = vec4(0.0);

    if (local.x < label_width) {
        r = max(r, draw_char(c0, local, cx));
        r = max(r, draw_char(c1, local, cx));
        r = max(r, draw_char(c2, local, cx));
        r = max(r, draw_char(CH_COLON, local, cx));
    } else {
        cx = label_width;
        r = max(r, draw_number(value, local, cx));
    }

    cx = width;
    return r;
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    vec2 px = HOOKED_pos * HOOKED_size;
    float value = METERING_tex(METERING_pos).x;

    vec4 highlight = draw_highlights(value);

    color.rgb = mix(color.rgb, highlight.rgb, highlight.a);

    // The longest row contains four label characters and a signed 5.2 number.
    const float MAX_ROW_WIDTH = 13.0 * (CHAR_W + SPACING);
    vec2 o3 = vec2(MARGIN * SCALE, HOOKED_size.y - MARGIN * SCALE - CHAR_H * SCALE);
    vec2 o0 = o3 - vec2(0.0, 3.0 * LINE_H * SCALE);
    vec2 panel_min = o0 - vec2(PAD * SCALE);
    vec2 panel_max = vec2(
        o0.x + (MAX_ROW_WIDTH + PAD) * SCALE,
        o3.y + (CHAR_H + PAD) * SCALE
    );

    if (any(lessThan(px, panel_min)) || any(greaterThan(px, panel_max))) {
        return color;
    }

    float label_width = 4.0 * (CHAR_W + SPACING);
    vec4 row_widths = label_width + vec4(
        pq_number_width(max_i),
        pq_number_width(min_i),
        pq_number_width(avg_i),
        number_width(ev)
    );
    float max_w = max(max(row_widths.x, row_widths.y),
                      max(row_widths.z, row_widths.w));

    if (px.x > o0.x + (max_w + PAD) * SCALE) {
        return color;
    }

    vec4 r = vec4(0.0, 0.0, 0.0, 1.0);
    float row_stride = LINE_H * SCALE;
    int row = int(floor((px.y - o0.y) / row_stride));

    if (row >= 0 && row < 4) {
        vec2 origin = o0 + vec2(0.0, float(row) * row_stride);
        vec2 local = px - origin;

        if (local.x >= 0.0 && local.x < row_widths[row] * SCALE &&
            local.y >= 0.0 && local.y < CHAR_H * SCALE) {
            float cx = 0.0;

            if (row == 0)
                r = max(r, draw_row(pq_eotf(max_i), origin, px, CH_M, CH_A, CH_X, cx));
            else if (row == 1)
                r = max(r, draw_row(pq_eotf(min_i), origin, px, CH_M, CH_I, CH_N, cx));
            else if (row == 2)
                r = max(r, draw_row(pq_eotf(avg_i), origin, px, CH_A, CH_V, CH_G, cx));
            else
                r = max(r, draw_row(ev, origin, px, CH_E, CH_V, CH_SPACE, cx));
        }
    }

    color.rgb = mix(color.rgb, r.rgb, r.a);
    return color;
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND METADATA
//!WHEN auto_exposure_anchor 0 > enable_metering 1 > avg_pq_y 0 > + scene_avg 0 > + *
//!DESC tone mapping (auto exposure)

vec3 exposure(vec3 x, float ev) {
    return x * exp2(ev);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    color.rgb = exposure(color.rgb, ev);

    return color;
}

//!HOOK OUTPUT
//!BIND METADATA
//!SAVE LUTS
//!WIDTH 4225
//!HEIGHT 131
//!COMPUTE 32 8
//!DESC tone mapping (LUT generation, astra)

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

vec3 pq_eotf_inv(vec3 x) {
    vec3 t = pow(x / pw, vec3(m1));
    return pow((c1 + c2 * t) / (1.0 + c3 * t), vec3(m2));
}

float pq_eotf(float x) {
    float t = pow(x, 1.0 / m2);
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), 1.0 / m1) * pw;
}

vec3 pq_eotf(vec3 x) {
    vec3 t = pow(x, vec3(1.0 / m2));
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), vec3(1.0 / m1)) * pw;
}

// Jzazbz added a factor to m2, which differs from the original PQ equation.
const float m2_z = 1.7 * m2;

float iz_eotf_inv(float x) {
    float t = pow(x / pw, m1);
    return pow((c1 + c2 * t) / (1.0 + c3 * t), m2_z);
}

vec3 iz_eotf_inv(vec3 x) {
    vec3 t = pow(x / pw, vec3(m1));
    return pow((c1 + c2 * t) / (1.0 + c3 * t), vec3(m2_z));
}

float iz_eotf(float x) {
    float t = pow(x, 1.0 / m2_z);
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), 1.0 / m1) * pw;
}

vec3 iz_eotf(vec3 x) {
    vec3 t = pow(x, vec3(1.0 / m2_z));
    return pow(max(t - c1, 0.0) / (c2 - c3 * t), vec3(1.0 / m1)) * pw;
}

vec3 RGB_to_XYZ(vec3 RGB) {
    const mat3 M = mat3(
        0.6369580483012914, 0.14461690358620832,  0.1688809751641721,
        0.2627002120112671, 0.6779980715188708,   0.05930171646986196,
        0.0               , 0.028072693049087428, 1.060985057710791
    );
    return RGB * M;
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    const mat3 M = mat3(
         1.716651187971268, -0.355670783776392, -0.25336628137366,
        -0.666684351832489,  1.616481236634939,  0.0157685458139111,
         0.017639857445311, -0.042770613257809,  0.942103121235474
    );
    return XYZ * M;
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
    const mat3 M =mat3(
         0.41478972, 0.579999, 0.0146480,
        -0.2015100,  1.120649, 0.0531008,
        -0.0166008,  0.264800, 0.6684799
    );
    return XYZ * M;
}

vec3 LMS_to_XYZ(vec3 LMS) {
    const mat3 M = mat3(
         1.9242264357876067,  -1.0047923125953657,  0.037651404030618,
         0.35031676209499907,  0.7264811939316552, -0.06538442294808501,
        -0.09098281098284752, -0.3127282905230739,  1.5227665613052603
    );
    return LMS * M;
}

vec3 LMS_to_Iab(vec3 LMS) {
    const mat3 M = mat3(
        0.0,       0.5,       0.5,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875
    );
    return LMS * M;
}

vec3 Iab_to_LMS(vec3 Iab) {
    const mat3 M = mat3(
        1.0,  0.13860504327153927,  0.05804731615611883,
        1.0, -0.1386050432715393,  -0.058047316156118904,
        1.0, -0.09601924202631895, -0.81189189605603900
    );
    return Iab * M;
}

// https://doi.org/10.2352/ISSN.2169-2629.2017.25.264
// Optimized matrices for Jzazbz about LMS to I conversion.
// https://doi.org/10.1364/OE.413659
// ZCAM defines Iz = G' - ε, where ε = 3.7035226210190005e-11.
// However, it appears we do not need it.
vec3 LMS_to_Iab_optimized(vec3 LMS) {
    const mat3 M = mat3(
        0.0,       1.0,       0.0,
        3.524000, -4.066708,  0.542708,
        0.199076,  1.096799, -1.295875
    );
    return LMS * M;
}

vec3 Iab_to_LMS_optimized(vec3 Iab) {
    const mat3 M = mat3(
        1.0, 0.2772100865430786,  0.1160946323122377,
        1.0, 0.0,                 0.0,
        1.0, 0.0425858012452203, -0.75384457989992
    );
    return Iab * M;
}

const float d = -0.56;
const float d0 = 1.6295499532821566e-11;

float I_to_J(float I) {
    return ((1.0 + d) * I) / (1.0 + (d * I)) - d0;
}

float J_to_I(float J) {
    return (J + d0) / (1.0 + d - d * (J + d0));
}

// CIELUV: -0.01585, -0.03017, -0.04556, -0.02667, -0.00295, 0.14592, 0.05084, -0.01900, -0.00764
float hke_fh_nayatani(
    float h, float k1,
    float k2, float k3, float k4, float k5,
    float k6, float k7, float k8, float k9
) {
    float q = k1 +
        k2 * cos(h) + k3 * cos(2.0 * h) + k4 * cos(3.0 * h) + k5 * cos(4.0 * h) +
        k6 * sin(h) + k7 * sin(2.0 * h) + k8 * sin(3.0 * h) + k9 * sin(4.0 * h);
    // flipped
    return -q;
}

// CIECAM02: -0.218, 0.167, -0.500, 0.032, 0.887
// CAM16: -0.160, 0.132, -0.405, 0.080, 0.792
float hke_fh_hellwig(float h, float a1, float a2, float a3, float a4, float a5) {
    return a1 * cos(h) + a2 * cos(2.0 * h) + a3 * sin(h) + a4 * sin(2.0 * h) + a5;
}

// CIELAB: 0.1644, 0.0603, 0.1307, 0.0060
float hke_fh_high(float h, float k1, float k2, float k3, float k4) {
    h = mod(mod(degrees(h), 360.0) + 360.0, 360.0);
    float by = k1 * abs(sin(radians((h - 90.0)/ 2.0))) + k2;
    float r  = h <= 90.0 || h >= 270.0 ? k3 * abs(cos(radians(h))) + k4 : 0.0;
    return by + r;
}

// CIECAM16: 1.5940, 45.0, 2.6518
// CIELAB: 0.1644, 45.0, 0.1024
float hke_fh_liao(float h, float k3, float k4, float k5) {
    h = mod(mod(degrees(h), 360.0) + 360.0, 360.0);
    return k3 * abs(log(((h + k4) / (90.0 + k4)))) + k5;
}

float hke_fh(float h) {
    float result = hke_fh_liao(h, 0.1351, 45.0, 0.1439);
    return result * hk_effect_compensate_scaling;
}

// Lightness modifications of the CIECAM16 and CIELAB based
// on the Helmholtz-Kohlrausch effect
// by Liao et al.
// https://doi.org/10.1364/OE.534073
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

// https://www.itu.int/rec/R-REC-BT.2124
// ΔE_ITP_JND = 1 / 720
// 0.0001 of Cz is much smaller than it
const float epsilon = 0.0001;

vec3 Lab_to_LCh(vec3 Lab) {
    float L = Lab.x;
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float h = C < epsilon ? 0.0 : atan(b, a);

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

// Perceptually uniform color space for image signals including
// high dynamic range and wide gamut
// by Safdar et al.
// https://doi.org/10.1364/OE.25.015131
//
// an optimized version of the LMS to Iab matrix was used,
// and H-K effect compensation was added.
vec3 RGB_to_Jab(vec3 color) {
    color *= reference_white;
    color = RGB_to_XYZ(color);
    color = XYZ_to_XYZm(color);
    color = XYZ_to_LMS(color);
    color = iz_eotf_inv(max(color, vec3(0.0)));
    color = LMS_to_Iab_optimized(color);
    color.x = I_to_J(color.x);
    color.x = J_to_Jhk(Lab_to_LCh(color));
    return color;
}

vec3 Jab_to_RGB(vec3 color) {
    color.x = Jhk_to_J(Lab_to_LCh(color));
    color.x = J_to_I(color.x);
    color = Iab_to_LMS_optimized(color);
    color = iz_eotf(max(color, vec3(0.0)));
    color = LMS_to_XYZ(color);
    color = XYZm_to_XYZ(color);
    color = XYZ_to_RGB(color);
    color /= max(reference_white, 1e-6);
    return color;
}

float f_slope(float x0, float y0, float x1, float y1) {
    float num = (y1 - y0);
    float den = (x1 - x0);
    return abs(den) < 1e-6 ? 1.0 : num / den;
}

float f_intercept(float slope, float x0, float y0) {
    return y0 - slope * x0;
}

float f_linear(float x, float slope, float intercept) {
    return slope * x + intercept;
}

// Linear relationship between angle and parameter c
// c = 0: angle = 45° (slope = 1)
// c = ±N: angle = 45° ± k*N
float f_contrast(float c) {
    float range = 40.0; // 40° per unit of c
    float angle = radians(45.0 + range * c);
    float slope = tan(angle);
    return 1.0 - 1.0 / slope;
}

// Hyperbola tone mapping
// by suzuki et al.
// https://technorgb.blogspot.com/2018/02/hyperbola-tone-mapping.html
float f_toe_suzuki(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;
    float dt = x - x0;
    float k = dy - slope * dx;
    float scale = dy * dy;
    float base = slope * dx * dx;

    return y0 + scale * dt / (dt * k + base);
}

float f_shoulder_suzuki(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;
    float dt = x - x0;
    float k = slope * dx - dy;
    float scale = slope * dx * dy;
    float base = dx * dy;

    return y0 + scale * dt / (dt * k + base);
}

// Filmic Tonemapping with Piecewise Power Curves
// by John Hable
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/
float f_toe_hable(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;

    float b = slope * dx / dy;
    float a = log(dy) - b * log(dx);
    float s = 1.0;

    float v = max((x - x0) * s, 1e-6);
    float o = y0;

    return exp(a + b * log(v)) * s + o;
}

float f_shoulder_hable(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;

    float b = slope * dx / dy;
    float a = log(dy) - b * log(dx);
    float s = -1.0;

    float v = max((x - x1) * s, 1e-6);
    float o = y1;

    return exp(a + b * log(v)) * s + o;
}

// Hable shoulder with overshoot: extends the virtual white point to
// (x1 + overshoot * dx, y1 + overshoot * dy), so the curve still has
// non-zero slope at x1.  Accepts a slight slope discontinuity at x0.
// overshoot = 0 recovers f_shoulder_hable.
float f_shoulder_hable_overshoot(float x, float slope, float x0, float y0, float x1, float y1, float overshoot) {
    float dx = x1 - x0;
    float dy = y1 - y0;
    float vx = x1 + overshoot * dx;
    float vy = y1 + overshoot * dy;

    float y  = f_shoulder_hable(x,  slope, x0, y0, vx, vy);
    float yw = f_shoulder_hable(x1, slope, x0, y0, vx, vy);

    float t = (y - y0) / (yw - y0);

    return mix(y0, y1, t);
}

float f(
    float x, float iw, float ib, float ow, float ob,
    float sw, float hw, float cb
) {
    float midgray   = 0.5 * ow;
    float shadow    = mix(midgray, ob, sw);
    float highlight = mix(midgray, ow, hw);
    float contrast  = f_contrast(cb);

    float x0 = ib;
    float y0 = ob;
    float x1 = mix(shadow, midgray, contrast);
    float y1 = shadow;
    float x2 = mix(highlight, midgray, contrast);
    float y2 = highlight;
    float x3 = iw;
    float y3 = ow;

    float slope = f_slope(x1, y1, x2, y2);
    float intercept = f_intercept(slope, x1, y1);

    if (x >= x1 && x <= x2) {
        return f_linear(x, slope, intercept);
    }

    if (x < x1) {
        float slope_toe = f_slope(x0, y0, x1, y1);
        if (slope_toe >= slope) {
            return f_linear(x, slope, intercept);
        }

        return f_toe_suzuki(x, slope, x0, y0, x1, y1);
    }

    if (x > x2) {
        float slope_shoulder = f_slope(x2, y2, x3, y3);
        if (slope_shoulder >= slope) {
            return f_linear(x, slope, intercept);
        }

        return f_shoulder_hable_overshoot(x, slope, x2, y2, x3, y3, highlight_overshoot);
    }

    return x;
}

float f(float x, float iw, float ib, float ow, float ob) {
    return f(
        x, iw, ib, ow, ob,
        shadow_weight, highlight_weight, contrast_bias
    );
}

float curve(float x) {
    float ow = I_to_J(iz_eotf_inv(reference_white));
    float ob = I_to_J(iz_eotf_inv(reference_white / contrast_ratio));
    float iw = I_to_J(iz_eotf_inv(pq_eotf(max_i)));
    float ib = I_to_J(iz_eotf_inv(pq_eotf(min_i)));

    iw = max(iw, ow);
    ib = min(ib, ob);

    float y = f(x, iw, ib, ow, ob);

    return clamp(y, ob, ow);
}

// LUT atlas layout: two flattened 65^3 LUTs followed by one 1024-point row.
const int LUT_SIZE = 65;
const int LUT_LAST = LUT_SIZE - 1;
const int RGB_TO_LAB_ROW = 0;
const int LAB_TO_RGB_ROW = LUT_SIZE;
const int CURVE_ROW = LUT_SIZE * 2;
const int CURVE_SIZE = 1024;

// LAB chroma-coordinate shaper: the scale concentrates precision near neutral,
// while the limits define the representable ranges of the a/L and b/L ratios.
const float AB_RATIO_SCALE = 0.25;
const float A_RATIO_LIMIT = 2.0;
const float B_RATIO_LIMIT = 2.5;

vec3 lut_coordinates_to_RGB(vec3 coordinates) {
    vec3 absolute_rgb = pq_eotf(clamp(coordinates, 0.0, 1.0));
    return absolute_rgb / max(reference_white, 1e-6);
}

float decode_signed_coordinate(float coordinate, float limit) {
    float qmax = limit / (limit + AB_RATIO_SCALE);
    float signed_coordinate = 2.0 * clamp(coordinate, 0.0, 1.0) - 1.0;
    float q = abs(signed_coordinate) * qmax;
    float value = AB_RATIO_SCALE * q / max(1.0 - q, 1e-6);
    return sign(signed_coordinate) * value;
}

vec3 lut_coordinates_to_LAB(vec3 coordinates) {
    float L = clamp(coordinates.x, 0.0, 1.0);
    float a_ratio = decode_signed_coordinate(coordinates.y, A_RATIO_LIMIT);
    float b_ratio = decode_signed_coordinate(coordinates.z, B_RATIO_LIMIT);
    return vec3(L, a_ratio * L, b_ratio * L);
}

vec3 atlas_to_lut_coordinates(ivec2 atlas_position, int first_row) {
    ivec3 lut_texel = ivec3(
        atlas_position.x % LUT_SIZE,
        atlas_position.x / LUT_SIZE,
        atlas_position.y - first_row
    );
    return vec3(lut_texel) / float(LUT_LAST);
}

void store_atlas(ivec2 atlas_position, vec3 value) {
    imageStore(out_image, atlas_position, vec4(value, 1.0));
}

void generate_RGB_to_LAB_lut(ivec2 atlas_position) {
    vec3 coordinates = atlas_to_lut_coordinates(
        atlas_position,
        RGB_TO_LAB_ROW
    );
    vec3 rgb = lut_coordinates_to_RGB(coordinates);
    store_atlas(atlas_position, RGB_to_Jab(rgb));
}

void generate_LAB_to_RGB_lut(ivec2 atlas_position) {
    vec3 coordinates = atlas_to_lut_coordinates(
        atlas_position,
        LAB_TO_RGB_ROW
    );
    vec3 lab = lut_coordinates_to_LAB(coordinates);
    store_atlas(atlas_position, Jab_to_RGB(lab));
}

void generate_curve_lut(ivec2 atlas_position) {
    float coordinate = float(atlas_position.x) / float(CURVE_SIZE - 1);
    store_atlas(atlas_position, vec3(curve(coordinate), 0.0, 0.0));
}

void hook() {
    ivec2 atlas_position = ivec2(gl_GlobalInvocationID.xy);

    if (atlas_position.x >= LUT_SIZE * LUT_SIZE ||
        atlas_position.y > CURVE_ROW) {
        return;
    }

    if (atlas_position.y < LAB_TO_RGB_ROW) {
        generate_RGB_to_LAB_lut(atlas_position);
    } else if (atlas_position.y < CURVE_ROW) {
        generate_LAB_to_RGB_lut(atlas_position);
    } else if (atlas_position.x < CURVE_SIZE) {
        generate_curve_lut(atlas_position);
    }
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND LUTS
//!DESC tone mapping (LUT application)

// LUT atlas layout: two flattened 65^3 LUTs followed by one 1024-point row.
const int LUT_SIZE = 65;
const int LUT_LAST = LUT_SIZE - 1;
const int RGB_TO_LAB_ROW = 0;
const int LAB_TO_RGB_ROW = LUT_SIZE;
const int CURVE_ROW = LUT_SIZE * 2;
const int CURVE_SIZE = 1024;

// LAB chroma-coordinate shaper: the scale concentrates precision near neutral,
// while the limits define the representable ranges of the a/L and b/L ratios.
const float AB_RATIO_SCALE = 0.25;
const float A_RATIO_LIMIT = 2.0;
const float B_RATIO_LIMIT = 2.5;

// SMPTE ST 2084 (PQ), converting absolute luminance in nit to code values.
const float m1 = 2610.0 / 4096.0 / 4.0;
const float m2 = 2523.0 / 4096.0 * 128.0;
const float c1 = 3424.0 / 4096.0;
const float c2 = 2413.0 / 4096.0 * 32.0;
const float c3 = 2392.0 / 4096.0 * 32.0;
const float pw = 10000.0;

vec3 pq_eotf_inv(vec3 x) {
    vec3 t = pow(x / pw, vec3(m1));
    return pow((c1 + c2 * t) / (1.0 + c3 * t), vec3(m2));
}

vec3 fetch_atlas_raw(ivec2 position) {
    return texelFetch(LUTS_raw, position, 0).rgb;
}

vec3 fetch_lut3d_raw(int first_row, ivec3 texel) {
    ivec2 atlas_position = ivec2(
        texel.x + texel.y * LUT_SIZE,
        first_row + texel.z
    );
    return fetch_atlas_raw(atlas_position);
}

// Select the two middle vertices of the tetrahedron and sort the fractional
// coordinates into the corresponding interpolation order.
void select_tetrahedron(
    vec3 fraction,
    out ivec3 second_offset,
    out ivec3 third_offset,
    out vec3 weights
) {
    if (fraction.x >= fraction.y) {
        if (fraction.y >= fraction.z) {
            second_offset = ivec3(1, 0, 0);
            third_offset = ivec3(1, 1, 0);
            weights = fraction.xyz;
        } else if (fraction.x >= fraction.z) {
            second_offset = ivec3(1, 0, 0);
            third_offset = ivec3(1, 0, 1);
            weights = fraction.xzy;
        } else {
            second_offset = ivec3(0, 0, 1);
            third_offset = ivec3(1, 0, 1);
            weights = fraction.zxy;
        }
    } else {
        if (fraction.x >= fraction.z) {
            second_offset = ivec3(0, 1, 0);
            third_offset = ivec3(1, 1, 0);
            weights = fraction.yxz;
        } else if (fraction.y >= fraction.z) {
            second_offset = ivec3(0, 1, 0);
            third_offset = ivec3(0, 1, 1);
            weights = fraction.yzx;
        } else {
            second_offset = ivec3(0, 0, 1);
            third_offset = ivec3(0, 1, 1);
            weights = fraction.zyx;
        }
    }
}

vec3 sample_lut_tetrahedral(vec3 lut_coordinates, int first_row) {
    vec3 position = clamp(lut_coordinates, 0.0, 1.0) * float(LUT_LAST);
    ivec3 base_texel = ivec3(floor(position));
    vec3 fraction = fract(position);

    ivec3 second_offset;
    ivec3 third_offset;
    vec3 weights;
    select_tetrahedron(fraction, second_offset, third_offset, weights);

    ivec3 last_texel = ivec3(LUT_LAST);
    ivec3 texel0 = base_texel;
    ivec3 texel1 = min(base_texel + second_offset, last_texel);
    ivec3 texel2 = min(base_texel + third_offset, last_texel);
    ivec3 texel3 = min(base_texel + ivec3(1), last_texel);

    vec3 value0 = fetch_lut3d_raw(first_row, texel0);
    vec3 value1 = fetch_lut3d_raw(first_row, texel1);
    vec3 value2 = fetch_lut3d_raw(first_row, texel2);
    vec3 value3 = fetch_lut3d_raw(first_row, texel3);

    vec3 interpolated = value0
                      + weights.x * (value1 - value0)
                      + weights.y * (value2 - value1)
                      + weights.z * (value3 - value2);
    return LUTS_mul * interpolated;
}

// Rational signed shaper mapping [-limit, limit] to [0, 1], with additional
// precision around zero where most a/b values are concentrated.
float encode_signed_coordinate(float value, float limit) {
    float maximum_magnitude = limit / (limit + AB_RATIO_SCALE);
    float encoded_magnitude = abs(value) / (abs(value) + AB_RATIO_SCALE);
    float signed_magnitude = sign(value) * encoded_magnitude / maximum_magnitude;
    return clamp(0.5 + 0.5 * signed_magnitude, 0.0, 1.0);
}

vec3 RGB_to_lut_coordinates(vec3 rgb) {
    vec3 absolute_rgb = clamp(
        max(rgb, vec3(0.0)) * max(reference_white, 0.0),
        0.0,
        pw
    );
    return pq_eotf_inv(absolute_rgb);
}

vec3 LAB_to_lut_coordinates(vec3 lab) {
    float L = max(lab.x, 0.0);
    vec2 chroma_ratio = lab.yz / max(L, 1e-6);
    return vec3(
        clamp(L, 0.0, 1.0),
        encode_signed_coordinate(chroma_ratio.x, A_RATIO_LIMIT),
        encode_signed_coordinate(chroma_ratio.y, B_RATIO_LIMIT)
    );
}

vec3 RGB_to_LAB(vec3 rgb) {
    vec3 coordinates = RGB_to_lut_coordinates(rgb);
    return sample_lut_tetrahedral(coordinates, RGB_TO_LAB_ROW);
}

vec3 LAB_to_RGB(vec3 lab) {
    vec3 coordinates = LAB_to_lut_coordinates(lab);
    return sample_lut_tetrahedral(coordinates, LAB_TO_RGB_ROW);
}

float curve(float x) {
    float position = clamp(x, 0.0, 1.0) * float(CURVE_SIZE - 1);
    int lower_index = int(floor(position));
    int upper_index = min(lower_index + 1, CURVE_SIZE - 1);
    float weight = fract(position);
    float lower_value = fetch_atlas_raw(ivec2(lower_index, CURVE_ROW)).x;
    float upper_value = fetch_atlas_raw(ivec2(upper_index, CURVE_ROW)).x;
    return LUTS_mul * mix(lower_value, upper_value, weight);
}

float chroma_correction_attenuation(float x, float rate, float threshold) {
    float range = max(1.0 - threshold, 1e-6);
    float norm = clamp((x - threshold) / range, 0.0, 1.0);
    return pow(norm, 1.0 + rate * (1.0 - norm));
}

// based on the chroma correction method for ICtCp in BT.2390/BT.2408
// https://www.itu.int/pub/R-REP-BT.2408
//
// a power factor is added to increase correction rate.
//
// this is a correction in generic vividness and depth.
// V = sqrt(J^2 + C^2)
// D = sqrt((J_max - J)^2 + C^2)
//
// more specific definitions of V and D for Jzazbz,
// see the following links:
// https://doi.org/10.2352/ISSN.2169-2629.2018.26.96
// https://doi.org/10.2352/issn.2169-2629.2019.27.43
vec2 chroma_correction(vec2 ab, float l1, float l2) {
    float ratio_min = min(l1, l2) / max(max(l1, l2), 1e-6);
    float ratio_scaled = mix(1.0, ratio_min, chroma_correction_scaling);
    float ratio_safe = max(ratio_scaled, 0.0);
    return ab * chroma_correction_attenuation(
        ratio_safe,
        chroma_correction_rate,
        chroma_correction_threshold
    );
}

vec3 tone_mapping(vec3 lab) {
    float l2 = curve(lab.x);
    vec2 ab2 = chroma_correction(lab.yz, lab.x, l2);
    return vec3(l2, ab2);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    color.rgb = RGB_to_LAB(color.rgb);
    color.rgb = tone_mapping(color.rgb);
    color.rgb = LAB_to_RGB(color.rgb);
    return color;
}
