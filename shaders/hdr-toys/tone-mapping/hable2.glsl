// Filmic Tonemapping with Piecewise Power Curves
// by John Hable
// http://filmicworlds.com/blog/filmic-tonemapping-with-piecewise-power-curves/

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

//!PARAM sigma
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.5

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (hable2)

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

float toeLength = 0.1;
float toeStrength = 0.5;
float shoulderAngle = 1.0;
float shoulderLength = 0.5;
float shoulderStrength = log2(L_hdr / L_sdr);

float x0 = 0.0;
float y0 = 0.0;
float x1 = 0.0;
float y1 = 0.0;
float W  = 0.0;
float overshootX = 0.0;
float overshootY = 0.0;

// Convert from "user" to "direct" parameters
void calc_direct_params_from_user() {
    // This is not actually the display gamma. It's just a UI space to avoid having to
    // enter small numbers for the input.
    const float perceptualGamma = 2.4;

    // constraints
    toeLength = clamp(pow(toeLength, perceptualGamma), 0.0, 1.0);
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
    vec2  tmp = as_slope_intercept(x0, x1, y0, y1);
    float m = tmp.x,
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

    float toeM = eval_derivative_linear_gamma(m, b, g, x0);
    float shoulderM = eval_derivative_linear_gamma(m, b, g, x1);

    float y0 = max(pow(y0, g), 1e-6);
    float y1 = max(pow(y1, g), 1e-6);
    float overshootY = pow(1.0 + overshootY, g) - 1.0;

    vec2  toeAB  = solve_AB(x0, y0, m);
    float   toeOffsetX = 0.0,
            toeOffsetY = 0.0,
            toeScaleX  = 1.0,
            toeScaleY  = 1.0,
            toeLnA     = toeAB.x,
            toeB       = toeAB.y;

    float shoulderX0  = (1.0 + overshootX) - x1;
    float shoulderY0  = (1.0 + overshootY) - y1;

    vec2  shoulderAB  = solve_AB(shoulderX0, shoulderY0, m);
    float   shoulderOffsetX = 1.0 + overshootX,
            shoulderOffsetY = 1.0 + overshootY,
            shoulderScaleX  = -1.0,
            shoulderScaleY  = -1.0,
            shoulderLnA     = shoulderAB.x,
            shoulderB       = shoulderAB.y;

    // Normalize (correct for overshooting)
    float scale = curve_segment_eval(1.0,
        shoulderLnA, shoulderB,
        shoulderOffsetX, shoulderOffsetY,
        shoulderScaleX, shoulderScaleY);
    float invScale = 1.0 / scale;

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

vec3 tone_mapping_ictcp(vec3 ICtCp) {
    float I2  = Y_to_ST2084(curve(ST2084_to_Y(ICtCp.x) / L_sdr) * L_sdr);
    ICtCp.yz *= mix(1.0, min(ICtCp.x / I2, I2 / ICtCp.x), sigma);
    ICtCp.x   = I2;
    return ICtCp;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    calc_direct_params_from_user();
    color.rgb = RGB_to_ICtCp(color.rgb);
    color.rgb = tone_mapping_ictcp(color.rgb);
    color.rgb = ICtCp_to_RGB(color.rgb);

    return color;
}
