#version 330 core

uniform sampler2D u_TextureSSR;
uniform sampler2D u_Kernel;
uniform int u_KernelRadius;

in vec2 fs_UV;
layout (location = 0) out vec4 out_Col;

void main() {
    // TODO: Apply a Gaussian blur to the screen-space reflection
    // texture using the kernel stored in u_Kernel.
    vec4 blurred_color = vec4(0.0);
    for(int y = -u_KernelRadius; y < u_KernelRadius; ++y){
        for(int x = -u_KernelRadius; x <= u_KernelRadius; ++x){
            vec2 offset = vec2(x, y) / textureSize(u_TextureSSR, 0);
            vec2 texture_coord = fs_UV + offset;
            
            vec4 neighbor_col = texture(u_TextureSSR, texture_coord);
            float kernel_val = texelFetch(u_Kernel, ivec2(x + u_KernelRadius, y + u_KernelRadius), 0).r;

            blurred_color += neighbor_col * kernel_val;
        }
    }
    out_Col = blurred_color;
}
