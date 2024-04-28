#version 330 core
#if 1
uniform sampler2D u_TexPositionWorld;
uniform sampler2D u_TexNormal;
uniform sampler2D u_TexAlbedo;
uniform sampler2D u_TexMetalRoughMask;
uniform sampler2D u_TexPBR;

uniform vec3 u_CamPos;
uniform vec3 u_CamForward;
uniform mat4 u_View;
uniform mat4 u_Proj;

in vec2 fs_UV;

const float PI = 3.14159f;
const float MARCH_STEP = 0.034f; // Each step to march
const float MAX_RAYMARCH_DIST = 100; // Maximum marching distance along wi
const float MAX_ITER_COUNT = 20;
const float EPSILON = 0.07; // define EPSILON for the start position
const float THRESHOLD = 0.07;  // define the threshold for intersection
const float TOLERANCE_BIN_SEARCH = 0.01;


#define SCREEN_WIDTH (textureSize(u_TexPositionWorld, 0).x)
#define SCREEN_HEIGHT (textureSize(u_TexPositionWorld, 0).x)

layout (location = 0) out vec4 gb_Reflection;

// Define some spatial transformation helpers
vec3 transform_vec_from_world_to_view(vec3 vec_w){
    return mat3(u_View) * vec_w; // Only Rotation is applied
}

vec3 transform_pos_from_world_to_view(vec3 pos_w){
    return (u_View * vec4(pos_w, 1.f)).xyz;
}


/**
* @brief Transform from View Space to Pixel Space
*/
vec2 transform_pos_from_view_to_pixel(vec3 pos_v){
    vec4 pos_clip = u_Proj * vec4(pos_v, 1.f);
    pos_clip /= pos_clip.w; // obtain the NDC postiion
    vec2 textureDim = textureSize(u_TexPositionWorld, 0); // Obtain from the texture size
    // return the Pixel Space coordinates
    return (pos_clip.xy * 0.5 + 0.5) * textureDim;
}

vec2 transform_pos_from_view_to_UV(vec3 pos_v){
    vec4 pos_clip = u_Proj * vec4(pos_v, 1.f);
    pos_clip /= pos_clip.w; // obtain the NDC postiion
    vec2 textureDim = textureSize(u_TexPositionWorld, 0); // Obtain from the texture size
    // return the Pixel Space coordinates
    return (pos_clip.xy * 0.5 + 0.5);
}

#if 1
vec4 transfromFromWorldToPixel(vec3 world_pos){
    // Apply the proj and view matrices
    vec4 clip_pos = u_Proj * u_View * vec4(world_pos, 1.f);
    clip_pos /= clip_pos.w; // obtain the NDC postiion by perpective divide
    // return the Pixel Space coordinates
    return vec4(
        clip_pos.xy * 0.5 + 0.5,
        clip_pos.z,
        clip_pos.w
    );
}
#endif

/**
* @brief | Ray marching in the current world space and compute the intersection point
* @param start_pos_world : the start of the ray marching position in the world space
* @param end_pos_world: the end of the ray marching position in the world space
* @param wo_world: the outgoing direction in the world space
* @param wi_world: the incoming direction in the world space
* @param last_unhit_pos_w: the last unhit position in the world space
* @param hit_pos_w: the hit position in the world space
*/
bool raymarch_find_intersection(vec3 start_pos_v, vec3 wi_v, inout vec3 last_unhit_pos_v, inout vec3 hit_pos_v){
    
    // march in the view space
    vec3 curr_march_pos_v = start_pos_v;
    for(float accum_dist = 0.0; accum_dist <= MAX_RAYMARCH_DIST; accum_dist += MARCH_STEP, curr_march_pos_v += wi_v * MARCH_STEP)
    {    
        vec2 curr_march_pos_pixel = transform_pos_from_view_to_pixel(curr_march_pos_v);
        vec2 curr_march_pos_UV = transform_pos_from_view_to_UV(curr_march_pos_v);
        
        // make sure that everything outside the screen is not considered                
        if(curr_march_pos_UV.x < 0.0 || curr_march_pos_UV.y  < 0.0 || curr_march_pos_UV.x > 1.0 || curr_march_pos_UV.y > 1.0){
            return false;
        }
        float depth_curr_buffer = abs(transform_pos_from_world_to_view(texture(u_TexPositionWorld, curr_march_pos_UV).xyz).z);
        float depth_diff = abs(curr_march_pos_v.z) - depth_curr_buffer;
         
        if(texture(u_TexPositionWorld, curr_march_pos_UV).w != 0 && depth_diff > 0 && abs(depth_diff) < THRESHOLD){ // if hit something (marched behind)
            hit_pos_v = curr_march_pos_v; //record the position marching further
            return true; // return found            
        }
                
        // record the last unhit position
        last_unhit_pos_v = curr_march_pos_v;
    }
    return false;
}

