
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

@group(0) @binding(0) var prev_frame: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(1) var generic_texture: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(2) var dummy_texture: texture_storage_2d<rgba8unorm, read_write>;
@group(0) @binding(3) var float_texture1: texture_storage_2d<rgba32float, read_write>;
@group(0) @binding(4) var float_texture2: texture_storage_2d<rgba32float, read_write>;
@group(1) @binding(0) var<uniform> un: Uniform;

@compute
@workgroup_size(1, 1)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
}