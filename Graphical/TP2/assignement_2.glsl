/*
 * Glass Sculpture & Carousel Shader
 * ==========================================================
 * A vibrant raymarched scene featuring glass sculptures with realistic refraction,
 * chromatic dispersion, a decorative carousel, and a playful animated floor
 *
 * FEATURES:
 * - Rainbow-tinted checkerboard tiles that shift over time
 * - Disco ball reflections with bouncy animated light spots
 * - Multi-colored confetti sparkles in three layers
 * - Dancing rainbow swirls radiating from the center
 * - Colorful twinkling stars with shooting stars across the sky
 * - Shimmering rainbow-gold text that cycles through colors
 *
 * TABLE OF CONTENTS:
 * ------------------
 *   1. SETTINGS (Line ~25)       - All configurable parameters
 *   2. SDF OPERATORS (Line ~95)  - Smooth min/max and primitive SDFs
 *   3. LIGHTING (Line ~130)      - Light structs and global light arrays
 *   4. TEXT RENDERING (Line ~170)- Segment-based character rendering
 *   5. PROCEDURAL NOISE (Line ~440)- Hash, noise, and FBM functions
 *   6. FLOOR PATTERN (Line ~470) - Rainbow tiles, disco ball, sparkles, dancing swirls
 *   7. 3D SHAPES (Line ~580)     - Carousel and glass sculpture SDFs
 *   8. RAYMARCHING (Line ~890)   - Map, normals, ray casting
 *   9. SHADING (Line ~950)       - Diffuse, specular, shadows
 *  10. RENDERING (Line ~1100)    - Background with colorful stars & shooting stars,
 *                                  glass refraction, and main loop
 */

// =====================================================================
//                              SETTINGS
// =====================================================================
// Adjust these values to customize the scene appearance and performance.

// --- Shape Selection ---
// 0 = glass sculpture only
// 1 = carousel only  
// 2 = both shapes side by side
#define SHAPE_MODE 2

// --- Raymarching Quality ---
// Lower values = faster but less accurate; higher = slower but better quality
#define RAYMARCH_STEPS 80           // Primary ray iterations
#define RAYMARCH_MAX_DIST 20.0      // Maximum ray travel distance
#define RAYMARCH_HIT_THRESHOLD 0.0008 // Distance considered a "hit"
#define INTERNAL_STEPS 48           // Iterations inside glass volume
#define SHADOW_STEPS 24             // Shadow ray iterations
#define SHADOW_SOFTNESS 10.0        // Shadow penumbra (higher = softer)

// --- Camera ---
#define CAM_ORBIT_SPEED 0.1         // Auto-orbit speed (0 to disable)
#define CAM_DIST 3.0                // Distance from target
#define CAM_HEIGHT 1.5              // Base camera height
#define CAM_BOB_AMOUNT 0.3          // Vertical oscillation amplitude
#define CAM_BOB_SPEED 0.15          // Vertical oscillation speed
#define CAM_ZOOM 1.8                // Field of view (higher = more zoom)
#define CAM_TARGET vec3(0.0, 0.4, 0.0)

// --- Sculpture ---
#define SCULPTURE_HEIGHT 0.5        // Y position of sculpture center
#define SCULPTURE_SPACING 0.8       // X offset when showing both shapes

// --- Glass Material ---
#define GLASS_IOR 3.45              // Index of refraction (1.0 = no refraction)
#define GLASS_TINT vec3(0.92, 0.95, 1.0)   // Glass color tint
#define GLASS_ABSORB vec3(0.15, 0.18, 0.22) // Absorption coefficient (Beer-Lambert)
#define GLASS_DISPERSION 0.025      // Chromatic aberration strength

// --- Environment ---
#define ENV_COLOR vec3(0.85, 0.88, 0.92)  // Ambient environment color

// --- Text ---
#define TEXT_SCALE 2.5              // Floor text size
#define TEXT_REVEAL true            // Show text on floor

// --- Lighting ---
#define NUM_LIGHTS 6
#define KEY_LIGHT_DIR vec3(0.4, -1.0, 0.3)
#define KEY_LIGHT_COLOR vec3(1.3, 1.2, 1.05)
#define FILL_LIGHT_DIR vec3(-0.7, -0.5, -0.4)
#define FILL_LIGHT_COLOR vec3(0.25, 0.4, 0.8)
#define ACCENT1_LIGHT_DIR vec3(0.6, -0.4, 0.8)
#define ACCENT1_LIGHT_COLOR vec3(0.85, 0.55, 0.25)
#define ACCENT2_LIGHT_DIR vec3(-0.4, -0.9, 0.3)
#define ACCENT2_LIGHT_COLOR vec3(0.45, 0.2, 0.5)
#define RIM_LIGHT_DIR vec3(-0.2, -0.3, -0.9)
#define RIM_LIGHT_COLOR vec3(0.2, 0.6, 0.5)
#define SIDE_LIGHT_DIR vec3(0.9, -0.2, -0.2)
#define SIDE_LIGHT_COLOR vec3(0.7, 0.3, 0.4)

// --- Point Lights (Bulbs) ---
#define NUM_BULBS 4
#define GLOW_PULSE_SPEED 0.8        // Pulsing speed

// --- Post Processing ---
#define VIGNETTE_STRENGTH 0.15      // Edge darkening (0 = none)
#define GAMMA 0.95                  // Gamma correction

// --- Animation Speeds ---
#define CAROUSEL_SPIN_SPEED 0.5     // Carousel rotation speed
#define HORSE_BOB_SPEED 2.0         // Horse up/down speed
#define SCULPTURE_TWIST_SPEED 0.2   // Core twist animation
#define RIBBON_SPEED 0.15           // Ribbon rotation
#define DROPLET_ORBIT_SPEED 0.4     // Orbiting droplets
#define CROWN_ROTATION_SPEED 0.08   // Crown petal rotation
#define RING_WOBBLE_SPEED 0.6       // Torus ring animation


// =====================================================================
//                           SDF OPERATORS
// =====================================================================

// Smooth minimum - blends two SDFs with a smooth transition
// k controls the blend radius (larger k = smoother blend)
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Smooth maximum - inverse of smin, used for subtractive operations
float smax(float a, float b, float k) { return -smin(-a, -b, k); }

// =====================================================================
//                           SDF Primitives
// =====================================================================
// Sphere centered at origin with radius r
float sdSphere(vec3 p, float r) { return length(p) - r; }

