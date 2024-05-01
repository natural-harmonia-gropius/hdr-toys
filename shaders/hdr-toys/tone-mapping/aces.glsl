// The Academy Color Encoding System (ACES)
// https://github.com/ampas/aces-dev

//             |-------|           |-------|          |-------|
//             |       |           |       |          |       |
//   ACES ---->|  LMT  |---ACES'-->|  RRT  |---OCES-->|  ODT  |--> code values
//             |       |           |       |          |       |
//             |-------|           |-------|          |-------|

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (aces)

const float TINY         = 1e-5;
const float HALF_POS_INF = 31744.0;

// Gamut Compress Parameters
const float LIM_CYAN    = 1.147;
const float LIM_MAGENTA = 1.264;
const float LIM_YELLOW  = 1.312;

const float THR_CYAN    = 0.815;
const float THR_MAGENTA = 0.803;
const float THR_YELLOW  = 0.880;

const float PWR         = 1.2;

// "Glow" module constants
const float RRT_GLOW_GAIN = 0.05;
const float RRT_GLOW_MID  = 0.08;

// Red modifier constants
const float RRT_RED_SCALE = 0.82;
const float RRT_RED_PIVOT = 0.03;
const float RRT_RED_HUE   = 0.0;
const float RRT_RED_WIDTH = 135.0;

// Desaturation constants
const float RRT_SAT_FACTOR = 0.96;
const float ODT_SAT_FACTOR = 0.93;

// Gamma compensation factor
const float DIM_SURROUND_GAMMA = 0.9811;


const mat3 RGB_to_XYZ = mat3(
    0.6369580483012914, 0.14461690358620832,  0.1688809751641721,
    0.2627002120112671, 0.6779980715188708,   0.05930171646986196,
    0.000000000000000,  0.028072693049087428, 1.060985057710791
);

const mat3 XYZ_to_RGB = mat3(
     1.716651187971268,  -0.355670783776392, -0.253366281373660,
    -0.666684351832489,   1.616481236634939,  0.0157685458139111,
     0.017639857445311,  -0.042770613257809,  0.942103121235474
);

const mat3 AP0_to_XYZ = mat3(
    0.9525523959, 0.0000000000,  0.0000936786,
    0.3439664498, 0.7281660966, -0.0721325464,
    0.0000000000, 0.0000000000,  1.0088251844
);

const mat3 XYZ_to_AP0 = mat3(
     1.0498110175, 0.0000000000, -0.0000974845,
    -0.4959030231, 1.3733130458,  0.0982400361,
     0.0000000000, 0.0000000000,  0.9912520182
);

const mat3 AP1_to_XYZ = mat3(
     0.6624541811, 0.1340042065, 0.1561876870,
     0.2722287168, 0.6740817658, 0.0536895174,
    -0.0055746495, 0.0040607335, 1.0103391003
);

const mat3 XYZ_to_AP1 = mat3(
     1.6410233797, -0.3248032942, -0.2364246952,
    -0.6636628587,  1.6153315917,  0.0167563477,
     0.0117218943, -0.0082844420,  0.9883948585
);

const vec3 LUMINANCE_AP1 = vec3(0.2722287168, 0.6740817658, 0.0536895174);

const mat3 D60_to_D65_CAT = mat3(
     0.987224,   -0.00611327, 0.0159533,
    -0.00759836,  1.00186,    0.00533002,
     0.00307257, -0.00509595, 1.08168
);

const mat3 D65_to_D60_CAT = mat3(
     1.0130349238541335252,    0.0061053088545854651618, -0.014970963195236360098,
     0.0076982295895192892886, 0.9981648317745535941,    -0.0050320341346474782061,
    -0.0028413125165573776196, 0.0046851555780399034147,  0.92450665292696206889
);

