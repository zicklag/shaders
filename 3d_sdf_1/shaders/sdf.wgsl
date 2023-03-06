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

fn opTwist(p: vec3<f32>) -> vec3<f32> {
    let  c = cos(10.0 * p.y + 10.0);
    let  s = sin(10.0 * p.y + 10.0);
    let   m = mat2x2(c, -s, s, c);
    return vec3(m * p.xz, p.y);
}