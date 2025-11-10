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

// Blend toward fogColor using depth-based exponential falloff
vec3 addDepthHaze(vec3 color, float depth, vec3 fogColor, float strength) {
  float fog = pow(depth, strength);
  return mix(color, fogColor, fog);
}

// Reverse perspective transformation
vec2 removePerspective(vec2 uv, vec2 vanishingPoint, float strength) {
  vec2 dir = uv - vanishingPoint;
  float dist = length(dir);
  float factor = (1.0 + strength * dist);
  return vanishingPoint + dir * factor;
}

// ===================================================================
// =================== Perspective Projection Utils ==================
// ===================================================================

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


float waveNoise(vec2 uv, float time, float frequency, float amplitude) {
    float n = fbm(uv * frequency + vec2(time * 0.1, time * 0.1), time);
    return n * amplitude;
}


const int SHORE_POINT_COUNT = 11;
const int SHORELINE_STEPS = 32;

struct ShoreSample {
  vec2 position;
  vec2 tangent;
  float distance;
  float sign;
  float param;
};

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
// Blobby cloud made from 3 circles (smooth union), returns mask 0..1
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


float rockShape(vec2 uv, vec2 center, float size) {
  float d = length(uv - center);
  return smoothstep(size * 0.5, size, d);
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

// Layered noise for wave texture
// float noiseLayer(vec2 p, float ti) {
//     float e = 0.0;
//     for(float j = 1.0; j < 9.0; j += 1.0) {
//         e += noise(p * j + vec2(ti * 7.89541) + vec2(j * 159.78)) / (j / 2.0);
//     }
//     e /= 8.5;
//     return e;
// }
float noiseLayer(vec2 p, float ti){
    float e =0.;
    for(float j=1.; j<9.; j++){
        e += texture(iChannel0, p * float(j) + vec2(ti*7.89541) + vec2(j*159.78) ).r / (j/2.);
    }
    e /= 8.5;
    return e;
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



vec3 randomRockShape(vec2 uv, vec2 center, float size, float noiseIntensity) {
  vec2 p = (uv - center) / size;

  float baseShape = sdCircle(p, 0.5);

  // Add noise to the shape
  float n = fbm(p * 3.0, 0.0);
  float noisyShape = baseShape + (n - 0.5) * noiseIntensity;

  float feather = 0.02;
  float mask = 1.0 - smoothstep(0.0, feather, noisyShape);

  return vec3(mask);
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





// ====================================================================
// ============================ Main Image ============================
// ====================================================================
// "Paris 2025 JO style" beach with nice blue water (non transparent) and "orange" rocks on the side with failaises. Someone goes and swims in the water. The sun is shining bright. The sky is blue with some clouds. The scene is peaceful and relaxing.
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  // - Make the canvas scale with the window size properly
  // - Use bezier curve for shoreline
  // - Better fuse waves and the sea

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
  float cloudSpeed = 0.1;
  // sun will be updated with perspective below
  float cloudSize = 0.12;

  vec2 towelCenter = vec2(0.5, 0.2);
  float towelWidth = 0.8;
  float towelHeight = 0.4;
  float towelSkew = 0.2;
  float numStripes = 4.0; // Number of stripe pairs (white+blue) - even number to start/end with same color
  float stripeOrientation = 1.0; // 0.0 = horizontal, 1.0 = vertical

  float rockSize = 0.2;

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

  vec3 beachColor = rgb(234, 169, 61);

  vec3 seaColor = rgb(12, 129, 164);
  vec3 shallowSeaColor = rgb(58, 176, 161);
  vec3 deepSeaColor = rgb(10, 103, 150);
  vec3 foamColor = rgb(200, 230, 240);

  vec3 rockColor = rgb(230, 122, 21);
  vec3 darkRockColor = rgb(212, 81, 22);
  vec3 darkerRockColor = rgb(144, 65, 37);

  vec3 towelTone1 = whiteColor;
  vec3 towelTone2 = rgb(0, 105, 200);

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
  float sunBlurSize = 0.5 * sunSize * max(3.0 * abs(cos(iTime * 0.1)), 0.4);
  float sunDist = sdCircle(uv - sunPos, sunSize);

  // Clouds with perspective scaling
  vec2 cloud1Pos = vec2(0.12 + 0.6*sin(iTime*0.04), 0.82);
  float cloud1Depth = yToDepth(cloud1Pos.y, horizonY);
  float cloud1Scale = 6.4*getDepthScale(cloud1Depth, focalLength);
  cloud1Pos.x = applyPerspectiveX(cloud1Pos.x, vanishingPointCenter.x, cloud1Depth, focalLength);
  cloudMask = max(cloudMask, cloudBlob(uv, cloud1Pos, cloudSize * cloud1Scale));

  vec2 cloud2Pos = vec2(-2.0 + 0.5*cos(iTime*0.05), 0.72);
  float cloud2Depth = yToDepth(cloud2Pos.y, horizonY);
  float cloud2Scale = 5.0*getDepthScale(cloud2Depth, focalLength);
  cloud2Pos.x = applyPerspectiveX(cloud2Pos.x, vanishingPointCenter.x, cloud2Depth, focalLength);
  cloudMask = max(cloudMask, cloudBlob(uv, cloud2Pos, cloudSize * cloud2Scale));

  vec2 cloud3Pos = vec2(3.82 + 0.7*sin(iTime*0.1), 0.90);
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
    color = beachColor;
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

    vec3 waveColor = generateBeachWaves(wavesUV, beachColor, seaColor, iTime, waveDepthFactor);
    float maskIntensity = waveMask * mix(0.35, 1.0, waveDepthFactor);
    color = mix(color, waveColor, maskIntensity);

    float depthGradient = clamp(-seaDist * 4.0, 0.0, 1.0);
    vec3 deepSeaColor = mix(baseSea * 0.45, baseSea, depthGradient);
    color = mix(color, deepSeaColor, seaMask * 0.6);
  }

    // =============================================
    // =================== Rocks ===================
    // =============================================  
    vec2 rockPointBase = vec2(-0.3, 0.56);
    float rockDepth = yToDepth(rockPointBase.y, horizonY);
    float rockScale = getDepthScale(rockDepth, focalLength);

    // Apply perspective to rock position and size
    vec2 rockPoint = vec2(
      applyPerspectiveX(rockPointBase.x, vanishingPointCenter.x, rockDepth, focalLength),
      rockPointBase.y
    );

    // Scale rock triangle points with perspective
    vec2 rockTop = rockPoint + vec2(8.0, 3.7) * rockScale;
    vec2 rockBottom = rockPoint + vec2(8.0, -1.14) * rockScale;

    float rockDist = sdTriangle(uv, rockPoint, rockTop, rockBottom);
    // Fractal cliff fill: use layered ridged fbm for height & apply threshold
    float cliffUVScale = 3.0 * rockScale;
    vec2 cliffUV = (uv - rockPoint) / (rockScale * 1.0);
    
    // Rotate/scale cliffUV to stretch along triangle edges
    vec2 e1n = normalize(rockTop - rockPoint);
    vec2 e2n = normalize(rockBottom - rockPoint);
    mat2 align = mat2(e1n.x, e2n.x, e1n.y, e2n.y);
    cliffUV = align * cliffUV * cliffUVScale;

    // Ridged fbm
    float ridge = 0.0;
    float amp = 1.0;
    vec2 pR = cliffUV;
    for(int i=0;i<5;i++) {
      float n = noise(pR);
      n = 1.0 - abs(2.0*n - 1.0); // ridged
      ridge += n * amp;
      pR = mat2(1.7, -1.2, 1.2, 1.7) * pR * 1.85;
      amp *= 0.55;
    }
    ridge /= 1.0 + 0.55 + 0.3025 + 0.166375 + 0.0915; // approximate normalization

    // Height mask: allow spill (slightly outside triangle) using rockDist + ridge
    float spillMargin = 0.04 * (0.7 + 0.3 * ridge);
    float insideMask = smoothstep(spillMargin, -spillMargin, rockDist);
    
    if (insideMask > 0.0) {
      // Build local coordinates (barycentric-like) within triangle
      vec2 A = rockPoint;
      vec2 E1 = rockTop - rockPoint;
      vec2 E2 = rockBottom - rockPoint;
      vec2 V = uv - A;
      float denom = cro(E1, E2);
      // Guard against degenerate triangle
      if (abs(denom) > 1e-6) {
        float u = cro(V, E2) / denom;
        float v = cro(E1, V) / denom;
        vec2 q = vec2(u, v); // Triangle local space, valid if u>=0,v>=0,u+v<=1

        // Use ridge height to modulate density for stratification
        float baseDensity = mix(30.0, 110.0, ridge);
        float density = max(8.0, baseDensity * rockScale);

  // Cellular (Voronoi) pattern in q-space for rock fragments
        vec2 p = q * density;
        vec2 pi = floor(p);
        vec2 pf = fract(p);

        float da = 1e9; // nearest
        float db = 1e9; // second nearest
        vec2 bestCell = vec2(0.0);
        vec2 bestDelta = vec2(0.0);

        for (int oy = -1; oy <= 1; ++oy) {
          for (int ox = -1; ox <= 1; ++ox) {
            vec2 o = vec2(float(ox), float(oy));
            vec2 cell = pi + o;
            // Jittered seed inside the cell
            float jx = rand(cell + vec2(0.123, 0.457));
            float jy = rand(cell + vec2(7.321, 3.113));
            vec2 r = vec2(jx, jy);
            vec2 g = o + r; // seed position in the 1x1 neighborhood cell

            // Allow limited spill using ridge-based expansion
            vec2 seedQ = (cell + r) / density;
            if (seedQ.x + seedQ.y > 1.15 + 0.1 * ridge || seedQ.x < -0.1 || seedQ.y < -0.1) {
              continue; // outside expanded domain
            }

            vec2 d = pf - g;
            float dist = dot(d, d);
            if (dist < da) {
              db = da;
              da = dist;
              bestCell = cell;
              bestDelta = d;
            } else if (dist < db) {
              db = dist;
            }
          }
        }

  // Convert squared distances to actual distances
        da = sqrt(da);
        db = sqrt(db);

  // Fractal cliff fragment shading with pseudo-3D lighting
  float idNoise = rand(bestCell + vec2(3.71, 1.91));
  float striation = ridge * (0.6 + 0.4 * idNoise);
  vec3 layerColor = mix(darkerRockColor, rockColor, clamp(0.25 + striation, 0.0, 1.0));
  // Add subtle vertical gradient to mimic erosion
  float erosion = smoothstep(0.0, 1.0, u + v);
  layerColor = mix(layerColor, darkRockColor, 0.25 * erosion * (0.5 + 0.5 * idNoise));

  // Sphere-cap normal from distance to seed center (bestDelta)
  vec2 dlocal = bestDelta;                   // in cell space
  float radius = 0.33 + 0.12 * idNoise;      // stone radius in cell space
  float r = length(dlocal);
  float rN = clamp(r / max(radius, 1e-4), 0.0, 1.0);
  float heightScale = 0.9;                   // thickness of stones
  float z = sqrt(max(0.0, 1.0 - rN * rN)) * heightScale;
  vec3 N = normalize(vec3(dlocal / max(radius, 1e-4), z));

  // Lighting
  vec3 L = normalize(vec3(0.6, 0.35, 0.7));  // sun-ish direction
  vec3 V = vec3(0.0, 0.0, 1.0);              // view direction
  vec3 H = normalize(L + V);
  float ndotl = clamp(dot(N, L), 0.0, 1.0);
  float spec = pow(max(dot(N, H), 0.0), 32.0) * 0.25;

  // Edge darkening (AO) using F2-F1 distance
  float edgeAO = smoothstep(0.02, 0.15, db - da);

  vec3 fragColorRock = layerColor;
  fragColorRock *= mix(0.35, 1.05, ndotl);      // diffuse lighting
  fragColorRock += spec * (0.4 + 0.6 * idNoise);
  fragColorRock *= 0.85 + 0.15 * edgeAO;        // crevice darkening
  // Accent ridge height
  fragColorRock += 0.12 * ridge * vec3(1.0, 0.6, 0.3);
  color = fragColorRock;
      } else {
        color = rockColor;
      }
    }

    
  // ==============================================
  // =================== People ===================
  // ==============================================
  // Towel with vertical perspective - appears smaller when higher (further away)
  // Position towel safely on dry beach, away from where waves reach
  
  // Find a safe position on the beach (using shoreline information)
  // Place towel at a distance from the shore where waves don't reach
  float safeDistanceFromShore = 10.0; // Distance inland from shoreline
  vec2 towelShoreRef = shore.position - shoreNormal * safeDistanceFromShore;
  
  // Use a fixed position along the shore (around middle of visible beach)
  float towelAlongShore = 0.35; // Position along shoreline (0-1)
  vec2 towelCenterAdj = vec2(0.7 * aspectRatio, 0.17); // Adjusted position
  
  float towelBaseSize = 1.2; // Smaller, more realistic size
  
  // Calculate perspective scale based on y position
  float towelScale = getPerspectiveScale(towelCenterAdj.y, horizonY, perspectiveStrength);
  float towelSizeAdj = towelBaseSize * towelScale;
  
  float towelWidthAdj = 0.55; // Narrower towel
  float towelHeightAdj = 0.34; // Longer towel (typical beach towel proportions)
  float towelSkewAdj = 0.05; // Less skew for more natural look
  
  vec2 towelPerspectivePos = vec2(towelCenterAdj.x, towelCenterAdj.y);
  float towel = towelShape(uv, towelPerspectivePos, towelSizeAdj, towelWidthAdj, towelHeightAdj, towelSkewAdj, numStripes, stripeOrientation);
  
  // Add shadow for towel (simple offset shadow)
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
  
  // Scale person with towel for proper proportions
  float personScale = towelScale * 0.7;
  
  // Head
  float personHead = sdCircle(uv - personCenter - vec2(0.0, 0.022) * personScale, 0.012 * personScale);
  
  // Body (torso)
  float personBody = sdBox(uv - personCenter - vec2(0.0, 0.005) * personScale, vec2(0.010, 0.018) * personScale);
  
  // Arms (lying down position)
  float armThickness = 0.004 * personScale;
  float personArmL = sdOrientedBox(uv, 
    personCenter + vec2(-0.012, 0.008) * personScale, 
    personCenter + vec2(-0.025, 0.005) * personScale, 
    armThickness);
  float personArmR = sdOrientedBox(uv, 
    personCenter + vec2(0.012, 0.008) * personScale, 
    personCenter + vec2(0.025, 0.005) * personScale, 
    armThickness);
  
  // Legs
  float personLegL = sdBox(uv - personCenter - vec2(-0.005, -0.015) * personScale, vec2(0.004, 0.015) * personScale);
  float personLegR = sdBox(uv - personCenter - vec2(0.005, -0.015) * personScale, vec2(0.004, 0.015) * personScale);
  
  // Combine person parts
  float person = opSmoothUnion(personHead, personBody, 0.003 * personScale);
  person = opUnion(person, personArmL);
  person = opUnion(person, personArmR);
  person = opUnion(person, personLegL);
  person = opUnion(person, personLegR);
  
  vec3 skinColor = rgb(255, 200, 150);
  vec3 swimsuitColor = rgb(220, 50, 80);
  
  if (person < 0.0) {
    // Differentiate skin and swimsuit
    float swimsuitArea = sdBox(uv - personCenter - vec2(0.0, 0.0), vec2(0.012, 0.012) * personScale);
    if (swimsuitArea < 0.0) {
      color = swimsuitColor;
    } else {
      color = skinColor;
    }
  }

  // Person swimming in the water - better figure
  vec2 swimmerCenter = vec2(0.28 + 0.04*sin(iTime*0.6), 0.38 + 0.015*cos(iTime*2.5));
  
  // Check if swimmer is in water using triangle
  float swimmerInSea = sdTriangle(swimmerCenter, shore.position, shore.position + shoreNormal * 0.1, shore.position - shoreTangent * 0.1);
  
  if (swimmerInSea < 0.0 && swimmerCenter.y < skyHeight) {
    // Swimming person (side view, doing front crawl)
    float swimHead = sdCircle(uv - swimmerCenter - vec2(0.0, 0.0), 0.010);
    float swimBody = sdBox(uv - swimmerCenter - vec2(0.005, -0.008), vec2(0.012, 0.006));
    
    // Arm in swimming motion
    float armAngle = sin(iTime * 3.0);
    vec2 armOffset = vec2(0.015 * armAngle, 0.008 + 0.006 * abs(armAngle));
    float swimArm = sdCircle(uv - swimmerCenter - armOffset, 0.005);
    
    float swimmer = opSmoothUnion(swimHead, swimBody, 0.004);
    swimmer = opUnion(swimmer, swimArm);
    
    if (swimmer < 0.0) {
      color = skinColor;
    }
    
    // Add splash/wake around swimmer
    float splash = smoothstep(0.03, 0.02, length(uv - swimmerCenter));
    color = mix(color, whiteColor, splash * 0.3 * (sin(iTime * 5.0) * 0.5 + 0.5));
  }




  // ===============================================================
  // =================== Paris 2025 grain filter ===================
  // ===============================================================
  vec3 grain = vec3(fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453) * noise_intensity);
  color = mix(color, grain, 0.1);

  fragColor = vec4(color, 1.0);
}