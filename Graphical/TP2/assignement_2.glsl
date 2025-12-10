// =============== SDF OPERATORS ===============
float dot2( in vec3 v ) { return dot(v,v); }

// =============== LIGHTING ===============
#define NUM_LIGHTS 4
struct DirLight {
    vec3 dir;   // direction pointing from light toward the scene
    vec3 color; // light radiance/tint
};

// Point bulbs
const vec3 bulbPosOrange = vec3(0.0);
const vec3 bulbColorOrange = vec3(1.0, 0.55, 0.2); // warmer, less white
const vec3 bulbPosBlue = vec3(3.0, .2, .2);
const vec3 bulbColorBlue = vec3(0.1, 0.2, 2.0); // brighter and more saturated blue

// =============== TEXT HELPERS ===============
float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

// Individual glyphs built from segments; simple and compact
float charA(vec2 p) {
    float d = min(sdSegment(p, vec2(-0.2,-0.3), vec2(0.0,0.3)), sdSegment(p, vec2(0.0,0.3), vec2(0.2,-0.3)));
    d = min(d, sdSegment(p, vec2(-0.1,0.0), vec2(0.1,0.0)));
    return d;
}
float charB(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2,0.3), vec2(0.1,0.3)));
    d = min(d, sdSegment(p, vec2(0.1,0.3), vec2(0.15,0.15)));
    d = min(d, sdSegment(p, vec2(0.15,0.15), vec2(0.1,0.0)));
    d = min(d, sdSegment(p, vec2(0.1,0.0), vec2(-0.2,0.0)));
    d = min(d, sdSegment(p, vec2(-0.2,0.0), vec2(0.1,0.0)));
    d = min(d, sdSegment(p, vec2(0.1,0.0), vec2(0.15,-0.15)));
    d = min(d, sdSegment(p, vec2(0.15,-0.15), vec2(0.1,-0.3)));
    d = min(d, sdSegment(p, vec2(0.1,-0.3), vec2(-0.2,-0.3)));
    return d;
}
float charC(vec2 p) {
    float d = sdSegment(p, vec2(0.15,0.25), vec2(-0.1,0.3));
    d = min(d, sdSegment(p, vec2(-0.1,0.3), vec2(-0.2,0.15)));
    d = min(d, sdSegment(p, vec2(-0.2,0.15), vec2(-0.2,-0.15)));
    d = min(d, sdSegment(p, vec2(-0.2,-0.15), vec2(-0.1,-0.3)));
    d = min(d, sdSegment(p, vec2(-0.1,-0.3), vec2(0.15,-0.25)));
    return d;
}
float charD(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2,0.3), vec2(0.1,0.3)));
    d = min(d, sdSegment(p, vec2(0.1,0.3), vec2(0.2,0.15)));
    d = min(d, sdSegment(p, vec2(0.2,0.15), vec2(0.2,-0.15)));
    d = min(d, sdSegment(p, vec2(0.2,-0.15), vec2(0.1,-0.3)));
    d = min(d, sdSegment(p, vec2(0.1,-0.3), vec2(-0.2,-0.3)));
    return d;
}
float charE(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2, 0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2, 0.0), vec2( 0.1,0.0)));
    d = min(d, sdSegment(p, vec2(-0.2,-0.3), vec2( 0.2,-0.3)));
    return d;
}
float charF(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2,0.3), vec2(0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2,0.05), vec2(0.1,0.05)));
    return d;
}
float charG(vec2 p) {
    float d = charC(p);
    d = min(d, sdSegment(p, vec2(0.0,0.0), vec2(0.15,0.0)));
    d = min(d, sdSegment(p, vec2(0.15,0.0), vec2(0.15,-0.15)));
    return d;
}
float charH(vec2 p) {
    return min(min(sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3)),
                   sdSegment(p, vec2( 0.2,-0.3), vec2( 0.2,0.3))),
                   sdSegment(p, vec2(-0.2, 0.0), vec2( 0.2,0.0)));
}
float charI(vec2 p) {
    float d = sdSegment(p, vec2(-0.15,0.3), vec2(0.15,0.3));
    d = min(d, sdSegment(p, vec2(0.0,0.3), vec2(0.0,-0.3)));
    d = min(d, sdSegment(p, vec2(-0.15,-0.3), vec2(0.15,-0.3)));
    return d;
}
float charL(vec2 p) {
    return min(sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3)),
               sdSegment(p, vec2(-0.2,-0.3), vec2( 0.2,-0.3)));
}
float charM(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2,0.3), vec2(0.0,0.05)));
    d = min(d, sdSegment(p, vec2(0.0,0.05), vec2(0.2,0.3)));
    d = min(d, sdSegment(p, vec2(0.2,0.3), vec2(0.2,-0.3)));
    return d;
}
float charN(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2,0.3), vec2(0.2,-0.3)));
    d = min(d, sdSegment(p, vec2(0.2,-0.3), vec2(0.2,0.3)));
    return d;
}
float charO(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2( 0.2,-0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2, 0.3), vec2( 0.2,0.3)));
    d = min(d, sdSegment(p, vec2(-0.2,-0.3), vec2( 0.2,-0.3)));
    return d;
}
float charP(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,-0.3), vec2(-0.2,0.3));
    d = min(d, sdSegment(p, vec2(-0.2,0.3), vec2(0.15,0.3)));
    d = min(d, sdSegment(p, vec2(0.15,0.3), vec2(0.15,0.05)));
    d = min(d, sdSegment(p, vec2(0.15,0.05), vec2(-0.2,0.05)));
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
float charS(vec2 p) {
    float d = sdSegment(p, vec2(0.15,0.3), vec2(-0.15,0.3));
    d = min(d, sdSegment(p, vec2(-0.15,0.3), vec2(-0.2,0.05)));
    d = min(d, sdSegment(p, vec2(-0.2,0.05), vec2(0.15,0.05)));
    d = min(d, sdSegment(p, vec2(0.15,0.05), vec2(0.2,-0.2)));
    d = min(d, sdSegment(p, vec2(0.2,-0.2), vec2(-0.15,-0.2)));
    d = min(d, sdSegment(p, vec2(-0.15,-0.2), vec2(-0.15,-0.3)));
    d = min(d, sdSegment(p, vec2(-0.15,-0.3), vec2(0.15,-0.3)));
    return d;
}
float charT(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,0.3), vec2(0.2,0.3));
    d = min(d, sdSegment(p, vec2(0.0,0.3), vec2(0.0,-0.3)));
    return d;
}
float charU(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,0.3), vec2(-0.2,-0.2));
    d = min(d, sdSegment(p, vec2(-0.2,-0.2), vec2(0.0,-0.3)));
    d = min(d, sdSegment(p, vec2(0.0,-0.3), vec2(0.2,-0.2)));
    d = min(d, sdSegment(p, vec2(0.2,-0.2), vec2(0.2,0.3)));
    return d;
}
float charV(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,0.3), vec2(0.0,-0.3));
    d = min(d, sdSegment(p, vec2(0.0,-0.3), vec2(0.2,0.3)));
    return d;
}
float charW(vec2 p) {
    float d = sdSegment(p, vec2(-0.3, 0.3), vec2(-0.15,-0.3));
    d = min(d, sdSegment(p, vec2(-0.15,-0.3), vec2( 0.0, 0.0)));
    d = min(d, sdSegment(p, vec2( 0.0, 0.0), vec2( 0.15,-0.3)));
    d = min(d, sdSegment(p, vec2( 0.15,-0.3), vec2( 0.3, 0.3)));
    return d;
}
float charX(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,0.3), vec2(0.2,-0.3));
    d = min(d, sdSegment(p, vec2(0.2,0.3), vec2(-0.2,-0.3)));
    return d;
}
float charY(vec2 p) {
    float d = sdSegment(p, vec2(-0.2,0.3), vec2(0.0,0.0));
    d = min(d, sdSegment(p, vec2(0.2,0.3), vec2(0.0,0.0)));
    d = min(d, sdSegment(p, vec2(0.0,0.0), vec2(0.0,-0.3)));
    return d;
}