/**
* @brief Compute the final intersection point using binary search for refinement.
*/
vec3 compute_final_intersection(vec3 last_unhit_pos_v, vec3 hit_pos_v){
    // TODO: implemented the binary search algorithm
    vec3 low = last_unhit_pos_v;
    vec3 high = hit_pos_v;

    for(int i = 0; i < MAX_ITER_COUNT; i++){
        vec3 mid = mix(low, high, 0.5);

        // convert the mid piont to pixel coordinate
        vec2 texture_coord = vec2(transform_pos_from_view_to_UV(mid));
        float gbuffer_depth = abs(transform_pos_from_world_to_view(texture(u_TexPositionWorld, texture_coord).xyz).z);
        
        if(abs(mid.z) < gbuffer_depth){
            low = mid;
        }else{
            high = mid;
        }

        if(distance(low, high) < TOLERANCE_BIN_SEARCH){
            break;
        }
    }
    return low;
}


void main() {
    // Fetch the frag_pos_w, frag_nor_w, view_pos (cam_pos)_w
    
    vec3 frag_pos_w = vec3(texture(u_TexPositionWorld, fs_UV));
    vec3 frag_nor_w = vec3(texture(u_TexNormal, fs_UV));
    vec3 view_pos_w = u_CamPos;
    
    // Step 0 | Before Ray Marching, just justitfy wether the material is reflective
    if(abs(texture(u_TexMetalRoughMask, fs_UV).g - 1.f) < EPSILON){
        return;
    }



    // Step 1 | Ray Marching Prepartaion work
    // Find start_pos_v, wi_v (ray marching direction) 
    // compute the view position, view normal, and wi_v
    // remember, in view space, cam_pos is just (0, 0, 0)
    vec3 frag_pos_v = transform_pos_from_world_to_view(frag_pos_w);
    vec3 frag_nor_v = transform_vec_from_world_to_view(frag_nor_w);
    vec3 wo_w = normalize(frag_pos_w - view_pos_w);
    vec3 wi_w = normalize(reflect(wo_w, frag_nor_w));
    vec3 wo_v = normalize(frag_pos_v); // any point in the view space is the vector that spans from view to that pos
    bool is_background = texture(u_TexPositionWorld, fs_UV).w == 0;
    // compute the wi_v
    vec3 wi_v =  normalize(reflect(wo_v, frag_nor_v));
    // defining the start point at the view space
    vec3 start_pos_v = frag_pos_v + EPSILON * frag_nor_v;

    // Step 2 | Start Ray Marching to Find the Intersection Point
    // After this step, obtain a roughly last_unhit_pos, hit_pos, both in view space
    // and a bool indicating whether we have hit the geometry or not
    vec3 last_unhit_pos = start_pos_v;
    vec3 hit_pos = start_pos_v;

    
    bool isIntersected = raymarch_find_intersection(start_pos_v, wi_v, last_unhit_pos, hit_pos);
    if(!isIntersected){
        gb_Reflection = vec4(0.f);
        return;
    }

#if 0
    // Step 3 | Apply Binary Search on last hit pos and last unhit_pos
    vec3 isect_pos_v = compute_final_intersection(last_unhit_pos, hit_pos);    
    float depth = abs(isect_pos_v.z);
    
    // Step 4 | Attenuate the Reflection UV and refine the reflection result
    vec2 refl_UV = transform_pos_from_view_to_UV(isect_pos_v);     
#endif
#if 1
    vec2 refl_UV = transform_pos_from_view_to_UV(hit_pos);
#endif

    float visibility = 1.f;
    visibility *= smoothstep(0.f, 0.05f, refl_UV.x)
          * (1 - smoothstep(0.95f, 1.f, refl_UV.x))
          * smoothstep(0.f, 0.05f, refl_UV.y)
          * (1 - smoothstep(0.95f, 1.f, refl_UV.y));
    gb_Reflection = vec4(texture(u_TexPBR, refl_UV).xyz, visibility);
    // gb_Reflection = vec4(vec3(0.f ), visibility);
}
#endif