// Ellipsoid centered at origin with radii r.xyz
float sdEllipsoid(vec3 p, vec3 r) {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

// Torus: t.x = major radius, t.y = minor radius
float sdTorus(vec3 p, vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

// Rounded cone: r1 = bottom radius, r2 = top radius, h = height
float sdRoundCone(vec3 p, float r1, float r2, float h) {
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    vec2 q = vec2(length(p.xz), p.y);
    float k = dot(q, vec2(-b, a));
    if (k < 0.0) return length(q) - r1;
    if (k > a * h) return length(q - vec2(0.0, h)) - r2;
    return dot(q, vec2(a, b)) - r1;
}

// =====================================================================
//                              LIGHTING
// =====================================================================
// Scene illumination: directional lights (sun, fill) + point lights (bulbs)

// Directional light structure
struct DirLight {
    vec3 dir;   // Direction from light to scene (normalized)
    vec3 color; // Light color/intensity (can be > 1.0 for HDR)
};

// --- Point Light Bulbs ---
// Colored point lights positioned around the scene for dramatic effect
const vec3 bulbPositions[NUM_BULBS] = vec3[](
    vec3(1.8, 0.6, 1.2),   // Bulb 0: front right
    vec3(-1.6, 1.4, -1.0), // Bulb 1: back left (high)
    vec3(-1.2, 0.3, 1.5),  // Bulb 2: front left (low)
    vec3(1.0, 1.8, -0.5)   // Bulb 3: top right back
);
const vec3 bulbColors[NUM_BULBS] = vec3[](
    vec3(1.0, 0.55, 0.2),  // Warm orange
    vec3(0.15, 0.35, 1.4), // Cool blue
    vec3(1.0, 0.3, 0.7),   // Magenta/pink
    vec3(0.2, 0.9, 0.9)    // Cyan
);

// --- Directional Lights Array ---
// Classic 3-point lighting setup extended with accent lights
const DirLight lights[NUM_LIGHTS] = DirLight[](
    DirLight(normalize(vec3(0.4, -1.0, 0.3)), vec3(1.3, 1.2, 1.05)),   // [0] Key: warm sun
    DirLight(normalize(vec3(-0.7, -0.5, -0.4)), vec3(0.25, 0.4, 0.8)), // [1] Fill: cool blue
    DirLight(normalize(vec3(0.6, -0.4, 0.8)), vec3(0.85, 0.55, 0.25)), // [2] Accent: orange
    DirLight(normalize(vec3(-0.4, -0.9, 0.3)), vec3(0.45, 0.2, 0.5)),  // [3] Accent: purple
    DirLight(normalize(vec3(-0.2, -0.3, -0.9)), vec3(0.2, 0.6, 0.5)),  // [4] Rim: teal
    DirLight(normalize(vec3(0.9, -0.2, -0.2)), vec3(0.7, 0.3, 0.4))    // [5] Side: rose
);


// =====================================================================
//                          TEXT RENDERING
// =====================================================================
// Segment-based font rendering for floor text display.

// SDF for a 2D line segment from point a to point b
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// --- Character Definitions ---
// Characters are sized to fit in a ~0.24 x 0.5 bounding box.
float charA(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.25), vec2(0.0, 0.25));
    d = min(d, sdSegment(p, vec2(0.0, 0.25), vec2(0.12, -0.25)));
    d = min(d, sdSegment(p, vec2(-0.08, -0.05), vec2(0.08, -0.05)));
    return d;
}
float charC(vec2 p) {
    float d = sdSegment(p, vec2(0.12, 0.2), vec2(-0.08, 0.25));
    d = min(d, sdSegment(p, vec2(-0.08, 0.25), vec2(-0.12, 0.0)));
    d = min(d, sdSegment(p, vec2(-0.12, 0.0), vec2(-0.08, -0.25)));
    d = min(d, sdSegment(p, vec2(-0.08, -0.25), vec2(0.12, -0.2)));
    return d;
}
float charD(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.25), vec2(-0.12, 0.25));
    d = min(d, sdSegment(p, vec2(-0.12, 0.25), vec2(0.05, 0.2)));
    d = min(d, sdSegment(p, vec2(0.05, 0.2), vec2(0.12, 0.0)));
    d = min(d, sdSegment(p, vec2(0.12, 0.0), vec2(0.05, -0.2)));
    d = min(d, sdSegment(p, vec2(0.05, -0.2), vec2(-0.12, -0.25)));
    return d;
}
float charE(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.25), vec2(-0.12, 0.25));
    d = min(d, sdSegment(p, vec2(-0.12, 0.25), vec2(0.12, 0.25)));
    d = min(d, sdSegment(p, vec2(-0.12, 0.0), vec2(0.08, 0.0)));
    d = min(d, sdSegment(p, vec2(-0.12, -0.25), vec2(0.12, -0.25)));
    return d;
}
float charG(vec2 p) {
    float d = charC(p);
    d = min(d, sdSegment(p, vec2(0.12, -0.2), vec2(0.12, 0.0)));
    d = min(d, sdSegment(p, vec2(0.12, 0.0), vec2(0.02, 0.0)));
    return d;
}
float charH(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.25), vec2(-0.12, 0.25));
    d = min(d, sdSegment(p, vec2(0.12, -0.25), vec2(0.12, 0.25)));
    d = min(d, sdSegment(p, vec2(-0.12, 0.0), vec2(0.12, 0.0)));
    return d;
}
float charI(vec2 p) {
    float d = sdSegment(p, vec2(-0.08, 0.25), vec2(0.08, 0.25));
    d = min(d, sdSegment(p, vec2(0.0, 0.25), vec2(0.0, -0.25)));
    d = min(d, sdSegment(p, vec2(-0.08, -0.25), vec2(0.08, -0.25)));
    return d;
}
float charL(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, 0.25), vec2(-0.12, -0.25));
    d = min(d, sdSegment(p, vec2(-0.12, -0.25), vec2(0.12, -0.25)));
    return d;
}
float charM(vec2 p) {
    float d = sdSegment(p, vec2(-0.15, -0.25), vec2(-0.15, 0.25));
    d = min(d, sdSegment(p, vec2(-0.15, 0.25), vec2(0.0, 0.0)));
    d = min(d, sdSegment(p, vec2(0.0, 0.0), vec2(0.15, 0.25)));
    d = min(d, sdSegment(p, vec2(0.15, 0.25), vec2(0.15, -0.25)));
    return d;
}
float charN(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.25), vec2(-0.12, 0.25));
    d = min(d, sdSegment(p, vec2(-0.12, 0.25), vec2(0.12, -0.25)));
    d = min(d, sdSegment(p, vec2(0.12, -0.25), vec2(0.12, 0.25)));
    return d;
}
float charO(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.2), vec2(-0.12, 0.2));
    d = min(d, sdSegment(p, vec2(-0.12, 0.2), vec2(0.0, 0.25)));
    d = min(d, sdSegment(p, vec2(0.0, 0.25), vec2(0.12, 0.2)));
    d = min(d, sdSegment(p, vec2(0.12, 0.2), vec2(0.12, -0.2)));
    d = min(d, sdSegment(p, vec2(0.12, -0.2), vec2(0.0, -0.25)));
    d = min(d, sdSegment(p, vec2(0.0, -0.25), vec2(-0.12, -0.2)));
    return d;
}
float charP(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, -0.25), vec2(-0.12, 0.25));
    d = min(d, sdSegment(p, vec2(-0.12, 0.25), vec2(0.1, 0.25)));
    d = min(d, sdSegment(p, vec2(0.1, 0.25), vec2(0.12, 0.12)));
    d = min(d, sdSegment(p, vec2(0.12, 0.12), vec2(0.1, 0.0)));
    d = min(d, sdSegment(p, vec2(0.1, 0.0), vec2(-0.12, 0.0)));
    return d;
}
float charR(vec2 p) {
    float d = charP(p);
    d = min(d, sdSegment(p, vec2(0.0, 0.0), vec2(0.12, -0.25)));
    return d;
}
float charS(vec2 p) {
    float d = sdSegment(p, vec2(0.12, 0.2), vec2(-0.05, 0.25));
    d = min(d, sdSegment(p, vec2(-0.05, 0.25), vec2(-0.12, 0.15)));
    d = min(d, sdSegment(p, vec2(-0.12, 0.15), vec2(0.12, -0.15)));
    d = min(d, sdSegment(p, vec2(0.12, -0.15), vec2(0.05, -0.25)));
    d = min(d, sdSegment(p, vec2(0.05, -0.25), vec2(-0.12, -0.2)));
    return d;
}
float charT(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, 0.25), vec2(0.12, 0.25));
    d = min(d, sdSegment(p, vec2(0.0, 0.25), vec2(0.0, -0.25)));
    return d;
}
float charU(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, 0.25), vec2(-0.12, -0.2));
    d = min(d, sdSegment(p, vec2(-0.12, -0.2), vec2(0.0, -0.25)));
    d = min(d, sdSegment(p, vec2(0.0, -0.25), vec2(0.12, -0.2)));
    d = min(d, sdSegment(p, vec2(0.12, -0.2), vec2(0.12, 0.25)));
    return d;
}
float charV(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, 0.25), vec2(0.0, -0.25));
    d = min(d, sdSegment(p, vec2(0.0, -0.25), vec2(0.12, 0.25)));
    return d;
}
float charW(vec2 p) {
    float d = sdSegment(p, vec2(-0.18, 0.25), vec2(-0.09, -0.25));
    d = min(d, sdSegment(p, vec2(-0.09, -0.25), vec2(0.0, 0.05)));
    d = min(d, sdSegment(p, vec2(0.0, 0.05), vec2(0.09, -0.25)));
    d = min(d, sdSegment(p, vec2(0.09, -0.25), vec2(0.18, 0.25)));
    return d;
}
float charY(vec2 p) {
    float d = sdSegment(p, vec2(-0.12, 0.25), vec2(0.0, 0.0));
    d = min(d, sdSegment(p, vec2(0.12, 0.25), vec2(0.0, 0.0)));
    d = min(d, sdSegment(p, vec2(0.0, 0.0), vec2(0.0, -0.25)));
    return d;
}

