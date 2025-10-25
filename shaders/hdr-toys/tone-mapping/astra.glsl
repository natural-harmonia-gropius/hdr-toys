// Astra, a tone mapping operator designed to preserve the creator's intent

// working space: https://doi.org/10.1364/OE.25.015131
// hk effect: https://doi.org/10.1364/OE.534073
// chroma correction: https://www.itu.int/pub/R-REP-BT.2408
// dynamic metadata: https://github.com/mpv-player/mpv/pull/15239
// fast gaussian blur: https://www.rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
// toe segment of curve: https://technorgb.blogspot.com/2018/02/hyperbola-tone-mapping.html
// shoulder segment of curve: http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/

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
0.75

//!PARAM auto_exposure_limit_negtive
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
2.3

//!PARAM auto_exposure_limit_postive
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 5.0
0.0

//!PARAM shadow_weight
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.46

//!PARAM highlight_weight
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.04

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
//!VAR uint metered_max_i_t[128]
//!VAR uint metered_min_i_t[128]
//!VAR uint metered_avg_i_t[128]
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
    const vec3 luma_coef = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);
    return dot(rgb, luma_coef);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);
    return vec4(pq_eotf_inv(RGB_to_Y(color.rgb) * reference_white));
}

//!HOOK OUTPUT
//!BIND METERING
//!SAVE METERING
//!WIDTH 512
//!HEIGHT 288
//!DESC metering (spatial stabilization, downscaling)

vec4 hook() {
    return METERING_tex(METERING_pos);
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
//!DESC metering (max, min)

shared uint local_max;
shared uint local_min;

void hook() {
    if (gl_GlobalInvocationID.x == 0 && gl_GlobalInvocationID.y == 0) {
        metered_max_i = 0;
        metered_min_i = 4095;
    }

    if (gl_LocalInvocationIndex == 0) {
        local_max = 0;
        local_min = 4095;
    }

    memoryBarrierShared();
    barrier();

    float value = METERING_tex(METERING_pos).x;
    uint rounded = uint(value * 4095.0 + 0.5);
    atomicMax(local_max, rounded);
    atomicMin(local_min, rounded);

    memoryBarrierShared();
    barrier();

    if (gl_LocalInvocationIndex == 0) {
        atomicMax(metered_max_i, local_max);
        atomicMin(metered_min_i, local_min);
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
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 128)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 64)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 32)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 16)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 8)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 4)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!SAVE AVG
//!WIDTH AVG.w 2 /
//!HEIGHT AVG.h 2 /
//!DESC metering (avg, 2)
vec4 hook() { return AVG_tex(AVG_pos); }

//!HOOK OUTPUT
//!BIND AVG
//!BIND METERED
//!SAVE AVG
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!DESC metering (avg)