// Power compression function
// https://www.desmos.com/calculator/iwcyjg6av0
float compress(float dist, float lim, float thr, float pwr) {
    float scl = (lim - thr) / pow(pow((1.0 - thr) / (lim - thr), -pwr) - 1.0, 1.0 / pwr);
    float c = thr + (dist - thr) / (pow(1.0 + pow((dist - thr) / scl, pwr), 1.0 / pwr));
    return (dist < thr ? dist : c);
}

vec3 reference_gamut_compress(vec3 rgb) {
    // Achromatic axis
    float ac = max(max(rgb.r, rgb.g), rgb.b);

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    // Compressed distance
    vec3 cd = vec3(
        compress(d.x, LIM_CYAN,    THR_CYAN,    PWR),
        compress(d.y, LIM_MAGENTA, THR_MAGENTA, PWR),
        compress(d.z, LIM_YELLOW,  THR_YELLOW,  PWR)
    );

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    return crgb;
}

float rgb_to_saturation(vec3 rgb) {
    float mi = min(min(rgb.r, rgb.g), rgb.b);
    float ma = max(max(rgb.r, rgb.g), rgb.b);
    return (max(ma, TINY) - max(mi, TINY)) / max(ma, 1e-2);
}

// Converts RGB to a luminance proxy, here called YC
// YC is ~ Y + K * Chroma
// Constant YC is a cone-shaped surface in RGB space, with the tip on the
// neutral axis, towards white.
// YC is normalized: RGB 1 1 1 maps to YC = 1
//
// ycRadiusWeight defaults to 1.75, although can be overridden in function
// call to rgb_to_yc
// ycRadiusWeight = 1 -> YC for pure cyan, magenta, yellow == YC for neutral
// of same value
// ycRadiusWeight = 2 -> YC for pure red, green, blue  == YC for  neutral of
// same value.
float rgb_to_yc(vec3 rgb) {
    float ycRadiusWeight = 1.75;

    float r = rgb.r;
    float g = rgb.g;
    float b = rgb.b;

    float chroma = sqrt(b * (b - g) + g * (g - r) + r * (r - b));

    return (b + g + r + ycRadiusWeight * chroma) / 3.0;
}

// Sigmoid function in the range 0 to 1 spanning -2 to +2.
float sigmoid_shaper(float x) {
    float t = max(1.0 - abs(x / 2.0), 0.0);
    float y = 1.0 + sign(x) * (1.0 - t * t);
    return y / 2.0;
}

float glow_fwd(float ycIn, float glowGainIn, float glowMid) {
    float glowGainOut;

    if (ycIn <= 2.0 / 3.0 * glowMid) {
        glowGainOut = glowGainIn;
    } else if ( ycIn >= 2.0 * glowMid) {
        glowGainOut = 0.0;
    } else {
        glowGainOut = glowGainIn * (glowMid / ycIn - 1.0 / 2.0);
    }

    return glowGainOut;
}

// Returns a geometric hue angle in degrees (0-360) based on RGB values.
// For neutral colors, hue is undefined and the function will return a quiet NaN value.
float rgb_to_hue(vec3 rgb) {
    // RGB triplets where RGB are equal have an undefined hue
    float hue = 0.0;

    if (!(rgb.x == rgb.y && rgb.y == rgb.z)) {
        float x = sqrt(3.0) * (rgb.y - rgb.z);
        float y = 2.0 * rgb.x - rgb.y - rgb.z;
        hue = degrees(atan(y, x));
    }

    return (hue < 0.0) ? hue + 360.0 : hue;
}

float center_hue(float hue, float centerH) {
    float hueCentered = hue - centerH;
    if (hueCentered < -180.0) {
        hueCentered = hueCentered + 360.0;
    } else if (hueCentered > 180.0) {
        hueCentered = hueCentered - 360.0;
    }
    return hueCentered;
}