// --- Character Lookup ---
// Maps character IDs to their SDF functions
// 0=space, 1=A, 2=C, 3=D, 4=E, 5=G, 6=H, 7=I, 8=L, 9=M,
// 10=N, 11=O, 12=P, 13=R, 14=S, 15=T, 16=U, 17=V, 18=W, 19=Y
float renderChar(vec2 p, int c) {
    if (c == 0) return 1e5;  // Space returns large distance
    if (c == 1) return charA(p);
    if (c == 2) return charC(p);
    if (c == 3) return charD(p);
    if (c == 4) return charE(p);
    if (c == 5) return charG(p);
    if (c == 6) return charH(p);
    if (c == 7) return charI(p);
    if (c == 8) return charL(p);
    if (c == 9) return charM(p);
    if (c == 10) return charN(p);
    if (c == 11) return charO(p);
    if (c == 12) return charP(p);
    if (c == 13) return charR(p);
    if (c == 14) return charS(p);
    if (c == 15) return charT(p);
    if (c == 16) return charU(p);
    if (c == 17) return charV(p);
    if (c == 18) return charW(p);
    if (c == 19) return charY(p);
    return 1e5;
}

// --- Text Layout ---
// Renders "Gödel's Incompleteness Theorem"
// Each line is an array of character IDs positioned at specific Y offsets
float getTextSDF(vec2 p) {
    float charW = 0.38;  // Horizontal spacing between characters

    // Early out - bounding box
    if (abs(p.x) > 4.5 || abs(p.y) > 3.5) return 1e5;
    
    float d = 1e5;

    // Line 0: "GODEL" (y = 2.25)
    float ly0 = p.y - 2.25;
    if (abs(ly0) < 0.4) {
        int chars0[5] = int[5](5,11,3,4,8);
        float startX = -float(5-1) * charW * 0.5;
        for (int i = 0; i < 5; i++) {
            vec2 cp = vec2(p.x - startX - float(i) * charW, ly0);
            if (abs(cp.x) < charW) d = min(d, renderChar(cp, chars0[i]));
        }
    }
    
    // Line 1: "INCOMPLETENESS" (y = 1.5)
    float ly1 = p.y - 1.5;
    if (abs(ly1) < 0.4) {
        int chars1[14] = int[14](7,10,2,11,9,12,8,4,15,4,10,4,14,14);
        float startX = -float(14-1) * charW * 0.5;
        for (int i = 0; i < 14; i++) {
            vec2 cp = vec2(p.x - startX - float(i) * charW, ly1);
            if (abs(cp.x) < charW) d = min(d, renderChar(cp, chars1[i]));
        }
    }
    
    // Line 2: "THEOREM I" (y = 0.75)
    float ly2 = p.y - 0.75;
    if (abs(ly2) < 0.4) {
        int chars2[9] = int[9](15,6,4,11,13,4,9,0,7);
        float startX = -float(9-1) * charW * 0.5;
        for (int i = 0; i < 9; i++) {
            vec2 cp = vec2(p.x - startX - float(i) * charW, ly2);
            if (abs(cp.x) < charW) d = min(d, renderChar(cp, chars2[i]));
        }
    }
    
    // Line 3: spacer
    
    // Line 4: "NO SYSTEM CAN" (y = -0.75)
    float ly4 = p.y + 0.75;
    if (abs(ly4) < 0.4) {
        int chars4[13] = int[13](10,11,0,14,19,14,15,4,9,0,2,1,10);
        float startX = -float(13-1) * charW * 0.5;
        for (int i = 0; i < 13; i++) {
            vec2 cp = vec2(p.x - startX - float(i) * charW, ly4);
            if (abs(cp.x) < charW) d = min(d, renderChar(cp, chars4[i]));
        }
    }
    
    // Line 5: "PROVE ITS OWN" (y = -1.5)
    float ly5 = p.y + 1.5;
    if (abs(ly5) < 0.4) {
        int chars5[13] = int[13](12,13,11,17,4,0,7,15,14,0,11,18,10);
        float startX = -float(13-1) * charW * 0.5;
        for (int i = 0; i < 13; i++) {
            vec2 cp = vec2(p.x - startX - float(i) * charW, ly5);
            if (abs(cp.x) < charW) d = min(d, renderChar(cp, chars5[i]));
        }
    }
    
    // Line 6: "CONSISTENCY" (y = -2.25)
    float ly6 = p.y + 2.25;
    if (abs(ly6) < 0.4) {
        int chars6[11] = int[11](2,11,10,14,7,14,15,4,10,2,19);
        float startX = -float(11-1) * charW * 0.5;
        for (int i = 0; i < 11; i++) {
            vec2 cp = vec2(p.x - startX - float(i) * charW, ly6);
            if (abs(cp.x) < charW) d = min(d, renderChar(cp, chars6[i]));
        }
    }
    
    return d;
}


// =====================================================================
//                         PROCEDURAL NOISE
// =====================================================================
// Simple hash function - returns pseudo-random value in [0,1]
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}


