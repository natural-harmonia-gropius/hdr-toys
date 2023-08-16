//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (bt.709, inverse)

const float beta = 0.018053968510807;
const float alpha = 1.0 + 5.5 * beta;

float bt709_f(float V) {
    return V < 4.5 * beta ? V / 4.5 : pow((V + (alpha - 1.0)) / alpha, 1.0 / 0.45);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = vec3(
        bt709_f(color.r),
        bt709_f(color.g),
        bt709_f(color.b)
    );

    return color;
}
