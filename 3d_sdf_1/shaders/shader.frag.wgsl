struct Uniform {
  pos: vec3<f32>,
  resolution: vec2<f32>,
  mouse: vec2<f32>,
  mouse_pressed: u32,
  time: f32,
  time_delta: f32,
  frame: u32,
  record_period: f32,
};

@group(0) @binding(0)
var prev_frame: texture_2d<f32>;
@group(0) @binding(1) var generic_texture: texture_2d<f32>;
@group(0) @binding(2) var dummy_texture: texture_2d<f32>;
@group(0) @binding(3) var float_texture1: texture_2d<f32>;
@group(0) @binding(4) var float_texture2: texture_2d<f32>;
@group(1) @binding(4) var tex_sampler: sampler;
@group(2) @binding(0) var<uniform> u: Uniform;

struct VertexOutput {
  @builtin(position) pos: vec4<f32>,
  @location(0) uv: vec2<f32>,
};

fn sdCircle(p: vec2<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdBox(p: vec2<f32>, b: vec2<f32>) -> f32 {
    let d = abs(p) - b;
    return length(max(d, vec2<f32>(0.0))) + min(max(d.x, d.y), 0.0);
}

fn sdHexagon(p: vec2<f32>, r: f32) -> f32 {
    let k = vec3(-0.9238795325, 0.3826834323, 0.4142135623);
    var p = abs(p);
    p -= 2.0 * min(dot(vec2(k.x, k.y), p), 0.0) * vec2(k.x, k.y);
    p -= 2.0 * min(dot(vec2(-k.x, k.y), p), 0.0) * vec2(-k.x, k.y);
    p -= vec2<f32>(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

fn sdHexagram(p: vec2<f32>, r: f32) -> f32 {
    let k = vec4(-0.5, 0.8660254038, 0.5773502692, 1.7320508076);
    var p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= 2.0 * min(dot(k.yx, p), 0.0) * k.yx; p -= vec2(clamp(p.x, r * k.z, r * k.w), r);
    return length(p) * sign(p.y);
}

fn sdMoon(p: vec2<f32>, d: f32, ra: f32, rb: f32) -> f32 {
    var p = p;
    p.y = abs(p.y);
    let a = (ra * ra - rb * rb + d * d) / (2.0 * d);
    let b = sqrt(max(ra * ra - a * a, 0.0));
    if d * (p.x * b - p.y * a) > d * d * max(b - p.y, 0.0) {
        return length(p - vec2(a, b));
    } else {
        return max(
            (length(p) - ra),
            -(length(p - vec2(d, 0.)) - rb)
        );
    }
}

fn sdSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdf(p: vec3<f32>) -> f32 {
    return
        sdSphere(p, 100.)
    ;
}

fn castRay(ro: vec3<f32>, rd: vec3<f32>) -> vec2<f32> {


    return vec2(0.0);
}

fn render(ro: vec3<f32>, rd: vec3<f32>) -> vec3<f32> {
    return vec3(castRay(ro, rd), 0.6);
}

fn setCamera(ro: vec3<f32>, ta: vec3<f32>, cr: f32) -> mat3x3<f32> {
    let cw = normalize(ta - ro);
    let cp = vec3(sin(cr), cos(cr), 0.0);
    let cu = normalize(cross(cw, cp));
    let cv = normalize(cross(cu, cw));
    return mat3x3(cu, cv, cw);
}

@fragment
fn main(in: VertexOutput) -> @location(0) vec4<f32> {
    let color = vec4<f32>(0.0, 0.3, 0.9, 1.0);
    let scale = 1.;

    var tot = vec3(0.);
    let p = u.resolution * in.uv / scale - u.resolution / 2.0 / scale;

    let ro = vec3(-0.5 + 3.5 * cos(0.1 * u.time + 6.0), 1.0 + 2.0, 0.5 + 4.0 * sin(0.1 * u.time + 6.0));
    let ta = vec3(-0.5, -0.4, 0.5);
    let ca = setCamera(ro, ta, 0.0);
    let rd = ca * normalize(vec3(p.xy, 2.0));

    var col = render(ro, rd);
    col = pow(col, vec3(0.4545));
    tot += col;

    return vec4(tot, 1.0);
}