// =====================================================================
//                          FLOOR PATTERN
// =====================================================================
vec3 getPlaneColor(vec2 p, float textScale, bool revealText) {
    // Layered floor pattern combining multiple techniques:
    // 1. Marble-like veins (FBM noise)
    // 2. Anti-aliased checkerboard
    // 3. Hexagonal grid overlay
    // 4. Radial rings from center
    float marbleNoise = fbm(p * 0.8 + vec2(iTime * 0.02, 0.0));
    float marbleVeins = abs(sin(p.x * 2.0 + p.y * 1.5 + marbleNoise * 6.0));
    marbleVeins = pow(marbleVeins, 0.3);
    
    // Anti-aliased checkerboard overlay
    float checkerSize = 0.5;
    vec2 uv = p / checkerSize;
    vec2 w = fwidth(uv) + 0.001;
    vec2 i = 2.0 * (abs(fract((uv - 0.5 * w) * 0.5) - 0.5) - abs(fract((uv + 0.5 * w) * 0.5) - 0.5)) / w;
    float checker = 0.5 - 0.5 * i.x * i.y;
    
    // Hexagonal pattern overlay
    vec2 hexUV = p * 1.5;
    vec2 hexGrid = vec2(hexUV.x + hexUV.y * 0.5, hexUV.y * 0.866);
    vec2 hexF = fract(hexGrid);
    float hexDist = min(min(length(hexF - vec2(0.5, 0.5)), 
                           length(hexF - vec2(0.0, 0.0))),
                       min(length(hexF - vec2(1.0, 0.0)),
                           length(hexF - vec2(0.0, 1.0))));
    float hexPattern = smoothstep(0.02, 0.06, hexDist);
    
    // Radial rings emanating from center
    float dist = length(p);
    float rings = sin(dist * 3.0 - iTime * 0.5) * 0.5 + 0.5;
    rings = smoothstep(0.3, 0.7, rings);
    
    // Color palette - fun rainbow-tinted tiles!
    float rainbowPhase = atan(p.y, p.x) * 0.5 + iTime * 0.3;
    vec3 rainbow = 0.5 + 0.5 * cos(rainbowPhase + vec3(0.0, 2.1, 4.2));
    vec3 darkTile = vec3(0.06, 0.08, 0.15) + rainbow * 0.08;  // Subtle rainbow dark
    vec3 lightTile = vec3(0.82, 0.80, 0.75) + rainbow * 0.12; // Rainbow-kissed light
    vec3 marbleLight = vec3(0.95, 0.92, 0.88);
    vec3 marbleDark = vec3(0.15, 0.12, 0.10);
    
    // Compose the pattern - checkerboard with visible marble veins
    vec3 tileColor = mix(darkTile, lightTile, checker);
    vec3 veinColor = mix(marbleDark, marbleLight, checker);
    vec3 col = mix(tileColor, veinColor, marbleVeins * 0.35);
    col = mix(col, col * 0.85, 1.0 - hexPattern); // Hex grid lines
    
    // Disco ball reflections - bouncy light spots
    float disco = sin(p.x * 8.0 + iTime * 3.0) * sin(p.y * 8.0 - iTime * 2.5);
    disco = pow(max(disco, 0.0), 8.0);
    vec3 discoColor = 0.5 + 0.5 * cos(iTime * 2.0 + p.x * 3.0 + vec3(0.0, 2.0, 4.0));
    col += disco * discoColor * 0.25;

    // Rainbow swirl that dances around
    float swirl = sin(atan(p.y, p.x) * 8.0 + iTime * 2.0 + dist * 2.0);
    vec3 swirlColor = 0.5 + 0.5 * cos(iTime + atan(p.y, p.x) * 2.0 + vec3(0.0, 2.1, 4.2));
    col += swirl * 0.08 * swirlColor;

    // Party confetti sparkles - multiple colors
    for (int sp = 0; sp < 3; sp++) {
        float spScale = 3.0 + float(sp) * 1.5;
        vec2 sCell = floor(p * spScale);
        vec2 sLocal = fract(p * spScale) - 0.5;
        float sRand = hash(sCell + float(sp) * 50.0 + floor(iTime * 2.0));
        float sparkle = step(0.992, sRand);
        float twinkle = sin(iTime * (4.0 + sRand * 8.0)) * 0.5 + 0.5;
        float sFalloff = smoothstep(0.2, 0.0, length(sLocal));
        vec3 sparkleCol = 0.5 + 0.5 * cos(sRand * 6.28 + vec3(0.0, 2.0, 4.0));
        col += sparkle * twinkle * sFalloff * sparkleCol * 0.6;
    }
    
    // Distance-based color shift (warmer near center, cooler at edges)
    float distFade = 1.0 - smoothstep(0.0, 12.0, dist);
    col = mix(col * vec3(0.7, 0.75, 0.9), col * vec3(1.1, 1.05, 1.0), distFade);
    
    // Subtle grid highlight at tile edges
    vec2 tileEdge = abs(fract(p) - 0.5);
    float edgeGlow = smoothstep(0.48, 0.5, max(tileEdge.x, tileEdge.y));
    col += vec3(0.15, 0.2, 0.3) * edgeGlow * 0.3;
    
    // Vignette on the floor
    col *= 0.7 + 0.3 * distFade;
    
    if (revealText) {
        vec2 tp = p * textScale;
        float d = getTextSDF(tp);
        float textW = fwidth(d);
        float textAlpha = smoothstep(0.02 + textW, 0.0, d);
        float textShimmer = sin(p.x * 15.0 + iTime * 4.0) * 0.5 + 0.5;
        vec3 gold = vec3(1.0, 0.85, 0.4);
        vec3 rose = vec3(1.0, 0.6, 0.7);
        vec3 cyan = vec3(0.4, 0.9, 1.0);
        vec3 textCol = mix(gold, mix(rose, cyan, sin(iTime * 1.5) * 0.5 + 0.5), textShimmer * 0.4);
        col = mix(col, textCol, textAlpha);
    }
    return col;
}


// =====================================================================
//                           3D SHAPES
// =====================================================================
// Mathematical constants
#define PI 3.14159265
#define HALF_PI 1.5707963
#define TWO_PI 6.28318530

// 2D rotation helper - rotates point p by angle (c=cos, s=sin)
vec2 rot2D(vec2 p, float c, float s) { return vec2(p.x*c - p.y*s, p.x*s + p.y*c); }

// --- Additional SDFs for Carousel ---
// Vertical cylinder: r = radius, h = half-height
float sdCylinder(vec3 p, float r, float h) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Cone: c = (sin, cos) of apex angle, h = height
float sdCone(vec3 p, vec2 c, float h) {
    vec2 q = h * vec2(c.x / c.y, -1.0);
    vec2 w = vec2(length(p.xz), p.y);
    vec2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
    vec2 b = w - q * vec2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
    float k = sign(q.y);
    float d = min(dot(a, a), dot(b, b));
    float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
    return sqrt(d) * sign(s);
}

// --- Carousel Horse ---
float sdHorse(vec3 p) {
    // Body: elongated ellipsoid
    vec3 bodyP = p;
    bodyP.x *= 0.7;
    float body = sdEllipsoid(bodyP, vec3(0.06, 0.035, 0.025));
    
    // Head - small sphere offset forward and up
    vec3 headP = p - vec3(0.055, 0.025, 0.0);
    float head = sdSphere(headP, 0.022);
    
    // Neck connecting head to body
    vec3 neckP = p - vec3(0.035, 0.015, 0.0);
    neckP.x *= 1.5;
    float neck = sdEllipsoid(neckP, vec3(0.025, 0.02, 0.015));
    
    // Front legs
    vec3 flegP = p - vec3(0.025, -0.04, 0.0);
    float fleg = sdCylinder(flegP, 0.008, 0.03);
    
    // Back legs  
    vec3 blegP = p - vec3(-0.03, -0.04, 0.0);
    float bleg = sdCylinder(blegP, 0.008, 0.03);
    
    // Tail
    vec3 tailP = p - vec3(-0.07, 0.0, 0.0);
    tailP.y += tailP.x * 0.5;
    float tail = sdEllipsoid(tailP, vec3(0.02, 0.025, 0.01));
    
    float d = smin(body, head, 0.015);
    d = smin(d, neck, 0.01);
    d = smin(d, fleg, 0.008);
    d = smin(d, bleg, 0.008);
    d = smin(d, tail, 0.01);
    
    return d;
}

// --- Christmas Carousel ---
// Decorative carousel with central pole, canopy, base, and 4 horses
float mapCarousel(vec3 p, vec3 carouselPos, float time) {
    vec3 q = p - carouselPos;
    
    // Early-out: bounding cylinder check for performance
    float boundDist = max(length(q.xz) - 0.7, abs(q.y - 0.3) - 0.5);
    if (boundDist > 0.1) return boundDist;
    
    // Carousel rotation
    float rotSpeed = time * CAROUSEL_SPIN_SPEED;
    float rc = cos(rotSpeed), rs = sin(rotSpeed);
    
    // === CENTRAL POLE ===
    float pole = sdCylinder(q - vec3(0.0, 0.25, 0.0), 0.04, 0.35);
    
    // Decorative ridges on pole
    vec3 poleP = q - vec3(0.0, 0.25, 0.0);
    float ridges = sdTorus(poleP - vec3(0.0, 0.15, 0.0), vec2(0.05, 0.012));
    ridges = min(ridges, sdTorus(poleP - vec3(0.0, 0.0, 0.0), vec2(0.055, 0.01)));
    ridges = min(ridges, sdTorus(poleP - vec3(0.0, -0.15, 0.0), vec2(0.05, 0.012)));
    
    // === CANOPY/ROOF ===
    // Main conical roof
    vec3 roofP = q - vec3(0.0, 0.55, 0.0);
    float roof = sdCone(roofP, vec2(0.5, 0.2), 0.18);
    
    // Roof rim - decorative torus at edge
    vec3 rimP = q - vec3(0.0, 0.5, 0.0);
    float rim = sdTorus(rimP, vec2(0.45, 0.025));
    
    // Scalloped edge - wave pattern around the rim
    float scallops = 1e5;
    for (int i = 0; i < 12; i++) {
        float angle = float(i) * 0.5236; // 2π/12
        vec3 scP = rimP - vec3(cos(angle) * 0.45, -0.02, sin(angle) * 0.45);
        scallops = smin(scallops, sdSphere(scP, 0.04), 0.02);
    }
    
    // Top finial - golden ball
    vec3 finialP = q - vec3(0.0, 0.72, 0.0);
    float finial = sdSphere(finialP, 0.035);
    // Small stem
    float finialStem = sdCylinder(q - vec3(0.0, 0.68, 0.0), 0.015, 0.04);
    
    // Main circular base
    vec3 baseP = q - vec3(0.0, -0.05, 0.0);
    float base = sdCylinder(baseP, 0.5, 0.06);
    
    // Decorative base rim
    float baseRim = sdTorus(q - vec3(0.0, 0.0, 0.0), vec2(0.5, 0.02));
    float baseRim2 = sdTorus(q - vec3(0.0, -0.1, 0.0), vec2(0.48, 0.018));
    
    // Lower decorative tier
    vec3 lowerP = q - vec3(0.0, -0.15, 0.0);
    float lowerBase = sdCylinder(lowerP, 0.42, 0.04);
    
    // ===  4 carousel horses ===
    float horses = 1e5;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float horseAngle = fi * 1.5708 + rotSpeed; // π/2 spacing + rotation
        float hc = cos(horseAngle), hs = sin(horseAngle);
        
        // Horse position on carousel
        float horseRadius = 0.32;
        float horseY = 0.18 + sin(time * HORSE_BOB_SPEED + fi * 1.5) * 0.03; // Bobbing up/down
        
        vec3 horsePos = vec3(hc * horseRadius, horseY, hs * horseRadius);
        vec3 horseP = q - horsePos;
        
        // Rotate horse to face tangent direction
        horseP.xz = vec2(horseP.x * hc + horseP.z * hs, -horseP.x * hs + horseP.z * hc);
        
        float horse = sdHorse(horseP);
        
        // Horse pole
        vec3 horsePoleP = q - vec3(hc * horseRadius, 0.35, hs * horseRadius);
        float horsePole = sdCylinder(horsePoleP, 0.008, 0.25);
        
        horses = min(horses, horse);
        horses = min(horses, horsePole);
    }
    
    float d = pole;
    d = min(d, ridges);
    d = smin(d, roof, 0.02);
    d = smin(d, rim, 0.015);
    d = smin(d, scallops, 0.02);
    d = min(d, finial);
    d = min(d, finialStem);
    d = smin(d, base, 0.02);
    d = smin(d, baseRim, 0.01);
    d = smin(d, baseRim2, 0.01);
    d = smin(d, lowerBase, 0.02);
    d = smin(d, horses, 0.01);
    
    return d;
}

