#version 330 core

#define SPHERE    (1 << 0)
#define WAHOO     (1 << 1)
#define FREEFORM1 (1 << 2)

#define OBJECT_TYPE FREEFORM1

#define USE_SPHERE    ((OBJECT_TYPE & SPHERE) != 0)
#define USE_WAHOO     ((OBJECT_TYPE & WAHOO) != 0)
#define USE_FREEFORM1 ((OBJECT_TYPE & FREEFORM1) != 0)

uniform float u_Time;

uniform vec3 u_CamPos;
uniform vec3 u_Forward, u_Right, u_Up;
uniform vec2 u_ScreenDims;

// PBR material attributes
uniform vec3 u_Albedo;
uniform float u_Metallic;
uniform float u_Roughness;
uniform float u_AmbientOcclusion;
// Texture maps for controlling some of the attribs above, plus normal mapping
uniform sampler2D u_AlbedoMap;
uniform sampler2D u_MetallicMap;
uniform sampler2D u_RoughnessMap;
uniform sampler2D u_AOMap;
uniform sampler2D u_NormalMap;
// If true, use the textures listed above instead of the GUI slider values
uniform bool u_UseAlbedoMap;
uniform bool u_UseMetallicMap;
uniform bool u_UseRoughnessMap;
uniform bool u_UseAOMap;
uniform bool u_UseNormalMap;

// Image-based lighting
uniform samplerCube u_DiffuseIrradianceMap;
uniform samplerCube u_GlossyIrradianceMap;
uniform sampler2D u_BRDFLookupTexture;

// Varyings
in vec2 fs_UV;
out vec4 out_Col;

const float PI = 3.14159f;

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct BSDF {
    vec3 pos;
    vec3 nor;
    vec3 albedo;
    float metallic;
    float roughness;
    float ao;
    float thickness;
};

struct MarchResult {
    float t;
    int hitSomething;
    BSDF bsdf;
};

struct SmoothMinResult {
    float dist;
    float material_t;
};

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }

float sceneSDF(vec3 query);

vec3 SDF_Normal(vec3 query) {
    vec2 epsilon = vec2(0.0, 0.001);
    return normalize( vec3( sceneSDF(query + epsilon.yxx) - sceneSDF(query - epsilon.yxx),
                            sceneSDF(query + epsilon.xyx) - sceneSDF(query - epsilon.xyx),
                            sceneSDF(query + epsilon.xxy) - sceneSDF(query - epsilon.xxy)));
}

float SDF_Sphere(vec3 query, vec3 center, float radius) {
    return length(query - center) - radius;
}

