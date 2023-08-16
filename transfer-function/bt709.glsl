//!HOOK OUTPUT
//!BIND HOOKED
//!DESC transfer function (bt.709)

const float beta = 0.018053968510807;
const float alpha = 1.0 + 5.5 * beta;

float bt709_r(float L) {
    return L < beta ? 4.5 * L : alpha * pow(L, 0.45) - (alpha - 1.0);
}

vec4 hook() {
    vec4 color = HOOKED_texOff(0);

    color.rgb = vec3(
        bt709_r(color.r),
        bt709_r(color.g),
        bt709_r(color.b)
    );

    return color;
}