void hook() {
    metered_avg_i = uint(AVG_tex(AVG_pos).x * 4095.0 + 0.5);
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

// ============================================================================
// TEMPORAL STABILIZATION - Configuration Parameters
// ============================================================================
// These parameters control the temporal smoothing behavior to reduce flicker
// while maintaining responsiveness to actual scene changes.

// Exponential decay factor for weighted moving average
// Range: 0.7-0.95. Lower = more smoothing but slower response
// Default: 0.85 balances smoothness and responsiveness
const float TEMPORAL_DECAY = 0.85;

// EMA (Exponential Moving Average) smoothing factor
// Range: 0.1-0.3. Lower = smoother but less responsive
// Default: 0.2 provides good stability without excessive lag
const float TEMPORAL_EMA_ALPHA = 0.2;

// Blend factor for gradual scene transition
// Range: 0.3-0.7. Lower = smoother transitions during scene cuts
// Default: 0.5 provides balanced transition speed
const float TEMPORAL_SCENE_BLEND = 0.5;

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
// Range: 8.0-32.0 (in 12-bit range). Higher = more aggressive black detection
// Default: 16.0 catches most black frames without false positives
const float TEMPORAL_BLACK_THRESHOLD = 16.0;

// Metric weights for scene change detection
// These weights determine the relative importance of each metric
// Total should sum to 1.0 for balanced detection
const float TEMPORAL_WEIGHT_AVG = 0.50; // Average is most reliable
const float TEMPORAL_WEIGHT_MAX = 0.35; // Maximum is important for highlights
const float TEMPORAL_WEIGHT_MIN = 0.15; // Minimum is least reliable (noise)

// Delta scale for converting normalized differences to perceptual units
// This converts [0,1] differences to ΔE-like perceptual differences
const float TEMPORAL_DELTA_SCALE = 720.0;

// Metric type identifiers for array access
const int METRIC_MAX = 0;
const int METRIC_MIN = 1;
const int METRIC_AVG = 2;

// ============================================================================
// TEMPORAL STABILIZATION - Core Functions
// ============================================================================

/**
 * Prepends current frame values to temporal history arrays
 * Maintains a sliding window of the last N frames for all three metrics
 */
void temporal_prepend() {
    // Shift all historical values one position forward
    for (uint i = temporal_stable_frames - 1; i > 0; i--) {
        metered_max_i_t[i] = metered_max_i_t[i - 1];
        metered_min_i_t[i] = metered_min_i_t[i - 1];
        metered_avg_i_t[i] = metered_avg_i_t[i - 1];
    }

    // Insert current frame values at position 0
    metered_max_i_t[0] = metered_max_i;
    metered_min_i_t[0] = metered_min_i;
    metered_avg_i_t[0] = metered_avg_i;
}

/**
 * Calculates weighted moving average with exponential decay
 * Recent frames have higher weight than older frames
 *
 * @param type Metric type: METRIC_MAX, METRIC_MIN, or METRIC_AVG
 * @return Weighted average value
 */
float temporal_weighted_mean(int type) {
    float sum_weighted = 0.0;
    float sum_weights = 0.0;

    for (uint i = 0; i < temporal_stable_frames; i++) {
        // Select appropriate buffer based on metric type
        float current;
        if (type == METRIC_MAX) {
            current = float(metered_max_i_t[i]);
        } else if (type == METRIC_MIN) {
            current = float(metered_min_i_t[i]);
        } else { // METRIC_AVG
            current = float(metered_avg_i_t[i]);
        }

        // Calculate exponential decay weight: w(i) = decay^i
        // Recent frames (i=0) have weight=1.0, older frames decay exponentially
        float weight = pow(TEMPORAL_DECAY, float(i));
        sum_weighted += current * weight;
        sum_weights += weight;
    }

    // Return normalized weighted average
    return sum_weighted / max(sum_weights, 1e-6);
}

/**
 * Applies Exponential Moving Average (EMA) smoothing
 * Provides additional stability on top of weighted average
 *
 * @param new_value New computed value
 * @param prev_value Previous frame's value
 * @return Smoothed value: prev + alpha * (new - prev)
 */
float apply_ema_smoothing(float new_value, float prev_value) {
    return prev_value + TEMPORAL_EMA_ALPHA * (new_value - prev_value);
}

/**
 * Gradually transitions temporal buffers during scene changes
 * Blends old values towards new values to avoid sudden jumps
 */
void temporal_fill_gradual() {
    for (uint i = 0; i < temporal_stable_frames; i++) {
        // Blend each buffer entry towards current value
        float old_max = float(metered_max_i_t[i]);
        float new_max = float(metered_max_i);
        metered_max_i_t[i] = uint(mix(old_max, new_max, TEMPORAL_SCENE_BLEND) + 0.5);

        float old_min = float(metered_min_i_t[i]);
        float new_min = float(metered_min_i);
        metered_min_i_t[i] = uint(mix(old_min, new_min, TEMPORAL_SCENE_BLEND) + 0.5);

        float old_avg = float(metered_avg_i_t[i]);
        float new_avg = float(metered_avg_i);
        metered_avg_i_t[i] = uint(mix(old_avg, new_avg, TEMPORAL_SCENE_BLEND) + 0.5);
    }
}

/**
 * Performs linear regression prediction for scene change detection
 * Uses least squares method to predict next frame value
 *
 * @param type Metric type: METRIC_MAX, METRIC_MIN, or METRIC_AVG
 * @return Predicted value for next frame
 */
float temporal_predict(int type) {
    float sum_x = 0.0;
    float sum_y = 0.0;
    float sum_x2 = 0.0;
    float sum_xy = 0.0;

    float n = float(temporal_stable_frames);
    float xp = n + 1.0; // Predict position n+1

    // Accumulate sums for least squares regression
    for (int i = 0; i < int(temporal_stable_frames); i++) {
        float x = float(i + 1);
        float y;

        // Select appropriate buffer based on metric type
        if (type == METRIC_MAX) {
            y = float(metered_max_i_t[i]);
        } else if (type == METRIC_MIN) {
            y = float(metered_min_i_t[i]);
        } else { // METRIC_AVG
            y = float(metered_avg_i_t[i]);
        }

        sum_x += x;
        sum_y += y;
        sum_x2 += x * x;
        sum_xy += x * y;
    }

    // Calculate linear regression coefficients
    // y = a*x + b
    float denominator = n * sum_x2 - sum_x * sum_x;
    float a = (n * sum_xy - sum_x * sum_y) / denominator;
    float b = (sum_y - a * sum_x) / n;

    // Return prediction for next frame
    return a * xp + b;
}

/**
 * Detects scene changes using multi-metric prediction error analysis
 * Combines max, min, and avg metrics with adaptive thresholding
 *
 * @param max_smoothed Smoothed maximum value
 * @param min_smoothed Smoothed minimum value
 * @param avg_smoothed Smoothed average value
 * @param max_pred Predicted maximum value
 * @param min_pred Predicted minimum value
 * @param avg_pred Predicted average value
 * @return true if scene change is detected
 */
bool is_scene_changed(float max_smoothed, float min_smoothed, float avg_smoothed,
                      float max_pred, float min_pred, float avg_pred) {
    // Detect pure black scenes (always considered a scene change)
    if (metered_max_i < TEMPORAL_BLACK_THRESHOLD) {
        return true;
    }

    // Calculate adaptive tolerance based on current brightness
    // Brighter scenes get higher tolerance to reduce false positives
    float brightness_factor = float(metered_max_i) / 4095.0;
    float adaptive_tolerance = TEMPORAL_BASE_TOLERANCE *
                               (1.0 + brightness_factor * TEMPORAL_ADAPTIVE_SCALE);

    // Calculate prediction errors in perceptual units (ΔE-like)
    // Normalize to [0,1] then scale to perceptual differences
    float max_delta = TEMPORAL_DELTA_SCALE *
                      abs(max_smoothed / 4095.0 - max_pred / 4095.0);
    float min_delta = TEMPORAL_DELTA_SCALE *
                      abs(min_smoothed / 4095.0 - min_pred / 4095.0);
    float avg_delta = TEMPORAL_DELTA_SCALE *
                      abs(avg_smoothed / 4095.0 - avg_pred / 4095.0);

    // Combine errors using weighted average
    // Average is most reliable, max is important, min is least reliable
    float weighted_delta = avg_delta * TEMPORAL_WEIGHT_AVG +
                           max_delta * TEMPORAL_WEIGHT_MAX +
                           min_delta * TEMPORAL_WEIGHT_MIN;

    // Scene change detected if weighted error exceeds adaptive threshold
    return weighted_delta > adaptive_tolerance;
}

/**
 * Main temporal stabilization hook
 * Processes max, min, and avg metrics with multi-stage smoothing
 * and intelligent scene change detection
 */
void hook() {
    // Cache previous frame values for EMA smoothing
    float prev_max = float(metered_max_i);
    float prev_min = float(metered_min_i);
    float prev_avg = float(metered_avg_i);

    // Update temporal history with current frame
    temporal_prepend();

    // Stage 1: Weighted moving average (exponential decay)
    // Gives more weight to recent frames
    float max_weighted = temporal_weighted_mean(METRIC_MAX);
    float min_weighted = temporal_weighted_mean(METRIC_MIN);
    float avg_weighted = temporal_weighted_mean(METRIC_AVG);

    // Stage 2: Exponential moving average smoothing
    // Provides additional stability and reduces noise
    float max_smoothed = apply_ema_smoothing(max_weighted, prev_max);
    float min_smoothed = apply_ema_smoothing(min_weighted, prev_min);
    float avg_smoothed = apply_ema_smoothing(avg_weighted, prev_avg);

    // Generate predictions for scene change detection
    float max_pred = temporal_predict(METRIC_MAX);
    float min_pred = temporal_predict(METRIC_MIN);
    float avg_pred = temporal_predict(METRIC_AVG);

    // Detect and handle scene changes
    if (is_scene_changed(max_smoothed, min_smoothed, avg_smoothed,
                         max_pred, min_pred, avg_pred)) {
        // Gradually transition buffer values to new scene
        temporal_fill_gradual();

        // Apply reduced smoothing for scene cuts to maintain some stability
        // while still responding to the new scene quickly
        max_smoothed = mix(prev_max, float(metered_max_i), TEMPORAL_CUT_BLEND);
        min_smoothed = mix(prev_min, float(metered_min_i), TEMPORAL_CUT_BLEND);
        avg_smoothed = mix(prev_avg, float(metered_avg_i), TEMPORAL_CUT_BLEND);
    }

    // Write back smoothed values with clamping to valid range [0, 4095]
    metered_max_i = uint(clamp(max_smoothed, 0.0, 4095.0) + 0.5);
    metered_min_i = uint(clamp(min_smoothed, 0.0, 4095.0) + 0.5);
    metered_avg_i = uint(clamp(avg_smoothed, 0.0, 4095.0) + 0.5);
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
    float value = METERING_tex(METERING_pos).x;
    vec3 color = vec3(value);

    float max_i = float(metered_max_i) / 4095.0;
    float min_i = float(metered_min_i) / 4095.0;

    float d_max_i = 720 * abs(value - max_i);
    float d_min_i = 720 * abs(value - min_i);

    if (d_max_i < 4.0)
        color = vec3(1.0, 0.0, 0.0);
    if (d_min_i < 4.0)
        color = vec3(0.0, 0.0, 1.0);

    if (almost_equal(1.0 - METERING_pos.y, max_i, 1e-3))
        color = vec3(1.0, 0.0, 0.0);
    if (almost_equal(1.0 - METERING_pos.y, min_i, 1e-3))
        color = vec3(0.0, 0.0, 1.0);

    if (enable_metering > 1) {
        float avg_i = float(metered_avg_i) / 4095.0;
        float d_avg_i = 720 * abs(value - avg_i);

        if (d_avg_i < 4.0)
            color = vec3(0.0, 1.0, 0.0);

        if (almost_equal(1.0 - METERING_pos.y, avg_i, 1e-3))
            color = vec3(0.0, 1.0, 0.0);
    }

    return vec4(color, 1.0);
}

//!HOOK OUTPUT
//!BIND METERED
//!BIND METADATA
//!SAVE EMPTY
//!WIDTH 1
//!HEIGHT 1
//!COMPUTE 1 1
//!WHEN preview_metering 0 =
//!DESC tone mapping (metadata)

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
    const vec3 luma_coef = vec3(0.2627002120112671, 0.6779980715188708, 0.05930171646986196);
    return dot(rgb, luma_coef);
}