float SDF_Box(vec3 query, vec3 bounds ) {
  vec3 q = abs(query) - bounds;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float SDF_RoundCone( vec3 query, vec3 a, vec3 b, float r1, float r2) {
  // sampling independent computations (only depend on shape)
  vec3  ba = b - a;
  float l2 = dot(ba,ba);
  float rr = r1 - r2;
  float a2 = l2 - rr*rr;
  float il2 = 1.0/l2;

  // sampling dependant computations
  vec3 pa = query - a;
  float y = dot(pa,ba);
  float z = y - l2;
  float x2 = dot2( pa*l2 - ba*y );
  float y2 = y*y*l2;
  float z2 = z*z*l2;

  // single square root!
  float k = sign(rr)*rr*rr*x2;
  if( sign(z)*a2*z2>k ) return  sqrt(x2 + z2)        *il2 - r2;
  if( sign(y)*a2*y2<k ) return  sqrt(x2 + y2)        *il2 - r1;
                        return (sqrt(x2*a2*il2)+y*rr)*il2 - r1;
}

float smooth_min( float a, float b, float k ) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

SmoothMinResult smooth_min_lerp( float a, float b, float k ) {
    float h = max( k-abs(a-b), 0.0 )/k;
    float m = h*h*0.5;
    float s = m*k*0.5;
    if(a < b) {
        return SmoothMinResult(a-s,m);
    }
    return SmoothMinResult(b-s,1.0-m);
}

vec3 repeat(vec3 query, vec3 cell) {
    return mod(query + 0.5 * cell, cell) - 0.5 * cell;
}

float subtract(float d1, float d2) {
    return max(d1, -d2);
}

float opIntersection( float d1, float d2 ) {
    return max(d1,d2);
}

float opOnion(float sdf, float thickness ) {
    return abs(sdf)-thickness;
}

vec3 rotateX(vec3 p, float angle) {
    angle = angle * 3.14159 / 180.f;
    float c = cos(angle);
    float s = sin(angle);
    return vec3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
}

vec3 rotateZ(vec3 p, float angle) {
    angle = angle * 3.14159 / 180.f;
    float c = cos(angle);
    float s = sin(angle);
    return vec3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
}

float SDF_Stache(vec3 query) {
    float left = SDF_Sphere(query / vec3(1,1,0.3), vec3(0.2, -0.435, 3.5), 0.1) * 0.1;
    left = min(left, SDF_Sphere(query / vec3(1,1,0.3), vec3(0.45, -0.355, 3.5), 0.1) * 0.1);
    left = min(left, SDF_Sphere(query / vec3(1,1,0.3), vec3(0.7, -0.235, 3.5), 0.09) * 0.1);
    left = subtract(left, SDF_Sphere(rotateZ(query, -15) / vec3(1.3,1,1), vec3(0.3, -0.1, 1.), 0.35));

    float right = SDF_Sphere(query / vec3(1,1,0.3), vec3(-0.2, -0.435, 3.5), 0.1) * 0.1;
    right = min(right, SDF_Sphere(query / vec3(1,1,0.3), vec3(-0.45, -0.355, 3.5), 0.1) * 0.1);
    right = min(right, SDF_Sphere(query / vec3(1,1,0.3), vec3(-0.7, -0.235, 3.5), 0.09) * 0.1);
    right = subtract(right, SDF_Sphere(rotateZ(query, 15) / vec3(1.3,1,1), vec3(-0.3, -0.1, 1.), 0.35));

    return min(left, right);
}

float SDF_Wahoo_Skin(vec3 query) {
    // head base
    float result = SDF_Sphere(query / vec3(1,1.2,1), vec3(0,0,0), 1.) * 1.1;
    // cheek L
    result = smooth_min(result, SDF_Sphere(query, vec3(0.5, -0.4, 0.5), 0.5), 0.3);
    // cheek R
    result = smooth_min(result, SDF_Sphere(query, vec3(-0.5, -0.4, 0.5), 0.5), 0.3);
    // chin
    result = smooth_min(result, SDF_Sphere(query, vec3(0.0, -0.85, 0.5), 0.35), 0.3);
    // nose
    result = smooth_min(result, SDF_Sphere(query / vec3(1.15,1,1), vec3(0, -0.2, 1.15), 0.35), 0.05);
    return result;
}

float SDF_Wahoo_Hat(vec3 query) {
    float result = SDF_Sphere(rotateX(query, 20) / vec3(1.1,0.5,1), vec3(0,1.65,0.4), 1.);
    result = smooth_min(result, SDF_Sphere((query - vec3(0,0.7,-0.95)) / vec3(2.5, 1.2, 1), vec3(0,0,0), 0.2), 0.3);
    result = smooth_min(result, SDF_Sphere(query / vec3(1.5,1,1), vec3(0, 1.3, 0.65), 0.5), 0.3);

    float brim = opOnion(SDF_Sphere(query / vec3(1.02, 1, 1), vec3(0, -0.15, 1.), 1.1), 0.02);

    brim = subtract(brim, SDF_Box(rotateX(query - vec3(0, -0.55, 0), 10), vec3(10, 1, 10)));

    result = min(result, brim);

    return result;
}


float SDF_Wahoo(vec3 query) {
    // Flesh-colored parts
    float result = SDF_Wahoo_Skin(query);
    // 'stache parts
    result = min(result, SDF_Stache(query));
    // hat
    result = min(result, SDF_Wahoo_Hat(query));

    return result;
}

/**
* Return the normal of a cone
* Credit: https://iquilezles.org/articles/distfunctions/
* IQ's SDF_exact_cone function
*/
float SDF_exact_cone( vec3 p, vec2 c, float h ) {

    // c is the sin/cos of the angle, h is height
    // Alternatively pass q instead of (c,h),
    // which is the point at the base in 2D
    vec2 q = h*vec2(c.x/c.y,-1.0);

    vec2 w = vec2( length(p.xz), p.y );
    vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
    float k = sign( q.y );
    float d = min(dot( a, a ),dot(b, b));
    float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
    return sqrt(d)*sign(s);
}

/**
* SDF of the horns of the freeform object
* @return float the sdf value
*/
float SDF_Freeform_horns(vec3 query){
    // Define the left and right horns
    // right horns
    float result1 = SDF_exact_cone(rotateZ(rotateX(query - vec3(1.2, 1.0, -0.3), 15), 45), vec2(0.5, 0.7), 1.0);
    float result2 = SDF_exact_cone(rotateZ(rotateX(query - vec3(-1.2, 1.0, -0.3), 15), -45), vec2(0.5, 0.7), 1.0);
    float horn_sdf = smooth_min(result1, result2, 0.1);
    return horn_sdf;
}

/**
* SDF of the head of the freeform object
*tstatus
*/
float SDF_Freeform_head(vec3 query){

    float face_sdf = SDF_Sphere(query / vec3(1,1.2,1), vec3(0,0,0), 1.) * 1.1;
    // cheek L
    face_sdf= smooth_min(face_sdf, SDF_Sphere(query, vec3(0.5, -0.4, 0.5), 0.5), 0.3);
    // cheek R
    face_sdf = smooth_min(face_sdf, SDF_Sphere(query, vec3(-0.5, -0.4, 0.5), 0.5), 0.3);
    // chin
    face_sdf = smooth_min(face_sdf, SDF_Sphere(query, vec3(0.0, -0.85, 0.5), 0.35), 0.3);
    // nose
    face_sdf = smooth_min(face_sdf, SDF_Sphere(query / vec3(1.15,1, 1.7), vec3(0, -0.2, 0.43), 0.6), 0.05);
    face_sdf = smooth_min(face_sdf, SDF_Sphere(query, vec3(0.0, -1.0, 0.0), 1.0), 0.1);

    return face_sdf;
}


float SDF_freeform_cross(vec3 query) {
    // Create the sphere base

    float sphere_base = SDF_Sphere(query, vec3(0.0, 1.0, 0.0), 1.0);
    float box1 = SDF_Box(query - vec3(0.0, 2.5, 0.0), vec3(0.2, 1.5, 0.2));
    float box2 = SDF_Box(query - vec3(0.0, 2.5, 0.0), vec3(1.0, 0.2, 0.2));
    box1 = smooth_min(box1, box2, 0.1);
    box1 = smooth_min(box1, sphere_base, 0.1);
    return box1;
}


float SDF_Freeform1(vec3 query) {
    float head = SDF_Freeform_head(query);
    float horns = SDF_Freeform_horns(query);
    float cross = SDF_freeform_cross(query);
    float result = smooth_min(head, horns, 0.1);
    result = smooth_min(result, cross, 0.1);
    return result;
}


/**
* Return the BSDF of Wahoo{
*/
BSDF BSDF_Wahoo(vec3 query) {
    // Head base
    BSDF result = BSDF(query, normalize(query), pow(vec3(239, 181, 148) / 255., vec3(2.2)),
                       0., 0.7, 1., 2.0);

    result.nor = SDF_Normal(query);

    float skin = SDF_Wahoo_Skin(query);
    float stache = SDF_Stache(query);
    float hat = SDF_Wahoo_Hat(query);

    if(stache < skin && stache < hat) {
        result.albedo = pow(vec3(68,30,16) / 255., vec3(2.2));
    }
    if(hat < skin && hat < stache) {
        result.albedo = pow(vec3(186,45,41) / 255., vec3(2.2));
    }

    return result;
}

/**
* Return the BSDF of the head
*/
BSDF BSDF_freeform1(vec3 query){
    // Head Base
    BSDF result = BSDF(query, normalize(query), pow(vec3(239, 181, 148) / 255., vec3(2.2)), 0., 0.7, 1., 2.0);
    result.nor = SDF_Normal(query);
    float head = SDF_Freeform_head(query);
    float horns = SDF_Freeform_horns(query);
    float cross = SDF_freeform_cross(query);

    if(horns < head && horns < cross) {
        result.albedo = pow(vec3(30,60,16) / 255., vec3(2.2));
        result.metallic = 0.1;
        result.roughness = 0.7;
    }

    if(cross < head && cross < horns) {
        result.albedo = pow(vec3(186,45,41) / 255., vec3(2.2));
        result.metallic = 1.0;
        result.roughness = 0.3;
    }

    return result;
}

BSDF BSDF_freeform_rep1(vec3 query){
    // Head Base
    BSDF result = BSDF(query, normalize(query), pow(vec3(239, 181, 148) / 255., vec3(2.2)),
    0., 0.7, 1., 2.0);
    result.nor = SDF_Normal(query);
    float head = SDF_Freeform_head(query);
    float horns = SDF_Freeform_horns(query);
    float cross = SDF_freeform_cross(query);

    if(horns < head && horns < cross) {
        result.albedo = pow(vec3(30,60,16) / 255., vec3(2.2));
        result.metallic = 0.1;
        result.roughness = 0.7;
    }

    if(cross < head && cross < horns) {
        result.albedo = pow(vec3(186,45,41) / 255., vec3(2.2));
        result.metallic = 1.0;
        result.roughness = 0.3;
    }

    return result;
}

BSDF BSDF_freeform_rep2(vec3 query){
    // Head Base
    BSDF result = BSDF(query, normalize(query), pow(vec3(239, 181, 148) / 255., vec3(2.2)),
    0., 0.7, 1., 2.0);
    result.nor = SDF_Normal(query);
    float head = SDF_Freeform_head(query);
    float horns = SDF_Freeform_horns(query);
    float cross = SDF_freeform_cross(query);

    if(horns < head && horns < cross) {
        result.albedo = pow(vec3(30,60,16) / 255., vec3(2.2));
        result.metallic = 0.1;
        result.roughness = 0.7;
    }

    if(cross < head && cross < horns) {
        result.albedo = pow(vec3(186,45,41) / 255., vec3(2.2));
        result.metallic = 1.0;
        result.roughness = 0.3;
    }

    return result;
}

BSDF BSDF_freeform_rep3(vec3 query){
    // Head Base
    BSDF result = BSDF(query, normalize(query), pow(vec3(239, 181, 148) / 255., vec3(2.2)),
    0., 0.7, 1., 2.0);
    result.nor = SDF_Normal(query);
    float head = SDF_Freeform_head(query);
    float horns = SDF_Freeform_horns(query);
    float cross = SDF_freeform_cross(query);

    if(horns < head && horns < cross) {
        result.albedo = pow(vec3(30,60,16) / 255., vec3(2.2));
        result.metallic = 0.1;
        result.roughness = 0.7;
    }

    if(cross < head && cross < horns) {
        result.albedo = pow(vec3(186,45,41) / 255., vec3(2.2));
        result.metallic = 1.0;
        result.roughness = 0.3;
    }

    return result;
}

BSDF BSDF_freeform_rep4(vec3 query){
    // Head Base
    BSDF result = BSDF(query, normalize(query), pow(vec3(239, 181, 148) / 255., vec3(2.2)),
    0., 0.7, 1., 2.0);
    result.nor = SDF_Normal(query);
    float head = SDF_Freeform_head(query);
    float horns = SDF_Freeform_horns(query);
    float cross = SDF_freeform_cross(query);

    if(horns < head && horns < cross) {
        result.albedo = pow(vec3(30,60,16) / 255., vec3(2.2));
        result.metallic = 0.1;
        result.roughness = 0.7;
    }

    if(cross < head && cross < horns) {
        result.albedo = pow(vec3(186,45,41) / 255., vec3(2.2));
        result.metallic = 1.0;
        result.roughness = 0.3;
    }

    return result;
}


/**
* Scene SDF
*/
float sceneSDF(vec3 query){

    vec3 p= repeat(query, vec3(10.0));

    if(USE_SPHERE){
        return SDF_Sphere(p, vec3(0.), 1.f);
    }

    if(USE_WAHOO){
        return SDF_Wahoo(p);
    }

    if(USE_FREEFORM1){
        return SDF_Freeform1(p);
    }

    return 0.f;
}

BSDF sceneBSDF(vec3 query) {

    vec3 p = repeat(query, vec3(10.0));
    if(USE_SPHERE){ // Use a simple default materials
        return BSDF(query, SDF_Normal(p), vec3(0.5, 0.5, 0.5), 0.5, 0.5, 1., 2.0);
    }
    if(USE_WAHOO){
//        return BSDF(query, SDF_Normal(query), vec3(0.5, 0, 0), 0.5, 0.5, 1.);
         return BSDF_Wahoo(p);
    }
    if(USE_FREEFORM1){
        return BSDF_freeform1(p);
//        return BSDF(query, SDF_Normal(query), vec3(0.5, 0.5, 0.5), 0.5, 0.5, 1.);
    }
    return BSDF(query, SDF_Normal(p), vec3(0.5, 0.5, 0.5), 0.5, 0.5, 1., 2.0);
}

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


#define FOVY 45 * PI / 180.f
#define EPSILON 0.001
#define DISTORTION 0.2
#define GLOW 6.0
#define SCALE 3.0
#define AMBIENT 0.1

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
    vec3 curr_pos = ray.origin;// initialize the origin of the ray to be the current position

    // Declare a march result and initialize it to 0
    MarchResult result = MarchResult(0., 0, BSDF(vec3(0.), vec3(0.), vec3(0.), 0.f, 0.f, 0.f, 0.f));
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

    //TODO
    vec3 subsurface_color = (1 - bsdf.metallic) * subsurfaceColor(light_vec, result.bsdf.nor, view_vec, ao_thickness, bsdf.albedo, light_col);

    vec3 color = metallic_plastic_LTE(bsdf, -ray.direction) + subsurface_color;
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
} 
