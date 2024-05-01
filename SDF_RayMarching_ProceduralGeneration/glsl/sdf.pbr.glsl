#define GAMMA 2.2
#define INV_GAMMA (1.0 / GAMMA)
const float MAX_REFLECTION_LOD = 4.0;

// Smith's Schlick-GGX approximation
float geometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return num / denom;
}

float geometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = geometrySchlickGGX(NdotV, roughness);
    float ggx1  = geometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// Trowbridge-Reitz GGX microfacet distribution
// An approximation of the Trowbridge-Reitz D() function from PBRT
float distributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

// F0 is surface reflection at zero incidence (looking head on)
vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    float ct = clamp(1.0 - cosTheta, 0.0, 1.0);
    return F0 + (1.0 - F0) * ((ct * ct) * (ct * ct) * ct);
}

// Same as above, but accounts for surface roughness
vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

void coordinateSystem(in vec3 nor, out vec3 tan, out vec3 bit) {
    if (abs(nor.x) > abs(nor.y))
        tan = vec3(-nor.z, 0, nor.x) / sqrt(nor.x * nor.x + nor.z * nor.z);
    else
        tan = vec3(0, nor.z, -nor.y) / sqrt(nor.y * nor.y + nor.z * nor.z);
    bit = cross(nor, tan);
}

/**
* Compute the Metallic, Roughness, and Mask values for the material
*/
vec3 metallic_plastic_LTE(BSDF bsdf, vec3 wo) {
    vec3 N = bsdf.nor;
    vec3 albedo = bsdf.albedo;
    float metallic = bsdf.metallic;
    float roughness = bsdf.roughness;
    float ambientOcclusion = bsdf.ao;

    vec3 woW = wo; // retrive the woW from the input
    vec3 wiW = reflect(-woW, N); // get the incoming direction of the light

    // Compute the material innate color R
    // R innnate material color used in Fresnel reflectance function, R depends on the metalness of our surface
    // Fully plastic, R is just vec3(0.04)
    // Full metal, R is the albedo
    vec3 R = mix(vec3(0.04), albedo, metallic);


    /**
    * Retrieve the diffuse component from the pre-computed u_DiffuseIrradianceMap
    */
    vec3 final_col = vec3(0.f);
    vec3 diffuse = albedo * texture(u_DiffuseIrradianceMap, N).rgb;

    /**
    * Compute the glossy reflection
    */
    // 1. Fresnel Term using Schlick approximation
    vec3 ks = fresnelSchlick(max(dot(N, woW), 0.f), R);
    vec3 kd = vec3(1.f) - ks;
    kd *= 1.f - metallic;
    // 2. Retrieve the combined D and G term by sampling u_BRDFLookupTexture
    vec2 brdfLookUpResult = texture(u_BRDFLookupTexture, vec2(max(dot(N, woW), 0.0), roughness)).xy;
    // 3. Use wi, roughness to sample u_GlossyIrradianceMap using textureLod to determine the mipmap level
    vec3 glossy = textureLod(u_GlossyIrradianceMap, wiW, roughness * MAX_REFLECTION_LOD).rgb;

    // Compute the Specular Term
    vec3 specular = glossy * (ks * brdfLookUpResult.x + brdfLookUpResult.y);
    vec3 ambient = (kd * diffuse + specular) * ambientOcclusion;
    // Direct return thes Material Color without reinhard and gamma (will do later)
    vec3 final_Col = ambient + vec3(0.f);
    return final_Col;
}
