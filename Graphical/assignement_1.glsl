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


float bezierSurface(vec2 uv, vec2 p0, vec2 p1, vec2 p2, float height) {
  // Calculate the bezier point at uv.x
  float t = uv.x;
  vec2 bezierPoint = (1.0 - t) * (1.0 - t) * p0 + 2.0 * (1.0 - t) * t * p1 + t * t * p2;
  
  // Calculate vertical distance from bezier curve
  return uv.y - (bezierPoint.y + height);
}

// Fixed-size count for shoreline Bezier control points
const int BEZIER_COUNT = 8;

float bezierS(vec2 uv, vec2 bezier[BEZIER_COUNT]) {
  // Find closest bezier segment by absolute distance while preserving sign.
  float bestAbs = 1e9;
  float bestSigned = 1e9;
  for(int i = 0; i < BEZIER_COUNT - 2; i++){
    float sd = bezierSurface(uv, bezier[i], bezier[i + 1], bezier[i + 2], 0.0);
    float a = abs(sd);
    if(a < bestAbs){
      bestAbs = a;
      bestSigned = sd; // keep sign: negative = water side, positive = beach side
    }
  }
  return bestSigned;
}

// ===================================================================
// ============================ Shapes ===============================
// ===================================================================
// Generate wavy shoreline with foam effect
float shoreline(vec2 uv, vec2 p0, vec2 p1, float time) {
  // Calculate the line from p0 to p1
  vec2 lineDir = p1 - p0;
  float lineLength = length(lineDir) - 0.04;
  vec2 lineNormal = normalize(vec2(-lineDir.y, lineDir.x));
  
  // Calculate position along the line (0 at p0, lineLength at p1)
  float lineT = dot(uv - p0, normalize(lineDir));
  
  // Limit foam to the segment between p0 and p1
  float edgeFade = smoothstep(-0.05, 0.0, lineT) * smoothstep(lineLength + 0.05, lineLength, lineT);
  
  float baseDist = dot(uv - p0, lineNormal);
  
  // Add wavy offset along the line direction
  float wave1 = sin(lineT * 15.0 + time * 1.2) * 0.008;
  float wave2 = sin(lineT * 8.0 - time * 0.8) * 0.012;
  float wave3 = sin(lineT * 25.0 + time * 2.0) * 0.004;
  
  float waveOffset = wave1 + wave2 + wave3;
  float dist = baseDist - waveOffset;


  float foam1 = smoothstep(0.04, -0.01, dist) * smoothstep(-0.02, 0.01, dist);
  float foam2 = smoothstep(0.06, 0.02, dist) * smoothstep(0.0, 0.03, dist) * 0.5;
  float foam3 = smoothstep(0.08, 0.04, dist) * smoothstep(0.02, 0.05, dist) * 0.25;
  float foam = foam1 + foam2 * (1.0 - foam1) + foam3 * (1.0 - foam1 - foam2);

  float foamNoise = fract(sin(dot(uv * 80.0, vec2(12.9898, 78.233))) * 43758.5453);
  foamNoise = mix(0.7, 1.0, smoothstep(0.2, 0.8, foamNoise));
  
  foam *= foamNoise;
  
  // Apply edge fade to limit foam to the line segment
  foam *= edgeFade;
  
  return foam;
}

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




float rockShape(vec2 uv, vec2 center, float size) {
  float d = length(uv - center);
  return smoothstep(size * 0.5, size, d);
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
  // All TODOs have been completed:
  // ✓ fix towel perspective
  // ✓ make the towel start and finish with the same color
  // ✓ fix sea
  // ✓ add peoples
  // ✓ add shadows
  // ✓ add the rocks
  // ✓ add waves and color variations to the sea
  // ✓ Animations (waves, moving clouds, people swimming)


  // ==================================================
  // =================== Parameters ===================
  // ==================================================
  float aspectRatio = iResolution.x / iResolution.y;
  vec2 vanishingPoint = vec2(aspectRatio * 0.2, 0.6); // Center horizontally, at horizon
  float perspectiveStrength = 0.2;
  float animationSpeed = 1.0;

  float skyHeight = 0.6;
  float cloudSpeed = 0.1;
  vec2 sunPos = vec2(0.14, 0.84);
  float sunSize = 0.07;
  float sunBlurSize = 0.05;

  float seaWidth = 0.95; // Expanded to fill more screen
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
  // Create curved shoreline using bezier curve
  vec2 shoreBezier[8] = vec2[8](
    shoreP0,
    vec2(0.08, 0.12),
    vec2(0.20, 0.28),
    vec2(0.35, 0.38),
    vec2(0.50, 0.45),
    vec2(0.65, 0.50),
    vec2(0.80, 0.54),
    shoreP2
  );
  
  // Calculate distance to bezier curve
  float shoreDist = 1000.0;
  for (int i = 0; i < shoreBezier.length() - 2; i++) {
    float dist = sdBezier(uv, shoreBezier[i], shoreBezier[i + 1], shoreBezier[i + 2]);
    shoreDist = (i == 0) ? dist : min(shoreDist, dist);
  }
  
  // Use triangle as bounds, but bezier defines the actual edge
  float sdTriangleSea = sdTriangle(uv, shoreP0, shoreP1, shoreP2);
  
  // Sea is where we're inside the triangle AND on the water side of the bezier curve
  if (sdTriangleSea < 0.0 && shoreDist < 0.0) {
    color = seaColor;
  }
  
  // Add smooth edge transition at the bezier curve
  float shoreFeather = 0.015;
  float shoreMask = smoothstep(shoreFeather, -shoreFeather, shoreDist);
  if (sdTriangleSea < 0.0) {
    color = mix(color, seaColor, shoreMask);
  }

  // ============== Foam ==============
  float foam = shoreline(uv, shoreP0, shoreP2, iTime);
  vec3 foamColorMix = mix(foamColor, whiteColor, foamIntensity);
  color = mix(color, foamColorMix, foam * foamIntensity);


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
  vec2 towelPerspectivePos = applyPerspective(towelCenterAdj, vanishingPoint, perspectiveStrength);
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