float get_max_i() {
    if (max_pq_y > 0.0)
        return max_pq_y;

    if (scene_max_r > 0.0 || scene_max_g > 0.0 || scene_max_b > 0.0)
        return pq_eotf_inv(RGB_to_Y(vec3(scene_max_r, scene_max_g, scene_max_b)));

    if (enable_metering > 0)
        return float(metered_max_i) / 4095.0;

    if (max_cll > 0.0)
        return pq_eotf_inv(max_cll);

    if (max_luma > 0.0)
        return pq_eotf_inv(max_luma);

    return pq_eotf_inv(1000.0);
}

float get_min_i() {
    if (enable_metering > 0)
        return float(metered_min_i) / 4095.0;

    if (min_luma > 0.0)
        return pq_eotf_inv(min_luma);

    return pq_eotf_inv(0.0);
}

float get_avg_i() {
    if (avg_pq_y > 0.0)
        return avg_pq_y;

    if (scene_avg > 0.0)
        return pq_eotf_inv(scene_avg);

    if (enable_metering > 1)
        return float(metered_avg_i) / 4095.0;

    // not useful
    // if (max_fall > 0.0)
    //     return pq_eotf_inv(max_fall);

    return 0.0;
}

float get_ev(float avg_i) {
    float reference_iz = iz_eotf_inv(reference_white);
    float reference_j = I_to_J(reference_iz);
    float anchor_j = auto_exposure_anchor * reference_j;
    float anchor_iz = J_to_I(anchor_j);
    float anchor = iz_eotf(anchor_iz);

    float average = pq_eotf(avg_i);

    float ev = log2(anchor / average);
    return clamp(ev, -auto_exposure_limit_negtive, auto_exposure_limit_postive);
}

