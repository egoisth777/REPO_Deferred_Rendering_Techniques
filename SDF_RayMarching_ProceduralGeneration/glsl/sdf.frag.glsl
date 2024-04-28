
#define FOVY 45 * PI / 180.f
Ray rayCast() {
    vec2 ndc = fs_UV;
    ndc = ndc * 2.f - vec2(1.f);

    float aspect = u_ScreenDims.x / u_ScreenDims.y;
    vec3 ref = u_CamPos + u_Forward;
    vec3 V = u_Up * tan(FOVY * 0.5);
    vec3 H = u_Right * tan(FOVY * 0.5) * aspect;
    vec3 p = ref + H * ndc.x + V * ndc.y;

    return Ray(u_CamPos, normalize(p - u_CamPos));
}

#define MAX_ITERATIONS 128
MarchResult raymarch(Ray ray) {
    return MarchResult(-1, 0, BSDF(vec3(0.), vec3(0.), vec3(0.), 0., 0., 0.));
}

void main()
{
    Ray ray = rayCast();
    MarchResult result = raymarch(ray);
    BSDF bsdf = result.bsdf;
    vec3 pos = ray.origin + result.t * ray.direction;

    vec3 color = metallic_plastic_LTE(bsdf, -ray.direction);

    // Reinhard operator to reduce HDR values from magnitude of 100s back to [0, 1]
    color = color / (color + vec3(1.0));
    // Gamma correction
    color = pow(color, vec3(1.0/2.2));

    out_Col = vec4(color, result.hitSomething > 0 ? 1. : 0.);
}

