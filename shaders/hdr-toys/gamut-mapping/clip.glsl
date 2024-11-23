// RGB to RGB conversion, include chromatic adaptation transform

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (clip)

// You can use custom chromaticity here.
// Example: BT.709 with a D93 white point: Chromaticity(BT709.r, BT709.g, BT709.b, D93)
// You can also define custom coordinates: Chromaticity(vec2(0.7347, 0.2653), BT709.g, BT709.b, D65)

#define from    BT2020
#define to      BT709


// White points of standard illuminants
// https://en.wikipedia.org/wiki/Standard_illuminant#White_points_of_standard_illuminants

const vec2 A    = vec2(0.44757, 0.40745);
const vec2 B    = vec2(0.34842, 0.35161);
const vec2 C    = vec2(0.31006, 0.31616);
const vec2 D50  = vec2(0.34567, 0.35850);
const vec2 D55  = vec2(0.33242, 0.34743);
const vec2 D65  = vec2(0.31271, 0.32902);
const vec2 D75  = vec2(0.29902, 0.31485);
const vec2 D93  = vec2(0.28315, 0.29711);
const vec2 E    = vec2(1.0/3.0, 1.0/3.0);
const vec2 F2   = vec2(0.37208, 0.37529);
const vec2 F7   = vec2(0.31292, 0.32933);
const vec2 F11  = vec2(0.38052, 0.37713);
const vec2 DCI  = vec2(0.31400, 0.35100);
const vec2 ACES = vec2(0.32168, 0.33767);

// https://en.wikipedia.org/wiki/Standard_illuminant#Illuminant_series_D
vec2 CIE_D(float CCT) {
    // https://en.wikipedia.org/wiki/Planckian_locus
    // c2 = 1.4387768775039337
    CCT = (CCT * 1.4388) / 1.438;

    CCT = clamp(CCT, 4000.0, 25000.0);

    float t1 = 1000.0 / CCT;
    float t2 = t1 * t1;
    float t3 = t1 * t2;

    float x = CCT <= 7000.0
        ? 0.244063 + 0.09911 * t1 + 2.9678 * t2 - 4.6070 * t3
        : 0.237040 + 0.24748 * t1 + 1.9018 * t2 - 2.0064 * t3;
    float y = -0.275 + 2.87 * x - 3.0 * x * x;

    return vec2(x, y);
}

// Chromaticities
// https://www.itu.int/rec/T-REC-H.273
// https://github.com/colour-science/colour/tree/develop/colour/models/rgb/datasets

struct Chromaticity {
    vec2 r, g, b, w;
};

// ITU-R BT.2020, ITU-R BT.2100
const Chromaticity BT2020 = Chromaticity(
    vec2(0.708, 0.292),
    vec2(0.170, 0.797),
    vec2(0.131, 0.046),
    D65
);

// ITU-R BT.709, IEC 61966-2-1 (sRGB)
const Chromaticity BT709 = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.30, 0.60),
    vec2(0.15, 0.06),
    D65
);

// ITU-R BT.601 (525 lines), SMPTE ST 240
const Chromaticity BT601_525 = Chromaticity(
    vec2(0.630, 0.340),
    vec2(0.310, 0.595),
    vec2(0.155, 0.070),
    D65
);

// ITU-R BT.601 (625 lines), BT.470 (B/G), EBU 3213-E
const Chromaticity BT601_625 = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.29, 0.60),
    vec2(0.15, 0.06),
    D65
);

// ITU-R BT.470 (M)
const Chromaticity BT470m = Chromaticity(
    vec2(0.67, 0.33),
    vec2(0.21, 0.71),
    vec2(0.14, 0.08),
    C
);

// P3-DCI (Theater)
const Chromaticity P3DCI = Chromaticity(
    vec2(0.680, 0.320),
    vec2(0.265, 0.690),
    vec2(0.150, 0.060),
    DCI
);

// P3-D65 (Display)
const Chromaticity P3D65 = Chromaticity(
    P3DCI.r,
    P3DCI.g,
    P3DCI.b,
    D65
);

// P3-D60 (ACES Cinema)
const Chromaticity P3D60 = Chromaticity(
    P3DCI.r,
    P3DCI.g,
    P3DCI.b,
    ACES
);

