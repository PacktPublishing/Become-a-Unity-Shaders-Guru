#ifndef PARALLAX_FUNCTIONS_INCLUDED
#define PARALLAX_FUNCTIONS_INCLUDED

void ParallaxLoop_float(
    TEXTURE2D_PARAM(mask, sampler_mask),
    float parallaxOffset,
    float iterations,
    float3 viewDirectionTS,
    float2 UV,
    out float4 Result)
{
    float4 result = float4(1, 1, 1, 1);
    float maskSample = 0;
    float totalOffset = 0;

    for (int i = 0; i < iterations; ++i) {
        totalOffset += parallaxOffset;
        float2 offset = float2(viewDirectionTS.r * totalOffset, viewDirectionTS.g * totalOffset);
        maskSample = SAMPLE_TEXTURE2D(mask, sampler_mask, UV + offset).r;
        result *= clamp(maskSample + (i / iterations), 0, 1);
    }
    result.a = 1;

    Result = result;
}

#endif