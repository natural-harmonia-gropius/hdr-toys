// adapt from a source whitepoint or illuminant W1
// to a destination whitepoint or illuminant W2

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC chromatic adaptation transform

vec2 A   = vec2(0.44757, 0.40745);
vec2 B   = vec2(0.34842, 0.35161);
vec2 C   = vec2(0.31006, 0.31616);
vec2 D50 = vec2(0.34567, 0.35850);
vec2 D55 = vec2(0.33242, 0.34743);
vec2 D60 = vec2(0.32168, 0.33767);
vec2 D65 = vec2(0.31271, 0.32902);
vec2 D75 = vec2(0.29902, 0.31485);
vec2 D93 = vec2(0.28315, 0.29711);
vec2 E   = vec2(1.0/3.0, 1.0/3.0);
vec2 DCI = vec2(0.314  , 0.351  );

mat3 Bradford = mat3(
     0.8951000,  0.2664000, -0.1614000,
    -0.7502000,  1.7135000,  0.0367000,
     0.0389000, -0.0685000,  1.0296000
);

mat3 von_Kries = mat3(
     0.4002400,  0.7076000, -0.0808100,
    -0.2263000,  1.1653200,  0.0457000,
     0.0000000,  0.0000000,  0.9182200
);

mat3 CAT02 = mat3(
     0.7328000,  0.4296000, -0.1624000,
    -0.7036000,  1.6975000,  0.0061000,
     0.0030000,  0.0136000,  0.9834000
);

mat3 CAT16 = mat3(
     0.401288,  0.650173, -0.051461,
    -0.250268,  1.204414,  0.045854,
    -0.002079,  0.048952,  0.953127
);

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

mat3 adapt(vec2 w1, vec2 w2, mat3 cone) {
    vec3 src_xyY = vec3(w1, 1.0);
    vec3 dst_xyY = vec3(w2, 1.0);

    vec3 src_XYZ = xyY_to_XYZ(src_xyY);
    vec3 dst_XYZ = xyY_to_XYZ(dst_xyY);

    vec3 src_cone = src_XYZ * cone;
    vec3 dst_cone = dst_XYZ * cone;

    mat3 scale = mat3(
        dst_cone.x / src_cone.x, 0.0, 0.0,
        0.0, dst_cone.y / src_cone.y, 0.0,
        0.0, 0.0, dst_cone.z / src_cone.z
    );

    return (scale * invert_mat3(cone)) * cone;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    color.rgb  = RGB_to_XYZ(color.rgb);
    color.rgb *= adapt(D65, DCI, Bradford);
    color.rgb  = XYZ_to_RGB(color.rgb);
    return color;
}