// ITU-T H.273 (Generic film)
const Chromaticity H273_8 = Chromaticity(
    vec2(0.681, 0.319),
    vec2(0.243, 0.692),
    vec2(0.145, 0.049),
    C
);

// ITU-T H.273 (No corresponding industry specification identified)
const Chromaticity H273_22 = Chromaticity(
    vec2(0.630, 0.340),
    vec2(0.295, 0.605),
    vec2(0.155, 0.077),
    D65
);

// CIE RGB (CIE 1931 color space)
const Chromaticity CIERGB = Chromaticity(
    vec2(0.73474284, 0.26525716),
    vec2(0.27377903, 0.7174777),
    vec2(0.16655563, 0.00891073),
    E
);

// CIE XYZ (CIE 1931 color space)
const Chromaticity XYZ = Chromaticity(
    vec2(1.0, 0.0),
    vec2(0.0, 1.0),
    vec2(0.0, 0.0),
    E
);

// CIE XYZ (CIE 1931 color space, D65 whitepoint)
const Chromaticity XYZD65 = Chromaticity(
    XYZ.r,
    XYZ.g,
    XYZ.b,
    D65
);

// CIE XYZ (CIE 1931 color space, D50 whitepoint)
const Chromaticity XYZD50 = Chromaticity(
    XYZ.r,
    XYZ.g,
    XYZ.b,
    D50
);

// Grayscale, Monochrome
const Chromaticity GRAY = Chromaticity(
    vec2(0.0, 1.0),
    vec2(0.0, 1.0),
    vec2(0.0, 1.0),
    E
);

// Adobe RGB (1998)
const Chromaticity AdobeRGB = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.21, 0.71),
    vec2(0.15, 0.06),
    D65
);

// Adobe Wide Gamut RGB
const Chromaticity AdobeWideGamutRGB = Chromaticity(
    vec2(0.7347, 0.2653),
    vec2(0.1152, 0.8264),
    vec2(0.1566, 0.0177),
    D50
);

// ROMM (ProPhoto RGB)
const Chromaticity ROMM = Chromaticity(
    vec2(0.734699, 0.265301),
    vec2(0.159597, 0.840403),
    vec2(0.036598, 0.000105),
    D50
);

// AP0 (ACES 2065-1)
const Chromaticity AP0 = Chromaticity(
    vec2(0.7347,  0.2653),
    vec2(0.0000,  1.0000),
    vec2(0.0001, -0.0770),
    ACES
);

// AP1 (ACEScg, cc, cct, proxy)
const Chromaticity AP1 = Chromaticity(
    vec2(0.713, 0.293),
    vec2(0.165, 0.830),
    vec2(0.128, 0.044),
    ACES
);

// ARRI Wide Gamut 4
const Chromaticity AWG4 = Chromaticity(
    vec2(0.7347,  0.2653),
    vec2(0.1424,  0.8576),
    vec2(0.0991, -0.0308),
    D65
);

// FUJIFILM F-Gamut C
const Chromaticity FGAMUTC = Chromaticity(
    vec2(0.7347,  0.2653),
    vec2(0.0263,  0.9737),
    vec2(0.1173, -0.0224),
    D65
);

// Sony S-Gamut3/S-Gamut
const Chromaticity SGAMUT = Chromaticity(
    vec2(0.73,  0.280),
    vec2(0.14,  0.855),
    vec2(0.10, -0.050),
    D65
);

// Sony S-Gamut.Cine
const Chromaticity SGAMUTCINE = Chromaticity(
    vec2(0.766,  0.275),
    vec2(0.225,  0.800),
    vec2(0.089, -0.087),
    D65
);

// Panasonic V-Gamut
const Chromaticity VGAMUT = Chromaticity(
    vec2(0.730,  0.28),
    vec2(0.165,  0.84),
    vec2(0.100, -0.03),
    D65
);

// DJI D-Gamut
const Chromaticity DGAMUT = Chromaticity(
    vec2(0.71,  0.31),
    vec2(0.21,  0.88),
    vec2(0.09, -0.08),
    D65
);

// Chromatic adaptation transform
// https://en.wikipedia.org/wiki/LMS_color_space

const mat3 HPE = mat3(
     0.4002400,  0.7076000, -0.0808100,
    -0.2263000,  1.1653200,  0.0457000,
     0.0000000,  0.0000000,  0.9182200
);