// --- Glass Sculpture ---
// Organic glass form with animated elements:
// - Twisted central core
// - Flowing helical ribbons
// - Orbiting droplets
// - Crown of petals
// - Dripping stalactite base
// - Wobbling torus rings
float mapSculpture(vec3 p, vec3 sculpturePos, float time) {
    vec3 q = p - sculpturePos;
    
    // Early-out: bounding sphere check for performance
    float boundDist = length(q) - 1.2;
    if (boundDist > 0.1) return boundDist;
    
    // Precompute animation values once
    float t05 = time * 0.5;
    float t025 = time * 0.25;
    float pulse = sin(t05) * 0.04;
    float breathe = sin(t025) * 0.03;
    
    // === CENTRAL CORE - twisted ellipsoid ===
    vec3 coreP = q;
    float twistAmount = coreP.y * 0.8 + time * SCULPTURE_TWIST_SPEED;
    float tc = cos(twistAmount), ts = sin(twistAmount);
    coreP.xz = rot2D(coreP.xz, tc, ts);
    coreP.y *= 1.6;
    float core = sdSphere(coreP, 0.32 + pulse + breathe);
    
    // === FLOWING RIBBONS - 4 ribbons ===
    float ribbons = 1e5;
    float ribbonBase = time * RIBBON_SPEED;
    float ribbonWave = time * 0.3;
    for (int i = 0; i < 4; i++) {
        float ribbonAngle = float(i) * 1.5708 + ribbonBase; // π/2
        float rc = cos(ribbonAngle), rs = sin(ribbonAngle);
        
        vec3 ribbonP = vec3(q.x * rc + q.z * rs, q.y, -q.x * rs + q.z * rc);
        
        float helixAngle = ribbonP.y * 3.0 + ribbonAngle + ribbonWave;
        float helixRadius = 0.35 + sin(ribbonP.y * 4.0 + time) * 0.05;
        ribbonP.x -= cos(helixAngle) * helixRadius;
        ribbonP.z -= sin(helixAngle) * helixRadius;
        ribbonP.x *= 2.5;
        
        ribbons = smin(ribbons, length(ribbonP) - 0.08, 0.12);
    }
    
    // === ORBITING DROPLETS - 5 droplets ===
    float drops = 1e5;
    float dropBase = time * DROPLET_ORBIT_SPEED;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float dropAngle = fi * 1.2566 + dropBase; // 2π/5
        float dropOrbit = 0.55 + sin(time * 0.6 + fi * 0.8) * 0.12;
        float dropY = sin(t05 + fi * 1.3) * 0.25;
        
        vec3 dropP = q - vec3(cos(dropAngle) * dropOrbit, dropY, sin(dropAngle) * dropOrbit);
        dropP.y += dropP.y * dropP.y * 0.5;
        float dropSize = 0.09 + sin(time * 1.2 + fi * 2.5) * 0.025;
        
        drops = smin(drops, length(dropP) - dropSize, 0.18);
    }
    
    // === CROWN - 8 petals ===
    vec3 crownP = q - vec3(0.0, 0.38 + breathe, 0.0);
    float crown = 1e5;
    float crownBase = time * CROWN_ROTATION_SPEED;
    for (int i = 0; i < 8; i++) {
        float fi = float(i);
        float petalAngle = fi * 0.7854 + crownBase; // π/4
        float petalOpen = 0.3 + sin(time * 0.4 + fi * 0.5) * 0.1;
        
        // Combined rotation - Y then Z
        float cy = cos(petalAngle), sy = sin(petalAngle);
        float cz = cos(petalOpen), sz = sin(petalOpen);
        vec3 petalP = vec3(
            crownP.x * cy + crownP.z * sy,
            crownP.y * cz - (crownP.z * cy - crownP.x * sy) * sz,
            crownP.y * sz + (crownP.z * cy - crownP.x * sy) * cz
        );
        petalP.x -= 0.15;
        petalP.y *= 1.8;
        petalP.z *= 2.5;
        
        crown = smin(crown, sdEllipsoid(petalP, vec3(0.12, 0.08, 0.04)), 0.1);
    }
    
    // === dripping stalactite ===
    vec3 baseP = vec3(q.x, -q.y - 0.35, q.z);
    float baseDrop = sdRoundCone(baseP, 0.18, 0.03, 0.35);
    
    // 3 drips
    for (int i = 0; i < 3; i++) {
        float dripAngle = float(i) * 2.094 + 0.5; // 2π/3
        vec3 dripP = baseP - vec3(cos(dripAngle) * 0.12, -0.1, sin(dripAngle) * 0.12);
        float dripLen = 0.15 + sin(time + float(i)) * 0.05;
        baseDrop = smin(baseDrop, sdRoundCone(dripP, 0.05, 0.015, dripLen), 0.08);
    }
    
    // === TORUS RINGS - 2 animated rings ===
    float rings = 1e5;
    for (int i = 0; i < 2; i++) {
        float fi = float(i);
        float ringY = fi * 0.4 - 0.15 + sin(time * RING_WOBBLE_SPEED + fi * 2.0) * 0.08;
        float ringTilt = 0.15 + sin(time * RING_WOBBLE_SPEED * 0.67 + fi) * 0.1;
        float ringSize = 0.42 - fi * 0.08 + pulse;
        
        vec3 ringP = q - vec3(0.0, ringY, 0.0);
        // Simplified rotation - just X tilt
        float cx = cos(ringTilt), sx = sin(ringTilt);
        ringP.yz = rot2D(ringP.yz, cx, sx);
        
        rings = smin(rings, sdTorus(ringP, vec2(ringSize, 0.025 + fi * 0.01)), 0.08);
    }
    
    // === INNER VOID ===
    vec3 voidP = q;
    voidP.y *= 1.3;
    float innerVoid = length(voidP) - (0.12 + sin(time * 0.8) * 0.02);
    

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


// =====================================================================
//                          RAYMARCHING
// =====================================================================
// Main scene SDF - selects shape(s) based on SHAPE_MODE setting
float map(vec3 p, vec3 sculpturePos) {
    #if SHAPE_MODE == 0
        // Glass sculpture only
        return mapSculpture(p, sculpturePos, iTime);
    #elif SHAPE_MODE == 1
        // Carousel only
        return mapCarousel(p, sculpturePos, iTime);
    #else
        // Both shapes side by side
        float d1 = mapSculpture(p, sculpturePos - vec3(SCULPTURE_SPACING, 0.0, 0.0), iTime);
        float d2 = mapCarousel(p, sculpturePos + vec3(SCULPTURE_SPACING, 0.0, 0.0), iTime);
        return min(d1, d2);
    #endif
}

