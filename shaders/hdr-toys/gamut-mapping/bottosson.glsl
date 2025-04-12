// https://bottosson.github.io/posts/gamutclipping/
// https://www.shadertoy.com/view/7sXcWn

//!PARAM softness_scale
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.3

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC gamut mapping (bottosson, soft)

float cbrt(float x) {
    return sign(x) * pow(abs(x), 1.0 / 3.0);
}

vec3 cbrt(vec3 color) {
    return vec3(
        cbrt(color.x),
        cbrt(color.y),
        cbrt(color.z)
    );
}

vec3 RGB_to_XYZ(vec3 RGB) {
    return RGB * mat3(
        0.6369580483012914, 0.14461690358620832,  0.1688809751641721,
        0.2627002120112671, 0.6779980715188708,   0.05930171646986196,
        0.000000000000000,  0.028072693049087428, 1.060985057710791
    );
}

vec3 XYZ_to_RGB(vec3 XYZ) {
    return XYZ * mat3(
         1.716651187971268,  -0.355670783776392, -0.253366281373660,
        -0.666684351832489,   1.616481236634939,  0.0157685458139111,
         0.017639857445311,  -0.042770613257809,  0.942103121235474
    );
}

vec3 XYZ_to_LMS(vec3 XYZ) {
    return XYZ * mat3(
        0.8190224379967030, 0.3619062600528904, -0.1288737815209879,
        0.0329836539323885, 0.9292868615863434,  0.0361446663506424,
        0.0481771893596242, 0.2642395317527308,  0.6335478284694309
    );
}

vec3 LMS_to_XYZ(vec3 LMS) {
    return LMS * mat3(
         1.2268798758459243, -0.5578149944602171,  0.2813910456659647,
        -0.0405757452148008,  1.1122868032803170, -0.0717110580655164,
        -0.0763729366746601, -0.4214933324022432,  1.5869240198367816
    );
}

vec3 LMS_to_Lab(vec3 LMS) {
    return LMS * mat3(
        0.2104542683093140,  0.7936177747023054, -0.0040720430116193,
        1.9779985324311684, -2.4285922420485799,  0.4505937096174110,
        0.0259040424655478,  0.7827717124575296, -0.8086757549230774
    );
}

vec3 Lab_to_LMS(vec3 Lab) {
    return Lab * mat3(
        1.0000000000000000,  0.3963377773761749,  0.2158037573099136,
        1.0000000000000000, -0.1055613458156586, -0.0638541728258133,
        1.0000000000000000, -0.0894841775298119, -1.2914855480194092
    );
}

vec3 RGB_to_Lab(vec3 color) {
    color = RGB_to_XYZ(color);
    color = XYZ_to_LMS(color);
    color = cbrt(color);
    color = LMS_to_Lab(color);
    return color;
}

vec3 Lab_to_RGB(vec3 color) {
    color = Lab_to_LMS(color);
    color = pow(color, vec3(3.0));
    color = LMS_to_XYZ(color);
    color = XYZ_to_RGB(color);
    return color;
}

const float epsilon = 1e-6;

vec3 Lab_to_LCh(vec3 Lab) {
    float L = Lab.x;
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float h = (abs(a) < epsilon && abs(b) < epsilon) ? 0.0 : atan(b, a);

    return vec3(L, C, h);
}

vec3 LCh_to_Lab(vec3 LCh) {
    float L = LCh.x;
    float C = LCh.y;
    float h = LCh.z;

    C = max(C, 0.0);
    float a = C * cos(h);
    float b = C * sin(h);

    return vec3(L, a, b);
}





vec3 output_RGB_to_XYZ(vec3 RGB) {
    mat3 M = mat3(
        0.41239079926595934, 0.357584339383878,   0.1804807884018343,
        0.21263900587151027, 0.715168678767756,   0.07219231536073371,
        0.01933081871559182, 0.11919477979462598, 0.9505321522496607);
    return RGB * M;
}

vec3 output_XYZ_to_RGB(vec3 XYZ) {
    mat3 M = mat3(
        3.2409699419045226,  -1.537383177570094,   -0.4986107602930034,
        -0.9692436362808796,   1.8759675015077202,   0.04155505740717559,
        0.05563007969699366, -0.20397695888897652,  1.0569715142428786);
    return XYZ * M;
}

