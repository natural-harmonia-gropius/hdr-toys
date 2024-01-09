// RGB to RGB conversion, include chromatic adaptation transform

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (clip)

// You can use custom chromaticity here
// e.g. BT.709 with D93 white point: Chromaticity(BT709.r, BT709.g, BT709.b, D93)

#define from    BT2020
#define to      BT709
#define cone    Bradford


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

vec2 K(float CCT) {
    CCT = clamp(CCT, 4000, 25000) * 1.4387768775039337 / 1.438;

    const float t1 = 1000.0 / CCT;
    const float t2 = t1 * t1;
    const float t3 = t1 * t2;

    const float x = CCT <= 7000
        ? 0.244063 + 0.09911 * t1 + 2.9678 * t2 - 4.6070 * t3
        : 0.237040 + 0.24748 * t1 + 1.9018 * t2 - 2.0064 * t3;
    const float y = -0.275 + 2.87 * x - 3.0 * x * x;

    return vec2(x, y);
}

// Chromaticities

struct Chromaticity {
    vec2 r, g, b, w;
};

// ITU-R Recommendation BT.2020, BT.2100
const Chromaticity BT2020 = Chromaticity(
    vec2(0.708, 0.292),
    vec2(0.170, 0.797),
    vec2(0.131, 0.046),
    D65
);

// ITU-R Recommendation BT.709, IEC 61966-2-1 (sRGB)
const Chromaticity BT709 = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.30, 0.60),
    vec2(0.15, 0.06),
    D65
);

// ITU-R Recommendation BT.601 (625 lines), BT.470 (B/G), EBU 3213-E
const Chromaticity BT601_625 = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.29, 0.60),
    vec2(0.15, 0.06),
    D65
);

// ITU-R Recommendation BT.601 (525 lines), SMPTE ST 240
const Chromaticity BT601_525 = Chromaticity(
    vec2(0.630, 0.340),
    vec2(0.310, 0.595),
    vec2(0.155, 0.070),
    D65
);

// ITU-R Recommendation BT.470 (M)
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

// ITU-T Recommendation H.273 (Generic film)
const Chromaticity H273_8 = Chromaticity(
    vec2(0.681, 0.319),
    vec2(0.243, 0.692),
    vec2(0.145, 0.049),
    C
);

// ITU-T Recommendation H.273 (No corresponding industry specification identified)
const Chromaticity H273_22 = Chromaticity(
    vec2(0.630, 0.340),
    vec2(0.295, 0.605),
    vec2(0.155, 0.077),
    D65
);

// CIE 1931 XYZ
const Chromaticity XYZ = Chromaticity(
    vec2(1.0, 0.0),
    vec2(0.0, 1.0),
    vec2(0.0, 0.0),
    E
);

// CIE 1931 XYZ (D65 whitepoint)
const Chromaticity XYZD65 = Chromaticity(
    XYZ.r,
    XYZ.g,
    XYZ.b,
    D65
);

// CIE 1931 XYZ (D50 whitepoint)
const Chromaticity XYZD50 = Chromaticity(
    XYZ.r,
    XYZ.g,
    XYZ.b,
    D50
);

// Grayscale, Monochrome
const Chromaticity GRAY = Chromaticity(
    vec2(0.0, 0.0),
    vec2(0.0, 0.0),
    vec2(0.0, 0.0),
    E
);

// Adobe RGB
const Chromaticity AdobeRGB = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.21, 0.71),
    vec2(0.15, 0.06),
    D65
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

// Chromatic adaptation methods

const mat3 Bradford = mat3(
     0.8951000,  0.2664000, -0.1614000,
    -0.7502000,  1.7135000,  0.0367000,
     0.0389000, -0.0685000,  1.0296000
);

const mat3 von_Kries = mat3(
     0.4002400,  0.7076000, -0.0808100,
    -0.2263000,  1.1653200,  0.0457000,
     0.0000000,  0.0000000,  0.9182200
);

const mat3 CAT02 = mat3(
     0.7328000,  0.4296000, -0.1624000,
    -0.7036000,  1.6975000,  0.0061000,
     0.0030000,  0.0136000,  0.9834000
);

const mat3 CAT16 = mat3(
     0.401288,  0.650173, -0.051461,
    -0.250268,  1.204414,  0.045854,
    -0.002079,  0.048952,  0.953127
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

mat3 invert_mat3(mat3 m) {
    float determinant =
          m[0][0] * m[1][1] * m[2][2]
        + m[0][1] * m[1][2] * m[2][0]
        + m[0][2] * m[1][0] * m[2][1]
        - m[2][0] * m[1][1] * m[0][2]
        - m[2][1] * m[1][2] * m[0][0]
        - m[2][2] * m[1][0] * m[0][1];

    if (determinant == 0.0)
        return Identity3;

    return mat3(
        m[1][1] * m[2][2] - m[1][2] * m[2][1],
        m[2][1] * m[0][2] - m[2][2] * m[0][1],
        m[0][1] * m[1][2] - m[0][2] * m[1][1],
        m[2][0] * m[1][2] - m[1][0] * m[2][2],
        m[0][0] * m[2][2] - m[2][0] * m[0][2],
        m[1][0] * m[0][2] - m[0][0] * m[1][2],
        m[1][0] * m[2][1] - m[2][0] * m[1][1],
        m[2][0] * m[0][1] - m[0][0] * m[2][1],
        m[0][0] * m[1][1] - m[1][0] * m[0][1]
    ) / determinant;
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

mat3 RGB_to_XYZ(Chromaticity C) {
    if (C == GRAY)
        return Identity3;

    vec3 r = xyY_to_XYZ(vec3(C.r, 1.0));
    vec3 g = xyY_to_XYZ(vec3(C.g, 1.0));
    vec3 b = xyY_to_XYZ(vec3(C.b, 1.0));
    vec3 w = xyY_to_XYZ(vec3(C.w, 1.0));

    mat3 n = transpose(mat3(r, g, b));
    vec3 s = w * invert_mat3(n);
    mat3 m = mat3(n[0] * s, n[1] * s, n[2] * s);

    return m;
}

mat3 XYZ_to_RGB(Chromaticity C) {
    if (C == GRAY)
        return SingularY3;

    return invert_mat3(RGB_to_XYZ(C));
}

mat3 adaptation(vec2 W1, vec2 W2, mat3 cone) {
    if (W1 == W2)
        return Identity3;

    vec3 src_XYZ = xyY_to_XYZ(vec3(W1, 1.0));
    vec3 dst_XYZ = xyY_to_XYZ(vec3(W2, 1.0));

    vec3 src_cone = src_XYZ * cone;
    vec3 dst_cone = dst_XYZ * cone;

    mat3 scale = mat3(
        dst_cone.x / src_cone.x, 0.0, 0.0,
        0.0, dst_cone.y / src_cone.y, 0.0,
        0.0, 0.0, dst_cone.z / src_cone.z
    );

    return cone * scale * invert_mat3(cone);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb *= RGB_to_XYZ(from);
    color.rgb *= adaptation(from.w, to.w, cone);
    color.rgb *= XYZ_to_RGB(to);

    return color;
}
