#version 330 core

uniform sampler2D u_AlbedoTexture;
uniform sampler2D u_MetallicTexture;
uniform sampler2D u_RoughnessTexture;

// Image-based lighting (only used if computing PBR reflection here)
uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

in vec3 fs_Pos;
in vec3 fs_Nor;
in vec2 fs_UV;

layout (location = 0) out vec4 gb_WorldSpacePosition;
layout (location = 1) out vec4 gb_Normal;
layout (location = 2) out vec3 gb_Albedo;
// R channel is metallic, G channel is roughness, B channel is mask
layout (location = 3) out vec3 gb_Metal_Rough_Mask;
layout (location = 4) out vec3 gb_PBR; // Optional

uniform vec3 u_CamPos;


const float PI = 3.14159f;

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

vec3 ComputeLTE(vec3 pos, vec3 N, vec3 albedo, float metallic, float roughness)
{
    vec3 V = normalize(u_CamPos - fs_Pos);
    vec3 R = reflect(-V, N);

    vec3 Lo = vec3(0.f);

    vec3 F0 = mix(vec3(0.04), albedo, metallic);

    // The above loop is effectively the integral over the hemisphere
    // for fs_Pos since we only care about direct light & there are
    // only point lights

    vec3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);

    vec3 kS = F;
    vec3 kD = vec3(1.0) - kS;
    kD *= (1.0 - metallic);

    // Sample our diffuse illumination & combine it with our albedo
    vec3 diffuseIrradiance = texture(u_DiffuseIrradianceMap, N).rgb;
    vec3 diffuse = diffuseIrradiance * albedo;

    // Sample the glossy irradiance map & the BRDF lookup texture
    // Combine these values via the split-sum approximation
    const float MAX_REFLECTION_LOD = 4.0;
    vec3 glossyIrradiance = textureLod(u_GlossyIrradianceMap, R,
                                       roughness * MAX_REFLECTION_LOD).rgb;
    vec2 brdf = texture(u_BRDFLookupTexture, vec2(max(dot(N, V), 0.0), roughness)).rg;
    vec3 specular = glossyIrradiance * (F * brdf.x + brdf.y);

//    out_Col = vec4(specular, 1.);
//    out_Col = out_Col / (out_Col + vec4(1.0));
//    // Gamma correction
//    out_Col = pow(out_Col, vec4(1.0/2.2));
//    out_Col.a = 1.;
//    return;

    vec3 ambient = (kD * diffuse + specular);
    return ambient + Lo;
}

void main()
{
    // TODO: Write the appropriate values into each of the
    // out variables in this shader so that the G-buffer
    // can save each of them in a texture.
    gb_WorldSpacePosition = vec4(fs_Pos, 1.0);
    gb_Normal= vec4(fs_Nor, 1.0);
    gb_Albedo = pow(texture(u_AlbedoTexture, fs_UV).rgb, vec3(2.2));
    gb_Metal_Rough_Mask = vec3(texture(u_MetallicTexture, fs_UV).r, texture(u_RoughnessTexture, fs_UV).r, 0.0);


    gb_PBR = ComputeLTE(fs_Pos, fs_Nor, gb_Albedo, gb_Metal_Rough_Mask.r, gb_Metal_Rough_Mask.g);
}
