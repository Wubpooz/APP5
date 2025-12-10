// =============== SDF OPERATORS ===============
float dot2( in vec3 v ) { return dot(v,v); }

// =============== TEXT HELPERS ===============
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float charH(vec2 p) {
    return min(min(sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3)),
                   sdSegment(p, vec2( 0.2,-0.3), vec2( 0.2,0.3))),
                   sdSegment(p, vec2(-0.2, 0.0), vec2( 0.2,0.0)));
}
float charE(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2, 0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2, 0.0), vec2( 0.1,0.0)));
    d = min(d, sdSegment(p, vec2(-0.2,-0.3), vec2( 0.2,-0.3)));
    return d;
}
float charL(vec2 p) {
    return min(sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3)),
               sdSegment(p, vec2(-0.2,-0.3), vec2( 0.2,-0.3)));
}
float charO(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2( 0.2,-0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2, 0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2,-0.3), vec2( 0.2,-0.3)));
    return d;
}
float charW(vec2 p) {
    float d = sdSegment(p, vec2(-0.3, 0.3), vec2(-0.15,-0.3));
    d = min(d, sdSegment(p, vec2(-0.15,-0.3), vec2( 0.0, 0.0)));
    d = min(d, sdSegment(p, vec2( 0.0, 0.0), vec2( 0.15,-0.3)));
    d = min(d, sdSegment(p, vec2( 0.15,-0.3), vec2( 0.3, 0.3)));
    return d;
}
float charR(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2, 0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2( 0.2, 0.3), vec2( 0.2,0.0)));
    d = min(d, sdSegment(p, vec2( 0.2, 0.0), vec2(-0.2,0.0)));
    d = min(d, sdSegment(p, vec2(-0.1, 0.0), vec2( 0.2,-0.3)));
    return d;
}
float charD(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2, 0.3), vec2( 0.1,0.3)));
    d = min(d, sdSegment(p, vec2( 0.1, 0.3), vec2( 0.2,0.15)));
    d = min(d, sdSegment(p, vec2( 0.2, 0.15), vec2( 0.2,-0.15)));
    d = min(d, sdSegment(p, vec2( 0.2,-0.15), vec2( 0.1,-0.3)));
    d = min(d, sdSegment(p, vec2( 0.1,-0.3), vec2(-0.2,-0.3)));
    return d;
}

float getText(vec2 p) {
    // HELLO WORLD
    p.x += 2.5;
    float d = charH(p); p.x -= 0.5;
    d = min(d, charE(p)); p.x -= 0.5;
    d = min(d, charL(p)); p.x -= 0.5;
    d = min(d, charL(p)); p.x -= 0.5;
    d = min(d, charO(p)); p.x -= 0.8; // Space
    d = min(d, charW(p)); p.x -= 0.6; // W is wide
    d = min(d, charO(p)); p.x -= 0.5;
    d = min(d, charR(p)); p.x -= 0.5;
    d = min(d, charL(p)); p.x -= 0.5;
    d = min(d, charD(p));
    return d;
}

vec3 getPlaneColor(vec2 p, float textScale) {
    // Grid pattern (kept for subtle shading if needed later)
    vec2 grid = abs(fract(p - 0.5) - 0.5) / fwidth(p);
    float line = min(grid.x, grid.y);
    
    // Text pattern
    vec2 tp = p * textScale;
    float lineIndex = floor(tp.y);
    tp.y = fract(tp.y) - 0.5;
    tp.x += lineIndex * 2.0; // Shift lines
    tp.x = mod(tp.x, 6.0) - 3.0; // Repeat sentence
    
    float d = getText(tp);
    float textAlpha = smoothstep(0.05, 0.04, d);
    
    // Glowing Button
    vec2 btnPos = vec2(2.0, 0.0);
    float btnD = length(p - btnPos) - 0.4;
    float btnGlow = 0.02 / (abs(btnD) + 0.001);
    vec3 btnCol = vec3(1.0, 0.1, 0.1) * smoothstep(0.01, 0.0, -btnD); // Red core
    btnCol += vec3(1.0, 0.3, 0.1) * btnGlow; // Orange glow
    
    vec3 bgColor = vec3(0.95); // Paper white
    vec3 inkColor = vec3(0.1); // Dark ink
    
    vec3 col = bgColor;
    col = mix(col, inkColor, textAlpha);
    col += btnCol; // Add button
    
    return col;
}

// =============== 3D SCENE ===============

// 3D Capsule SDF
float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float map(vec3 p, vec3 pillPos, vec4 pillParams) {
    // Flattening the pill
    vec3 q = p - pillPos;
    q.y *= pillParams.x; // Squash Y axis more for flatter look
    
    // Capsule defined in local space
    // Wider and longer to match the reference
    float d = sdCapsule(q, vec3(-pillParams.y, 0.0, 0.0), vec3(pillParams.y, 0.0, 0.0), pillParams.z);
    
    // Return distance with correction factor
    return d * pillParams.w;
}

vec3 calcNormal( in vec3 p, vec3 pillPos, vec4 pillParams )
{
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*map( p + k.xyy*h, pillPos, pillParams ) + 
                      k.yyx*map( p + k.yyx*h, pillPos, pillParams ) + 
                      k.yxy*map( p + k.yxy*h, pillPos, pillParams ) + 
                      k.xxx*map( p + k.xxx*h, pillPos, pillParams ) );
}

