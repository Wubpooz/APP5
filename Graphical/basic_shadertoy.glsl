void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord / iResolution.xy;

  vec3 lightDir = vec3(.7, 0.0, 0.2);
  vec3 normLightDir = normalize(lightDir);
  float intensity = dot(normLightDir, vec3(uv,0.0));

  vec3 color = vec3(0.0);
  if (intensity > 0.75)
    color = vec3(0.8, 0.2, 0.2);
  else if (intensity > 0.5)
    color = vec3(0.6, 0.15, 0.15);
  else if (intensity > 0.25)
    color = vec3(0.4, 0.12, 0.12);
  else if(intensity > 0.0)
    color = vec3(0.2, 0.06, 0.06);


  vec2 center = vec2(0.5, 0.5);
  center.x += 0.4 * cos(iTime);
  center.y += 0.1 * sin(iTime);
  float dist = distance(uv, center);
  if (dist > 0.2)
    color = vec3(0.0);
    // color += vec3(0.0, 0.5, 0.8) * (0.2 - dist) * 5.0;
  
  

  fragColor = vec4(color, 1.0);
}