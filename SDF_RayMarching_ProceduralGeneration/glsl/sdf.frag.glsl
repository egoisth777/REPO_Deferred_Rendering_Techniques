
#define FOVY 45 * PI / 180.f
#define EPSILON 0.01

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
/**
* @param ray The ray to march along
* @return A MarchResult struct containing the distance to the closest object,
* the number of iterations taken, and the BSDF at the hit point
*/
//TODO: Implement raymarch function
MarchResult raymarch(Ray ray) {
    float accum_dist = 0.;// initialize the accumulated distance to be 0
    float march_step = 0.001;// initialize the march step to be 0.001
    float min_dist = EPSILON;// Epsilon value to stop ray marching
    float max_dist = 100.;
    int hit_something = 0;
    vec3 curr_pos = ray.origin;// initialize the origin of the ray to be the current position

    // Declare a march result and initialize it to 0
    MarchResult result = MarchResult(0., 0, BSDF(vec3(0.), vec3(0.), vec3(0.), 0.f, 0.f, 0.f));

    for (int i = 0; i < MAX_ITERATIONS; i++) { // define the loop to iterate over MAX_ITERATIONS

        // Query the scene SDF to gain the minimum distance to the surfaces defined by SDFs
        march_step = sceneSDF(curr_pos);

        if (march_step > max_dist) { // too far away from the surface, simply cut it
            break;
        }
        if (abs(march_step) < min_dist) { // already clase enough to the surface
            hit_something = 1;
            BSDF bsdf = sceneBSDF(curr_pos);
            return MarchResult(accum_dist, i, bsdf);
        }
        accum_dist += march_step;// update the accumulated distance
        // update the curr_pos according to the march_step given by the sdf
        // by marching the minimum distance along the ray direction
        curr_pos = ray.origin + accum_dist * ray.direction;
    }
    return result;
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

#if 0// print normal for debugging
    out_Col = vec4(vec3(result.bsdf.nor * 0.5 + 0.5), result.hitSomething > 0 ? 1. : 0.);
#endif
#if 0
    out_Col = vec4(vec3(result.hitSomething), result.hitSomething > 0 ? 1. : 0.);
#endif
#if 1
    out_Col = vec4(color, result.hitSomething > 0 ? 1. : 0.);
#endif
}