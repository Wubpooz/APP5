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

// Reverse perspective transformation
vec2 removePerspective(vec2 uv, vec2 vanishingPoint, float strength) {
  vec2 dir = uv - vanishingPoint;
  float dist = length(dir);
  float factor = (1.0 + strength * dist);
  return vanishingPoint + dir * factor;
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


vec3 generateBeachWaves(vec2 uv, vec2 lineStart, vec2 lineEnd, vec3 sandColor, vec3 seaBaseColor, float time) {
    // Wave parameters
    const int waveNumber = 16;
    const float speed = 0.015;
    const float waveCurve = 1.0; // Increased for more frequent waves
    const float waveScale = 0.01; // Scale down the wave height
    vec3 deepSeaColor = seaBaseColor * 0.3;
    
    float t = time * speed + 12.2;
    vec4 col = vec4(sandColor, 0.0);
    vec3 wetSand = sandColor * vec3(0.7, 0.6, 0.4);
    float lastWaveAge = 10.0;
    

    for(int i = 0; i < waveNumber; i++) {
        float ti = floor(t - 0.25) + float(i);
        float waveAge = fract(t - 0.25);
        float waveNoise = hash1(ti) / 3.0 + noise1d((uv.x + uv.y * 0.5 + ti) * waveCurve) * max(0.0, waveAge * 1.5 - 0.3);
        
        // Wave vertical offset with perspective
        float offset = (uv.y + sin(t * (2.0 * 3.14159265)) / 2.2 - 0.3) + waveNoise;
        
        // Position in wave space
        vec2 pos = vec2(uv.x + uv.y * 0.3, -offset / (0.2 + waveAge * 20.0) * 2.0);

        float foam = noiseLayer(pos, ti);
        offset -= foam / 10.0;
        offset -= noiseLayer(uv / 10.0, 0.0) / 5.0;

        // Max wave calculation (for wet sand)
        float maxWaveNoise = hash1(ti) / 3.0 + noise1d((uv.x + uv.y * 0.5 + ti) * waveCurve) * max(0.0, 0.5 * 1.5 - 0.3);
        float maxOffset = (uv.y + sin((ti + 0.5) * (2.0 * 3.14159265)) / 2.2 - 0.3) + maxWaveNoise;
        vec2 maxPos = vec2(uv.x + uv.y * 0.3, -maxOffset / (0.2 + 0.5 * 20.0) * 2.0);
        float maxFoam = noiseLayer(maxPos, ti);
        maxOffset -= maxFoam / 20.0;
        maxOffset -= noiseLayer(uv / 10.0, 0.0) / 10.0;
        
        if(offset < 0.0) { // In wave area
            if(waveAge < lastWaveAge) { // Draw newer waves on top
                vec3 n = vec3(
                    foam - noiseLayer(pos + vec2(0.001, 0.0), ti),
                    foam - noiseLayer(pos + vec2(0.0, 0.001), ti),
                    0.5
                );
                // n = normalize(n);
                foam = (foam + 0.8 - waveAge * waveAge + offset * offset * 0.5 + clamp(offset + 0.2, 0.0, 1.0));
                float light = dot(n, vec3(1.0, 1.0, 1.0));

                // Wave color with transparency fade
                col.rgb = mix(sandColor, seaBaseColor, clamp(1.5 - waveAge * 3.0, 0.02, 1.0));
                // Darken away from wave front
                col.rgb = mix(col.rgb, deepSeaColor, -offset);

                float denseFoam = clamp(foam * 20.0 - 20.0, 0.0, 1.0) * 0.8;
                col.rgb = mix(col.rgb, vec3(light) * 1.5, denseFoam);

                // Thin white line at wave front
                col.rgb += max(0.0, floor(offset + 1.004) * n.r * 10.0);

                // Specular highlights
                col.rgb += max(0.0, dot(n, vec3(1.0, 0.3, 0.95)) * 10.0 - 5.0);

                // Foam texture
                col.rgb *= foam * foam * (1.0 - waveAge) + waveAge * 1.2;

                col.a = 1.0;
            }
            lastWaveAge = waveAge;
        } else {
            // Wet sand effect
            if(col.a == 0.0 && waveAge > 0.5) {
                float dryness = 50.0 * (1.0 - waveAge);
                col.rgb = mix(col.rgb, wetSand, clamp((dryness - 2.5 - maxOffset * dryness * 2.0), 0.0, 1.0) * (1.0 - waveAge));
            }
        }

        t += 1.0 / float(waveNumber);
    }
    
    return col.rgb;
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


  // ==================================================
  // =================== Parameters ===================
  // ==================================================
  float aspectRatio = iResolution.x / iResolution.y;
  vec2 vanishingPoint = vec2(-0.12, .21);
  float perspectiveStrength = 0.02;
  float animationSpeed = 1.0;

  float skyHeight = 0.6;
  float cloudSpeed = 0.1;
  vec2 sunPos = vec2(0.14, 0.84);
  float sunSize = 0.07;
  float sunBlurSize = 0.05;

  float seaWidth = 0.6; // Expanded to fill more screen
  vec2 shoreP0 = vec2(0.0, -0.04);
  vec2 shoreP1 = vec2(0.0, skyHeight);
  vec2 shoreP2 = vec2(seaWidth, skyHeight);
  float foamIntensity = 0.9;

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
  // Apply perspective to UVs for beach objects
  vec2 uvPerspective = applyPerspective(uv, vanishingPoint, perspectiveStrength);
  
  float time = iTime * animationSpeed;

  // ==============================================
  // =================== Colors ===================
  // ==============================================
  vec3 color = vec3(0.0);
  vec3 whiteColor = rgb(255, 255, 255);

  vec3 skyColor = mix(rgb(96, 178, 197), rgb(35, 140, 181), uv.x + uv.y);
  vec3 cloudColor = rgb(255, 255, 255);
  vec3 sunColor = rgb(240, 180, 27);

  vec3 beachColor = rgb(234, 169, 61);

  vec3 seaColor = mix(rgb(0, 105, 148), rgb(0, 168, 232), uv.y * 2.0);
  vec3 foamColor = rgb(200, 230, 240);

  vec3 rockColor = rgb(212, 81, 20);

  vec3 towelTone1 = whiteColor;
  vec3 towelTone2 = rgb(0, 105, 200);


  uv = applyPerspective(uv, vanishingPoint, perspectiveStrength);
  // ===========================================
  // =================== Sky ===================
  // ===========================================
  float cloudMask = 0.0;
  cloudMask = max(cloudMask, cloudBlob(uv, vec2(0.32 + 0.06*sin(iTime*0.4), 0.82), 0.2));
  cloudMask = max(cloudMask, cloudBlob(uv, vec2(0.62 + 0.05*cos(iTime*0.5), 0.72), 0.2));
  cloudMask = max(cloudMask, cloudBlob(uv, vec2(0.82 + 0.04*sin(iTime*0.3), 0.90), 0.2));
  if (uv.y > skyHeight) {
    color = skyColor;
    color = mix(color, cloudColor, cloudMask);
  }

  // ===========================================
  // =================== Sun ===================
  // ===========================================
  float sunDist = sdCircle(uv - sunPos, sunSize);
  if (sunDist < 0.0) {
    color = sunColor;
  }

  // Sun rays
  if (sunDist > 0.0 && sunDist < sunBlurSize) {
    color = mix(sunColor, color, sunDist / sunBlurSize);
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
  float seaDist = sdSea(uv, shoreP0, shoreP1, shoreP2);

  // Align beachUV with shoreline
  vec2 lineDir = normalize(shoreP2 - shoreP0);
  vec2 lineNormal = normalize(vec2(lineDir.y, -lineDir.x));
  vec2 beachUV = vec2(dot(uv - shoreP0, lineDir), dot(uv - shoreP0, lineNormal));
  beachUV *= 6.0; // Scale down for beach space
  vec3 waveColor = generateBeachWaves(beachUV, shoreP0, shoreP1, beachColor, seaColor, iTime);
  if (uv.y < skyHeight) {
    float waveBlend = smoothstep(-0.02, 0.01, seaDist);
    color = waveColor;mix(seaColor, waveColor, waveBlend);
  }
  if (uv.y < skyHeight && seaDist < 0.0) {
    color = seaColor;
  }

  // =============================================
  // =================== Rocks ===================
  // =============================================
  // Keep only the right side cliff formation (calanque-style)
  
  // Right side cliff formation (larger, more prominent)
  float rightCliff1 = sdBox(uv - vec2(0.88, 0.65), vec2(0.12, 0.22));
  float rightCliff2 = sdCircle(uv - vec2(0.88, 0.87), 0.14);
  float rightCliff3 = sdBox(uv - vec2(0.78, 0.70), vec2(0.08, 0.15));
  float rightCliff4 = sdCircle(uv - vec2(0.95, 0.72), 0.10);
  float rightCliff = opSmoothUnion(rightCliff1, rightCliff2, 0.02);
  rightCliff = opSmoothUnion(rightCliff, rightCliff3, 0.02);
  rightCliff = opSmoothUnion(rightCliff, rightCliff4, 0.015);
  
  // Use only the right cliff
  float allRocks = rightCliff;
  
  if (allRocks < 0.0) {
    // Add shading for depth - darker at edges, lighter on top
    float rockShading = smoothstep(-0.08, 0.0, allRocks);
    vec3 darkRockColor = rockColor * 0.5;
    vec3 lightRockColor = rockColor * 1.1;
    color = mix(darkRockColor, lightRockColor, rockShading);
    
    // Add some texture variation
    float rockNoise = fract(sin(dot(uv * 200.0, vec2(12.9898, 78.233))) * 43758.5453);
    color = mix(color, color * 0.9, rockNoise * 0.2);
  }



  // ==============================================
  // =================== People ===================
  // ==============================================
  // Towel with improved perspective - make it smaller and closer to beach
  vec2 towelCenterAdj = vec2(0.42, 0.15);
  float towelSizeAdj = 0.08; // Smaller for better perspective
  float towelWidthAdj = 0.6;
  float towelHeightAdj = 0.3;
  float towelSkewAdj = 0.15;
  
  // Apply perspective to towel position for depth effect
  vec2 towelPerspectivePos = vec2(towelCenterAdj.x, towelCenterAdj.y);
  float towel = towelShape(uv, towelPerspectivePos, towelSizeAdj, towelWidthAdj, towelHeightAdj, towelSkewAdj, numStripes, stripeOrientation);
  
  // Add shadow for towel (simple offset shadow)
  vec2 shadowOffset = vec2(0.015, -0.012);
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
  vec2 personCenter = towelPerspectivePos + vec2(-0.01, 0.0);
  
  // Head
  float personHead = sdCircle(uv - personCenter - vec2(0.0, 0.022), 0.012);
  
  // Body (torso)
  float personBody = sdBox(uv - personCenter - vec2(0.0, 0.005), vec2(0.010, 0.018));
  
  // Arms (lying down position)
  float armThickness = 0.004;
  float personArmL = sdOrientedBox(uv, personCenter + vec2(-0.012, 0.008), personCenter + vec2(-0.025, 0.005), armThickness);
  float personArmR = sdOrientedBox(uv, personCenter + vec2(0.012, 0.008), personCenter + vec2(0.025, 0.005), armThickness);
  
  // Legs
  float personLegL = sdBox(uv - personCenter - vec2(-0.005, -0.015), vec2(0.004, 0.015));
  float personLegR = sdBox(uv - personCenter - vec2(0.005, -0.015), vec2(0.004, 0.015));
  
  // Combine person parts
  float person = opSmoothUnion(personHead, personBody, 0.003);
  person = opUnion(person, personArmL);
  person = opUnion(person, personArmR);
  person = opUnion(person, personLegL);
  person = opUnion(person, personLegR);
  
  vec3 skinColor = rgb(255, 200, 150);
  vec3 swimsuitColor = rgb(220, 50, 80);
  
  if (person < 0.0) {
    // Differentiate skin and swimsuit
    float swimsuitArea = sdBox(uv - personCenter - vec2(0.0, 0.0), vec2(0.012, 0.012));
    if (swimsuitArea < 0.0) {
      color = swimsuitColor;
    } else {
      color = skinColor;
    }
  }

  // Person swimming in the water - better figure
  vec2 swimmerCenter = vec2(0.28 + 0.04*sin(iTime*0.6), 0.38 + 0.015*cos(iTime*2.5));
  
  // Check if swimmer is in water using triangle
  float swimmerInSea = sdTriangle(swimmerCenter, shoreP0, shoreP1, shoreP2);
  
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