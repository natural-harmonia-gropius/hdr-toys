// https://www.color.org/WP40-Black_Point_Compensation_2010-07-27.pdf

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC black point compensation

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

vec3 black_point_compensation(vec3 XYZ, float s, float d) {
    float r = (1.0 - d) / (1.0 - s);
    return r * XYZ + (1.0 - r) * RGB_to_XYZ(vec3(1.0));
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_XYZ(color.rgb);
    color.rgb = black_point_compensation(color.rgb, 0.0, 1.0 / CONTRAST_sdr);
    color.rgb = XYZ_to_RGB(color.rgb);

    return color;
}