float intersectPlane(vec3 ro, vec3 rd, float height) {
    if (abs(rd.y) < 0.0001) return -1.0;
    float t = (height - ro.y) / rd.y;
    return t > 0.0 ? t : -1.0;
}

// =============== RENDERING HELPERS ===============

vec3 getRayDir(vec2 uv, vec3 ro, vec3 ta, float zoom) {
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0)) );
    vec3 vv = normalize( cross(uu,ww));
    return normalize( uv.x*uu + uv.y*vv + zoom*ww );
}

vec3 updatePillPosition(vec3 ro, vec3 ta, float zoom, float pillHeight) {
    vec3 pillPos = vec3(0.0, pillHeight, 0.0);
    
    if (length(iMouse.xy) > 10.0) {
        vec2 mouseUV = (iMouse.xy - 0.5 * iResolution.xy) / iResolution.y;
        vec3 rd_mouse = getRayDir(mouseUV, ro, ta, zoom);
        
        // Avoid division by near-zero when camera is parallel to the pill plane
        if (abs(rd_mouse.y) > 1e-4) {
            float t_mouse = (pillHeight - ro.y) / rd_mouse.y;
            if (t_mouse > 0.0) {
                pillPos = ro + t_mouse * rd_mouse;
            }
        }
    }
    return pillPos;
}

bool castRay(vec3 ro, vec3 rd, vec3 pillPos, vec4 pillParams, out float t) {
    t = 0.0;
    float tmax = 20.0;
    for(int i=0; i<64; i++) {
        vec3 p = ro + t*rd;
        float d = map(p, pillPos, pillParams);
        if(d < 0.001) return true;
        t += d;
        if(t > tmax) break;
    }
    return false;
}

vec3 renderBackground(vec3 ro, vec3 rd, vec3 pillPos, vec4 pillParams, float textScale) {
    float t_plane = intersectPlane(ro, rd, 0.0);
    if (t_plane > 0.0) {
        vec3 p_plane = ro + t_plane * rd;
        vec3 col = getPlaneColor(p_plane.xz, textScale);

        return col; // Commenting this out will hide the plane but it'll be visible through the glass !!!!
        
        // Optional: Add pill shadow on the plane
        // float d_shadow = map(p_plane, pillPos, pillParams);
        // float shadow = smoothstep(0.0, 1.5, d_shadow);
        // return col * mix(0.9, 1.0, shadow);
    }
    return vec3(0.9);
}

vec3 renderGlass(vec3 ro, vec3 rd, float t, vec3 pillPos, vec4 pillParams, float glassIOR, vec3 glassTint, float textScale) {
    vec3 p = ro + t*rd;
    vec3 n = calcNormal(p, pillPos, pillParams);
    vec3 rd_in = refract(rd, n, 1.0/glassIOR);
    
    float t_in = 0.01; 
    vec3 p_in = p;
    for(int i=0; i<64; i++) {
        p_in = p + t_in * rd_in;
        float d_in = map(p_in, pillPos, pillParams);
        if(d_in > -0.001) break;
        t_in += abs(d_in); 
    }
    
    vec3 n_out = calcNormal(p_in, pillPos, pillParams);
    vec3 rd_out = refract(rd_in, -n_out, glassIOR);
    
    if (length(rd_out) == 0.0) rd_out = reflect(rd_in, -n_out);
    
    float t_plane = intersectPlane(p_in, rd_out, 0.0);
    vec3 col;
    if (t_plane > 0.0) {
        vec3 p_plane = p_in + t_plane * rd_out;
        col = getPlaneColor(p_plane.xz, textScale);
    } else {
      // Sides of the pill miss the plane, TODO add multiple bounces!
      vec3 p_plane = p_in + rd_out * rd_out;
      col = getPlaneColor(p_plane.xz, textScale);
    }
    
    // Softer Fresnel to avoid harsh white rims
    float fre = pow(clamp(1.0 + dot(rd, n), 0.0, 1.0), 5.0);
    col += vec3(0.6) * fre;
    col *= glassTint;
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // ================= SETTINGS =================
    // Camera
    vec3 camPos = vec3(0.0, 5.5, 4.5);
    float camZoom = 1.5;
  
    // Pill Geometry
    float pillHeight = 0.6;
    // x: SquashY, y: Length, z: Radius, w: SDF Correction
    vec4 pillParams = vec4(5.0, 0.8, 0.5, 0.2); 
    
    // Glass Look
    float glassIOR = 1.55;
    vec3 glassTint = vec3(0.95, 0.98, 1.0);
    
    // Text
    float textScale = 2.5;
    // ============================================

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Camera & Interaction
    vec3 ro = camPos;
    vec3 ta = vec3(0.0);
    vec3 pillPos = updatePillPosition(ro, ta, camZoom, pillHeight);
    vec3 rd = getRayDir(uv, ro, ta, camZoom);

    // Raymarch
    float t;
    bool hitPill = castRay(ro, rd, pillPos, pillParams, t);

    // Shading
    vec3 col;
    if (hitPill) {
        col = renderGlass(ro, rd, t, pillPos, pillParams, glassIOR, glassTint, textScale);
    } else {
        col = renderBackground(ro, rd, pillPos, pillParams, textScale);
    }
    
    // Vignette
    col *= 1.0 - 0.2 * length(uv);

    fragColor = vec4(col, 1.0);
}