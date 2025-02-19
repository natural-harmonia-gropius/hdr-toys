// Visualizes the exposure value of the image using false color

// Inspired by the Ansel Adams' Zone System
// https://en.wikipedia.org/wiki/Zone_System#Zones_as_tone_and_texture
// Expanded exposure stops based on the de facto devices' dynamic range

// You can preview the colors in Visual Studio Code by the following plugin
// https://marketplace.visualstudio.com/items?itemName=naumovs.color-highlight

// oklch(0.99500 0.00 000.0)    overexposure
// oklch(0.94659 0.11 005.0)    +7 stops
// oklch(0.89269 0.22 015.0)    +6 stops
// oklch(0.83878 0.33 025.0)    +5 stops
// oklch(0.78487 0.11 060.0)    +4 stops
// oklch(0.73097 0.33 090.0)    +3 stops
// oklch(0.67706 0.22 105.0)    +2 stops
// oklch(0.62315 0.11 120.0)    +1 stop
// oklch(0.56925 0.00 000.0)    middle gray
// oklch(0.52324 0.33 130.0)    -1 stop
// oklch(0.47724 0.22 145.0)    -2 stops
// oklch(0.43123 0.11 160.0)    -3 stops
// oklch(0.38523 0.32 220.0)    -4 stops
// oklch(0.33922 0.24 245.0)    -5 stops
// oklch(0.29322 0.24 290.0)    -6 stops
// oklch(0.24721 0.16 320.0)    -7 stops
// oklch(0.20104 0.08 350.0)    -8 stops
// oklch(0.13040 0.00 000.0)    underexposure

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC tone mapping (false color, exposure)

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
    color = vec3(pow(color.r, 3.0), pow(color.g, 3.0), pow(color.b, 3.0));
    color = LMS_to_XYZ(color);
    color = XYZ_to_RGB(color);
    return color;
}

const float epsilon = 1e-6;

vec3 Lab_to_LCH(vec3 Lab) {
    float a = Lab.y;
    float b = Lab.z;

    float C = length(vec2(a, b));
    float H = 0.0;

    if (!(abs(a) < epsilon && abs(b) < epsilon))
        H = atan(b, a);

    return vec3(Lab.x, C, H);
}

vec3 LCH_to_Lab(vec3 LCH) {
    float C = max(LCH.y, 0.0);
    float H = LCH.z;

    float a = C * cos(H);
    float b = C * sin(H);

    return vec3(LCH.x, a, b);
}

vec4 hook() {
    vec4 color = HOOKED_tex(HOOKED_pos);

    float stops = log2(max(RGB_to_XYZ(color.rgb).y, 1e-6) / 0.18);

    if      (stops >=  7.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.99500, 0.00, radians(000.0))));
    else if (stops >=  6.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.94659, 0.11, radians(005.0))));
    else if (stops >=  5.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.89269, 0.22, radians(015.0))));
    else if (stops >=  4.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.83878, 0.33, radians(025.0))));
    else if (stops >=  3.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.78487, 0.11, radians(060.0))));
    else if (stops >=  2.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.73097, 0.33, radians(090.0))));
    else if (stops >=  1.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.67706, 0.22, radians(105.0))));
    else if (stops >=  0.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.62315, 0.11, radians(120.0))));
    else if (stops >= -0.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.56925, 0.00, radians(000.0))));
    else if (stops >= -1.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.52324, 0.33, radians(130.0))));
    else if (stops >= -2.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.47724, 0.22, radians(145.0))));
    else if (stops >= -3.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.43123, 0.11, radians(160.0))));
    else if (stops >= -4.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.38523, 0.32, radians(220.0))));
    else if (stops >= -5.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.33922, 0.24, radians(245.0))));
    else if (stops >= -6.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.29322, 0.24, radians(290.0))));
    else if (stops >= -7.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.24721, 0.16, radians(320.0))));
    else if (stops >= -8.5) color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.20104, 0.08, radians(350.0))));
    else                    color.rgb = Lab_to_RGB(LCH_to_Lab(vec3(0.13040, 0.00, radians(000.0))));

    return color;
}