float findCenter(vec3 x) {
    float a = 1.9779985324311684 * x.x - 2.4285922420485799 * x.y + 0.4505937096174110 * x.z;
    float b = 0.0259040424655478 * x.x + 0.7827717124575296 * x.y - 0.8086757549230774 * x.z;
    float C = sqrt(a*a+b*b);

    // Matrix derived for max(l,m,s) to be as close to macadam limit as possible
    // this makes it some kind of g0-like estimate
    mat3 M = mat3(
         2.26923008, -1.43594808,  0.166718,
        -0.98545265,  2.12616699, -0.14071434,
        -0.02985871, -0.25753239,  1.2873911);
    x = x*M;

    float x_min = min(x.r,min(x.g,x.b));
    float x_max = max(x.r,max(x.g,x.b));

    float c = 0.5*(x_max+x_min);
    float s = (x_max-x_min);

    // math trickery to create values close to c and s, but without producing hard edges
    vec3 y = (x-c)/s;
    float c_smooth = c + dot(y*y*y, vec3(1.0/3.0))*s;
    float s_smooth = sqrt(dot(x-c,x-c)/2.0);

    return c_smooth;
}

vec2 findCenterAndPurity(vec3 x) {
    // Matrix derived for (c_smooth+s_smooth) to be an approximation of the macadam limit
    // this makes it some kind of g0-like estimate
    mat3 M = mat3(
         2.26775149, -1.43293879,  0.1651873,
        -0.98535505,  2.1260072,  -0.14065215,
        -0.02501605, -0.26349465,  1.2885107);

    x = x*M;

    float x_min = min(x.r,min(x.g,x.b));
    float x_max = max(x.r,max(x.g,x.b));

    float c = 0.5*(x_max+x_min);
    float s = (x_max-x_min);

    // math trickery to create values close to c and s, but without producing hard edges
    vec3 y = (x-c)/s;
    float c_smooth = c + dot(y*y*y, vec3(1.0/3.0))*s;
    float s_smooth = sqrt(dot(x-c,x-c)/2.0);
    return vec2(c_smooth, s_smooth);
}


vec3 toLms(vec3 c) {
    vec3 lms_ = XYZ_to_LMS(output_RGB_to_XYZ(c));
    return sign(lms_)*pow(abs(lms_), vec3(1.0/3.0));
}

float calculateC(vec3 lms) {
    // Most of this could be precomputed
    // Creating a transform that maps R,G,B in the target gamut to have same distance from grey axis

    vec3 lmsR = toLms(vec3(1.0,0.0,0.0));
    vec3 lmsG = toLms(vec3(0.0,1.0,0.0));
    vec3 lmsB = toLms(vec3(0.0,0.0,1.0));

    vec3 uDir = (lmsR - lmsG)/sqrt(2.0);
    vec3 vDir = (lmsR + lmsG - 2.0*lmsB)/sqrt(6.0);

    mat3 to_uv = inverse(mat3(
        1.0, uDir.x, vDir.x,
        1.0, uDir.y, vDir.y,
        1.0, uDir.z, vDir.z
    ));

    vec3 _uv = lms * to_uv;

    return sqrt(_uv.y*_uv.y + _uv.z*_uv.z);
}

vec3 calculateLCh(vec3 c) {
    vec3 lms = toLms(c);

    float maxLms = findCenter(lms);

    float a = 1.9779985324311684 * lms.x - 2.4285922420485799 * lms.y + 0.4505937096174110 * lms.z;
    float b = 0.0259040424655478 * lms.x + 0.7827717124575296 * lms.y - 0.8086757549230774 * lms.z;

    float C = sqrt(a*a+b*b);

    return vec3(maxLms, C, atan(-b, -a));
}

vec2 expandShape(vec3 rgb, vec2 ST) {
    vec3 LCh = calculateLCh(rgb);
    vec2 STnew = vec2(LCh.x/LCh.y, (1.0-LCh.x)/LCh.y);
    STnew = (STnew + 3.0*STnew*STnew*LCh.y);

    return vec2(min(ST.x, STnew.x), min(ST.y, STnew.y));
}

