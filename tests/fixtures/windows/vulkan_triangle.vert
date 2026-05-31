#version 450

layout(location = 0) out vec3 fragColor;

vec2 positions[3] = vec2[](
  vec2(0.0, -0.62),
  vec2(0.62, 0.52),
  vec2(-0.62, 0.52)
);

vec3 colors[3] = vec3[](
  vec3(0.95, 0.20, 0.18),
  vec3(0.18, 0.72, 0.28),
  vec3(0.20, 0.42, 0.95)
);

void main() {
  gl_Position = vec4(positions[gl_VertexIndex], 0.0, 1.0);
  fragColor = colors[gl_VertexIndex];
}
