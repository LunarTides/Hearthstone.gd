// Shader from: https://godotshaders.com/shader/corner-radius/
shader_type canvas_item;

uniform float corner_scale: hint_range(0., 1.) = 0.;

bool isOut(float x, float y) {
    return pow(x, 2.) + pow(y, 2.) > pow(corner_scale * .5, 2.);
}

void fragment() {
    float s = corner_scale * .5;

    if (
        (UV.x < s      && UV.y < s      && isOut(UV.x - s,      UV.y - s)) ||
        (UV.x < s      && UV.y > 1. - s && isOut(UV.x - s,      UV.y - 1. + s)) ||
        (UV.x > 1. - s && UV.y < s      && isOut(UV.x - 1. + s, UV.y - s)) ||
        (UV.x > 1. - s && UV.y > 1. - s && isOut(UV.x - 1. + s, UV.y - 1. + s))
    ) {
        discard;
    }
}
