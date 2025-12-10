// =============== SDF OPERATORS ===============
float dot2( in vec3 v ) { return dot(v,v); }

// Smooth minimum for organic blending
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Smooth maximum
float smax(float a, float b, float k) {
    return -smin(-a, -b, k);
}

// 3D SDFs
float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdEllipsoid(vec3 p, vec3 r) {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

float sdTorus(vec3 p, vec2 t) {
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCappedTorus(vec3 p, vec2 sc, float ra, float rb) {
    p.x = abs(p.x);
    float k = (sc.y * p.x > sc.x * p.y) ? dot(p.xy, sc) : length(p.xy);
    return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

float sdRoundCone(vec3 p, float r1, float r2, float h) {
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    vec2 q = vec2(length(p.xz), p.y);
    float k = dot(q, vec2(-b, a));
    if (k < 0.0) return length(q) - r1;
    if (k > a * h) return length(q - vec2(0.0, h)) - r2;
    return dot(q, vec2(a, b)) - r1;
}

float sdOctahedron(vec3 p, float s) {
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    vec3 q;
    if (3.0 * p.x < m) q = p.xyz;
    else if (3.0 * p.y < m) q = p.yzx;
    else if (3.0 * p.z < m) q = p.zxy;
    else return m * 0.57735027;
    float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
    return length(vec3(q.x, q.y - s + k, q.z - k));
}

// Rotation matrices
mat3 rotateX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

mat3 rotateY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotateZ(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, -s, 0, s, c, 0, 0, 0, 1);
}

// =============== LIGHTING ===============
#define NUM_LIGHTS 6
struct DirLight {
    vec3 dir;   // direction pointing from light toward the scene
    vec3 color; // light radiance/tint
};

// Point bulbs - repositioned to better illuminate the sculpture
#define NUM_BULBS 4
const vec3 bulbPositions[NUM_BULBS] = vec3[](
    vec3(1.8, 0.6, 1.2),    // warm orange - front right
    vec3(-1.6, 1.4, -1.0),  // cool blue - back left high
    vec3(-1.2, 0.3, 1.5),   // magenta/pink - front left low
    vec3(1.0, 1.8, -0.5)    // cyan - top right back
);
const vec3 bulbColors[NUM_BULBS] = vec3[](
    vec3(1.0, 0.55, 0.2),   // warm orange
    vec3(0.15, 0.35, 1.4),  // bright blue
    vec3(1.0, 0.3, 0.7),    // magenta/pink
    vec3(0.2, 0.9, 0.9)     // cyan
);

// Legacy aliases for compatibility
const vec3 bulbPosOrange = vec3(1.8, 0.6, 1.2);
const vec3 bulbColorOrange = vec3(1.0, 0.55, 0.2);
const vec3 bulbPosBlue = vec3(-1.6, 1.4, -1.0);
const vec3 bulbColorBlue = vec3(0.15, 0.35, 1.4);

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
    // Enhanced checkerboard with anti-aliasing (fixes grain on integrated graphics)
    float checkerSize = 0.4;
    
    // Anti-aliased checkerboard using fwidth
    vec2 uv = p / checkerSize;
    vec2 w = fwidth(uv) + 0.001; // derivative for AA, small bias to avoid division issues
    vec2 i = 2.0 * (abs(fract((uv - 0.5 * w) * 0.5) - 0.5) - abs(fract((uv + 0.5 * w) * 0.5) - 0.5)) / w;
    float checkerPattern = 0.5 - 0.5 * i.x * i.y; // smooth 0-1 transition
    
    // Add subtle color variation based on position
    float distFromCenter = length(p) * 0.08;
    vec3 lightColor = mix(vec3(0.95, 0.96, 0.98), vec3(0.88, 0.90, 0.93), clamp(distFromCenter, 0.0, 1.0));
    vec3 darkColor = mix(vec3(0.52, 0.55, 0.60), vec3(0.45, 0.48, 0.52), clamp(distFromCenter, 0.0, 1.0));
    
    vec3 col = mix(darkColor, lightColor, checkerPattern);
    
    // Add subtle radial gradient for depth
    float radialGrad = 1.0 - smoothstep(0.0, 10.0, length(p));
    col = mix(col * 0.82, col, radialGrad);
    
    if (revealText) {
        vec2 tp = p * textScale;
        float d = getText(tp);
        // Anti-aliased text edges
        float textW = fwidth(d) * 1.5;
        float textAlpha = smoothstep(0.05 + textW, 0.04 - textW, d);
        col = mix(col, vec3(0.06), textAlpha); // darker ink
    }
    return col;
}

// =============== 3D SCENE ===============
// Complex organic glass sculpture SDF - liquid crystal form
float mapSculpture(vec3 p, vec3 sculpturePos, float time) {
    vec3 q = p - sculpturePos;
    
    // Animate with gentle organic motion
    float pulse = sin(time * 0.5) * 0.04;
    float wave = sin(time * 0.3) * 0.08;
    float breathe = sin(time * 0.25) * 0.03;
    
    // === CENTRAL CORE - twisted ellipsoid ===
    vec3 coreP = q;
    // Add twist based on height
    float twistAmount = coreP.y * 0.8 + time * 0.2;
    coreP.xz = mat2(cos(twistAmount), -sin(twistAmount), sin(twistAmount), cos(twistAmount)) * coreP.xz;
    coreP.y *= 1.6;
    float core = sdSphere(coreP, 0.32 + pulse + breathe);
    
    // === FLOWING RIBBONS - wrap around the core ===
    float ribbons = 1e5;
    for (int i = 0; i < 4; i++) {
        float ribbonAngle = float(i) * 1.5708 + time * 0.15; // π/2
        float heightPhase = sin(float(i) * 1.2 + time * 0.5) * 0.2;
        
        vec3 ribbonP = q;
        ribbonP = rotateY(ribbonAngle) * ribbonP;
        
        // Helix path
        float helixAngle = ribbonP.y * 3.0 + ribbonAngle + time * 0.3;
        float helixRadius = 0.35 + sin(ribbonP.y * 4.0 + time) * 0.05;
        vec3 helixOffset = vec3(cos(helixAngle) * helixRadius, 0.0, sin(helixAngle) * helixRadius);
        ribbonP -= helixOffset;
        
        // Ribbon cross-section (flattened)
        ribbonP.x *= 2.5;
        float ribbon = sdSphere(ribbonP, 0.08);
        
        ribbons = smin(ribbons, ribbon, 0.12);
    }
    
    // === ORBITING DROPLETS - like mercury drops ===
    float drops = 1e5;
    for (int i = 0; i < 5; i++) {
        float dropAngle = float(i) * 1.2566 + time * 0.4; // 2π/5
        float dropOrbit = 0.55 + sin(time * 0.6 + float(i) * 0.8) * 0.12;
        float dropY = sin(time * 0.5 + float(i) * 1.3) * 0.25 + cos(time * 0.35 + float(i)) * 0.1;
        
        vec3 dropPos = vec3(cos(dropAngle) * dropOrbit, dropY, sin(dropAngle) * dropOrbit);
        
        // Teardrop shape - stretched sphere
        vec3 dropP = q - dropPos;
        float dropSpeed = length(vec3(cos(dropAngle + 0.1) - cos(dropAngle), 0.0, sin(dropAngle + 0.1) - sin(dropAngle)));
        dropP.y += dropP.y * dropP.y * 0.5; // elongate downward
        float dropSize = 0.09 + sin(time * 1.2 + float(i) * 2.5) * 0.025;
        float drop = sdSphere(dropP, dropSize);
        
        // Add connecting tendril to core
        vec3 tendrilP = q - dropPos * 0.5;
        float tendril = sdSphere(tendrilP * vec3(1.0, 2.5, 1.0), 0.04);
        drop = smin(drop, tendril, 0.15);
        
        drops = smin(drops, drop, 0.18);
    }
    
    // === CROWN - blooming lotus-like top ===
    vec3 crownP = q - vec3(0.0, 0.38 + breathe, 0.0);
    float crown = 1e5;
    for (int i = 0; i < 8; i++) {
        float petalAngle = float(i) * 0.7854 + time * 0.08; // π/4
        float petalOpen = 0.3 + sin(time * 0.4 + float(i) * 0.5) * 0.1;
        
        vec3 petalP = rotateY(petalAngle) * crownP;
        petalP = rotateZ(petalOpen) * petalP; // petals open outward
        petalP.x -= 0.15;
        
        // Curved petal shape
        petalP.y *= 1.8;
        petalP.z *= 2.5;
        float petal = sdEllipsoid(petalP, vec3(0.12, 0.08, 0.04));
        
        crown = smin(crown, petal, 0.1);
    }
    
    // === BASE - dripping stalactite ===
    vec3 baseP = q + vec3(0.0, 0.35, 0.0);
    baseP.y = -baseP.y;
    
    // Main drop
    float baseDrop = sdRoundCone(baseP, 0.18, 0.03, 0.35);
    
    // Smaller drips
    float drips = 1e5;
    for (int i = 0; i < 3; i++) {
        float dripAngle = float(i) * 2.094 + 0.5; // 2π/3
        vec3 dripP = baseP - vec3(cos(dripAngle) * 0.12, -0.1, sin(dripAngle) * 0.12);
        float dripLen = 0.15 + sin(time + float(i)) * 0.05;
        float drip = sdRoundCone(dripP, 0.05, 0.015, dripLen);
        drips = smin(drips, drip, 0.08);
    }
    baseDrop = smin(baseDrop, drips, 0.1);
    
    // === TORUS RINGS - floating halos ===
    float rings = 1e5;
    for (int i = 0; i < 2; i++) {
        float ringY = float(i) * 0.4 - 0.15 + sin(time * 0.6 + float(i) * 2.0) * 0.08;
        float ringTilt = 0.15 + sin(time * 0.4 + float(i)) * 0.1;
        float ringSize = 0.42 - float(i) * 0.08 + pulse;
        
        vec3 ringP = q - vec3(0.0, ringY, 0.0);
        ringP = rotateX(ringTilt) * ringP;
        ringP = rotateZ(sin(time * 0.3) * 0.1) * ringP;
        
        float ring = sdTorus(ringP, vec2(ringSize, 0.025 + float(i) * 0.01));
        rings = smin(rings, ring, 0.08);
    }
    
    // === INNER VOID - hollow core for complex refraction ===
    vec3 voidP = q;
    voidP.y *= 1.3;
    float innerVoid = sdSphere(voidP, 0.12 + sin(time * 0.8) * 0.02);
    
    // Secondary void - creates light channels
    vec3 channelP = q;
    channelP = rotateY(time * 0.1) * channelP;
    float channels = 1e5;
    for (int i = 0; i < 3; i++) {
        float chAngle = float(i) * 2.094;
        vec3 chP = rotateY(chAngle) * channelP;
        chP.x -= 0.15;
        float ch = sdSphere(chP * vec3(1.0, 3.0, 1.0), 0.04);
        channels = min(channels, ch);
    }
    innerVoid = smin(innerVoid, channels, 0.05);
    
    // === COMBINE ALL ELEMENTS ===
    float d = core;
    d = smin(d, ribbons, 0.15);
    d = smin(d, drops, 0.2);
    d = smin(d, crown, 0.12);
    d = smin(d, baseDrop, 0.15);
    d = smin(d, rings, 0.1);
    
    // Subtract inner void
    d = smax(d, -innerVoid, 0.06);
    
    return d;
}

float map(vec3 p, vec3 sculpturePos, vec4 unusedParams) {
    return mapSculpture(p, sculpturePos, iTime);
}

vec3 calcNormal( in vec3 p, vec3 sculpturePos, vec4 unused )
{
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*mapSculpture( p + k.xyy*h, sculpturePos, iTime ) + 
                      k.yyx*mapSculpture( p + k.yyx*h, sculpturePos, iTime ) + 
                      k.yxy*mapSculpture( p + k.yxy*h, sculpturePos, iTime ) + 
                      k.xxx*mapSculpture( p + k.xxx*h, sculpturePos, iTime ) );
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

// Soft shadow from sculpture onto the plane
float softShadow(vec3 ro, vec3 rd, vec3 sculpturePos, vec4 sculptureParams) {
    float t = 0.05;
    float res = 1.0;
    for (int i = 0; i < 48; ++i) {
        vec3 p = ro + rd * t;
        float h = mapSculpture(p, sculpturePos, iTime);
        if (h < 0.001) return 0.0;
        res = min(res, 12.0 * h / t);
        t += clamp(h, 0.02, 0.25);
        if (t > 8.0) break;
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
    // Loop through all point lights
    for (int i = 0; i < NUM_BULBS; i++) {
        vec3 lb = bulbPositions[i] - p;
        float lbDist = length(lb);
        vec3 lbDir = lb / max(lbDist, 1e-3);
        float bulbAtt = 1.0 / (1.0 + 0.35 * lbDist + 0.08 * lbDist * lbDist);
        diff += bulbColors[i] * max(dot(n, lbDir), 0.0) * bulbAtt;
    }
    return diff;
}

// Simple forward-scatter term: stronger when view aligns with light direction, attenuated by distance
vec3 bulbScatter(vec3 p, vec3 viewDir) {
    vec3 scatter = vec3(0.0);
    for (int i = 0; i < NUM_BULBS; i++) {
        vec3 toL = normalize(bulbPositions[i] - p);
        float dist = length(bulbPositions[i] - p);
        float phase = pow(max(dot(toL, -viewDir), 0.0), 3.0);
        float att = 1.0 / (1.0 + 0.3 * dist + 0.06 * dist * dist);
        scatter += bulbColors[i] * phase * att * 0.8;
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
    // Accumulate all point lights
    for (int i = 0; i < NUM_BULBS; i++) {
        accumulateBulb(p, viewDir, n, bulbPositions[i], bulbColors[i], diffuse, bulbSpec);
    }
    vec3 spec = evalSpecular(n, viewDir, lights, 32.0);
    // Keep more of the base checkerboard pattern visible
    return base * (0.55 + diffuse * 0.45) + spec * 0.06 + bulbSpec * 0.25;
}

bool castRay(vec3 ro, vec3 rd, vec3 sculpturePos, vec4 sculptureParams, out float t) {
    t = 0.0;
    float tmax = 25.0;
    for(int i=0; i<128; i++) {
        vec3 p = ro + t*rd;
        float d = mapSculpture(p, sculpturePos, iTime);
        if(d < 0.0005) return true;
        t += d * 0.8; // slightly conservative step for complex shapes
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

vec3 renderGlass(vec3 ro, vec3 rd, float t, vec3 sculpturePos, vec4 sculptureParams, float glassIOR, vec3 glassTint, float textScale, vec3 envColor, vec3 absorbCoeff, float dispersion, DirLight lights[NUM_LIGHTS]) {
    vec3 p = ro + t*rd;
    vec3 n = calcNormal(p, sculpturePos, sculptureParams);
    vec3 rd_in = refract(rd, n, 1.0/glassIOR);
    
    // If total internal reflection at entry (shouldn't happen but safety)
    if (length(rd_in) == 0.0) rd_in = reflect(rd, n);
    
    // March through the glass interior
    float t_in = 0.02; 
    vec3 p_in = p;
    float totalDist = 0.0;
    for(int i=0; i<96; i++) {
        p_in = p + t_in * rd_in;
        float d_in = mapSculpture(p_in, sculpturePos, iTime);
        if(d_in > -0.0005) break;
        float step = max(abs(d_in), 0.002);
        t_in += step;
        totalDist += step;
        if (t_in > 5.0) break;
    }
    
    vec3 n_out = calcNormal(p_in, sculpturePos, sculptureParams);
    
    // Per-channel dispersion for exit direction (rainbow caustics)
    float iorR = glassIOR * (1.0 - dispersion);
    float iorG = glassIOR;
    float iorB = glassIOR * (1.0 + dispersion);
    vec3 rd_out_r = refract(rd_in, -n_out, iorR);
    vec3 rd_out_g = refract(rd_in, -n_out, iorG);
    vec3 rd_out_b = refract(rd_in, -n_out, iorB);
    
    // Handle total internal reflection per channel
    if (length(rd_out_r)==0.0) rd_out_r = reflect(rd_in, -n_out);
    if (length(rd_out_g)==0.0) rd_out_g = reflect(rd_in, -n_out);
    if (length(rd_out_b)==0.0) rd_out_b = reflect(rd_in, -n_out);

    // Sample background for each color channel (chromatic dispersion)
    vec3 col;
    for (int channel = 0; channel < 3; ++channel) {
        vec3 rayOrigin = p_in;
        vec3 rayDir = channel == 0 ? rd_out_r : (channel == 1 ? rd_out_g : rd_out_b);
        vec3 c = envColor * (0.3 + evalDiffuse(vec3(0.0, 1.0, 0.0), lights) * 0.5);
        
        // Try to hit the floor plane - use analytic intersection (cleaner, faster)
        float t_plane = intersectPlane(rayOrigin, rayDir, 0.0);
        if (t_plane > 0.0) {
            vec3 p_plane = rayOrigin + t_plane * rayDir;
            c = shadePlane(p_plane, normalize(-rayDir), textScale, true, lights, sculpturePos, sculptureParams, false, false);
        }
        
        // Add caustic-like patterns from internal bounces
        c += bulbScatter(p_in, rayDir) * glassTint * 0.25;
        
        if (channel == 0) col.r = c.r;
        else if (channel == 1) col.g = c.g;
        else col.b = c.b;
    }
    
    // Beer-Lambert absorption - more dramatic for complex shapes
    vec3 absorb = exp(-absorbCoeff * totalDist * 2.0);
    col *= absorb * glassTint;
    
    // Internal glow effect - simulates subsurface scattering
    vec3 sss = vec3(0.1, 0.15, 0.2) * (1.0 - exp(-totalDist * 3.0));
    col += sss * glassTint;
    
    // Fresnel reflection
    float fresnelBase = 1.0 + dot(rd, n);
    float fre = pow(clamp(fresnelBase, 0.0, 1.0), 4.0);
    fre = mix(0.06, 1.0, fre);
    
    // Sample reflection
    vec3 rd_reflect = reflect(rd, n);
    vec3 reflCol = envColor;
    
    // Check if reflection hits the floor - use analytic intersection
    float t_refl = intersectPlane(p + rd_reflect * 0.02, rd_reflect, 0.0);
    if (t_refl > 0.0) {
        vec3 p_refl = p + rd_reflect * t_refl;
        reflCol = shadePlane(p_refl, normalize(-rd_reflect), textScale, true, lights, sculpturePos, sculptureParams, false, false);
    } else {
        // Sky gradient for upward reflections - more colorful
        float skyGrad = rd_reflect.y * 0.5 + 0.5;
        vec3 horizonCol = vec3(0.7, 0.75, 0.85);
        vec3 zenithCol = vec3(0.25, 0.45, 0.8);
        reflCol = mix(horizonCol, zenithCol, pow(skyGrad, 1.5));
        // Add subtle sun reflection in sky
        float sunDot = max(dot(rd_reflect, -lights[0].dir), 0.0);
        reflCol += lights[0].color * pow(sunDot, 32.0) * 0.5;
    }
    
    // Specular highlights
    vec3 specHighlights = vec3(0.0);
    
    // Multi-light specular
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lightRefl = reflect(lights[i].dir, n);
        float spec = pow(max(dot(lightRefl, -rd), 0.0), 64.0);
        specHighlights += lights[i].color * spec * 0.8;
    }
    
    // Sharp sun highlight
    vec3 sunRefl = reflect(lights[0].dir, n);
    float sunSpec = pow(max(dot(sunRefl, -rd), 0.0), 256.0);
    specHighlights += lights[0].color * sunSpec * 2.5;
    
    // Point light specular - loop through all bulbs
    for (int i = 0; i < NUM_BULBS; i++) {
        vec3 toBulb = normalize(bulbPositions[i] - p);
        vec3 reflBulb = reflect(-toBulb, n);
        float specBulb = pow(max(dot(reflBulb, -rd), 0.0), 64.0);
        float distBulb = length(bulbPositions[i] - p);
        float attBulb = 1.0 / (1.0 + 0.12 * distBulb + 0.025 * distBulb * distBulb);
        specHighlights += bulbColors[i] * specBulb * attBulb * 1.2;
    }
    
    reflCol += specHighlights;
    
    // Fresnel blend
    col = mix(col, reflCol, fre);
    
    // Edge highlight (rim lighting)
    float rim = pow(1.0 - max(dot(-rd, n), 0.0), 3.0);
    col += vec3(0.3, 0.35, 0.4) * rim * 0.4;
    
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
    // Camera - pulled back to see the sculpture
    vec3 camPos = vec3(0.0, 1.5, 3.0);
    float camZoom = 1.8;
  
    // Sculpture position
    float sculptureHeight = 0.5;
    vec4 sculptureParams = vec4(1.0); // unused but kept for compatibility
    
    // Glass Look - enhanced for complex sculpture
    float glassIOR = 1.45; // slightly lower for more dramatic refraction
    vec3 glassTint = vec3(0.92, 0.95, 1.0); // slight blue tint
    vec3 envColor = vec3(0.85, 0.88, 0.92);
    vec3 absorbCoeff = vec3(0.15, 0.18, 0.22); // subtle absorption
    float dispersion = 0.025; // more chromatic aberration for rainbow effects

    // Lighting: key + fill + rim + accent lights for dramatic effect
    DirLight lights[NUM_LIGHTS];
    lights[0] = DirLight(normalize(vec3(0.4, -1.0, 0.3)), vec3(1.3, 1.2, 1.05));  // key light - warm sun
    lights[1] = DirLight(normalize(vec3(-0.7, -0.5, -0.4)), vec3(0.25, 0.4, 0.8)); // fill - cool blue
    lights[2] = DirLight(normalize(vec3(0.6, -0.4, 0.8)), vec3(0.85, 0.55, 0.25)); // accent - warm orange
    lights[3] = DirLight(normalize(vec3(-0.4, -0.9, 0.3)), vec3(0.45, 0.2, 0.5));  // accent - purple
    lights[4] = DirLight(normalize(vec3(-0.2, -0.3, -0.9)), vec3(0.2, 0.6, 0.5));  // rim - teal from behind
    lights[5] = DirLight(normalize(vec3(0.9, -0.2, -0.2)), vec3(0.7, 0.3, 0.4));   // side - rose/magenta
    
    // Text
    float textScale = 2.5;
    
    // Bulb Glow Animation
    float glowPulseSpeed = 0.8;
    // ============================================

    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // Camera orbits slowly around the sculpture
    float camAngle = iTime * 0.1;
    vec3 ro = vec3(sin(camAngle) * 3.0, 1.5 + sin(iTime * 0.15) * 0.3, cos(camAngle) * 3.0);
    vec3 ta = vec3(0.0, 0.4, 0.0);
    
    // Mouse control overrides orbit
    if (iMouse.z > 0.0) {
        float mouseX = (iMouse.x / iResolution.x - 0.5) * 6.28;
        float mouseY = (iMouse.y / iResolution.y - 0.5) * 2.0;
        ro = vec3(sin(mouseX) * 3.0, 1.5 + mouseY, cos(mouseX) * 3.0);
    }
    
    vec3 sculpturePos = vec3(0.0, sculptureHeight, 0.0);
    vec3 rd = getRayDir(uv, ro, ta, camZoom);

    // Raymarch
    float t;
    bool hitSculpture = castRay(ro, rd, sculpturePos, sculptureParams, t);
    vec3 col;
    if (hitSculpture) {
        col = renderGlass(ro, rd, t, sculpturePos, sculptureParams, glassIOR, glassTint, textScale, envColor, absorbCoeff, dispersion, lights);
    } else {
        col = renderBackground(ro, rd, sculpturePos, sculptureParams, textScale, lights);
    }

    // Screen-space glow for all bulbs
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    for (int i = 0; i < NUM_BULBS; i++) {
        float phase = float(i) * 1.5708; // π/2 offset per bulb
        addBulbGlow(ro, ta, camZoom, fragCoord, bulbPositions[i], bulbColors[i], ww, uu, vv, col, phase, glowPulseSpeed);
    }
    
    // Subtle vignette
    col *= 1.0 - 0.15 * length(uv);
    
    // Tone mapping for HDR
    col = col / (col + vec3(1.0));
    col = pow(col, vec3(0.95)); // slight gamma adjustment

    fragColor = vec4(col, 1.0);
}