const mat3 Bradford = mat3(
     0.8951000,  0.2664000, -0.1614000,
    -0.7502000,  1.7135000,  0.0367000,
     0.0389000, -0.0685000,  1.0296000
);

const mat3 CAT97 = mat3(
     0.8562000,  0.3372000, -0.1934000,
    -0.8360000,  1.8327000,  0.0033000,
     0.0357000, -0.0469000,  1.0112000
);

const mat3 CAT02 = mat3(
     0.7328000,  0.4296000, -0.1624000,
    -0.7036000,  1.6975000,  0.0061000,
     0.0030000,  0.0136000,  0.9834000
);

const mat3 CAT16 = mat3(
     0.4012880,  0.6501730, -0.0514610,
    -0.2502680,  1.2044140,  0.0458540,
    -0.0020790,  0.0489520,  0.9531270
);

// Other constants

const mat3 Identity3 = mat3(
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0
);

const mat3 SingularY3 = mat3(
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 1.0, 0.0
);

// Constants End

vec3 xyY_to_XYZ(vec3 xyY) {
    float x = xyY.x;
    float y = xyY.y;
    float Y = xyY.z;

    float multiplier = Y / max(y, 1e-6);

    float z = 1.0 - x - y;
    float X = x * multiplier;
    float Z = z * multiplier;

    return vec3(X, Y, Z);
}

// http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
mat3 RGB_to_XYZ(Chromaticity C) {
    if (C == GRAY)
        return Identity3;

    vec3 r = xyY_to_XYZ(vec3(C.r, 1.0));
    vec3 g = xyY_to_XYZ(vec3(C.g, 1.0));
    vec3 b = xyY_to_XYZ(vec3(C.b, 1.0));
    vec3 w = xyY_to_XYZ(vec3(C.w, 1.0));

    mat3 xyz = transpose(mat3(r, g, b));

    vec3 scale = w * inverse(xyz);
    mat3 scale_diag = mat3(
        scale.x, 0.0, 0.0,
        0.0, scale.y, 0.0,
        0.0, 0.0, scale.z
    );

    return scale_diag * xyz;
}

mat3 XYZ_to_RGB(Chromaticity C) {
    if (C == GRAY)
        return SingularY3;

    return inverse(RGB_to_XYZ(C));
}

// http://www.brucelindbloom.com/index.html?Eqn_ChromAdapt.html
mat3 adaptation(vec2 w1, vec2 w2, mat3 cat) {
    vec3 src_xyz = xyY_to_XYZ(vec3(w1, 1.0));
    vec3 dst_xyz = xyY_to_XYZ(vec3(w2, 1.0));

    vec3 src_lms = src_xyz * cat;
    vec3 dst_lms = dst_xyz * cat;

    vec3 scale = dst_lms / src_lms;
    mat3 scale_diag = mat3(
        scale.x, 0.0, 0.0,
        0.0, scale.y, 0.0,
        0.0, 0.0, scale.z
    );

    return cat * scale_diag * inverse(cat);
}

mat3 adaptation_two_step(vec2 w1, vec2 w2, vec2 wt, mat3 cat) {
    return adaptation(w1, wt, cat) * adaptation(wt, w2, cat);
}

// https://www.researchgate.net/publication/318152296_Comprehensive_color_solutions_CAM16_CAT16_and_CAM16-UCS
// CAT16 uses equal-energy illuminant (E) as wt.
// https://android.googlesource.com/platform/frameworks/base/+/master/graphics/java/android/graphics/ColorSpace.java
// Android uses Bradford as cat and D50 as wt.
mat3 adaptation_two_step(vec2 w1, vec2 w2) {
    return adaptation_two_step(w1, w2, E, CAT16);
}

mat3 RGB_to_RGB(Chromaticity c1, Chromaticity c2) {
    mat3 m = Identity3;
    if (from != to) {
        m *= RGB_to_XYZ(c1);
        if (from.w != to.w) {
            m *= adaptation_two_step(c1.w, c2.w);
        }
        m *= XYZ_to_RGB(c2);
    }
    return m;
}

vec3 RGB_to_RGB(vec3 c, Chromaticity c1, Chromaticity c2) {
    return c * RGB_to_RGB(c1, c2);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_RGB(color.rgb, from, to);

    return color;
}