void hook() {
    max_i = get_max_i();
    min_i = get_min_i();
    avg_i = get_avg_i();

    if (avg_i > 0.0 && auto_exposure_anchor > 0.0) {
        ev = get_ev(avg_i);
    } else {
        ev = 0.0;
    }

    if (ev != 0.0) {
        float ev_scale = exp2(ev);
        max_i = pq_eotf_inv(pq_eotf(max_i) * ev_scale);
        min_i = pq_eotf_inv(pq_eotf(min_i) * ev_scale);
    }
}

//!HOOK OUTPUT
//!BIND HOOKED
//!BIND METADATA
//!WHEN preview_metering 0 = auto_exposure_anchor 0 > * enable_metering 1 > avg_pq_y 0 > + scene_avg 0 > + *
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
//!BIND HOOKED
//!BIND METADATA
//!WHEN preview_metering 0 =
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

vec3 RGB_to_Jab(vec3 color) {
    color *= reference_white;
    color = RGB_to_XYZ(color);
    color = XYZ_to_XYZm(color);
    color = XYZ_to_LMS(color);
    color = iz_eotf_inv(color);
    color = LMS_to_Iab_optimized(color);
    color.x = I_to_J(color.x);
    color.x = J_to_Jhk(Lab_to_LCh(color));
    return color;
}

