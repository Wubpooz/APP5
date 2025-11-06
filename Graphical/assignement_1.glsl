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



// ============== Own Utils ==============
vec3 rgb(int r, int g, int b) {
  return vec3(float(r), float(g), float(b)) / 255.0;
}


float cloudShape(vec2 uv, vec2 center, float size) {
  float d = length(uv - center);
  return smoothstep(size, size * 0.5, d);
}

float rockShape(vec2 uv, vec2 center, float size) {
  float d = length(uv - center);
  return smoothstep(size * 0.5, size, d);
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
    // Clouds
    float cloud1 = cloudShape(uv, vec2(0.3 + 0.1 * sin(iTime), 0.8), 0.15);
    float cloud2 = cloudShape(uv, vec2(0.6 + 0.1 * cos(iTime * 1.5), 0.7), 0.1);
    float cloud3 = cloudShape(uv, vec2(0.8 + 0.1 * sin(iTime * 0.5), 0.9), 0.12);
    float cloudMask = max(max(cloud1, cloud2), cloud3);
    color = mix(color, cloudColor, cloudMask);
  }

  // ============== Sun =============
  float sunDist = sdCircle(uv - vec2(0.2, 0.8), 0.1);
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

  // ============== Rocks ==============
  float sdBoxRock = sdBox(uv - vec2(0.8, 0.6), vec2(0.2, 0.2));
  if (sdBoxRock < 0.0) {
    color = rockColor; // Orange rocks on the left
  }

  // ============== People ==============


  // Animations (waves, moving clouds, people swimming)


  fragColor = vec4(color, 1.0);
}