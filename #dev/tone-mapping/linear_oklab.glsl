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

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (linear, Oklab)

float cbrt(float x) {
    return sign(x) * pow(abs(x), 1.0 / 3.0);
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
        0.8190224379967030, 0.3619062600528904, -0.1288737815209879,
        0.0329836539323885, 0.9292868615863434,  0.0361446663506424,
        0.0481771893596242, 0.2642395317527308,  0.6335478284694309);
    return XYZ * M;
}

vec3 LMS_to_XYZ(vec3 LMS) {
    mat3 M = mat3(
         1.2268798758459243, -0.5578149944602171,  0.2813910456659647,
        -0.0405757452148008,  1.1122868032803170, -0.0717110580655164,
        -0.0763729366746601, -0.4214933324022432,  1.5869240198367816);
    return LMS * M;
}

vec3 LMS_to_Lab(vec3 LMS) {
    mat3 M = mat3(
        0.2104542683093140,  0.7936177747023054, -0.0040720430116193,
        1.9779985324311684, -2.4285922420485799,  0.4505937096174110,
        0.0259040424655478,  0.7827717124575296, -0.8086757549230774);

    LMS = vec3(
        cbrt(LMS.x),
        cbrt(LMS.y),
        cbrt(LMS.z)
    );

    return LMS * M;
}

vec3 Lab_to_LMS(vec3 Lab) {
    mat3 M = mat3(
        1.0000000000000000,  0.3963377773761749,  0.2158037573099136,
        1.0000000000000000, -0.1055613458156586, -0.0638541728258133,
        1.0000000000000000, -0.0894841775298119, -1.2914855480194092);

    Lab = Lab * M;

    return vec3(
        pow(Lab.x, 3.0),
        pow(Lab.y, 3.0),
        pow(Lab.z, 3.0)
    );
}

float L_to_Lr(float x) {
    const float k1 = 0.206;
    const float k2 = 0.03;
    const float k3 = (1.0 + k1) / (1.0 + k2);
    return 0.5 * (k3 * x - k1 + sqrt(pow(k3 * x - k1, 2.0) + 4.0 * k2 * k3 * x));
}

float Lr_to_L(float x) {
    const float k1 = 0.206;
    const float k2 = 0.03;
    const float k3 = (1.0 + k1) / (1.0 + k2);
    return (x * (x + k1)) / (k3 * (x + k2));
}

vec3 RGB_to_Lab(vec3 color) {
    color   = RGB_to_XYZ(color);
    color   = XYZ_to_LMS(color);
    color   = LMS_to_Lab(color);
    color.x = L_to_Lr(color.x);
    return color;
}

vec3 Lab_to_RGB(vec3 color) {
    color.x = Lr_to_L(color.x);
    color   = Lab_to_LMS(color);
    color   = LMS_to_XYZ(color);
    color   = XYZ_to_RGB(color);
    return color;
}

float curve(float x) {
    const float iw = RGB_to_Lab(vec3(L_hdr / L_sdr)).x;
    const float ow = RGB_to_Lab(vec3(1.0)).x;
    const float w = iw / ow;
    return x / w;
}

vec3 tone_mapping_ictcp(vec3 ICtCp) {
    float I2  = curve(ICtCp.x);
    ICtCp.yz *= min(ICtCp.x / I2, I2 / ICtCp.x);
    ICtCp.x   = I2;

    return ICtCp;
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = RGB_to_Lab(color.rgb);
    color.rgb = tone_mapping_ictcp(color.rgb);
    color.rgb = Lab_to_RGB(color.rgb);

    return color;
}
