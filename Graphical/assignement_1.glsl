// ============== Primitive Shapes ==============
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


// ============== CSG Operations ==============
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


// ============== Own Utils ==============
vec3 rgb(int r, int g, int b) {
  return vec3(float(r), float(g), float(b)) / 255.0;
}


// ============== Shapes ==============
float cloudShape(vec2 uv, vec2 center, float size) {
  float d = length(uv - center);
  return smoothstep(size, size * 0.5, d);
}

float rockShape(vec2 uv, vec2 center, float size) {
  float d = length(uv - center);
  return smoothstep(size * 0.5, size, d);
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




// "Paris 2025 JO style" beach with nice blue water (non transparent) and "orange" rocks on the side with failaises. Someone goes and swims in the water. The sun is shining bright. The sky is blue with some clouds. The scene is peaceful and relaxing.
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord / iResolution.xy;
  float aspectRatio = iResolution.x / iResolution.y;
  uv.x *= aspectRatio;
  vec3 p = vec3(uv, 0.0);

  // ============== Colors ==============
  vec3 skyColor = mix(rgb(96, 178, 197), rgb(35, 140, 181), uv.x + uv.y);
  vec3 cloudColor = rgb(255, 255, 255);
  vec3 sunColor = rgb(240, 180, 27);
  vec3 beachColor = rgb(234, 169, 61);
  vec3 rockColor = rgb(212, 81, 20);
  vec3 seaColor = mix(rgb(0, 105, 148), rgb(0, 168, 232), uv.y * 2.0);

  // ============== Sky ==============
  vec3 color = vec3(0.0);
  if (uv.y > 0.5) {
    color = skyColor;
    float cloudMask = 0.0;
    cloudMask = max(cloudMask, cloudBlob(uv, vec2(0.32 + 0.06*sin(iTime*0.4), 0.82), 0.2));
    cloudMask = max(cloudMask, cloudBlob(uv, vec2(0.62 + 0.05*cos(iTime*0.5), 0.72), 0.2));
    cloudMask = max(cloudMask, cloudBlob(uv, vec2(0.82 + 0.04*sin(iTime*0.3), 0.90), 0.2));
    color = mix(color, cloudColor, cloudMask);
  }

  // ============== Sun =============
  float sunDist = sdCircle(uv - vec2(0.14, 0.84), 0.07);
  if (sunDist < 0.0) {
    color = sunColor;
  }

  // Sun rays
  if (sunDist > 0.0 && sunDist < 0.05) {
    color = mix(sunColor, color, sunDist / 0.05);
  }


  // ============== Beach ==============
  if (uv.y <= 0.5) {
    color = beachColor;
  }

  // ============== Sea ==============
  // float seaLevel = 0.4 + 0.1 * sin(iTime + uv.x * 10.0);
  float sdTriangleSea = sdTriangle(uv, vec2(0.0, -0.04), vec2(0.0, 0.5), vec2(0.7, 0.5));
  if (sdTriangleSea < 0.0) {
    color = seaColor;
  }

  // shoreline (sea edge, combination of bezier curves)

  // sea foam


  // ============== Rocks ==============
  // float sdBoxRock = sdBox(uv - vec2(0.8, 0.6), vec2(0.2, 0.2));
  // if (sdBoxRock < 0.0) {
  //   color = rockColor;
  // }

  // ============== People ==============


  // Animations (waves, moving clouds, people swimming)


  // Paris 2025 grain filter
  vec3 grain = vec3(0.0);
  float noise_intensity = 0.3;
  float noise = fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453) * noise_intensity;
  grain += vec3(noise);
  color = mix(color, grain, 0.1);

  fragColor = vec4(color, 1.0);
}