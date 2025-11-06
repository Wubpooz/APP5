#iChannel0 "/texture-ground-seamless.jpg"

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord / iResolution.xy;
  vec3 p = vec3(uv, 0.0);

  vec3 lightDir = vec3(.7, 0.0, 0.2);
  vec3 normLightDir = normalize(lightDir);
  float intensity = dot(normLightDir, p);

  vec3 color = vec3(0.0);
  if (intensity > 0.75)
    color = vec3(0.8, 0.2, 0.2);
  else if (intensity > 0.5)
    color = vec3(0.6, 0.15, 0.15);
  else if (intensity > 0.25)
    color = vec3(0.4, 0.12, 0.12);
  else if(intensity > 0.0)
    color = vec3(0.2, 0.06, 0.06);



  vec3 center = vec3(0.5, 0.5, 0.0);
  center.x += 0.4 * cos(iTime);
  center.y += 0.1 * sin(iTime);
  center.z += 0.2 * sin(iTime * 1.5);
  float dist = distance(p, center);
  if (dist > 0.2) {
    color = vec3(0.3255, 0.3137, 0.3137);
  }

  if (iMouse.x > 0.0 && iMouse.y > 2.0)
  {
    vec2 mouseUV = iMouse.xy / iResolution.xy;
    vec3 mouseP = vec3(mouseUV, 0.0);
    float mouseDist = distance(p, mouseP);
    if (mouseDist < 0.1)
      color += vec3(0.0, 0.5, 0.8) * (0.1 - mouseDist) * 10.0;
  }
  
  vec4 a = texture(iChannel0, uv);
  color *= a.xyz;

  fragColor = vec4(color, 1.0);
}