float glyph(vec2 p, int id) {
    // ASCII uppercase letters and space
    if (id == 32) return 1e5;
    if (id == 65) return charA(p);
    if (id == 66) return charB(p);
    if (id == 67) return charC(p);
    if (id == 68) return charD(p);
    if (id == 69) return charE(p);
    if (id == 70) return charF(p);
    if (id == 71) return charG(p);
    if (id == 72) return charH(p);
    if (id == 73) return charI(p);
    if (id == 76) return charL(p);
    if (id == 77) return charM(p);
    if (id == 78) return charN(p);
    if (id == 79) return charO(p);
    if (id == 80) return charP(p);
    if (id == 82) return charR(p);
    if (id == 83) return charS(p);
    if (id == 84) return charT(p);
    if (id == 85) return charU(p);
    if (id == 86) return charV(p);
    if (id == 87) return charW(p);
    if (id == 88) return charX(p);
    if (id == 89) return charY(p);
    return 1e5;
}

float renderLine(vec2 p, int line) {
    float d = 1e5;
    float adv = 0.55;
    if (line == 0) {
        p.x += 6.0; // "GODEL INCOMPLETENESS I"
        int chars[24];
        chars = int[24](71,79,68,69,76,32,73,78,67,79,77,80,76,69,84,69,78,69,83,83,32,73,32,32);
        for (int i = 0; i < 24; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    } else if (line == 1) {
        p.x += 5.2; // "TRUE STATEMENTS EXIST"
        int chars[21];
        chars = int[21](84,82,85,69,32,83,84,65,84,69,77,69,78,84,83,32,69,88,73,83,84);
        for (int i = 0; i < 21; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    } else if (line == 2) {
        p.x += 6.2; // "THE SYSTEM CANNOT PROVE"
        int chars[25];
        chars = int[25](84,72,69,32,83,89,83,84,69,77,32,67,65,78,78,79,84,32,80,82,79,86,69,32,32);
        for (int i = 0; i < 25; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    } else if (line == 3) {
        p.x += 6.0; // "ALL ARITHMETIC TRUTHS"
        int chars[24];
        chars = int[24](65,76,76,32,65,82,73,84,72,77,69,84,73,67,32,84,82,85,84,72,83,32,32,32);
        for (int i = 0; i < 24; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    } else if (line == 4) {
        d = 1e5; // spacer
    } else if (line == 5) {
        p.x += 5.0; // "INCOMPLETENESS II"
        int chars[20];
        chars = int[20](73,78,67,79,77,80,76,69,84,69,78,69,83,83,32,73,73,32,32,32);
        for (int i = 0; i < 20; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    } else if (line == 6) {
        p.x += 5.2; // "NO CONSISTENT SYSTEM"
        int chars[22];
        chars = int[22](78,79,32,67,79,78,83,73,83,84,69,78,84,32,83,89,83,84,69,77,32,32);
        for (int i = 0; i < 22; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    } else if (line == 7) {
        p.x += 7.0; // "PROVES ITS OWN CONSISTENCY"
        int chars[29];
        chars = int[29](80,82,79,86,69,83,32,73,84,83,32,79,87,78,32,67,79,78,83,73,83,84,69,78,67,89,32,32,32);
        for (int i = 0; i < 29; ++i) { d = min(d, glyph(p, chars[i])); p.x -= adv; }
    }
    return d;
}

float getText(vec2 p) {
    // float d = 1e5;
    // for (int i = 0; i < 8; ++i) {
    //     vec2 lp = p;
    //     lp.y -= float(i) * 0.8;
    //     d = min(d, renderLine(lp, i));
    // }
    // return d;
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

vec3 getPlaneColor(vec2 p, float textScale, bool revealText) {
    // Checkerboard pattern
    float checkerSize = 0.5;
    vec2 checker = floor(p / checkerSize);
    float checkerPattern = mod(checker.x + checker.y, 2.0);
    vec3 col = mix(vec3(0.6), vec3(1.0), checkerPattern); // alternate between gray and white
    
    if (revealText) {
        vec2 tp = p * textScale;
        float d = getText(tp);
        float textAlpha = smoothstep(0.05, 0.04, d);
        col = mix(col, vec3(0.1), textAlpha); // ink
    }
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

// Raymarch to plane y=0 using sphere tracing (more robust at grazing angles)
float marchToPlane(vec3 ro, vec3 rd, float eps, float tmax) {
    float t = 0.0;
    for (int i = 0; i < 64; ++i) {
        float h = ro.y + t * rd.y; // signed distance to plane y=0
        float d = abs(h);
        if (d < eps) return t;
        t += max(d, 0.001);
        if (t > tmax) break;
    }
    return -1.0;
}





// =============== RENDERING HELPERS ===============
vec3 getRayDir(vec2 uv, vec3 ro, vec3 ta, float zoom) {
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0)) );
    vec3 vv = normalize( cross(uu,ww));
    return normalize( uv.x*uu + uv.y*vv + zoom*ww );
}

vec3 evalDiffuse(vec3 normal, DirLight lights[NUM_LIGHTS]) {
    vec3 accum = vec3(0.0);
    for (int i = 0; i < NUM_LIGHTS; ++i) {
        float ndotl = max(dot(normal, -lights[i].dir), 0.0);
        accum += lights[i].color * ndotl;
    }
    return accum;
}

vec3 evalSpecular(vec3 normal, vec3 viewDir, DirLight lights[NUM_LIGHTS], float shininess) {
    vec3 accum = vec3(0.0);
    for (int i = 0; i < NUM_LIGHTS; ++i) {
        vec3 r = reflect(lights[i].dir, normal);
        float spec = pow(max(dot(r, viewDir), 0.0), shininess);
        accum += lights[i].color * spec;
    }
    return accum;
}

// Soft shadow from pill onto the plane (sun light only)
float softShadow(vec3 ro, vec3 rd, vec3 pillPos, vec4 pillParams) {
    float t = 0.02;
    float res = 1.0;
    for (int i = 0; i < 40; ++i) {
        vec3 p = ro + rd * t;
        float h = map(p, pillPos, pillParams);
        if (h < 0.0005) return 0.0;
        res = min(res, 10.0 * h / t);
        t += clamp(h, 0.01, 0.3);
        if (t > 10.0) break;
    }
    return clamp(res, 0.0, 1.0);
}

void accumulateBulb(vec3 p, vec3 viewDir, vec3 n, vec3 pos, vec3 color, inout vec3 diffuse, inout vec3 specAcc) {
    vec3 lb = pos - p;
    float lbDist = length(lb);
    vec3 lbDir = lb / max(lbDist, 1e-3);
    float bulbAtt = 1.0 / (1.0 + 0.45 * lbDist + 0.1 * lbDist * lbDist);
    float bulbDiff = max(dot(n, lbDir), 0.0);
    diffuse += color * bulbDiff * bulbAtt;
    specAcc += color * pow(max(dot(reflect(-lbDir, n), viewDir), 0.0), 32.0) * bulbAtt;
}

vec3 bulbDiffuse(vec3 p, vec3 n) {
    vec3 diff = vec3(0.0);
    // Orange bulb
    {
        vec3 lb = bulbPosOrange - p;
        float lbDist = length(lb);
        vec3 lbDir = lb / max(lbDist, 1e-3);
        float bulbAtt = 1.0 / (1.0 + 0.45 * lbDist + 0.1 * lbDist * lbDist);
        diff += bulbColorOrange * max(dot(n, lbDir), 0.0) * bulbAtt;
    }
    // Blue bulb
    {
        vec3 lb = bulbPosBlue - p;
        float lbDist = length(lb);
        vec3 lbDir = lb / max(lbDist, 1e-3);
        float bulbAtt = 1.0 / (1.0 + 0.45 * lbDist + 0.1 * lbDist * lbDist);
        diff += bulbColorBlue * max(dot(n, lbDir), 0.0) * bulbAtt;
    }
    return diff;
}

// Simple forward-scatter term: stronger when view aligns with light direction, attenuated by distance
vec3 bulbScatter(vec3 p, vec3 viewDir) {
    vec3 scatter = vec3(0.0);
    // Orange bulb
    {
        vec3 toL = normalize(bulbPosOrange - p);
        float dist = length(bulbPosOrange - p);
        float phase = pow(max(dot(toL, -viewDir), 0.0), 3.0);
        float att = 1.0 / (1.0 + 0.35 * dist + 0.08 * dist * dist);
        scatter += bulbColorOrange * phase * att;
    }
    // Blue bulb
    {
        vec3 toL = normalize(bulbPosBlue - p);
        float dist = length(bulbPosBlue - p);
        float phase = pow(max(dot(toL, -viewDir), 0.0), 3.0);
        float att = 1.0 / (1.0 + 0.35 * dist + 0.08 * dist * dist);
        scatter += bulbColorBlue * phase * att;
    }
    return scatter;
}

vec3 shadePlane(vec3 p, vec3 viewDir, float textScale, bool revealText, DirLight lights[NUM_LIGHTS], vec3 pillPos, vec4 pillParams, bool flipX, bool flipY) {
    vec2 uv = p.xz;
    if (flipX) uv.x = -uv.x;
    if (flipY) uv.y = -uv.y; // fix upside-down text in reflections
    vec3 base = getPlaneColor(uv, textScale, revealText);
    vec3 n = vec3(0.0, 1.0, 0.0);
    // Shadow only from the sun (light 0)
    float sunShadow = softShadow(p + n * 0.01, -lights[0].dir, pillPos, pillParams);
    vec3 diffuse = lights[0].color * max(dot(n, -lights[0].dir), 0.0) * sunShadow;
    for (int i = 1; i < NUM_LIGHTS; ++i) {
        diffuse += lights[i].color * max(dot(n, -lights[i].dir), 0.0);
    }
    vec3 bulbSpec = vec3(0.0);
    accumulateBulb(p, viewDir, n, bulbPosOrange, bulbColorOrange, diffuse, bulbSpec);
    accumulateBulb(p, viewDir, n, bulbPosBlue, bulbColorBlue, diffuse, bulbSpec);
    vec3 spec = evalSpecular(n, viewDir, lights, 32.0);
    // Keep more of the base checkerboard pattern visible by using additive lighting instead of multiplicative
    return base * (0.6 + diffuse * 0.4) + spec * 0.05 + bulbSpec * 0.3;
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

vec3 renderBackground(vec3 ro, vec3 rd, vec3 pillPos, vec4 pillParams, float textScale, DirLight lights[NUM_LIGHTS]) {
    float t_plane = intersectPlane(ro, rd, 0.0);
    if (t_plane > 0.0) {
        vec3 p_plane = ro + t_plane * rd;
        vec3 col = shadePlane(p_plane, normalize(-rd), textScale, true, lights, pillPos, pillParams, false, false);
        return col;
    }
    return vec3(0.9);
}

vec3 renderGlass(vec3 ro, vec3 rd, float t, vec3 pillPos, vec4 pillParams, float glassIOR, vec3 glassTint, float textScale, vec3 envColor, vec3 absorbCoeff, float dispersion, DirLight lights[NUM_LIGHTS]) {
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
    // Per-channel dispersion for exit direction
    float iorR = glassIOR * (1.0 - dispersion);
    float iorG = glassIOR;
    float iorB = glassIOR * (1.0 + dispersion);
    vec3 rd_out_r = refract(rd_in, -n_out, iorR);
    vec3 rd_out_g = refract(rd_in, -n_out, iorG);
    vec3 rd_out_b = refract(rd_in, -n_out, iorB);
    if (length(rd_out_r)==0.0) rd_out_r = reflect(rd_in, -n_out);
    if (length(rd_out_g)==0.0) rd_out_g = reflect(rd_in, -n_out);
    if (length(rd_out_b)==0.0) rd_out_b = reflect(rd_in, -n_out);

    // Helper: manual inline to avoid GLSL lambda (uses raymarch to plane)
    vec3 col;
    for (int channel = 0; channel < 3; ++channel) {
        vec3 rayOrigin = p_in;
        vec3 rayDir = channel == 0 ? rd_out_r : (channel == 1 ? rd_out_g : rd_out_b);
        vec3 c = envColor * (0.2 + evalDiffuse(vec3(0.0, 1.0, 0.0), lights)); // light the env fallback a bit
        c += bulbDiffuse(rayOrigin, vec3(0.0, 1.0, 0.0)); // let bulbs tint fallback/reflection
        for (int bounce = 0; bounce < 8; ++bounce) {
            float t_plane = marchToPlane(rayOrigin, rayDir, 0.0005, 30.0);
            if (t_plane > 0.0) {
                vec3 p_plane = rayOrigin + t_plane * rayDir;
                bool flipX = bounce > 0; // reflections mirror X
                bool flipY = bounce % 2 == 0; // and also invert Y causing upside-down text
                c = shadePlane(p_plane, normalize(-rayDir), textScale, true, lights, pillPos, pillParams, flipX, flipY);
                break;
            }
            rayDir = reflect(rayDir, -n_out);
            rayOrigin += rayDir * 0.01; // small offset to avoid self-intersection
        }
        // Apply internal scattering inside glass (forward scatter along refracted path)
        c += bulbScatter(p_in, rayDir) * glassTint * 0.15;
        
        if (channel == 0) col.r = c.r;
        else if (channel == 1) col.g = c.g;
        else col.b = c.b;
    }
    
    // Beer-Lambert absorption based on distance traveled inside (apply to refracted content only)
    vec3 absorb = exp(-absorbCoeff * t_in);
    col *= absorb * glassTint;
    
    // Add a base glass tint/color so it's not fully transparent when far from text
    // This simulates internal reflections and slight opacity of real glass
    float glassOpacity = 0.08; // subtle base opacity
    vec3 glassBaseColor = glassTint * 0.95;
    col = mix(col, glassBaseColor, glassOpacity);

    // Fresnel reflection: sample the plane via a reflected ray so text appears in the glass
    float fresnelBase = 1.0 + dot(rd, n);
    float fre = pow(clamp(fresnelBase, 0.0, 1.0), 5.0);
    // Add a minimum fresnel so glass edges are always slightly visible
    fre = mix(0.04, 1.0, fre); // Schlick's approximation base reflectance ~0.04 for glass
    
    vec3 rd_reflect = reflect(rd, n);
    vec3 reflCol = envColor;
    float t_refl = marchToPlane(p + rd_reflect * 0.01, rd_reflect, 0.0005, 30.0);
    if (t_refl > 0.0) {
        vec3 p_refl = p + rd_reflect * t_refl;
        reflCol = shadePlane(p_refl, normalize(-rd_reflect), textScale, true, lights, pillPos, pillParams, true, false); // mirror X in reflection
    }
    
    // Compute all specular highlights before mixing with Fresnel reflection
    vec3 specHighlights = vec3(0.0);
    
    // Multi-light specular on glass (enhanced sun visibility)
    vec3 spec = evalSpecular(n, -rd, lights, 32.0);
    specHighlights += spec * 0.6;
    
    // Add bright sun highlight (high shininess for sharp reflection)
    vec3 sunRefl = reflect(lights[0].dir, n);
    float sunSpec = pow(max(dot(sunRefl, -rd), 0.0), 128.0);
    specHighlights += lights[0].color * sunSpec * 1.5;
    
    // Point light specular reflections on glass (visible from distance)
    // Orange bulb specular
    {
        vec3 toOrange = normalize(bulbPosOrange - p);
        vec3 reflOrange = reflect(-toOrange, n);
        float specOrange = pow(max(dot(reflOrange, -rd), 0.0), 64.0);
        float distOrange = length(bulbPosOrange - p);
        float attOrange = 1.0 / (1.0 + 0.2 * distOrange + 0.05 * distOrange * distOrange);
        specHighlights += bulbColorOrange * specOrange * attOrange * 2.0;
    }
    // Blue bulb specular
    {
        vec3 toBlue = normalize(bulbPosBlue - p);
        vec3 reflBlue = reflect(-toBlue, n);
        float specBlue = pow(max(dot(reflBlue, -rd), 0.0), 64.0);
        float distBlue = length(bulbPosBlue - p);
        float attBlue = 1.0 / (1.0 + 0.2 * distBlue + 0.05 * distBlue * distBlue);
        specHighlights += bulbColorBlue * specBlue * attBlue * 2.0;
    }
    
    // Add specular to reflection color for proper rim blending
    reflCol += specHighlights;
    
    // Smooth Fresnel blend between refracted content and reflection+specular
    col = mix(col, reflCol, fre);
    
    // Rim lighting effect - enhance edges of glass
    // float rim = pow(1.0 - max(dot(-rd, n), 0.0), 3.0);
    // col += vec3(0.15) * rim * 0.5;
    
    // // Gold glow at the bottom of the glass
    // // Calculate how much this point is at the bottom edge of the pill
    // vec3 localP = p - pillPos;
    // float bottomness = 1.0 - smoothstep(-0.05, 0.15, localP.y); // stronger near bottom
    // float edgeFactor = pow(1.0 - abs(dot(-rd, n)), 2.0); // stronger at edges
    // vec3 goldColor = vec3(1.0, 0.75, 0.3); // warm gold
    // col += goldColor * bottomness * edgeFactor * 0.6;
    return col;
}

void addBulbGlow(vec3 ro, vec3 ta, float camZoom, vec2 fragCoord, vec3 bulbPos, vec3 bulbColor, vec3 ww, vec3 uu, vec3 vv, inout vec3 col, float phase, float speed) {
    vec3 rel = bulbPos - ro;
    float depth = dot(rel, ww);
    if (depth > 0.0) {
        vec2 bulbProj = vec2(dot(rel, uu), dot(rel, vv)) / (depth * camZoom);
        vec2 pixUV = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
        float r2 = dot(pixUV - bulbProj, pixUV - bulbProj);
        // Time-based pulsing glow with adjustable speed
        float pulse = 0.85 + 0.15 * sin(iTime * speed + phase);
        float glowCore = exp(-r2 / (2.0 * 0.04 * 0.04));
        float glowBloom = exp(-r2 / (2.0 * 0.12 * 0.12));
        col += bulbColor * pulse * (glowCore * 1.2 + glowBloom * 0.7);
    }
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
    vec3 envColor = vec3(0.9); // Environment color used when rays miss the plane
    vec3 absorbCoeff = vec3(0.20, 0.25, 0.27); // Beer-Lambert per-channel absorption
    float dispersion = 0.01; // Chromatic dispersion amount

    // Lighting: sun + two colored lamps + soft red sun fill
    DirLight lights[NUM_LIGHTS];
    lights[0] = DirLight(normalize(vec3(0.15, -1.0, 0.1)), vec3(1.0, 0.97, 0.9));  // warm sun
    lights[1] = DirLight(normalize(vec3(-0.6, -1.0, -0.2)), vec3(0.45, 0.65, 1.1)); // cool blue lamp
    lights[2] = DirLight(normalize(vec3(0.7, -0.7, 0.6)), vec3(1.1, 0.7, 0.35));    // orange lamp
    lights[3] = DirLight(normalize(vec3(-0.25, -1.0, 0.3)), vec3(0.8, 0.25, 0.25)); // soft red sun fill
    
    // Text
    float textScale = 2.5;
    
    // Bulb Glow Animation
    float glowPulseSpeed = 1.0; // controls how fast bulbs pulse (lower = slower)
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
    vec3 col;
    if (hitPill) {
        col = renderGlass(ro, rd, t, pillPos, pillParams, glassIOR, glassTint, textScale, envColor, absorbCoeff, dispersion, lights);
    } else {
        col = renderBackground(ro, rd, pillPos, pillParams, textScale, lights);
    }

    // Screen-space glow for the bulb
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    addBulbGlow(ro, ta, camZoom, fragCoord, bulbPosOrange, bulbColorOrange, ww, uu, vv, col, 0.0, glowPulseSpeed);
    addBulbGlow(ro, ta, camZoom, fragCoord, bulbPosBlue, bulbColorBlue, ww, uu, vv, col, 3.14159, glowPulseSpeed);
    
    // Vignette
    col *= 1.0 - 0.2 * length(uv);

    fragColor = vec4(col, 1.0);
}


//TODO make complex shapes 3D with smooth Union or liquid sim OR complex glass shape with reflexions