// Fitting of RRT + ODT (RGB monitor 100 nits dim) from:
// https://github.com/colour-science/colour-unity/blob/master/Assets/Colour/Notebooks/CIECAM02_Unity.ipynb
// RMSE: 0.0012846272106
vec3 tonescale(vec3 ap1) {
    float a = 2.785085;
    float b = 0.107772;
    float c = 2.936045;
    float d = 0.887122;
    float e = 0.806889;
    return (ap1 * (a * ap1 + b)) / (ap1 * (c * ap1 + d) + e);
}

vec3 XYZ_to_xyY(vec3 XYZ) {
    float X = XYZ.x;
    float Y = XYZ.y;
    float Z = XYZ.z;

    float divisor = X + Y + Z;
    if (divisor == 0.0) divisor = 1e-6;

    float x = X / divisor;
    float y = Y / divisor;

    return vec3(x, y, Y);
}

vec3 xyY_to_XYZ(vec3 xyY) {
    float x = xyY.x;
    float y = xyY.y;
    float Y = xyY.z;

    float multiplo = Y / max(y, 1e-6);

    float z = 1.0 - x - y;
    float X = x * multiplo;
    float Z = z * multiplo;

    return vec3(X, Y, Z);
}

vec3 darkSurround_to_dimSurround(vec3 linearCV) {
    vec3 XYZ = linearCV * AP1_to_XYZ;
    vec3 xyY = XYZ_to_xyY(XYZ);

    xyY.z = clamp(xyY.z, 0.0, HALF_POS_INF);
    xyY.z = pow(xyY.z, DIM_SURROUND_GAMMA);

    XYZ = xyY_to_XYZ(xyY);
    return XYZ * XYZ_to_AP1;
}

vec3 ACES(vec3 color) {
    vec3 ap0;
    vec3 ap1;
    vec3 cv;

    // Look Modification Transforms (LMTs)
    ap1 = color * RGB_to_XYZ * D65_to_D60_CAT * XYZ_to_AP1;

    ap1 = reference_gamut_compress(ap1);

    ap0 = ap1 * AP1_to_XYZ * XYZ_to_AP0;


    // Reference Rendering Transform (RRT)

    // Glow module
    float saturation = rgb_to_saturation(ap0);
    float ycIn = rgb_to_yc(ap0);
    float s = sigmoid_shaper((saturation - 0.4) / 0.2);
    float addedGlow = 1.0 + glow_fwd(ycIn, RRT_GLOW_GAIN * s, RRT_GLOW_MID);
    ap0 *= addedGlow;

    // Red modifier
    float hue = rgb_to_hue(ap0);
    float centeredHue = center_hue(hue, RRT_RED_HUE);
    // hueWeight = cubic_basis_shaper(centeredHue, RRT_RED_WIDTH);
    float hueWeight = smoothstep(0.0, 1.0, 1.0 - abs(2.0 * centeredHue / RRT_RED_WIDTH));
    hueWeight *= hueWeight;

    ap0.r += hueWeight * saturation * (RRT_RED_PIVOT - ap0.r) * (1.0 - RRT_RED_SCALE);

    // ACES to RGB rendering space
    ap1 = ap0 * AP0_to_XYZ * XYZ_to_AP1;

    // avoids saturated negative colors from becoming positive in the matrix
    ap1 = clamp(ap1, 0.0, HALF_POS_INF);

    // Global desaturation
    ap1 = mix(vec3(dot(ap1, LUMINANCE_AP1)), ap1, RRT_SAT_FACTOR);


    // Output Device Transform (ODT)

    // Apply the tonescale independently in rendering-space RGB
    ap1 = tonescale(ap1);

    // Apply gamma adjustment to compensate for dim surround
    cv = darkSurround_to_dimSurround(ap1);

    // Apply desaturation to compensate for luminance difference
    cv = mix(vec3(dot(cv, LUMINANCE_AP1)), cv, ODT_SAT_FACTOR);

    // Convert to display primary encoding
    cv = cv * AP1_to_XYZ * D60_to_D65_CAT * XYZ_to_RGB;

    return cv;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = ACES(color.rgb);

    return color;
}
