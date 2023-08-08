// RGB to RGB conversion, include chromatic adaptation transform

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (clip, custom)

#define from    BT2020
#define to      BT709
#define cone    Bradford


// White points of standard illuminants

const vec2 A    = vec2(0.44757, 0.40745);
const vec2 B    = vec2(0.34842, 0.35161);
const vec2 C    = vec2(0.31006, 0.31616);
const vec2 D50  = vec2(0.34567, 0.35850);
const vec2 D55  = vec2(0.33242, 0.34743);
const vec2 D60  = vec2(0.32163, 0.33774);
const vec2 D65  = vec2(0.31271, 0.32902);
const vec2 D75  = vec2(0.29902, 0.31485);
const vec2 D93  = vec2(0.28315, 0.29711);
const vec2 E    = vec2(1.0/3.0, 1.0/3.0);
const vec2 F2   = vec2(0.37208, 0.37529);
const vec2 F7   = vec2(0.31292, 0.32933);
const vec2 F11  = vec2(0.38052, 0.37713);
const vec2 DCI  = vec2(0.31400, 0.35100);
const vec2 ACES = vec2(0.32168, 0.33767);

// Chromaticities

struct Chromaticity {
    vec2 r, g, b, w;
};

// ITU-R Recommendation BT.709
const Chromaticity BT709  = Chromaticity(
    vec2(0.64, 0.33),
    vec2(0.30, 0.60),
    vec2(0.15, 0.06),
    D65
);

// ITU-R Recommendation BT.2020
const Chromaticity BT2020 = Chromaticity(
    vec2(0.708, 0.292),
    vec2(0.170, 0.797),
    vec2(0.131, 0.046),
    D65
);

// P3-DCI (Theater)
const Chromaticity P3DCI  = Chromaticity(
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

// Constants End

mat3 invert_mat3(mat3 m) {
    float determinant =
          m[0][0] * m[1][1] * m[2][2]
        + m[0][1] * m[1][2] * m[2][0]
        + m[0][2] * m[1][0] * m[2][1]
        - m[2][0] * m[1][1] * m[0][2]
        - m[2][1] * m[1][2] * m[0][0]
        - m[2][2] * m[1][0] * m[0][1];

    if (determinant == 0.0) {
        return mat3(
            1.0, 0.0, 0.0,
            0.0, 1.0, 0.0,
            0.0, 0.0, 1.0
        );
    }

    return (1.0 / determinant) * mat3(
        m[1][1] * m[2][2] - m[1][2] * m[2][1],
        m[2][1] * m[0][2] - m[2][2] * m[0][1],
        m[0][1] * m[1][2] - m[0][2] * m[1][1],
        m[2][0] * m[1][2] - m[1][0] * m[2][2],
        m[0][0] * m[2][2] - m[2][0] * m[0][2],
        m[1][0] * m[0][2] - m[0][0] * m[1][2],
        m[1][0] * m[2][1] - m[2][0] * m[1][1],
        m[2][0] * m[0][1] - m[0][0] * m[2][1],
        m[0][0] * m[1][1] - m[1][0] * m[0][1]
    );
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
    vec3 r = xyY_to_XYZ(vec3(C.r, 1.0));
    vec3 g = xyY_to_XYZ(vec3(C.g, 1.0));
    vec3 b = xyY_to_XYZ(vec3(C.b, 1.0));
    vec3 w = xyY_to_XYZ(vec3(C.w, 1.0));

    vec3 s = w * invert_mat3(mat3(
        r.x, g.x, b.x,
        r.y, g.y, b.y,
        r.z, g.z, b.z
    ));

    return mat3(
        s.r * r.x, s.g * g.x, s.b * b.x,
        s.r * r.y, s.g * g.y, s.b * b.y,
        s.r * r.z, s.g * g.z, s.b * b.z
    );
}

mat3 XYZ_to_RGB(Chromaticity N) {
    mat3 M = invert_mat3(RGB_to_XYZ(N));
    return M;
}

mat3 adaptation(vec2 w1, vec2 w2, mat3 cone) {
    vec3 src_XYZ = xyY_to_XYZ(vec3(w1, 1.0));
    vec3 dst_XYZ = xyY_to_XYZ(vec3(w2, 1.0));

    vec3 src_cone = src_XYZ * cone;
    vec3 dst_cone = dst_XYZ * cone;

    mat3 scale = mat3(
        dst_cone.x / src_cone.x, 0.0, 0.0,
        0.0, dst_cone.y / src_cone.y, 0.0,
        0.0, 0.0, dst_cone.z / src_cone.z
    );

    return (scale * invert_mat3(cone)) * cone;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb *= RGB_to_XYZ(from);
    color.rgb *= adaptation(from.w, to.w, cone);
    color.rgb *= XYZ_to_RGB(to);

    return color;
}
