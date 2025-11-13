#iChannel0 'file://noise_2.png'
// ===================================================================
// ======================== CSG Operations ============================
// ===================================================================
float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5*(b - a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0 - h);
}

float opUnion( float d1, float d2 )
{
    return min(d1,d2);
}
float opSubtraction( float d1, float d2 )
{
    return max(-d1,d2);
}
float opIntersection( float d1, float d2 )
{
    return max(d1,d2);
}
float opXor( float d1, float d2 )
{
    return max(min(d1,d2),-max(d1,d2));
}

float opSmoothUnion( float d1, float d2, float k )
{
    k *= 4.0;
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
}

float opSmoothSubtraction( float d1, float d2, float k )
{
    return -opSmoothUnion(d1,-d2,k);

    //k *= 4.0;
    // float h = max(k-abs(-d1-d2),0.0);
    // return max(-d1, d2) + h*h*0.25/k;
}

float opSmoothIntersection( float d1, float d2, float k )
{
    return -opSmoothUnion(-d1,-d2,k);

    //k *= 4.0;
    // float h = max(k-abs(d1-d2),0.0);
    // return max(d1, d2) + h*h*0.25/k;
}
float dot2( vec2 v ) { return dot(v,v); }
float cro( vec2 a, vec2 b ) { return a.x*b.y-a.y*b.x; }
float cos_acos_3( float x ) { x=sqrt(0.5+0.5*x); return x*(x*(x*(x*-0.008972+0.039071)-0.107074)+0.576975)+0.5; } // https://www.shadertoy.com/view/WltSD7

float sdRoundedBox( in vec2 p, in vec2 b, float r )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) - r + min(max(d.x,d.y),0.0);
}

// ===================================================================
// ======================== CSG Shapes =========================
// ===================================================================
float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdOrientedBox( in vec2 p, in vec2 a, in vec2 b, float th )
{
    float l = length(b-a);
    vec2  d = (b-a)/l;
    vec2  q = (p-(a+b)*0.5);
          q = mat2(d.x,-d.y,d.y,d.x)*q;
          q = abs(q)-vec2(l,th)*0.5;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);    
}

float sdParallelogram( in vec2 p, float wi, float he, float sk )
{
    vec2 e = vec2(sk,he);
    p = (p.y<0.0)?-p:p;
    vec2  w = p - e; w.x -= clamp(w.x,-wi,wi);
    vec2  d = vec2(dot(w,w), -w.y);
    float s = p.x*e.y - p.y*e.x;
    p = (s<0.0)?-p:p;
    vec2  v = p - vec2(wi,0); v -= e*clamp(dot(v,e)/dot(e,e),-1.0,1.0);
    d = min( d, vec2(dot(v,v), wi*he-abs(s)));
    return sqrt(d.x)*sign(-d.y);
}

float sdTriangle( in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2 )
{
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}
float sdBezier( in vec2 pos, in vec2 A, in vec2 B, in vec2 C )
{    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;
    float kk = 1.0/dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      
    float res = 0.0;
    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx-3.0*ky) + kz;
    float h = q*q + 4.0*p3;
    if( h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h,-h)-q)/2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp( uv.x+uv.y-kx, 0.0, 1.0 );
        res = dot2(d + (c + b*t)*t);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3  t = clamp(vec3(m+m,-n-m,n-m)*z-kx,0.0,1.0);
        res = min( dot2(d+(c+b*t.x)*t.x),
                   dot2(d+(c+b*t.y)*t.y) );
        // the third root cannot be the closest
        // res = min(res,dot2(d+(c+b*t.z)*t.z));
    }
    return sqrt( res );
}



// ===================================================================
// ============================ Own Utils ============================
// ===================================================================
vec3 rgb(int r, int g, int b) {
  return vec3(float(r), float(g), float(b)) / 255.0;
}

vec2 applyPerspective(vec2 uv, vec2 vanishingPoint, float strength) {
  vec2 dir = uv - vanishingPoint;
  float dist = length(dir);
  float factor = 1.0 / (1.0 + strength * dist);
  return vanishingPoint + dir * factor;
}

// Apply vertical perspective: objects higher up (further away) get scaled down
vec2 applyVerticalPerspective(vec2 uv, float horizonY, float strength) {
  // Distance from horizon (0 at horizon, 1 at bottom)
  float depth = (uv.y - horizonY) / (1.0 - horizonY);
  depth = clamp(depth, 0.0, 1.0);
  
  // Scale factor: 0.0 (small) at horizon, 1.0 (full size) at bottom
  float scale = mix(0.1, 1.0, pow(depth, strength));
  
  // Apply horizontal compression for perspective
  float xFromCenter = uv.x - 0.5;
  float perspectiveX = 0.5 + xFromCenter * scale;
  
  return vec2(perspectiveX, uv.y);
}

// Get scale factor for objects based on their y position
float getPerspectiveScale(float y, float horizonY, float strength) {
  float depth = (y - horizonY) / (1.0 - horizonY);
  depth = clamp(depth, 0.0, 1.0);
  return mix(0.1, 1.0, pow(depth, strength));
}

// Approximate depth from vertical position (0 near camera, 1 near horizon)
float depthFromY(float y, float horizonY) {
  float clampedY = clamp(y, 0.0, horizonY);
  return smoothstep(0.0, horizonY, clampedY);
}

// Reverse perspective transformation
vec2 removePerspective(vec2 uv, vec2 vanishingPoint, float strength) {
  vec2 dir = uv - vanishingPoint;
  float dist = length(dir);
  float factor = (1.0 + strength * dist);
  return vanishingPoint + dir * factor;
}

mat2 rotate2D(float a) {
  float s = sin(a), c = cos(a);
  return mat2(c, -s, s, c);
}

// Generate a pseudo-random number based on vec2
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(41.23, 289.13))) * 43758.5453);
}