vec3 Jab_to_RGB(vec3 color) {
    color.x = Jhk_to_J(Lab_to_LCh(color));
    color.x = J_to_I(color.x);
    color = Iab_to_LMS_optimized(color);
    color = iz_eotf(color);
    color = LMS_to_XYZ(color);
    color = XYZm_to_XYZ(color);
    color = XYZ_to_RGB(color);
    color /= reference_white;
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

// Modified to make x0 and y0 controllable.
float f_toe_suzuki(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;
    float dx2 = dx * dx;
    float dy2 = dy * dy;
    float den = dy - slope * dx;

    float a = slope * dx2 * dy2 / (den * den);
    float b = slope * dx2 / den;
    float c = dy2 / den;

    return -(a / (x - x0 + b)) + c + y0;
}

float f_shoulder_suzuki(float x, float slope, float x0, float y0, float x1, float y1) {
    float d = slope * (x0 - x1) - y0 + y1;
    float a = (slope * (x0 - x1) * (x0 - x1) * (y0 - y1) * (y0 - y1)) / (d * d);
    float b = (slope * x0 * (x1 - x0) + x1 * (y0 - y1)) / d;
    float c = (y1 * (slope * (x0 - x1) + y0) - y0 * y0) / d;
    return -(a / (x + b)) + c;
}

float f_toe_hable(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;

    float b = slope * dx / dy;
    float a = log(dy) - b * log(dx);
    float s = 1.0;

    return exp(a + b * log(max((x - x0) * s, 1e-6))) * s + y0;
}

// Simplified, no overshoot.
float f_shoulder_hable(float x, float slope, float x0, float y0, float x1, float y1) {
    float dx = x1 - x0;
    float dy = y1 - y0;

    float b = slope * dx / dy;
    float a = log(dy) - b * log(dx);
    float s = -1.0;

    return exp(a + b * log(max((x - x1) * s, 1e-6))) * s + y1;
}

float f(
    float x, float iw, float ib, float ow, float ob,
    float sw, float hw, float c
) {
    float midgray   = 0.5 * ow;
    float shadow    = mix(midgray, ob, sw);
    float highlight = mix(midgray, ow, hw);
    float contrast  = 1.0 - pow(10, -2.0 * c);

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

        return f_shoulder_hable(x, slope, x2, y2, x3, y3);
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

// this is a correction in generic vividness and depth.
// V = sqrt(J^2 + C^2)
// D = sqrt((J_max - J)^2 + C^2)
// more specific definitions of V and D for Jzazbz,
// see the following links:
// https://doi.org/10.2352/ISSN.2169-2629.2018.26.96
// https://doi.org/10.2352/issn.2169-2629.2019.27.43
vec2 chroma_correction(vec2 ab, float l1, float l2) {
    float r_min = min(l1, l2) / max(max(l1, l2), 1e-6);
    float r_scaled = mix(1.0, r_min, chroma_correction_scaling);
    float r_safe = max(r_scaled, 0.0);
    return ab * r_safe;
}

vec3 tone_mapping(vec3 lab) {
    float l2 = curve(lab.x);
    vec2 ab2 = chroma_correction(lab.yz, lab.x, l2);
    return vec3(l2, ab2);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    color.rgb = RGB_to_Jab(color.rgb);
    color.rgb = tone_mapping(color.rgb);
    color.rgb = Jab_to_RGB(color.rgb);

    return color;
}
