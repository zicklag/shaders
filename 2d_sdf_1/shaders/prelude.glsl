
const float PI = acos(-1.);
const float TAU = 2. * PI;

const float HALF_WIDTH = 1.0;

vec4 ASSERT_COL = vec4(0.);
void assert(bool cond, int v) {
    if (!(cond)) {
        if      (v == 0) ASSERT_COL.x = -1.0;
        else if (v == 1) ASSERT_COL.y = -1.0;
        else if (v == 2) ASSERT_COL.z = -1.0;
        else             ASSERT_COL.w = -1.0;
    }
}
void assert(bool cond) { assert(cond, 0); }
#define catch_assert(out)                                   if (ASSERT_COL.x < 0.0) out = vec4(1.0, 0.0, 0.0, 1.0); if (ASSERT_COL.y < 0.0) out = vec4(0.0, 1.0, 0.0, 1.0); if (ASSERT_COL.z < 0.0) out = vec4(0.0, 0.0, 1.0, 1.0); if (ASSERT_COL.w < 0.0) out = vec4(1.0, 1.0, 0.0, 1.0);

#define AAstep(x0, x) clamp(((x) - (x0)) / (4. / pc.resolution.y), 0., 1.)

float worldSDF(vec3 rayPos);

vec2 ray_march(vec3 rayPos, vec3 rayDir) {
    const vec3 EPS = vec3(0., 0.001, 0.0001);
    const float HIT_DIST = EPS.y;
    const int MAX_STEPS = 100;
    const float MISS_DIST = 10.0;
    float dist = 0.0;

    for(int i = 0; i < MAX_STEPS; i++) {
        vec3 pos = rayPos + (dist * rayDir);
        float posToScene = worldSDF(pos);
        dist += posToScene;
        if(abs(posToScene) < HIT_DIST) return vec2(dist, i);
        if(posToScene > MISS_DIST) break;
    }

    return vec2(-dist, MAX_STEPS);
}

float crossSDF(vec3 rayPos) {
    const vec3 corner = vec3(HALF_WIDTH);
    vec3 ray = abs(rayPos);
    vec3 cornerToRay = ray - corner;
    float minComp = min(min(cornerToRay.x, cornerToRay.y), cornerToRay.z);
    float maxComp = max(max(cornerToRay.x, cornerToRay.y), cornerToRay.z);
    float midComp = cornerToRay.x + cornerToRay.y + cornerToRay.z
                                             - minComp - maxComp;
    vec2 closestOutsidePoint = max(vec2(minComp, midComp), 0.0);
    vec2 closestInsidePoint = min(vec2(midComp, maxComp), 0.0);
    return (midComp > 0.0) ? length(closestOutsidePoint) : -length(closestInsidePoint);
}

float cubeSDF(vec3 rayPos) {
    const vec3 corner = vec3(HALF_WIDTH);
    vec3 ray = abs(rayPos);
    vec3 cornerToRay = ray - corner;
    float cornerToRayMaxComponent = max(max(cornerToRay.x, cornerToRay.y), cornerToRay.z);
    float distToInsideRay = min(cornerToRayMaxComponent, 0.0);
    vec3 closestToOusideRay = max(cornerToRay, 0.0);
    return length(closestToOusideRay) + distToInsideRay;
}

float squareSDF(vec2 rayPos) {
    const vec2 corner = vec2(HALF_WIDTH);
    vec2 ray = abs(rayPos.xy);
    vec2 cornerToRay = ray - corner;
    float cornerToRayMaxComponent = max(cornerToRay.x, cornerToRay.y);
    float distToInsideRay = min(cornerToRayMaxComponent, 0.0);
    vec2 closestToOusideRay = max(cornerToRay, 0.0);
    return length(closestToOusideRay) + distToInsideRay;
}

float sphereSDF(vec3 rayPosition, vec3 sphereCenterPosition, float radius) {
    vec3 centerToRay = rayPosition - sphereCenterPosition;
    float distToCenter = length(centerToRay);
    return distToCenter - radius;
}

float sphereSDF(vec3 rayPos, float radius) {
    return length(rayPos) - radius;
}

float sphereSDF(vec3 rayPos) {
    return length(rayPos) - HALF_WIDTH;
}

float yplaneSDF(vec3 rayPos) {
    return abs(rayPos.y);
}

mat2 rotate(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec3 enlight(in vec3 at, vec3 normal, vec3 diffuse, vec3 l_color, vec3 l_pos) {
  vec3 l_dir = l_pos - at;
  return diffuse * l_color * max(0., dot(normal, normalize(l_dir))) /
         dot(l_dir, l_dir);
}

vec3 wnormal(in vec3 p) {
    const vec3 EPS = vec3(0., 0.01, 0.0001);
    return normalize(vec3(worldSDF(p + EPS.yxx) - worldSDF(p - EPS.yxx),
                        worldSDF(p + EPS.xyx) - worldSDF(p - EPS.xyx),
                        worldSDF(p + EPS.xxy) - worldSDF(p - EPS.xxy)));
}