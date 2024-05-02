#define FOVY 45 * PI / 180.f
#define EPSILON 0.001
#define DISTORTION 0.2
#define GLOW 6.0
#define SCALE 3.0
#define AMBIENT 0.1
#define SUBSURFACE_COL 0
const float ao_thickness_k = 2.0;
const float ao_thickness_search_dist = 0.085;


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
MarchResult raymarch(Ray ray){
    float accum_dist = 0.;// initialize the accumulated distance to be 0
    float march_step = 0.001;// initialize the march step to be 0.001
    float min_dist = EPSILON;// Epsilon value to stop ray marching
    float max_dist = 100.;
    int hit_something = 0;
    vec3 curr_pos = ray.origin; // initialize the origin of the ray to be the current position

    // Declare a march result and initialize it to 0
    MarchResult result = MarchResult(0., 0, BSDF(vec3(0.), vec3(0.), vec3(0.), 0.f, 0.f, 0.f, 0.f));
    for (int i = 0; i < MAX_ITERATIONS; i++) { // define the loop to iterate over MAX_ITERATIONS

        // Compute the cell index ofthe current position
        vec3 cell = floor(curr_pos / vec3(grid_size) + vec3(0.5f));
        ivec3 odd = (ivec3(cell) % ivec3(2) + ivec3(2)) % ivec3(2);
        int id = odd.x ^ odd.y ^ odd.z;
        // Compute the blending factor of the current scale amount
        float scale = 0.5f * random31(cell * -26849.f) + 0.5f;
        vec2 scale_bound = vec2(0.5f, 3.0f);
        // Compute the scale of the current cell
        float scale_x = mix(scale_bound.x, scale_bound.y, scale);
        float scale_y = mix(scale_bound.x, scale_bound.y, scale);
        float scale_z = mix(scale_bound.x, scale_bound.y, scale);
        vec3 scale_dim3 = vec3(scale_x, scale_y, scale_z);
        
        float max_offset = 5.f;
        vec3 offset =max_offset * vec3(random31(cell * -175.234f), random31(cell * 13.45f + 1.f), random31(cell * 25.31f + 2.f));
        vec3 point = repeat(curr_pos, vec3(grid_size));
        point = repeat(point, vec3(grid_size));
        point += offset;
        
        point /= scale_dim3;
        point = rotateX(point, 15);

        // Query the scene SDF to gain the minimum distance to the surfaces defined by SDF
        march_step = sceneSDF(point);


        if (march_step > max_dist) { // too far away from the surface, simply cut it
             break;
        }
        if (abs(march_step) < min_dist) { // already clase enough to the surface
            hit_something = 1;
            BSDF bsdf = sceneBSDF(point, id);
            return MarchResult(accum_dist, i, bsdf);
        }

        accum_dist += march_step;// update the accumulated distance
        // update the curr_pos according to the march_step given by the sdf
        // by marching the minimum distance along the ray direction
        curr_pos = ray.origin + accum_dist * ray.direction;
    }
    return result;
}

float compute_wall_thickness(Ray ray){
    float max_dist = 1.0;
    vec3 curr_pos = ray.origin;// initialize the origin of the ray to be the current position

    // Declare a march result and initialize it to 0
    float accum_dist = 0.;// initialize the accumulated distance to be 0
    float march_step = 0.005;// initialize the march step to be 0.001
    float wall_thickness = 0.0;

    for (int i = 0; i < 5; ++i) {
        accum_dist += march_step; // update the accumulated distance
        if(accum_dist > ao_thickness_search_dist){
            break;
        }
        curr_pos = ray.origin + accum_dist * ray.direction;
        wall_thickness = 1.0 / pow(2.0, float(i)) * (float(i) * march_step - sceneSDF(curr_pos));
    }

    return 1.0 - wall_thickness;
}


/**
* Compute the subsurface scattering color function
*/
vec3 subsurfaceColor(vec3 lightDir, vec3 normal, vec3 viewVec, float thin, vec3 albedo, vec3 light_col) {
    vec3 scatterDir = lightDir + normal * DISTORTION; // Last term is tunable
    float lightReachingEye = pow(clamp(dot(viewVec, -scatterDir), 0.0, 1.0), GLOW) * SCALE;
    float attenuation = max(0.0, dot(normal, lightDir) + dot(viewVec, -lightDir));
    float totalLight = attenuation * (lightReachingEye + AMBIENT) * thin;
    return albedo * light_col * totalLight;
}


void main()
{
    initializeCells(); // initialize the cell grid
    Ray ray = rayCast();
    MarchResult result = raymarch(ray);
    BSDF bsdf = result.bsdf;

    if(USE_SPHERE){
        bsdf.albedo = u_Albedo;
        bsdf.metallic = u_Metallic;
        bsdf.roughness = u_Roughness;
        bsdf.ao = u_AmbientOcclusion;
    }

    // Compute Subsurface Scattering color
    Ray nor = Ray(bsdf.pos, -bsdf.nor);
    float ao_thickness = compute_wall_thickness(nor);
    vec3 light_vec = normalize(-u_CamPos + bsdf.pos);
    vec3 view_vec  = normalize(u_CamPos - bsdf.pos);
    vec3 light_col = texture(u_DiffuseIrradianceMap, -bsdf.nor).rgb;

#if SUBSURFACE_COL
    vec3 subsurface_color = (1 - bsdf.metallic) * subsurfaceColor(light_vec, result.bsdf.nor, view_vec, ao_thickness, bsdf.albedo, light_col);
    vec3 color = metallic_plastic_LTE(bsdf, -ray.direction) + subsurface_color;
#endif
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