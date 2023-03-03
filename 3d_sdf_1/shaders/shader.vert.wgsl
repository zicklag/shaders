
struct VertexOutput {
  @builtin(position)
  pos: vec4<f32>,
  @location(0)
  uv: vec2<f32>,
};

@vertex
fn main(@builtin(vertex_index) vertex_idx: u32) -> VertexOutput {
    let uv = vec2<u32>((vertex_idx << 1u) & 2u, vertex_idx & 2u);
    let out = VertexOutput(vec4<f32>(2.0 * vec2<f32>(uv) - 1.0, 0.0, 1.0), vec2<f32>(uv));
    return out;
}