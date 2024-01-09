// https://github.com/jedypod/gamut-compress
// https://github.com/ampas/aces-dev/blob/dev/transforms/ctl/lmt/LMT.Academy.ReferenceGamutCompress.ctl
// Pick compressed color's chroma replace the orginal color's chroma in CIE-Lab.

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

//!PARAM L_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000
203.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (jedypod)

#define func    parabolic


// Parabolic compression function: https://www.desmos.com/calculator/nvhp63hmtj
float parabolic(float dist, float lim, float thr) {
    if (dist > thr) {
        // Calculate scale so compression function passes through distance limit: (x=dl, y=1)
        float scale = (1.0 - thr) / sqrt(lim - 1.0);
        float sacle_ = scale * scale / 4.0;
        dist = scale * (sqrt(dist - thr + sacle_) - sqrt(sacle_)) + thr;
    }

    return dist;
}

float power(float dist, float lim, float thr) {
    float pwr = 1.2;

    if (dist > thr) {
        // Calculate scale factor for y = 1 intersect
        float scl = (lim - thr) / pow(pow((1.0 - thr) / (lim - thr), -pwr) - 1.0, 1.0 / pwr);

        // Normalize distance outside threshold by scale factor
        float nd = (dist - thr) / scl;
        float p = pow(nd, pwr);

        // Compress
        dist = thr + scl * nd / (pow(1.0 + p, 1.0 / pwr));
    }

    return dist;
}

vec3 gamut_compress(vec3 rgb) {
    // Distance limit: How far beyond the gamut boundary to compress
    vec3 dl = vec3(cyan_limit, magenta_limit, yellow_limit);

    // Amount of outer gamut to affect
    vec3 th = vec3(cyan_threshold, magenta_threshold, yellow_threshold);

    // Achromatic axis
    float ac = max(max(rgb.r, rgb.g), rgb.b);

    // Inverse RGB Ratios: distance from achromatic axis
    vec3 d = ac == 0.0 ? vec3(0.0) : (ac - rgb) / abs(ac);

    // Compressed distance
    vec3 cd = vec3(
        func(d.x, dl.x, th.x),
        func(d.y, dl.y, th.y),
        func(d.z, dl.z, th.z)
    );

    // Inverse RGB Ratios to RGB
    vec3 crgb = ac - cd * abs(ac);

    return crgb;
}

#define cbrt(x) (sign(x) * pow(abs(x), 1.0 / 3.0))


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
        0.8190224432164319,   0.3619062562801221,  -0.12887378261216414,
        0.0329836671980271,   0.9292868468965546,   0.03614466816999844,
        0.048177199566046255, 0.26423952494422764,  0.6335478258136937);
    return XYZ * M;
}

vec3 LMS_to_XYZ(vec3 LMS) {
    mat3 M = mat3(
         1.2268798733741557,  -0.5578149965554813,  0.28139105017721583,
        -0.04057576262431372,  1.1122868293970594, -0.07171106666151701,
        -0.07637294974672142, -0.4214933239627914,  1.5869240244272418);
    return LMS * M;
}

vec3 LMS_to_Lab(vec3 LMS) {
    mat3 M = mat3(
        0.2104542553,  0.7936177850, -0.0040720468,
        1.9779984951, -2.4285922050,  0.4505937099,
        0.0259040371,  0.7827717662, -0.8086757660);

    LMS = vec3(
        cbrt(LMS.x),
        cbrt(LMS.y),
        cbrt(LMS.z)
    );

    return LMS * M;
}

vec3 Lab_to_LMS(vec3 Lab) {
    mat3 M = mat3(
        0.99999999845051981432,  0.39633779217376785678,   0.21580375806075880339,
        1.0000000088817607767,  -0.1055613423236563494,   -0.063854174771705903402,
        1.0000000546724109177,  -0.089484182094965759684, -1.2914855378640917399);

    Lab = Lab * M;

    return vec3(
        pow(Lab.x, 3.0),
        pow(Lab.y, 3.0),
        pow(Lab.z, 3.0)
    );
}

vec3 RGB_to_Lab(vec3 color) {
    color  = RGB_to_XYZ(color);
    color  = XYZ_to_LMS(color);
    color  = LMS_to_Lab(color);
    return color;
}

vec3 Lab_to_RGB(vec3 color) {
    color  = Lab_to_LMS(color);
    color  = LMS_to_XYZ(color);
    color  = XYZ_to_RGB(color);
    return color;
}

const float pi = 3.141592653589793;
const float epsilon = 1e-6;

vec3 Lab_to_LCH(vec3 Lab) {
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float H = 0.0;

    if (!(abs(a) < epsilon && abs(b) < epsilon)) {
        H = atan(b, a);
        H = H * 180.0 / pi;
        H = mod((mod(H, 360.0) + 360.0), 360.0);
    }

    return vec3(Lab.x, C, H);
}

vec3 LCH_to_Lab(vec3 LCH) {
    float C = max(LCH.y, 0.0);
    float H = LCH.z * pi / 180.0;

    float a = C * cos(H);
    float b = C * sin(H);

    return vec3(LCH.x, a, b);
}

mat3 M = mat3(
     1.660491, -0.587641, -0.072850,
    -0.124550,  1.132900, -0.008349,
    -0.018151, -0.100579,  1.118730
);

mat3 M_inv = mat3(
     0.627404, 0.329283, 0.043313,
     0.069097, 0.919540, 0.011362,
     0.016391, 0.088013, 0.895595
);

vec4 hook() {
    vec4 color = HOOKED_texOff(0);
    vec3 color_crgb = color.rgb;

    color_crgb = gamut_compress(color_crgb * M) * M_inv;
    color_crgb = RGB_to_Lab(color_crgb);
    color_crgb = Lab_to_LCH(color_crgb);

    color.rgb = RGB_to_Lab(color.rgb);
    color.rgb = Lab_to_LCH(color.rgb);
    color.y   = color_crgb.y;
    color.rgb = LCH_to_Lab(color.rgb);
    color.rgb = Lab_to_RGB(color.rgb);
    color.rgb = color.rgb * M;

    return color;
}
