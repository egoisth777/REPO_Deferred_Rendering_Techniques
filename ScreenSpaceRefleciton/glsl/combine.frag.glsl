#version 330 core

// [0] is the specular reflection.
// [4] is the diffuse reflection.
// [1][2][3] are intermediate levels of glossy reflection.
uniform sampler2D u_TexSSR[5];

uniform sampler2D u_TexPositionWorld;
uniform sampler2D u_TexNormal;
uniform sampler2D u_TexAlbedo;
uniform sampler2D u_TexMetalRoughMask;

uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

uniform vec3 u_CamPos;

in vec2 fs_UV;

out vec4 out_Col;

const float PI = 3.14159f;
const float MAX_REFLECTION_LOD = 4.0;

#define GAMMA 2.2

// Define some helper functions
vec3 reinhard(vec3 color){
    return color / (color + vec3(1.0));
}

// Apply Gamma correction
vec3 gammaCorrect(vec3 color){
    return pow(color, vec3(1.0 / GAMMA));
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}


vec3 computeLTE(vec3 pos, vec3 N,
                vec3 albedo, float metallic, float roughness,
                vec3 wo,
                vec4 Li_Diffuse,
                vec4 Li_Glossy) {
    // TODO: Implement this based on your PBR shader code.
    // Don't apply the Reinhard operator or gamma correction;
    // they should be applied at the end of main().
    
    // When you evaluate the Diffuse BSDF portion of your LTE,
    // the Li term should be a LERP between Li_Diffuse and the
    // color in u_DiffuseIrradianceMap based on the alpha value
    // of Li_Diffuse.
    
    // Likewise, your Microfacet BSDF portion's Li will be a mix
    // of Li_Glossy and u_GlossyIrradianceMap's color based on
    // Li_Glossy.a

    // Everything else will be the same as in the code you
    // wrote for the previous assignment.
    vec3 wo_w = wo;
    vec3 wi_w = reflect(-wo_w, N);
    
    // R term of the Fresnel-Schlick approximation, R depends on the metalness of the surface
    vec3 R = mix(vec3(0.04), albedo, metallic);

    // Copmute the Diffuse BSDF term
    vec3 pbr_col = vec3(0.f);
    vec3 diffuse = albedo * mix(texture(u_DiffuseIrradianceMap, N).rgb, Li_Diffuse.rgb , Li_Diffuse.w); 
    // vec3 diffuse = albedo * texture(u_DiffuseIrradianceMap, N).rgb; 
    // Compute the Glossy Reflection term
    // 1. Fresnel Term using Schlick approximation
    vec3 ks = fresnelSchlick(max(dot(N, wo_w), 0.f), R);
    vec3 kd = vec3(1.f) - ks;
    kd *= 1.f - metallic;
    // 2. Retrieve the combined D and G term by sampling u_BRDFLookupTexture
    vec2 brdfLookUpResult = texture(u_BRDFLookupTexture, vec2(max(dot(N, wo_w), 0.0), roughness)).xy;
    // 3. Use wi, roughness to sample u_GlossyIrradianceMap using textureLod to determine the mipmap level
    vec3 glossy = textureLod(u_GlossyIrradianceMap, wi_w, roughness * MAX_REFLECTION_LOD).rgb;
    glossy = mix(glossy, Li_Glossy.rgb, Li_Glossy.a);
    
    // Compute the Specular Term
    vec3 specular = glossy * (ks * brdfLookUpResult.x + brdfLookUpResult.y);
    vec3 ambient = (kd * diffuse + specular) * 1.f;
    pbr_col = ambient + vec3(0.f);
    return pbr_col;
}



void main() {
    // TODO: Combine all G-buffer textures into your final
    // output color. Compared to the environment-mapped
    // PBR shader, you will have two additional Li terms.

    // One represents your diffuse screen reflections, sampled
    // from the last index in the u_TexSSR sampler2D array.

    // The other represents your glossy screen reflections,
    // interpolated between two levels of glossy reflection stored
    // in the lower indices of u_TexSSR. Your interpolation t will
    // be dependent on your roughness.
    // For example, if your roughness were 0.1, then your glossy
    // screen-space reflected color would be:
    // mix(u_TexSSR[0], u_TexSSR[1], fract(0.1 * 4))
    // If roughness were 0.9, then your color would be:
    // mix(u_TexSSR[2], u_TexSSR[3], fract(0.9 * 4))
#if 1
    if(texture(u_TexPositionWorld, fs_UV).a <= 0.f) return; 
    vec3 albedo = texture(u_TexAlbedo, fs_UV).rgb;
    vec3 pos_w = texture(u_TexPositionWorld, fs_UV).xyz;
    float metallic = texture(u_TexMetalRoughMask, fs_UV).r;
    float roughness = texture(u_TexMetalRoughMask, fs_UV).g;
    vec3 normal_w = texture(u_TexNormal, fs_UV).xyz;
    vec3 wo_w = normalize(u_CamPos - texture(u_TexPositionWorld, fs_UV).xyz);
    

    vec4 Li_Diffuse_refl = texture(u_TexSSR[4], fs_UV);
    
    vec4 Li_Glossy_refl;
    if(roughness >= 0 && roughness <= 0.25){
        Li_Glossy_refl = mix(texture(u_TexSSR[0], fs_UV), texture(u_TexSSR[1], fs_UV), fract(roughness * 4.f));
    }else if(roughness > 0.25 && roughness <= 0.5){
        Li_Glossy_refl = mix(texture(u_TexSSR[1], fs_UV), texture(u_TexSSR[2], fs_UV), fract(roughness * 4.f));
    }else if (roughness > 0.5 && roughness <= 0.75){
        Li_Glossy_refl = mix(texture(u_TexSSR[2], fs_UV), texture(u_TexSSR[3], fs_UV), fract(roughness * 4.f));
    }else{
        Li_Glossy_refl = mix(texture(u_TexSSR[3], fs_UV), texture(u_TexSSR[4], fs_UV), fract(roughness * 4.f));
    }

    
    vec3 LTE_col = computeLTE(pos_w, normal_w, albedo, metallic, roughness, wo_w, Li_Diffuse_refl, Li_Glossy_refl);
    
    vec3 col = gammaCorrect(reinhard(LTE_col));
    out_Col = vec4(col, 1.f);
#endif

#if 0 // test output of the SSR texture (What it looks like on the screen)
    out_Col = texture(u_TexSSR[0], fs_UV);
#endif 
}