// Calculate surface normal using tetrahedron technique (4 samples)
// More accurate than central differences with same sample count
vec3 calcNormal(vec3 p, vec3 sculpturePos) {
    const float h = 0.0003;  // Sample offset
    const vec2 k = vec2(1,-1);
    #if SHAPE_MODE == 0
        return normalize( k.xyy*mapSculpture( p + k.xyy*h, sculpturePos, iTime ) + 
                          k.yyx*mapSculpture( p + k.yyx*h, sculpturePos, iTime ) + 
                          k.yxy*mapSculpture( p + k.yxy*h, sculpturePos, iTime ) + 
                          k.xxx*mapSculpture( p + k.xxx*h, sculpturePos, iTime ) );
    #elif SHAPE_MODE == 1
        return normalize( k.xyy*mapCarousel( p + k.xyy*h, sculpturePos, iTime ) + 
                          k.yyx*mapCarousel( p + k.yyx*h, sculpturePos, iTime ) + 
                          k.yxy*mapCarousel( p + k.yxy*h, sculpturePos, iTime ) + 
                          k.xxx*mapCarousel( p + k.xxx*h, sculpturePos, iTime ) );
    #else
        return normalize( k.xyy*map( p + k.xyy*h, sculpturePos ) + 
                          k.yyx*map( p + k.yyx*h, sculpturePos ) + 
                          k.yxy*map( p + k.yxy*h, sculpturePos ) + 
                          k.xxx*map( p + k.xxx*h, sculpturePos ) );
    #endif
}

// Ray-plane intersection (horizontal plane at given height)
// Returns -1.0 if no intersection or behind ray origin
float intersectPlane(vec3 ro, vec3 rd, float height) {
    if (abs(rd.y) < 1e-4) return -1.0;
    float t = (height - ro.y) / rd.y;
    return (t > 0.0) ? t : -1.0;
}


// =====================================================================
//                            SHADING
// =====================================================================
// Construct camera ray direction from UV coordinates
vec3 getRayDir(vec2 uv, vec3 ro, vec3 ta, float zoom) {
    vec3 ww = normalize(ta - ro);                      // Forward
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0))); // Right
    vec3 vv = normalize(cross(uu, ww));                 // Up
    return normalize(uv.x * uu + uv.y * vv + zoom * ww);
}

// Accumulate diffuse lighting from all directional lights
vec3 evalDiffuse(vec3 normal, DirLight lights[NUM_LIGHTS]) {
    vec3 accum = vec3(0.0);
    for (int i = 0; i < NUM_LIGHTS; ++i) {
        float ndotl = max(dot(normal, -lights[i].dir), 0.0);
        accum += lights[i].color * ndotl;
    }
    return accum;
}

// Accumulate specular highlights from all directional lights
// Uses pow(32) approximation via repeated squaring for performance
vec3 evalSpecular(vec3 normal, vec3 viewDir, DirLight lights[NUM_LIGHTS]) {
    vec3 accum = vec3(0.0);
    for (int i = 0; i < NUM_LIGHTS; ++i) {
        vec3 r = reflect(lights[i].dir, normal);
        float NdotR = max(dot(r, viewDir), 0.0);
        // Approximate pow(x, 32) with repeated squaring
        float spec = NdotR * NdotR; // ^2
        spec *= spec; // ^4
        spec *= spec; // ^8
        spec *= spec; // ^16
        spec *= spec; // ^32
        accum += lights[i].color * spec;
    }
    return accum;
}

// Soft shadow calculation using sphere tracing
// Returns 0.0 (full shadow) to 1.0 (no shadow)
float softShadow(vec3 ro, vec3 rd, vec3 sculpturePos) {
    // Early-out: skip if pointing away from sculpture
    vec3 toSculpt = sculpturePos - ro;
    if (dot(rd, toSculpt) < -0.5) return 1.0;
    
    float t = 0.08;
    float res = 1.0;
    for (int i = 0; i < SHADOW_STEPS; ++i) {
        vec3 p = ro + rd * t;
        float h = map(p, sculpturePos);
        if (h < 0.002) return 0.0;
        res = min(res, SHADOW_SOFTNESS * h / t);
        t += clamp(h, 0.04, 0.4);
        if (t > 5.0 || res < 0.01) break;
    }
    return clamp(res, 0.0, 1.0);
}


// --- Point Light (Bulb) Helpers ---
// Accumulate diffuse and specular from a single point light
void accumulateBulb(vec3 p, vec3 viewDir, vec3 n, vec3 pos, vec3 color, inout vec3 diffuse, inout vec3 specAcc) {
    vec3 lb = pos - p;
    float lbDist2 = dot(lb, lb);
    float lbDist = sqrt(lbDist2);
    vec3 lbDir = lb / max(lbDist, 1e-3);
    float bulbAtt = 1.0 / (1.0 + 0.45 * lbDist + 0.1 * lbDist2);
    diffuse += color * max(dot(n, lbDir), 0.0) * bulbAtt;
    // Approximate pow(x, 32) with repeated squaring
    float NdotR = max(dot(reflect(-lbDir, n), viewDir), 0.0);
    float spec = NdotR * NdotR; spec *= spec; spec *= spec; spec *= spec; spec *= spec; // ^32
    specAcc += color * spec * bulbAtt;
}

// Calculate total diffuse contribution from all point lights
vec3 bulbDiffuse(vec3 p, vec3 n) {
    vec3 diff = vec3(0.0);
    for (int i = 0; i < NUM_BULBS; i++) {
        vec3 lb = bulbPositions[i] - p;
        float lbDist2 = dot(lb, lb);
        float lbDist = sqrt(lbDist2);
        vec3 lbDir = lb / max(lbDist, 1e-3);
        float bulbAtt = 1.0 / (1.0 + 0.35 * lbDist + 0.08 * lbDist2);
        diff += bulbColors[i] * max(dot(n, lbDir), 0.0) * bulbAtt;
    }
    return diff;
}

// Forward scatter term - simulates light passing through glass
// Creates a "glow" effect when looking toward a light source
vec3 bulbScatter(vec3 p, vec3 viewDir) {
    vec3 scatter = vec3(0.0);
    for (int i = 0; i < NUM_BULBS; i++) {
        vec3 toL = bulbPositions[i] - p;
        float dist2 = dot(toL, toL);
        float dist = sqrt(dist2);
        toL /= max(dist, 1e-3);
        float phase = max(dot(toL, -viewDir), 0.0);
        phase *= phase * phase; // ^3 without pow()
        float att = 1.0 / (1.0 + 0.3 * dist + 0.06 * dist2);
        scatter += bulbColors[i] * phase * att * 0.8;
    }
    return scatter;
}

// Shade the floor plane with all lighting effects
// flipX/flipY: pre-flip UV for correct text orientation through glass
vec3 shadePlane(vec3 p, vec3 viewDir, float textScale, bool revealText, vec3 sculpturePos, bool flipX, bool flipY) {
    vec2 uv = p.xz;
    // When viewing through glass, refraction flips the image,
    // so we pre-flip the text coordinates to keep it readable
    if (flipX) uv.x = -uv.x;
    if (flipY) uv.y = -uv.y;
    vec3 base = getPlaneColor(uv, textScale, revealText);
    vec3 n = vec3(0.0, 1.0, 0.0);
    
    // Skip shadow if far from sculpture
    float distToSculpt = length(p.xz - sculpturePos.xz);
    float sunShadow = 1.0;
    if (distToSculpt < 3.0) {
        sunShadow = softShadow(p + n * 0.01, -lights[0].dir, sculpturePos);
    }
    
    vec3 diffuse = lights[0].color * max(-lights[0].dir.y, 0.0) * sunShadow;
    // Unrolled for performance
    diffuse += lights[1].color * max(-lights[1].dir.y, 0.0);
    diffuse += lights[2].color * max(-lights[2].dir.y, 0.0);
    diffuse += lights[3].color * max(-lights[3].dir.y, 0.0);
    diffuse += lights[4].color * max(-lights[4].dir.y, 0.0);
    diffuse += lights[5].color * max(-lights[5].dir.y, 0.0);
    
    vec3 bulbSpec = vec3(0.0);
    for (int i = 0; i < NUM_BULBS; i++) {
        accumulateBulb(p, viewDir, n, bulbPositions[i], bulbColors[i], diffuse, bulbSpec);
    }
    vec3 spec = evalSpecular(n, viewDir, lights);
    return base * (0.55 + diffuse * 0.45) + spec * 0.06 + bulbSpec * 0.25;
}

