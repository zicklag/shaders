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

//
// Primitives
//

fn sdSphere(p: vec3<f32>, r: f32) -> f32 {
    return length(p) - r;
}

fn sdPlane(p: vec3<f32>) -> f32 {
    return p.y;
}

fn sdCapsule(p: vec3<f32>, a: vec3<f32>, b: vec3<f32>, r: f32) -> f32 {
    let pa = p - a;
    let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

fn sdBox(p: vec3<f32>, b: vec3<f32>) -> f32 {
    let d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, vec3(0.0)));
}

//
// Operations
//

fn opU(d1: vec2<f32>, d2: vec2<f32>) -> vec2<f32> {
    if d1.x < d2.x {
        return d1;
    } else {
        return d2;
    }
}

fn opS(d1: vec2<f32>, d2: f32) -> vec2<f32> {
    return vec2(max(-d2, d1.x), d1.y);
}

fn opTwist(p: vec3<f32>) -> vec3<f32> {
    let  c = cos(10.0 * p.y + 10.0);
    let  s = sin(10.0 * p.y + 10.0);
    let   m = mat2x2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}

fn opRep(p: vec3<f32>, c: vec3<f32>) -> vec3<f32> {
    return p % c - 0.5 * c;
}

//
// The scene
//

fn scene(p: vec3<f32>) -> vec2<f32> {
    // The ground
    var r = vec2(sdPlane(p), 0.0);

    // A sphere
    r = opU(r, vec2(sdSphere(p - vec3(0.0, 0.3, 0.0), 0.25), 100.0));
    r = opU(r, vec2(
        sdCapsule(p - vec3(-0.5, 0.4, 0.0), vec3(-0.5, 00., 0.0), vec3(0.1, 0.2, 0.0), 0.15),
        20. * u.time
    ));
    r = opS(r, sdBox(p - vec3(-0.4 + (sin(u.time)), 0.3, 0.0), vec3(0.3, 0.3, 0.3)));

    return r;
}

//
// Rendering functions
//

fn checkersGradBox(p: vec2<f32>) -> f32 {
    // filter kernel
    let w = fwidth(p) + 0.001;
    let a1 = abs(fract((p - 0.5 * w) * 0.5) - 0.5);
    let a2 = abs(fract((p + 0.5 * w) * 0.5) - 0.5);
    // analytical integral (box filter)
    let i = 2.0 * (a1 - a2) / w;
    // xor pattern
    return 0.5 - 0.5 * i.x * i.y;
}

fn calcNormal(pos: vec3<f32>) -> vec3<f32> {
    let e = vec2(1.0, -1.0) * 0.5773 * 0.000005;
    let a1 = e.xyy * scene(pos + e.xyy).x;
    let a2 = e.yyx * scene(pos + e.yyx).x;
    let a3 = e.yxy * scene(pos + e.yxy).x;
    let a4 = e.xxx * scene(pos + e.xxx).x;
    return normalize(a1 + a2 + a3 + a4);
}

fn calcSoftshadow(ro: vec3<f32>, rd: vec3<f32>, mint: f32, tmax: f32) -> f32 {
    var res = 1.0;
    var t = mint;

    for (var i = 0; i < 16; i++) {
        var h = scene(ro + rd * t).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.002, 0.10);
        if res < 0.005 || t > tmax {
            break;
        }
    }

    return clamp(res, 0.0, 1.0);
}

