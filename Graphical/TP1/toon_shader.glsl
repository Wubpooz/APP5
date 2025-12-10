precision highp float;
uniform float time;
uniform vec2 resolution;
varying vec3 fPosition;
varying vec3 fNormal;


void main()
{
  vec3 lightDir = vec3(.7, 0.0, 0.2);
  vec3 normLightDir = normalize(lightDir);
  vec3 normalizedNormal = normalize(fNormal);
  float intensity = dot(normLightDir, normalizedNormal); // or gl_Normal

  vec3 color = vec3(0.0);
  if (intensity > 0.75)
    color = vec3(0.8, 0.2, 0.2);
  else if (intensity > 0.5)
    color = vec3(0.6, 0.15, 0.15);
  else if (intensity > 0.25)
    color = vec3(0.4, 0.12, 0.12);
  else if(intensity > 0.05)
    color = vec3(0.2, 0.06, 0.06);

  gl_FragColor = vec4(color, 1.0);
}