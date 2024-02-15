// https://github.com/jedypod/gamut-compress
// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lmt/LMT.Academy.ReferenceGamutCompress.ctl

//!PARAM cyan_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.5187050250638159

//!PARAM magenta_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.0750082769546088

//!PARAM yellow_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.0887800403483898

//!PARAM cyan_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
1.050508660266247

//!PARAM magenta_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
0.940509816042432

//!PARAM yellow_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
0.9771607996420639

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (jedypod)

// Parabolic compression function
// https://www.desmos.com/calculator/khowxlu6xh
float parabolic(float x, float t0, float x0, float y0) {
    float s = (y0 - t0) / sqrt(x0 - y0);
    float ox = t0 - s * s / 4.0;
    float oy = t0 - s * sqrt(s * s / 4.0);
    return (x < t0 ? x : s * sqrt(x - ox) + oy);
}

vec3 gamut_compress(vec3 rgb) {
    // Achromatic axis
    float ac = max(max(rgb.r, rgb.g), rgb.b);

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    // Compressed distance
    vec3 cd = vec3(
        parabolic(d.x, cyan_threshold, cyan_limit, 1.0),
        parabolic(d.y, magenta_threshold, magenta_limit, 1.0),
        parabolic(d.z, yellow_threshold, yellow_limit, 1.0)
    );

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    return crgb;
}

// BT.2020 to BT.709
mat3 M = mat3(
     1.66049100210843540, -0.58764113878854950,  -0.072849863319884740,
    -0.12455047452159074,  1.13289989712595960,  -0.008349422604369515,
    -0.01815076335490526, -0.10057889800800737,   1.118729661362913000
);

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = gamut_compress(color.rgb * M);

    return color;
}
