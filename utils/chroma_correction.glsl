// ITU-R BT.2446 Conversion Method C - 6.1.8
// Optional processing of chroma correction above HDR Reference White

// In SDR production, highlight parts are sometimes intentionally expressed as white. The processing
// described in this section is optionally used to shift chroma above HDR Reference White to achromatic
// when the converted SDR content requires a degree of consistency for SDR production content. This
// processing is applied as needed before the tone-mapping processing.

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

//!PARAM sigma
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1
0.2

//!HOOK OUTPUT
//!BIND HOOKED
//!WHEN sigma
//!DESC chroma correction

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

vec3 XYZD65_to_XYZD50(vec3 XYZ) {
    mat3 M = mat3(
         1.0479298208405488,   0.022946793341019088, -0.05019222954313557,
         0.029627815688159344, 0.990434484573249,    -0.01707382502938514,
        -0.009243058152591178, 0.015055144896577895,  0.7518742899580008);
    return XYZ * M;
}

vec3 XYZD50_to_XYZD65(vec3 XYZ) {
    mat3 M = mat3(
         0.9554734527042182,   -0.023098536874261423, 0.0632593086610217,
        -0.028369706963208136,  1.0099954580058226,   0.021041398966943008,
         0.012314001688319899, -0.020507696433477912, 1.3303659366080753);
    return XYZ * M;
}

float delta = 6.0 / 29.0;
float deltac = delta * 2.0 / 3.0;

float f1(float x, float delta) {
    return x > pow(delta, 3.0) ?
        pow(x, 1.0 / 3.0) :
        deltac + x / (3.0 * pow(delta, 2.0));
}

float f2(float x, float delta) {
    return x > delta ?
        pow(x, 3.0) :
        (x - deltac) * (3.0 * pow(delta, 2.0));
}

vec3 XYZn = RGB_to_XYZ(vec3(L_sdr));

vec3 XYZ_to_Lab(vec3 XYZ) {
    float X = XYZ.x;
    float Y = XYZ.y;
    float Z = XYZ.z;

    X = f1(X / XYZn.x, delta);
    Y = f1(Y / XYZn.y, delta);
    Z = f1(Z / XYZn.z, delta);

    float L = 116.0 * Y - 16.0;
    float a = 500.0 * (X - Y);
    float b = 200.0 * (Y - Z);

    return vec3(L, a, b);
}

vec3 Lab_to_XYZ(vec3 Lab) {
    float L = Lab.x;
    float a = Lab.y;
    float b = Lab.z;

    float Y = (L + 16.0) / 116.0;
    float X = Y + a / 500.0;
    float Z = Y - b / 200.0;

    X = f2(X, delta) * XYZn.x;
    Y = f2(Y, delta) * XYZn.y;
    Z = f2(Z, delta) * XYZn.z;

    return vec3(X, Y, Z);
}

float pi = 3.141592653589793;
float epsilon = 0.02;

vec3 Lab_to_LCH(vec3 Lab) {
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float H = (abs(a) < epsilon && abs(b) < epsilon) ?
        0.0 :
        atan(b, a) * 180.0 / pi;

    return vec3(Lab.x, C, H);
}

vec3 LCH_to_Lab(vec3 LCH) {
    float C = max(LCH.y, 0.0);
    float H = LCH.z * pi / 180.0;

    float a = C * cos(H);
    float b = C * sin(H);

    return vec3(LCH.x, a, b);
}

float chroma_correction(float L, float Lref, float Lmax, float sigma) {
    return L > Lref ?
        max(1.0 - sigma * (L - Lref) / (Lmax - Lref), 0.0) :
        1.0;
}

vec4 color = HOOKED_tex(HOOKED_pos);
vec4 hook() {
    float L_ref = XYZ_to_Lab(RGB_to_XYZ(vec3(L_sdr))).x;
    float L_max = XYZ_to_Lab(RGB_to_XYZ(vec3(L_hdr))).x;

    color.rgb *= L_sdr;
    color.rgb  = RGB_to_XYZ(color.rgb);
    color.rgb  = XYZD65_to_XYZD50(color.rgb);
    color.rgb  = XYZ_to_Lab(color.rgb);
    color.rgb  = Lab_to_LCH(color.rgb);
    color.g   *= chroma_correction(color.x, L_ref, L_max, sigma);
    color.rgb  = LCH_to_Lab(color.rgb);
    color.rgb  = Lab_to_XYZ(color.rgb);
    color.rgb  = XYZD50_to_XYZD65(color.rgb);
    color.rgb  = XYZ_to_RGB(color.rgb);
    color.rgb /= L_sdr;
    return color;
}