// Primary raymarching - find intersection with scene geometry
// Returns true if hit, with distance in 't'
bool castRay(vec3 ro, vec3 rd, vec3 sculpturePos, out float t) {
    t = 0.0;
    float tmax = RAYMARCH_MAX_DIST;
    float minStep = 0.001;  // Prevent getting stuck
    
    // Optimization: start ray closer if outside bounding sphere
    float boundHit = length(ro - sculpturePos) - 1.3;
    if (boundHit > 0.0) t = max(0.0, boundHit - 0.1);
    
    for(int i=0; i<RAYMARCH_STEPS; i++) {
        vec3 p = ro + t*rd;
        float d = map(p, sculpturePos);
        if(d < RAYMARCH_HIT_THRESHOLD) return true;
        // Adaptive stepping
        float step = d * (0.85 + 0.1 * smoothstep(0.0, 1.0, d));
        t += max(step, minStep);
        if(t > tmax) break;
    }
    return false;
}


// =====================================================================
//                           RENDERING
// =====================================================================
// Render background (floor + sky)
vec3 renderBackground(vec3 ro, vec3 rd, vec3 sculpturePos, float textScale) {
    // Check for floor intersection first
    float t_plane = intersectPlane(ro, rd, 0.0);
    if (t_plane > 0.0) {
        vec3 p_plane = ro + t_plane * rd;
        vec3 col = shadePlane(p_plane, normalize(-rd), textScale, true, sculpturePos, false, false);
        return col;
    }
    
    // === SKY BACKGROUND ===
    // Base gradient - deep blue to warm horizon
    float skyGrad = rd.y * 0.5 + 0.5;
    vec3 zenith = vec3(0.05, 0.08, 0.18);      // Deep night blue
    vec3 midSky = vec3(0.15, 0.22, 0.45);      // Rich blue
    vec3 horizon = vec3(0.55, 0.45, 0.50);     // Warm purple-pink
    vec3 lowHorizon = vec3(0.7, 0.5, 0.4);     // Orange glow
    
    vec3 skyCol;
    if (skyGrad > 0.5) {
        skyCol = mix(midSky, zenith, (skyGrad - 0.5) * 2.0);
    } else if (skyGrad > 0.2) {
        skyCol = mix(horizon, midSky, (skyGrad - 0.2) / 0.3);
    } else {
        skyCol = mix(lowHorizon, horizon, skyGrad / 0.2);
    }
    
    // Aurora borealis effect
    float auroraY = rd.y * 2.0 + 0.3;
    if (auroraY > 0.0 && auroraY < 1.0) {
        float auroraX = atan(rd.z, rd.x) * 2.0;
        float aurora = sin(auroraX * 3.0 + iTime * 0.3) * sin(auroraX * 5.0 - iTime * 0.2);
        aurora += sin(auroraX * 7.0 + iTime * 0.5) * 0.5;
        aurora = aurora * 0.5 + 0.5;
        aurora *= sin(auroraY * 3.14159) * smoothstep(0.0, 0.3, auroraY) * smoothstep(1.0, 0.6, auroraY);
        vec3 auroraCol = mix(vec3(0.1, 0.8, 0.5), vec3(0.3, 0.4, 0.9), sin(auroraX * 2.0) * 0.5 + 0.5);
        auroraCol = mix(auroraCol, vec3(0.8, 0.3, 0.6), sin(auroraX * 4.0 + 1.0) * 0.5 + 0.5);
        skyCol += auroraCol * aurora * 0.25;
    }
    
    // Colorful twinkling stars
    vec3 starDir = normalize(rd);
    vec2 starUV = vec2(atan(starDir.z, starDir.x), asin(starDir.y));
    vec3 starTotal = vec3(0.0);
    for (int layer = 0; layer < 3; layer++) {
        vec2 starGrid = starUV * (120.0 + float(layer) * 80.0);
        vec2 starId = floor(starGrid);
        vec2 starF = fract(starGrid) - 0.5;
        float starRand = hash(starId + float(layer) * 100.0);
        if (starRand > 0.96) {
            float starDist = length(starF);
            float twinkle = sin(iTime * (4.0 + starRand * 8.0) + starRand * 6.28) * 0.4 + 0.6;
            float starBright = smoothstep(0.12, 0.0, starDist) * twinkle * (starRand - 0.96) * 25.0;
            // Colorful stars
            vec3 starCol = 0.7 + 0.3 * cos(starRand * 6.28 + vec3(0.0, 1.5, 3.0));
            starTotal += starCol * starBright;
        }
    }
    skyCol += starTotal * smoothstep(0.15, 0.5, skyGrad);
    
    // Shooting stars
    for (int sh = 0; sh < 2; sh++) {
        float shTime = iTime * 0.5 + float(sh) * 3.14;
        float shPhase = fract(shTime * 0.3);
        float shAngle = hash(vec2(floor(shTime * 0.3), float(sh))) * 6.28;
        vec2 shStart = vec2(cos(shAngle), sin(shAngle) * 0.3 + 0.5);
        vec2 shDir = normalize(vec2(-0.7, -0.3));
        vec2 shPos = shStart + shDir * shPhase * 1.5;
        float shDist = length(starUV - shPos);
        float shTrail = smoothstep(0.15, 0.0, shDist) * smoothstep(0.0, 0.3, shPhase) * smoothstep(1.0, 0.7, shPhase);
        vec3 shCol = mix(vec3(1.0, 0.9, 0.7), vec3(0.5, 0.8, 1.0), shPhase);
        skyCol += shCol * shTrail * 0.8 * smoothstep(0.3, 0.6, skyGrad);
    }
    
    // Sun/moon glow
    float sunDot = max(dot(rd, -lights[0].dir), 0.0);
    float sunGlow = pow(sunDot, 8.0) * 0.5;
    float sunCore = pow(sunDot, 64.0) * 2.0;
    skyCol += lights[0].color * sunGlow * vec3(1.0, 0.8, 0.6);
    skyCol += vec3(1.0, 0.95, 0.9) * sunCore;
    
    // Subtle clouds/nebula
    float cloudY = rd.y * 0.5 + 0.5;
    if (cloudY > 0.1 && cloudY < 0.8) {
        vec2 cloudUV = vec2(atan(rd.z, rd.x) * 0.5, rd.y * 2.0);
        float cloud = fbm(cloudUV * 3.0 + vec2(iTime * 0.02, 0.0));
        cloud = smoothstep(0.4, 0.7, cloud) * 0.15;
        skyCol = mix(skyCol, vec3(0.6, 0.5, 0.7), cloud * smoothstep(0.1, 0.3, cloudY) * smoothstep(0.8, 0.5, cloudY));
    }
    
    return skyCol;
}

