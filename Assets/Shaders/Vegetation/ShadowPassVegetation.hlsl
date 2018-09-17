#ifndef SHADOW_PASS_VEGETATION_INCLUDED
#define SHADOW_PASS_VEGETATION_INCLUDED

#include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Core.hlsl"

// x: global clip space bias, y: normal world space bias
float4 _ShadowBias;
float3 _LightDirection;

struct VertexInput
{
    float4 position     : POSITION;
    float3 normal       : NORMAL;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
    float2 uv           : TEXCOORD0;
    float4 clipPos      : SV_POSITION;
};

float4 GetShadowPositionHClip(VertexInput v)
{
    float3 positionWS = TransformObjectToWorld(v.position.xyz);
    float3 normalWS = TransformObjectToWorldDir(v.normal);

    float invNdotL = 1.0 - saturate(dot(_LightDirection, normalWS));
    float scale = invNdotL * _ShadowBias.y;

    // normal bias is negative since we want to apply an inset normal offset
    positionWS = normalWS * scale.xxx + positionWS;
    float4 clipPos = TransformWorldToHClip(positionWS);

    // _ShadowBias.x sign depens on if platform has reversed z buffer
    clipPos.z += _ShadowBias.x;

#if UNITY_REVERSED_Z
    clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#else
    clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return clipPos;
}

VertexOutput ShadowPassVegetationVertex(VertexInput v)
{
    VertexOutput o;
    UNITY_SETUP_INSTANCE_ID(v);

    o.uv = v.texcoord;
    o.clipPos = GetShadowPositionHClip(v);
    return o;
}

half4 ShadowPassVegetationFragment(VertexOutput IN) : SV_TARGET
{
    half alpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_PARAM(_MainTex, sampler_MainTex)).a;
    clip(alpha - _Cutoff);
    return 0;
}

#endif // SHADOW_PASS_VEGETATION_INCLUDED
