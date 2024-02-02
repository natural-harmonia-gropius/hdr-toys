// https://www.itu.int/rec/R-REC-BT.1886

//!PARAM CONTRAST_sdr
//!TYPE float
//!MINIMUM 0
//!MAXIMUM 1000000
1000.0

//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (bt.1886, inverse)

const float GAMMA = 2.4;

// The reference EOTF specified in Rec. ITU-R BT.1886
// L = a(max[(V+b),0])^g
float bt1886_f(float V, float gamma, float Lw, float Lb) {
    float a = pow(pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma), gamma);
    float b = pow(Lb, 1.0 / gamma) / (pow(Lw, 1.0 / gamma) - pow(Lb, 1.0 / gamma));
    float L = a * pow(max(V + b, 0.0), gamma);
    return L;
}

vec3 bt1886_f_f3(vec3 V, float gamma, float Lw, float Lb) {
    return vec3(
        bt1886_f(V.r, gamma, Lw, Lb),
        bt1886_f(V.g, gamma, Lw, Lb),
        bt1886_f(V.b, gamma, Lw, Lb)
    );
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = bt1886_f_f3(color.rgb, GAMMA, 1.0, 1.0 / CONTRAST_sdr);

    return color;
}