// Render glass material with refraction, dispersion, and Fresnel
// 1. Refract ray into glass
// 2. March through interior
// 3. Refract out with per-channel dispersion (chromatic aberration)
// 4. Apply Beer-Lambert absorption
// 5. Blend with Fresnel reflection
vec3 renderGlass(vec3 ro, vec3 rd, float t, vec3 sculpturePos, float textScale) {
    vec3 p = ro + t * rd;
    vec3 n = calcNormal(p, sculpturePos);
    vec3 rd_in = refract(rd, n, 1.0 / GLASS_IOR);
    
    // Safety: handle total internal reflection at entry (shouldn't happen)
    if (length(rd_in) == 0.0) rd_in = reflect(rd, n);
    
    // --- Interior March ---
    // Trace through the glass volume to find exit point
    float t_in = 0.02; 
    vec3 p_in = p;
    float totalDist = 0.0;
    for(int i=0; i<INTERNAL_STEPS; i++) {
        p_in = p + t_in * rd_in;
        float d_in = map(p_in, sculpturePos);
        if(d_in > -0.001) break;
        float step = max(abs(d_in), 0.005);
        t_in += step;
        totalDist += step;
        if (t_in > 3.0) break;
    }
    
    vec3 n_out = calcNormal(p_in, sculpturePos);
    
    // --- Chromatic Dispersion ---
    // Different IOR per color channel creates rainbow caustics
    float iorR = GLASS_IOR * (1.0 - GLASS_DISPERSION);  // Red bends less
    float iorG = GLASS_IOR;                              // Green is reference
    float iorB = GLASS_IOR * (1.0 + GLASS_DISPERSION);  // Blue bends more
    vec3 rd_out_r = refract(rd_in, -n_out, iorR);
    vec3 rd_out_g = refract(rd_in, -n_out, iorG);
    vec3 rd_out_b = refract(rd_in, -n_out, iorB);
    
    // Handle total internal reflection per channel
    if (dot(rd_out_r, rd_out_r) < 0.001) rd_out_r = reflect(rd_in, -n_out);
    if (dot(rd_out_g, rd_out_g) < 0.001) rd_out_g = reflect(rd_in, -n_out);
    if (dot(rd_out_b, rd_out_b) < 0.001) rd_out_b = reflect(rd_in, -n_out);

    // Sample background with green ray
    vec3 col = ENV_COLOR * (0.3 + evalDiffuse(vec3(0.0, 1.0, 0.0), lights) * 0.5);
    
    float t_plane = intersectPlane(p_in, rd_out_g, 0.0);
    if (t_plane > 0.0) {
        vec3 p_plane = p_in + t_plane * rd_out_g;
        // Through glass: flip Y so refraction makes text readable
        col = shadePlane(p_plane, normalize(-rd_out_g), textScale, true, sculpturePos, false, true);
        
        // Approximate chromatic offset based on ray divergence
        vec3 rayDiff = (rd_out_b - rd_out_r) * t_plane;
        float chromaStrength = length(rayDiff) * 2.0;
        col.r *= 1.0 - chromaStrength * 0.15;
        col.b *= 1.0 + chromaStrength * 0.15;
    }
    
    // Add caustic-like patterns from internal bounces
    col += bulbScatter(p_in, rd_out_g) * GLASS_TINT * 0.25;
    
    // Beer-Lambert absorption
    vec3 absorb = exp(-GLASS_ABSORB * totalDist * 2.0);
    col *= absorb * GLASS_TINT;
    
    // Internal glow effect - simulates subsurface scattering
    vec3 sss = vec3(0.1, 0.15, 0.2) * (1.0 - exp(-totalDist * 3.0));
    col += sss * GLASS_TINT;
    
    // Fresnel reflection
    float fresnelBase = 1.0 + dot(rd, n);
    float fre = pow(clamp(fresnelBase, 0.0, 1.0), 4.0);
    fre = mix(0.06, 1.0, fre);
    
    // Sample reflection
    vec3 rd_reflect = reflect(rd, n);
    vec3 reflCol = ENV_COLOR;
    
    // Check if reflection hits the floor
    float t_refl = intersectPlane(p + rd_reflect * 0.02, rd_reflect, 0.0);
    if (t_refl > 0.0) {
        vec3 p_refl = p + rd_reflect * t_refl;
        reflCol = shadePlane(p_refl, normalize(-rd_reflect), textScale, true, sculpturePos, false, false);
    } else {
        // Sky gradient for upward reflections - matches background
        float skyGrad = rd_reflect.y * 0.5 + 0.5;
        vec3 zenith = vec3(0.05, 0.08, 0.18);
        vec3 midSky = vec3(0.15, 0.22, 0.45);
        vec3 horizon = vec3(0.55, 0.45, 0.50);
        
        if (skyGrad > 0.5) {
            reflCol = mix(midSky, zenith, (skyGrad - 0.5) * 2.0);
        } else {
            reflCol = mix(horizon, midSky, skyGrad * 2.0);
        }
        
        // Add sun reflection
        float sunDot = max(dot(rd_reflect, -lights[0].dir), 0.0);
        reflCol += lights[0].color * pow(sunDot, 32.0) * 0.8;
        reflCol += vec3(1.0, 0.9, 0.8) * pow(sunDot, 128.0) * 1.5;
    }
    
    // Specular highlights
    vec3 specHighlights = vec3(0.0);
    
    // Combined directional + sun highlight
    for (int i = 0; i < NUM_LIGHTS; i++) {
        vec3 lightRefl = reflect(lights[i].dir, n);
        float NdotR = max(dot(lightRefl, -rd), 0.0);
        float spec = NdotR * NdotR; // spec^2
        spec *= spec; // spec^4
        spec *= spec; // spec^8
        spec *= spec; // spec^16
        spec *= spec; // spec^32
        spec *= spec; // spec^64
        specHighlights += lights[i].color * spec * 0.8;
        // Extra sharp highlight for key light
        if (i == 0) {
            float sunSpec = spec * spec * spec * spec; // 64^4 = 256
            specHighlights += lights[0].color * sunSpec * 2.5;
        }
    }
    
    // Point light specular - loop through all bulbs
    for (int i = 0; i < NUM_BULBS; i++) {
        vec3 toBulb = bulbPositions[i] - p;
        float distBulb = length(toBulb);
        toBulb /= distBulb;
        vec3 reflBulb = reflect(-toBulb, n);
        float NdotR = max(dot(reflBulb, -rd), 0.0);
        float specBulb = NdotR * NdotR;
        specBulb *= specBulb; specBulb *= specBulb; specBulb *= specBulb; specBulb *= specBulb; // ^64
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

// Screen-space glow effect for point light bulbs
// Creates a soft, pulsing glow around each light source
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

// =====================================================================
//                           MAIN ENTRY
// =====================================================================
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // --- Setup ---
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // --- Camera ---
    // Orbit camera around the scene, with optional mouse control
    float camAngle = iTime * CAM_ORBIT_SPEED;
    vec3 ro = vec3(sin(camAngle) * CAM_DIST, CAM_HEIGHT + sin(iTime * CAM_BOB_SPEED) * CAM_BOB_AMOUNT, cos(camAngle) * CAM_DIST);
    vec3 ta = CAM_TARGET;
    
    // Mouse control overrides orbit
    if (iMouse.z > 0.0) {
        float mouseX = (iMouse.x / iResolution.x - 0.5) * TWO_PI;
        float mouseY = (iMouse.y / iResolution.y - 0.5) * 2.0;
        ro = vec3(sin(mouseX) * CAM_DIST, CAM_HEIGHT + mouseY, cos(mouseX) * CAM_DIST);
    }
    
    vec3 sculpturePos = vec3(0.0, SCULPTURE_HEIGHT, 0.0);
    vec3 rd = getRayDir(uv, ro, ta, CAM_ZOOM);

    // --- Raymarch Scene ---
    float t;
    bool hitSculpture = castRay(ro, rd, sculpturePos, t);
    
    // --- Shade Pixel ---
    vec3 col;
    if (hitSculpture) {
        col = renderGlass(ro, rd, t, sculpturePos, TEXT_SCALE);
    } else {
        col = renderBackground(ro, rd, sculpturePos, TEXT_SCALE);
    }

    // --- Point Light Glow ---
    // Add screen-space glow effects for all bulbs
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    for (int i = 0; i < NUM_BULBS; i++) {
        float phase = float(i) * HALF_PI;
        addBulbGlow(ro, ta, CAM_ZOOM, fragCoord, bulbPositions[i], bulbColors[i], ww, uu, vv, col, phase, GLOW_PULSE_SPEED);
    }
    
    // --- Post Processing ---
    // Vignette: darken edges
    col *= 1.0 - VIGNETTE_STRENGTH * length(uv);
    
    // Reinhard tone mapping + gamma correction
    col = col / (col + vec3(1.0));
    col = pow(col, vec3(GAMMA));

    fragColor = vec4(col, 1.0);
}