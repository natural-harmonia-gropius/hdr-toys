// https://github.com/jedypod/gamut-compress
// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lmt/LMT.Academy.ReferenceGamutCompress.ctl

//!PARAM cyan_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.518705262732682

//!PARAM magenta_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.0750082200767368

//!PARAM yellow_limit
//!TYPE float
//!MINIMUM 1.000001
//!MAXIMUM 2
1.0887800398456782

//!PARAM cyan_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
1.0505085424784364

//!PARAM magenta_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
0.9405097727736265

//!PARAM yellow_threshold
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 2
0.9771607745933959

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (jedypod)

vec3 gamut_compress(vec3 rgb) {
    // Distance limit: How far beyond the gamut boundary to compress
    vec3 dl = vec3(cyan_limit, magenta_limit, yellow_limit);

    // Amount of outer gamut to affect
    vec3 th = vec3(cyan_threshold, magenta_threshold, yellow_threshold);

    // Achromatic axis
    float ac = max(max(rgb.r, rgb.g), rgb.b);

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
    vec3 s;
    s.x = (1.0 - th.x) / sqrt(dl.x - 1.0);
    s.y = (1.0 - th.y) / sqrt(dl.y - 1.0);
    s.z = (1.0 - th.z) / sqrt(dl.z - 1.0);

    vec3 cd; // Compressed distance
    // Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
    cd.x = d.x < th.x ? d.x : s.x * sqrt(d.x - th.x + s.x * s.x / 4.0) - s.x * sqrt(s.x * s.x / 4.0) + th.x;
    cd.y = d.y < th.y ? d.y : s.y * sqrt(d.y - th.y + s.y * s.y / 4.0) - s.y * sqrt(s.y * s.y / 4.0) + th.y;
    cd.z = d.z < th.z ? d.z : s.z * sqrt(d.z - th.z + s.z * s.z / 4.0) - s.z * sqrt(s.z * s.z / 4.0) + th.z;

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    return crgb;
}

mat3 M = mat3(
     1.6604910021084354,  -0.5876411387885495,  -0.07284986331988474,
    -0.12455047452159074,  1.1328998971259596,  -0.008349422604369515,
    -0.01815076335490526, -0.10057889800800737,  1.118729661362913);

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    vec3 color_src = color.rgb;
    vec3 color_dst = color_src * M;

    color.rgb = gamut_compress(color_dst);

    return color;
}