float expandScale(vec3 rgb, vec2 ST, float scale) {
    vec3 LCh = calculateLCh(rgb);
    float Cnew = (1.0/((ST.x/LCh.x) + (ST.y/(1.0-LCh.x))));

    return max(LCh.y/Cnew, scale);
}

vec2 approximateShape() {
    float m = -softness_scale*0.2;
    float s = 1.0 + (softness_scale*0.2+softness_scale*0.8);

    vec2 ST = vec2(1000.0,1000.0);
    ST = expandShape(m+s*vec3(1.0,0.0,0.0), ST);
    ST = expandShape(m+s*vec3(1.0,1.0,0.0), ST);
    ST = expandShape(m+s*vec3(0.0,1.0,0.0), ST);
    ST = expandShape(m+s*vec3(0.0,1.0,1.0), ST);
    ST = expandShape(m+s*vec3(0.0,0.0,1.0), ST);
    ST = expandShape(m+s*vec3(1.0,0.0,1.0), ST);

    float scale = 0.0;
    scale = expandScale(m+s*vec3(1.0,0.0,0.0), ST, scale);
    scale = expandScale(m+s*vec3(1.0,1.0,0.0), ST, scale);
    scale = expandScale(m+s*vec3(0.0,1.0,0.0), ST, scale);
    scale = expandScale(m+s*vec3(0.0,1.0,1.0), ST, scale);
    scale = expandScale(m+s*vec3(0.0,0.0,1.0), ST, scale);
    scale = expandScale(m+s*vec3(1.0,0.0,1.0), ST, scale);

    return ST/scale;
}

vec3 compute(float L, float hue, float sat) {
    vec3 c = vec3(L, cos(hue), sin(hue));

    float l_ = + 0.3963377773761749 * c.y + 0.2158037573099136 * c.z;
    float m_ = - 0.1055613458156586 * c.y - 0.0638541728258133 * c.z;
    float s_ = - 0.0894841775298119 * c.y - 1.2914855480194092 * c.z;

    vec3 lms = vec3(l_,m_,s_);

    vec2 MC = findCenterAndPurity(lms);

    lms -= MC.x;

    lms *= sat;

    lms += c.x;

    lms = lms*lms*lms;

    vec3 rgb = output_XYZ_to_RGB(LMS_to_XYZ(lms));

    return rgb;
}

vec3 softSaturate(vec3 x, vec3 a) {
    a = clamp(a, 0.0,softness_scale);
    a = 1.0+a;
    x = min(x, a);
    vec3 b = (a-1.0)*sqrt(a/(2.0-a));
    return 1.0 - (sqrt((x-a)*(x-a) + b*b) - b)/(sqrt(a*a+b*b)-b);
}

vec3 softClipColor(vec3 color) {
    // soft clip of rgb values to avoid artifacts of hard clipping
    // causes hues distortions, but is a smooth mapping

    float maxRGB = max(max(color.r, color.g), color.b);
    float minRGB = min(min(color.r, color.g), color.b);

    float grey = 0.2;

    vec3 x = color-grey;

    vec3 xsgn = sign(x);
    vec3 xscale = 0.5 + xsgn*(0.5-grey);
    x /= xscale;

    float softness_0 = maxRGB/(1.0+softness_scale)*softness_scale;
    float softness_1 = (1.0-minRGB)/(1.0+softness_scale)*softness_scale;

    vec3 softness = vec3(0.5)*(softness_0+softness_1 + xsgn*(softness_1 - softness_0));

    return grey + xscale*xsgn*softSaturate(abs(x), softness);
}





vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    vec3 lch = Lab_to_LCh(RGB_to_Lab(color.rgb));

    float L = lch.x;
    float C = lch.y;
    float h = lch.z;

    // if (L >= 1.0) {
    //     return vec4(vec3(1.0, 1.0, 1.0), color.a);
    // }

    // if (L <= 0.0) {
    //     return vec4(vec3(0.0, 0.0, 0.0), color.a);
    // }

    if (C <= 1e-6) {
        return color;
    }

    vec2 ST = approximateShape();
    float C_smooth = (1.0 / ((ST.x / L) + (ST.y / max(1.0 - L, 1e-6))));
    color.rgb = compute(L, h, C / sqrt(C * C / C_smooth / C_smooth + 1.0));
    color.rgb = softClipColor(color.rgb);

    return color;
}