fn calcAO(pos: vec3<f32>, nor: vec3<f32>) -> f32 {
    var occ = 0.0;
    var sca = 1.0;

    for (var i = 0; i < 5; i ++) {
        let hr = 0.01 + 0.12 * f32(i) / 4.0;
        let aopos = nor * hr + pos;
        let dd = scene(aopos).x;
        occ += -(dd - hr) * sca;
        sca *= 0.95;
    }

    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

fn castRay(ro: vec3<f32>, rd: vec3<f32>) -> vec2<f32> {
    var tmin = 1.0;
    var tmax = 70.0;

    // Bounding volume
    //
    // TODO: Understand this. It seems to be an optimization.
    let tp1 = (0.0 - ro.y) / rd.y;
    if tp1 > 0. {
        tmax = min(tmax, tp1);
    }
    let tp2 = (1.6 - ro.y) / rd.y;
    if tp2 > 0.0 {
        if ro.y > 1.6 {
            tmin = max(tmin, tp2);
        } else {
            tmax = min(tmax, tp2);
        }
    }

    // March ray
    var t = tmin;
    var m = -1.0;

    for (var i: i32 = 0; i < 1000; i++) {
        let precis = 0.0001 * t;
        let res = scene(ro + rd * t);
        if res.x < precis || t > tmax {
            break
        }
        t += res.x;
        m = res.y;
    }

    if t > tmax { m = -1.0; }

    return vec2(t, m);
}

fn render(ro: vec3<f32>, rd: vec3<f32>) -> vec3<f32> {
    let sky_col = vec3(0.7, 0.9, 1.0);
    var col = vec3(0.7, 0.9, 1.0) + rd.y * 0.8;
    let res = castRay(ro, rd);
    let t = res.x;
    let m = res.y;

    if m > -0.5 {
        let pos = ro + t * rd;
        let nor = calcNormal(pos);
        let refl = reflect(rd, nor);

        // material
        col = 0.45 + 0.35 * sin(vec3(0.05, 0.08, 0.10) * (m - 1.0));
        // TODO: checker floor
        if m < 1.5 {
            let f = checkersGradBox(5.0 * pos.xz);
            col = 0.3 + f * vec3(0.1);
        }

        // lighting
        let occ = calcAO(pos, nor);
        let lig = normalize(vec3(-0.4, 0.7, -0.6));
        let hal = normalize(lig - rd);
        let amb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
        var dif = clamp(dot(nor, lig), 0.0, 1.0);
        let bac = clamp(dot(nor, normalize(vec3(-lig.x, 0.0, -lig.z))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0);
        var dom = smoothstep(-0.1, 0.1, refl.y);
        let fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0);

        dif *= calcSoftshadow(pos, lig, 0.02, 2.5);
        dom *= calcSoftshadow(pos, refl, 0.02, 2.5);

        let spe = pow(clamp(dot(nor, hal), 0.0, 1.0), 16.0) * dif * (0.04 + 0.96 * pow(clamp(1.0 + dot(hal, rd), 0.0, 1.0), 5.0));

        var lin = vec3(0.0);
        lin += 1.30 * dif * vec3(1.00, 0.80, 0.55) * occ;
        lin += 0.40 * amb * vec3(0.40, 0.60, 1.00) * occ;
        lin += 0.50 * dom * vec3(0.40, 0.60, 1.00) * occ;
        lin += 0.50 * bac * vec3(0.25, 0.25, 0.25) * occ;
        lin += 0.25 * fre * vec3(1.00, 1.00, 1.00) * occ;
        col = col * lin;
        col += 10.00 * spe * vec3(1.00, 0.90, 0.70);

        col = mix(col, sky_col, 1.0 - exp(-0.0008 * t * t * t));
    }

    return vec3(clamp(col, vec3(0.0), vec3(1.0)));
}

fn setCamera(origin: vec3<f32>, look: vec3<f32>, rotation: f32) -> mat3x3<f32> {
    let cw = normalize(look - origin);
    let cp = vec3(sin(rotation), cos(rotation), 0.0);
    let cu = normalize(cross(cw, cp));
    let cv = normalize(cross(cu, cw));
    return mat3x3(cu, cv, cw);
}

@fragment
fn main(in: VertexOutput) -> @location(0) vec4<f32> {
    let fragCoord = in.uv * u.resolution;
    let mo = u.mouse.xy / u.resolution.xy;

    var tot = vec3(0.0);
    let p = (-u.resolution.xy + 2.0 * fragCoord) / u.resolution.y;

    // let ro = vec3(-0.5 + 3.5 * cos(0.3 * time + 6.0 * mo.x), 1.0 + 2.0 * mo.y, 0.5 + 4.0 * sin(0.3 * time + 6.0 * mo.x));
    let cam_pos = vec3(0.5, 1.1, -1.7);
    let cam_look = vec3(-0.4, 0.3, 0.0);
    let fov = 3.0;

    let camera_matrix = setCamera(cam_pos, cam_look, 0.0);
    let ray_direction = camera_matrix * normalize(vec3(p, fov));

    var col = render(cam_pos, ray_direction);

    col = pow(col, vec3(0.4545));

    tot += col;

    return vec4(tot, 1.);
}