// Get depth from y-coordinate (maps screen y to world depth)
float yToDepth(float screenY, float horizonY) {
  // Objects at horizonY are farther; objects at screenY=0 are closest
  float normalizedY = clamp(screenY / horizonY, 0.0, 1.0);
  return mix(0.0, 15.0, pow(normalizedY, 1.5));
}

// Get scale factor for object at given depth
float getDepthScale(float depth, float focalLength) {
  // Perspective scaling: size = focalLength/(focalLength + depth)
  return focalLength / (focalLength + depth);
}

// Apply perspective to horizontal position (converge toward center)
float applyPerspectiveX(float x, float centerX, float depth, float focalLength) {
  float offset = x - centerX;
  float scale = getDepthScale(depth, focalLength);
  return centerX + offset * scale;
}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u); // Smoothstep
    
    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0, 1.0)), rand(ip + vec2(1.0, 1.0)), u.x), u.y);
    return res*res;
}

// Hash functions for wave noise
float hash1(float p) {
    float h = dot(vec2(p), vec2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// 1D noise
float noise1d(float p) {
    float i = floor(p);
    float f = fract(p);
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(hash1(i), hash1(i + 1.0), u);
}


float noiseLayer(vec2 p, float ti){
    float e =0.;
    for(float j=1.; j<9.; j++){
        e += texture(iChannel0, p * float(j) + vec2(ti*7.89541) + vec2(j*159.78) ).r / (j/2.);
    }
    e /= 8.5;
    return e;
}

// Fractional Brownian Motion (for waves, rocks)
float fbm(vec2 p, float time) {
    float v = 0.0;
    float a = 0.5;
    mat2 m = mat2(1.6, 1.2, -1.2, 1.6); // Rotation matrix
    
    for (int i = 0; i < 4; ++i) {
        v += a * noise(p + time * 0.05);
        p = m * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Unsigned distance from point to segment
float udSegment(vec2 pos, vec2 a, vec2 b) {
  vec2 pa = pos - a;
  vec2 ba = b - a;
  float denom = dot(ba, ba);
  if(denom < 1e-6) {
    return length(pa);
  }
  float h = clamp(dot(pa, ba) / denom, 0.0, 1.0);
  vec2 closest = a + ba * h;
  return length(pos - closest);
}


// Utils for shoreline
const int SHORE_POINT_COUNT = 11;
const int SHORELINE_STEPS = 32;

struct ShoreSample {
  vec2 position;
  vec2 tangent;
  float distance;
  float sign;
  float param;
};

float waveNoise(vec2 uv, float time, float frequency, float amplitude) {
    float n = fbm(uv * frequency + vec2(time * 0.1, time * 0.1), time);
    return n * amplitude;
}

vec2 catmullRom(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
  float t2 = t * t;
  float t3 = t2 * t;
  return 0.5 * ((2.0 * p1) +
          (-p0 + p2) * t +
          (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
          (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3);
}

vec2 catmullRomTangent(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
  float t2 = t * t;
  return 0.5 * ((-p0 + p2) +
          2.0 * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t +
          3.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t2);
}

ShoreSample closestPointOnShoreline(vec2 uv, vec2 points[SHORE_POINT_COUNT]) {
  ShoreSample result;
  result.distance = 1e10;
  result.sign = 1.0;
  result.param = 0.0;
  result.position = vec2(0.0);
  result.tangent = vec2(1.0, 0.0);

  float globalParam = 0.0;
  for (int i = 0; i < SHORE_POINT_COUNT - 3; ++i) {
    for (int j = 0; j <= SHORELINE_STEPS; ++j) {
      float t = float(j) / float(SHORELINE_STEPS);
      vec2 pos = catmullRom(points[i], points[i + 1], points[i + 2], points[i + 3], t);
      vec2 tangent = catmullRomTangent(points[i], points[i + 1], points[i + 2], points[i + 3], t);
      if (length(tangent) > 0.0) {
        tangent = normalize(tangent);
      } else {
        tangent = vec2(1.0, 0.0);
      }
      float dist = length(uv - pos);
      if (dist < result.distance) {
        float side = cro(tangent, uv - pos);
        result.distance = dist;
        result.position = pos;
        result.tangent = tangent;
        result.sign = (side >= 0.0) ? -1.0 : 1.0;
        result.param = globalParam + t;
      }
    }
    globalParam += 1.0;
  }

  return result;
}


// ===================================================================
// ============================ Shapes ===============================
// ===================================================================
// Blobby cloud made from 3 circles (smooth union), returns mask
float cloudBlob(vec2 uv, vec2 c, float size) {
  // Scale UV relative to cloud center for size control
  vec2 p = (uv - c) / size;

  float radius_base = 0.13;
  float radius_mid = 0.08;
  float radius_small = 0.05;
  float smoothness = 0.0018;

  vec2 displ_base = p - vec2(0.0, 0.12);
  vec2 displ_mid_left = p - vec2(-0.18, 0.08);
  vec2 displ_mid_right = p - vec2(0.18, 0.08);
  vec2 displ_small_left = p - vec2(-0.3, 0.03);
  vec2 displ_small_right = p - vec2(0.3, 0.03);

  vec2 p_shifted = p - vec2(0.0, 0.0);
  float width = 0.30;
  float height = 0.02;
  float skew = -0.01;

  float d = sdParallelogram(p_shifted, width, height, skew);

  d = opSmoothUnion(d, sdCircle(displ_base, radius_base), smoothness);

  d = opSmoothUnion(d, sdCircle(displ_mid_left, radius_mid), smoothness);
  d = opSmoothUnion(d, sdCircle(displ_mid_right, radius_mid), smoothness);

  d = opSmoothUnion(d, sdCircle(displ_small_left, radius_small), smoothness);
  d = opSmoothUnion(d, sdCircle(displ_small_right, radius_small), smoothness);

  float feather = 0.03;
  return 1.0 - smoothstep(0.0, feather, d);
}

float sdSea(vec2 uv, vec2 p0, vec2 p1, vec2 p2) {
  float triangleDist = sdTriangle(uv, p0, p1, p2);
  return triangleDist;
}

vec3 generateBeachWaves(vec2 uv, vec3 sandColor, vec3 seaBaseColor, float time, float depthScale) {
  // Wave parameters
  const int waveNumber = 16;
  const float speed = 0.015;
  const float waveCurve = 1.0;
  vec3 deepSeaColor = seaBaseColor * 0.3;

  depthScale = clamp(depthScale, 0.0, 1.0);
  float sizeAttenuation = mix(0.35, 1.0, depthScale);
  float foamAttenuation = mix(0.5, 1.0, depthScale);
  float colourBlend = mix(0.25, 1.0, depthScale);

  float t = time * speed + 12.2;
  vec4 col = vec4(sandColor, 0.0);
  vec3 wetSand = sandColor * vec3(0.7, 0.6, 0.4);
  float lastWaveAge = 10.0;

  for(int i = 0; i < waveNumber; i++) {
    float ti = floor(t - 0.25) + float(i);
    float waveAge = fract(t - 0.25);

    float noiseTerm = hash1(ti) / 3.0 + noise1d((uv.x + uv.y * 0.5 + ti) * waveCurve) * max(0.0, waveAge * 1.5 - 0.3);
    float waveNoise = noiseTerm * sizeAttenuation;

    float baseOffset = uv.y + sin(t * (2.0 * 3.14159265)) / 2.2 - 0.3;
    float offset = mix(uv.y - 0.3, baseOffset, sizeAttenuation) + waveNoise;

    vec2 pos = vec2(uv.x + uv.y * 0.3, -offset / (0.2 + waveAge * 20.0) * 2.0);

    float foam = noiseLayer(pos, ti);
    foam = mix(0.55, foam, foamAttenuation);
    offset -= (foam / 10.0) * sizeAttenuation;
    offset -= noiseLayer(uv / 10.0, 0.0) / 5.0 * sizeAttenuation;

    float maxNoiseTerm = hash1(ti) / 3.0 + noise1d((uv.x + uv.y * 0.5 + ti) * waveCurve) * max(0.0, 0.5 * 1.5 - 0.3);
    float maxWaveNoise = maxNoiseTerm * sizeAttenuation;
    float baseMaxOffset = uv.y + sin((ti + 0.5) * (2.0 * 3.14159265)) / 2.2 - 0.3;
    float maxOffset = mix(uv.y - 0.3, baseMaxOffset, sizeAttenuation) + maxWaveNoise;
    vec2 maxPos = vec2(uv.x + uv.y * 0.3, -maxOffset / (0.2 + 0.5 * 20.0) * 2.0);
    float maxFoam = noiseLayer(maxPos, ti);
    maxFoam = mix(0.7, maxFoam, foamAttenuation);
    maxOffset -= (maxFoam / 20.0) * sizeAttenuation;
    maxOffset -= noiseLayer(uv / 10.0, 0.0) / 10.0 * sizeAttenuation;

    if(offset < 0.0) {
      if(waveAge < lastWaveAge) {
        vec3 n = vec3(
          foam - noiseLayer(pos + vec2(0.001, 0.0), ti),
          foam - noiseLayer(pos + vec2(0.0, 0.001), ti),
          0.5
        );
        foam = (foam + 0.8 - waveAge * waveAge + offset * offset * 0.5 + clamp(offset + 0.2, 0.0, 1.0));
        float light = dot(n, vec3(1.0, 1.0, 1.0));

        col.rgb = mix(sandColor, seaBaseColor, clamp(1.5 - waveAge * 3.0, 0.02, 1.0));
        col.rgb = mix(col.rgb, deepSeaColor, -offset * sizeAttenuation);

        float denseFoam = clamp(foam * 20.0 - 20.0, 0.0, 1.0) * 0.8 * foamAttenuation;
        col.rgb = mix(col.rgb, vec3(light) * 1.5, denseFoam);

        col.rgb += max(0.0, floor(offset + 1.004) * n.r * 10.0) * foamAttenuation;
        col.rgb += max(0.0, dot(n, vec3(1.0, 0.3, 0.95)) * 10.0 - 5.0) * foamAttenuation;
        col.rgb *= foam * foam * (1.0 - waveAge) + waveAge * 1.2;

        col.a = 1.0;
      }
      lastWaveAge = waveAge;
    } else {
      if(col.a == 0.0 && waveAge > 0.5) {
        float dryness = 50.0 * (1.0 - waveAge);
        float wetMix = clamp((dryness - 2.5 - maxOffset * dryness * 2.0), 0.0, 1.0) * (1.0 - waveAge);
        col.rgb = mix(col.rgb, wetSand, wetMix * colourBlend);
      }
    }

    t += 1.0 / float(waveNumber);
  }

  return mix(seaBaseColor, col.rgb, colourBlend);
}

// Procedural irregular polygon rock shape with noise
// verticalStretch: 1.0 = round, >1.0 = vertically elongated (cliff rocks)
float sdProceduralRock(vec2 uv, vec2 center, float radius, float irregularity, float seed, int facetsCount, float verticalStretch) {
  vec2 p = uv - center;
  
  // Apply vertical stretch to make rocks more elongated
  p.y /= verticalStretch;

  int facets = facetsCount + int(floor(hash(vec2(seed, seed * 1.3)) * 5.0));
  
  float angleStep = 6.28318 / float(facets); // 2pi / facets
  
  // Build vertices array
  vec2 vertices[25];
  for(int i = 0; i < facetsCount; i++) {
    if(i >= facets) break;
    float angle = float(i) * angleStep;
    float r = radius * (0.5 + hash(vec2(seed + float(i) * 0.1, seed * 2.0)) * irregularity);
    vertices[i] = r * vec2(cos(angle), sin(angle));
  }
  
  // Signed distance to polygon using winding number
  float d = dot(p - vertices[0], p - vertices[0]);
  float s = 1.0;
  
  for(int i = 0, j = facets - 1; i < facets; j = i, i++) {
    if(i >= facetsCount || j >= facetsCount) break;

    vec2 e = vertices[j] - vertices[i];
    vec2 w = p - vertices[i];
    vec2 b = w - e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    d = min(d, dot(b, b));
    
    bvec3 c = bvec3(p.y >= vertices[i].y, p.y < vertices[j].y, e.x * w.y > e.y * w.x);
    if(all(c) || all(not(c))) s *= -1.0;
  }


  // displacement, based on https://iquilezles.org/articles/distfunctions/
  // Adjust displacement intensity based on vertical stretch
  float dispIntensity = mix(0.15, 0.05, (verticalStretch - 1.0) / 2.0);
  float disp = dispIntensity * sin(-1.0*p.x)*sin(20.0*p.y);

  // Return signed distance (negative inside), compensate for vertical stretch
  return s * sqrt(d) * verticalStretch + disp * irregularity;
}

// Rock with 3-tone shading (light on left, shadow on right)
// Returns: 0 = outside, 1 = shadow, 2 = mid, 3 = light
// verticalStretch: 1.0 = round, >1.0 = vertically elongated (cliff rocks)
float proceduralRockWithShading(vec2 uv, vec2 center, float radius, float irregularity, float seed, int facetsCount, float verticalStretch, float lightAngle) {
  float dist = sdProceduralRock(uv, center, radius, irregularity, seed, facetsCount, verticalStretch);


  float midShadowThreshold = 0.01;
  float darkEdgeThreshold = 0.005;

  if(dist > 0.0) return 0.0; // Outside rock

  // Calculate position relative to rock center
  vec2 localPos = (uv - center) / radius;
  float horizontalOffset = localPos.x - localPos.y * lightAngle; // Slight tilt for lighting

  horizontalOffset = fbm(localPos * 5.0 + seed, 0.0) * 0.7 + horizontalOffset;
  // Light from left, shadow on right
  if(horizontalOffset < -midShadowThreshold) {
    return 3.0; // Light (left side)
  }

  // Gradient shadow from left to right
  float shadowIntensity = smoothstep(-0.1, 1.4, horizontalOffset);

  // Add noise to break up uniform bands
  float noiseBreakup = fbm((uv - center) * 8.0, 0.0) * 0.2;
  shadowIntensity += noiseBreakup;

  // Edge darkening for depth
  float edgeDist = -dist;
  float edgeDarkening = smoothstep(0.0, darkEdgeThreshold, edgeDist);

  // Combine effects
  float shadeFactor = edgeDarkening * (1.0 - shadowIntensity * 0.75);

  // Return 3-tone shading
  if(shadeFactor > 0.85) return 3.0;  // Light
  if(shadeFactor > 0.55) return 2.0;  // Mid
  return 1.0;                          // Shadow
}

// Generate a cliff wall with layered rocks
vec3 cliffWall(vec2 uv, vec2 origin, vec2 endTop, vec2 endBottom, float seed, vec3 rockLight, vec3 rockMid, vec3 rockDark, vec3 bgColor) {

  int rockNumber = 5;

  float vertical_step = 0.04;
  float horizontal_step = 0.15;
  float horizontal_position_variation = 0.008;
  float vertical_position_variation = 0.006;

  float slope = 2.0;

  float main_radius = 0.05;
  float radius_variation = 0.08;

  vec3 col = bgColor;
  
  // Transform UV to cliff-local coordinates
  vec2 cliffOrigin = origin;
  vec2 localUV = uv - cliffOrigin;

  // Layered rock clusters (5 vertical tiers, 5 horizontal positions)
  for (int i = 0; i < rockNumber; i++) {
    float yi = float(i) * vertical_step;
    
    // Height-based rock type: bottom rocks are rounded, top rocks are vertical
    float heightRatio = float(i) / float(rockNumber - 1); // 0.0 at bottom, 1.0 at top
    float verticalStretch = mix(0.7, 2.5, heightRatio); // 0.7 = rounded at bottom, 2.5 = tall cliff rocks at top
    int facets = int(mix(12.0, 8.0, heightRatio)); // More facets for rounded rocks, fewer for cliff faces


    for (int j = 0; j < rockNumber; j++) {
      float xj = float(j) * horizontal_step;
      
      // Randomize position slightly
      vec2 center = cliffOrigin + vec2(
        xj + horizontal_position_variation * hash(vec2(float(i), float(j))),
        yi + vertical_position_variation * hash(vec2(float(j), float(i)))
      );

      center.x += slope * yi;

      // Randomized size and irregularity
      float radius = main_radius + radius_variation * hash(vec2(float(j), float(i) + 1.0));
      float irregularity = 0.8 + 0.3 * hash(center * 5.0);
      float rockSeed = seed + float(i * 5 + j);
      
      // Light angle varies by horizontal position: left rocks (j=0) have top-down light, right rocks (j=4) have left-right light
      float horizontalRatio = float(j) / float(rockNumber - 1); // 0.0 at left, 1.0 at right
      float lightAngle = mix(2.0, 0.3, horizontalRatio); // 2.0 = top-down on left, 0.3 = left-right on right
      
      float rockResult = proceduralRockWithShading(uv, center, radius, irregularity, rockSeed, facets, verticalStretch, lightAngle);
      
      if (rockResult > 0.0) {
        vec3 rockColor;
        if (rockResult == 3.0) {
          rockColor = rockLight;
        } else if (rockResult == 2.0) {
          rockColor = rockMid;
        } else {
          rockColor = rockDark;
        }
        
        // Add per-rock color variation based on distance from sun (left side)
        // Rocks on the left (closer to sun) are brighter, rocks on the right are darker
        float baseVariation = 0.85 + 0.15 * hash(center * 10.0); // Small random variation
        float sunProximity = 1.0 - horizontalRatio; // 1.0 on left (near sun), 0.0 on right (far from sun)
        float colorVar = mix(0.95, 1.15, sunProximity) * baseVariation; // Brighter on left, darker on right
        rockColor *= colorVar;
        
        // Blend based on distance
        float dist = sdProceduralRock(uv, center, radius, irregularity, rockSeed, facets, verticalStretch);
        float blend = smoothstep(0.25, 0.1, dist);
        col = mix(col, rockColor, blend);
      }
    }
  }
  
  return col;
}

// parallelogram towel with white and blue stripes
// Returns 0 for outside, 1 for white stripes, 2 for blue stripes
// orientation: 0.0 = horizontal stripes, 1.0 = vertical stripes
float towelShape(vec2 uv, vec2 center, float size, float width, float height, float skew, float numStripes, float orientation) {
  vec2 p = (uv - center) / size;

  float d = sdParallelogram(p, width, height, skew);

  float feather = 0.01;
  float mask = 1.0 - smoothstep(0.0, feather, d);

  if (mask < 0.01) {
    return 0.0; // Outside towel
  }

  // Stripes pattern that follows the parallelogram shape
  // For horizontal: stripes follow the x-axis (compensate for skew in y)
  // For vertical: stripes follow the y-axis (no skew compensation needed)
  float stripeCoord;
  float stripeSize;
  
  if (orientation < 0.5) {
    // Horizontal stripes - follow the parallelogram's horizontal edges
    stripeCoord = p.x - skew * p.y;
    stripeSize = width;
  } else {
    // Vertical stripes - follow the parallelogram's vertical edges
    stripeCoord = p.y;
    stripeSize = height;
  }
  
  // float stripePattern = fract(stripeCoord * numStripes / stripeSize);
  float stripePattern = sin(stripeCoord * numStripes * 3.14159265 / stripeSize);

  // Alternate between white (1) and blue (2)
  // float stripeValue = step(0.5, stripePattern);
  float stripeValue = step(0.0, stripePattern);
  
  // Return 1 for white, 2 for blue (multiplied by mask)
  return mask * (1.0 + stripeValue);
}

// Returns 1.0 for swimmer, 2.0 for hair, 3.0 for swimsuit, 4.0 for splash, 0.0 for background
// float swimmer(vec2 uv, float time, vec2 center) {
//   float swimHead = sdCircle(uv - swimmerCenter, swimmerFullScale);
//   float swimHair = sdBox(uv - swimmerCenter - vec2(-0.008, 0.0) * swimmerFullScale, vec2(0.006, 0.01) * swimmerFullScale);

//   vec2 bodyOffset = vec2(-3.2, 0.0) * swimmerFullScale;
//   float swimBody = sdRoundedBox(uv - swimmerCenter - bodyOffset, vec2(2.3, 0.4) * swimmerFullScale, 0.003 * swimmerFullScale);

//   vec2 shoulderTop = swimmerCenter + vec2(-1.6, -0.009) * swimmerFullScale;
//   vec2 shoulderBottom = swimmerCenter + vec2(-1.6, 0.009) * swimmerFullScale;
//   float armAngle = sin(time * 3.0);
//   float armLength = 2.2 * swimmerFullScale;

//   float angleTop = armAngle * 1.8;
//   vec2 armEndTop = shoulderTop + vec2(cos(angleTop), sin(angleTop)) * armLength;
//   float swimArmTop = sdOrientedBox(uv, shoulderTop, armEndTop, 0.25 * swimmerFullScale);

//   float angleBottom = -armAngle * 1.8;
//   vec2 armEndBottom = shoulderBottom + vec2(cos(angleBottom), sin(angleBottom)) * armLength;
//   float swimArmBottom = sdOrientedBox(uv, shoulderBottom, armEndBottom, 0.25 * swimmerFullScale);

//   float splash = smoothstep(0.025 * swimmerFullScale, 0.015 * swimmerFullScale, length(uv - swimmerCenter));
//   color = mix(color, whiteColor, splash * 0.3 * (sin(time * 5.0) * 0.5 + 0.5));

//   float swimmer = opSmoothUnion(swimHead, swimBody, 0.002 * swimmerFullScale);
//   swimmer = opUnion(swimmer, swimArmTop);
//   swimmer = opUnion(swimmer, swimArmBottom);

//   if (swimmer < 0.0) {
//     color = skinColor;
//     if(sdBox(uv - swimmerCenter - bodyOffset, vec2(2.0, 1.0) * swimmerFullScale) < 0.0) {
//       color = swimsuitColor2;
//     }
//     if(swimHair < 0.0) {
//       color = rgb(50, 20, 10);
//     }
//   }
// }




// ====================================================================
// ============================ Main Image ============================
// ====================================================================
// "Paris 2025 JO style" beach with nice blue water (non transparent) and "orange" cliff.
// Someone goes and swims in the water. The sun is shining bright. The sky is blue with some clouds.
// The scene is peaceful and relaxing.
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // - improve cliff
  // - splash swimmer end of arms when they hit the water (foam, depends on the angle of the arm)
  // - put people shapes in functions
  // - fix hairs
  // - add grass on the cliff at certain positions


  // ==================================================
  // =================== Parameters ===================
  // ==================================================
  float aspectRatio = iResolution.x / iResolution.y;
  vec2 vanishingPoint = vec2(0.1, 0.6); // Centered at horizon
  float perspectiveStrength = 20.0; // Higher = more perspective
  float horizonY = 0.6; // Where the horizon/sky meets the beach
  float animationSpeed = 1.0;

  float focalLength = 2.5; // Controls perspective strength
  vec2 vanishingPointCenter = vec2(0.5 * aspectRatio, horizonY);

  float waveMergeDistance = 0.12; // How far into the sea waves blend back to base colour
  float waveBeachOverlap = 0.055; // How far waves overlap onto the sand
  float waveDepthFalloff = 3.0; // Controls how quickly waves shrink with depth
  float waveOverlayStrength = 0.85; // Overall contribution of the waves

  float skyHeight = 0.6;
  float cloudSpeed = 2.0;
  float cloudSize = 0.12;
  float sunGlowSpeed = 5.0;
  float sunGlowSpread = 0.5;

  vec2 towelCenter = vec2(0.5, 0.2);
  float towelWidth = 0.8;
  float towelHeight = 0.4;
  float towelSkew = 0.2;
  float numStripes = 4.0; // Number of stripe pairs (white+blue) - even number to start/end with same color
  float stripeOrientation = 1.0; // 0.0 = horizontal, 1.0 = vertical

  float noise_intensity = 0.3;

  // ===================================================
  // =================== Coordinates ===================
  // ===================================================

  vec2 uv = fragCoord / iResolution.xy;
  uv.x *= aspectRatio;
  vec3 p = vec3(uv, 0.0);

  vec2 uvOriginal = uv;
  
  float time = iTime * animationSpeed;

  // ==============================================
  // =================== Colors ===================
  // ==============================================
  vec3 color = vec3(0.0);
  vec3 whiteColor = rgb(255, 255, 255);

  vec3 skyColor = mix(rgb(95, 178, 197), rgb(30, 135, 178), 0.4*uv.x + 0.3*uv.y);
  vec3 cloudColor = rgb(255, 255, 255);
  vec3 sunColor = rgb(240, 180, 27);

  vec3 beachColor = rgb(237, 173, 62);

  vec3 seaColor = rgb(12, 129, 164);
  vec3 shallowSeaColor = rgb(58, 176, 161);
  vec3 deepSeaColor = rgb(10, 103, 150);
  vec3 foamColor = rgb(200, 230, 240);

  vec3 rockColor = rgb(230, 122, 21);
  vec3 darkRockColor = rgb(212, 81, 22);
  vec3 darkerRockColor = rgb(144, 65, 37);

  vec3 towelTone1 = whiteColor;
  vec3 towelTone2 = rgb(0, 105, 200);

  vec3 skinColor = rgb(224, 116, 45);
  vec3 swimsuitColor1 = rgb(200, 49, 41);
  vec3 swimsuitColor2 = rgb(24, 56, 84);

  vec2 shorePoints[SHORE_POINT_COUNT];
  shorePoints[0] = vec2(-0.32, -0.10);
  shorePoints[1] = vec2(-0.12, -0.02);
  shorePoints[2] = vec2(0.02, 0.04);
  shorePoints[3] = vec2(0.11, 0.08);
  shorePoints[4] = vec2(0.20, 0.16);
  shorePoints[5] = vec2(0.27, 0.28);
  shorePoints[6] = vec2(0.34, 0.40);
  shorePoints[7] = vec2(0.44, 0.50);
  shorePoints[8] = vec2(0.58, 0.58);
  shorePoints[9] = vec2(0.74, 0.62);
  shorePoints[10] = vec2(0.94, 0.64);

  for (int i = 0; i < SHORE_POINT_COUNT; ++i) {
    float depth = yToDepth(shorePoints[i].y, horizonY);
    // We keep y the same (screen-space) and only converge x toward vanishing point
    shorePoints[i].x = applyPerspectiveX(shorePoints[i].x, vanishingPointCenter.x, depth, focalLength);
    shorePoints[i].y = shorePoints[i].y;
  }

  ShoreSample shore = closestPointOnShoreline(uv, shorePoints);
  float seaDist = shore.distance * shore.sign;
  float alongNorm = shore.param / float(SHORE_POINT_COUNT - 3);
  alongNorm = clamp(alongNorm, 0.0, 1.0);
  vec2 shoreTangent = shore.tangent;
  vec2 shoreNormal = vec2(-shoreTangent.y, shoreTangent.x);
  vec2 localCoord = vec2(dot(uv - shore.position, shoreTangent), dot(uv - shore.position, shoreNormal));
  vec2 beachUV = vec2(alongNorm * 6.0 + localCoord.x * 4.0, localCoord.y * 6.0);

  // ===========================================
  // =================== Sky ===================
  // ===========================================
  float cloudMask = 0.0;

  // Compute perspective-aware sun position/scale
  float sunDepth = yToDepth(0.84, horizonY);
  float sunScale = getDepthScale(sunDepth, focalLength);
  vec2 sunPos = vec2(
    applyPerspectiveX(-2.7, vanishingPointCenter.x, sunDepth, focalLength),
    0.91
  );
  float sunSize = 0.18 * sunScale;
  float sunBlurSize = sunGlowSpread * sunSize * max(sunGlowSpeed * abs(cos(time * 0.1)), 0.4);
  float sunDist = sdCircle(uv - sunPos, sunSize);

  // Clouds with perspective scaling
  vec2 cloud1Pos = vec2(0.12 + cloudSpeed * 0.6 * sin(time * 0.04), 0.82);
  float cloud1Depth = yToDepth(cloud1Pos.y, horizonY);
  float cloud1Scale = 6.4*getDepthScale(cloud1Depth, focalLength);
  cloud1Pos.x = applyPerspectiveX(cloud1Pos.x, vanishingPointCenter.x, cloud1Depth, focalLength);
  cloudMask = max(cloudMask, cloudBlob(uv, cloud1Pos, cloudSize * cloud1Scale));

  vec2 cloud2Pos = vec2(-2.0 + cloudSpeed * 0.5 * cos(time * 0.05), 0.72);
  float cloud2Depth = yToDepth(cloud2Pos.y, horizonY);
  float cloud2Scale = 5.0*getDepthScale(cloud2Depth, focalLength);
  cloud2Pos.x = applyPerspectiveX(cloud2Pos.x, vanishingPointCenter.x, cloud2Depth, focalLength);
  cloudMask = max(cloudMask, cloudBlob(uv, cloud2Pos, cloudSize * cloud2Scale));

  vec2 cloud3Pos = vec2(3.82 + cloudSpeed * 0.7 * sin(time * 0.1), 0.90);
  float cloud3Depth = yToDepth(cloud3Pos.y, horizonY);
  float cloud3Scale = 3.4*getDepthScale(cloud3Depth, focalLength);
  cloud3Pos.x = applyPerspectiveX(cloud3Pos.x, vanishingPointCenter.x, cloud3Depth, focalLength);
  cloudMask = max(cloudMask, cloudBlob(uv, cloud3Pos, cloudSize * cloud3Scale));

  if (uv.y > skyHeight) {
    if (sunDist < 0.0) {
      color = sunColor;
    } else if (sunDist > 0.0 && sunDist < sunBlurSize) {
      // Sun rays
      color = mix(sunColor, skyColor, sunDist / sunBlurSize);
    } else {
      color = skyColor;
    }
    color = mix(color, cloudColor, cloudMask);
  }


  // =============================================
  // =================== Beach ===================
  // =============================================
  if (uv.y <= skyHeight) {
    float sandNoise = fbm(beachUV * 2.0, 0.0);
    
    // Add granular detail with multiple noise layers
    float fineGrain = noise(beachUV * 15.0) * 0.15;
    float mediumGrain = noise(beachUV * 5.0) * 0.25;
    float coarsePattern = fbm(beachUV * 0.8, 0.0) * 0.3;
    
    float combinedNoise = (sandNoise * 0.4 + fineGrain + mediumGrain + coarsePattern) * 0.3;
    vec3 sandVariation = beachColor * (0.85 + combinedNoise);    
    float colorVariation = noise(beachUV * 3.0) * 0.1;
    sandVariation = mix(sandVariation, beachColor * 1.15, colorVariation);
    
    color = sandVariation;
  }


  // ==========================================
  // =================== Sea ==================
  // ==========================================
  if (uv.y <= skyHeight) {
    float seaMask = smoothstep(0.04, -0.015, seaDist);
    vec3 baseSea = seaColor;
    vec3 baseBeach = beachColor;

    color = mix(baseBeach, baseSea, seaMask);

    float depthIntoWater = max(-seaDist, 0.0);
    float waveDepthFactor = clamp(exp(-waveDepthFalloff * depthIntoWater), 0.0, 1.0);
    float uvDepthScale = mix(0.6, 1.0, waveDepthFactor);
    vec2 wavesUV = vec2(-beachUV.x, -beachUV.y) * uvDepthScale;

    float waveSeaBlend = 1.0 - smoothstep(0.0, waveMergeDistance, depthIntoWater);
    float distWavesToShore = 1.4;
    float waveBeachFactor = 1.0 - smoothstep(0.0, waveBeachOverlap, max(seaDist, distWavesToShore));
    float waveMask = clamp(max(waveSeaBlend, waveBeachFactor), 0.0, 1.0) * waveOverlayStrength;

    vec3 waveColor = generateBeachWaves(wavesUV, beachColor, seaColor, time, waveDepthFactor);
    float maskIntensity = waveMask * mix(0.35, 1.0, waveDepthFactor);
    color = mix(color, waveColor, maskIntensity);

    float depthGradient = clamp(-seaDist * 4.0, 0.0, 1.0);
    vec3 deepSeaColor = mix(baseSea * 0.45, baseSea, depthGradient);
    color = mix(color, deepSeaColor, seaMask * 0.6);
  }

  // =============================================
  // =================== Rocks ===================
  // =============================================  
  float rockDepth = yToDepth(0.56, horizonY);
  float rockScale = getDepthScale(rockDepth, focalLength);
  // Apply perspective to rock position and size
  vec2 rockPointBase = vec2(
    applyPerspectiveX(-0.3, vanishingPointCenter.x, rockDepth, focalLength),
    0.56
  );
  vec2 rockPointTop = vec2(
    applyPerspectiveX(0.9, vanishingPointCenter.x, rockDepth, focalLength),
    0.72
  );
  vec2 rockPointBottom = vec2(
    applyPerspectiveX(0.5, vanishingPointCenter.x, rockDepth, focalLength),
    0.40
  );

  vec2 rockTop = rockPointBase + vec2(2.0, 1.7) * rockScale;
  vec2 rockBottom = rockPointBase + vec2(2.0, 0.14) * rockScale;

  vec3 cliffColor = cliffWall(uv, rockPointBase, rockTop, rockBottom, 1.23, rockColor, darkRockColor, darkerRockColor, color);
  color = cliffColor;
    
  // ==============================================
  // =================== People ===================
  // ==============================================
  // Place towel at a distance from the shore where waves don't reach
  float safeDistanceFromShore = 10.0;
  vec2 towelShoreRef = shore.position - shoreNormal * safeDistanceFromShore;
  float towelAlongShore = 0.35;
  vec2 towelCenterAdj = vec2(0.7 * aspectRatio, 0.17);
  float towelBaseSize = 1.2;
  float towelWidthAdj = 0.55;
  float towelHeightAdj = 0.34;
  float towelSkewAdj = 0.05;
  
  // Calculate perspective scale based on y position
  float towelScale = getPerspectiveScale(towelCenterAdj.y, horizonY, perspectiveStrength);
  float towelSizeAdj = towelBaseSize * towelScale;

  vec2 towelPerspectivePos = vec2(towelCenterAdj.x, towelCenterAdj.y);
  float towel = towelShape(uv, towelPerspectivePos, towelSizeAdj, towelWidthAdj, towelHeightAdj, towelSkewAdj, numStripes, stripeOrientation);
  
  // Add shadow for towel
  vec2 shadowOffset = vec2(0.1, -0.08) * towelScale; // Scale shadow with towel
  float towelShadow = towelShape(uv, towelPerspectivePos + shadowOffset, towelSizeAdj, towelWidthAdj, towelHeightAdj, towelSkewAdj, numStripes, stripeOrientation);
  if (towelShadow > 0.5) {
    color = mix(color, color * 0.65, 0.4); // Darken for shadow
  }
  
  if (towel > 0.5 && towel < 1.5) {
    color = towelTone1;
  } else if (towel >= 1.5) {
    color = towelTone2;
  }

  // Person on towel - better proportioned figure
  vec2 personCenter = towelPerspectivePos + vec2(-0.005, 0.0) * towelScale;
  float personScale = towelScale * 11.0;

  float personHead = sdCircle(uv - personCenter - vec2(0.0, 0.022) * personScale, 0.012 * personScale);
  float personBody = sdBox(uv - personCenter - vec2(0.0, 0.005) * personScale, vec2(0.010, 0.018) * personScale);
  
  float armThickness = 0.004 * personScale;
  float personArmL = sdOrientedBox(uv, 
    personCenter + vec2(-0.012, 0.008) * personScale, 
    personCenter + vec2(-0.025, 0.005) * personScale, 
    armThickness);
  float personArmR = sdOrientedBox(uv, 
    personCenter + vec2(0.012, 0.008) * personScale, 
    personCenter + vec2(0.025, 0.005) * personScale, 
    armThickness);

  float personLegL = sdBox(uv - personCenter - vec2(-0.005, -0.015) * personScale, vec2(0.004, 0.015) * personScale);
  float personLegR = sdBox(uv - personCenter - vec2(0.005, -0.015) * personScale, vec2(0.004, 0.015) * personScale);
  
  float person = opSmoothUnion(personHead, personBody, 0.003 * personScale);
  person = opUnion(person, personArmL);
  person = opUnion(person, personArmR);
  person = opUnion(person, personLegL);
  person = opUnion(person, personLegR);
  
  if (person < 0.0) {
    float swimsuitArea = sdBox(uv - personCenter - vec2(0.0, 0.0), vec2(0.012, 0.012) * personScale);
    if (swimsuitArea < 0.0) {
      color = swimsuitColor1;
    } else {
      color = skinColor;
    }
  }


  // Person swimming in the water - swimming horizontally (sideways)
  vec2 swimmerCenter = vec2(0.28 + 0.08*sin(time*0.4), 0.38 + 0.01*cos(time*2.0));
  
  float swimmerSize = 0.15;
  float swimmerScale = getPerspectiveScale(swimmerCenter.y, horizonY, perspectiveStrength);
  float swimmerFullScale = swimmerSize * swimmerScale;

  // float swimmer = swimmerShape(uv, swimmerCenter, swimmerFullScale);

    float swimHead = sdCircle(uv - swimmerCenter, swimmerFullScale);
    float swimHair = sdBox(uv - swimmerCenter - vec2(-0.008, 0.0) * swimmerFullScale, vec2(0.006, 0.01) * swimmerFullScale);

    vec2 bodyOffset = vec2(-3.2, 0.0) * swimmerFullScale;
    float swimBody = sdRoundedBox(uv - swimmerCenter - bodyOffset, vec2(2.3, 0.4) * swimmerFullScale, 0.003 * swimmerFullScale);

    vec2 shoulderTop = swimmerCenter + vec2(-1.6, -0.009) * swimmerFullScale;
    vec2 shoulderBottom = swimmerCenter + vec2(-1.6, 0.009) * swimmerFullScale;
    float armAngle = sin(time * 3.0);
    float armLength = 2.2 * swimmerFullScale;

    float angleTop = armAngle * 1.8;
    vec2 armEndTop = shoulderTop + vec2(cos(angleTop), sin(angleTop)) * armLength;
    float swimArmTop = sdOrientedBox(uv, shoulderTop, armEndTop, 0.25 * swimmerFullScale);

    float angleBottom = -armAngle * 1.8;
    vec2 armEndBottom = shoulderBottom + vec2(cos(angleBottom), sin(angleBottom)) * armLength;
    float swimArmBottom = sdOrientedBox(uv, shoulderBottom, armEndBottom, 0.25 * swimmerFullScale);

    float swimmer = opSmoothUnion(swimHead, swimBody, 0.002 * swimmerFullScale);
    swimmer = opUnion(swimmer, swimArmTop);
    swimmer = opUnion(swimmer, swimArmBottom);

    if (swimmer < 0.0) {
      color = skinColor;
      if(sdBox(uv - swimmerCenter - bodyOffset, vec2(2.0, 1.0) * swimmerFullScale) < 0.0) {
        color = swimsuitColor2;
      }
      if(swimHair < 0.0) {
        color = rgb(50, 20, 10);
      }
    }
  float splash = smoothstep(0.025 * swimmerFullScale, 0.015 * swimmerFullScale, length(uv - swimmerCenter));
  color = mix(color, whiteColor, splash * 0.3 * (sin(time * 5.0) * 0.5 + 0.5));


  // ===============================================================
  // =================== Paris 2025 grain filter ===================
  // ===============================================================
  vec3 grain = vec3(fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453) * noise_intensity);
  color = mix(color, grain, 0.1);

  fragColor = vec4(color, 1.0);
}