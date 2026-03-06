#ifndef UNIVERSAL_COPY_DEPTH_PASS_INCLUDED
#define UNIVERSAL_COPY_DEPTH_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float2 uv           : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings vert(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    output.uv = input.uv;
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    return output;
}

#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
#define DEPTH_TEXTURE(name) TEXTURE2D_ARRAY_FLOAT(name)
#define SAMPLE(uv) SAMPLE_TEXTURE2D_ARRAY(_BlitTex, sampler_BlitTex, uv, unity_StereoEyeIndex).r
#else
#define DEPTH_TEXTURE(name) TEXTURE2D_FLOAT(name)
#define SAMPLE(uv) SAMPLE_DEPTH_TEXTURE(_BlitTex, sampler_BlitTex, uv)
#endif




    DEPTH_TEXTURE(_BlitTex);
    SAMPLER(sampler_BlitTex);


#if UNITY_REVERSED_Z
    #define DEPTH_DEFAULT_VALUE 1.0
    #define DEPTH_OP min
#else
    #define DEPTH_DEFAULT_VALUE 0.0
    #define DEPTH_OP max
#endif

float SampleDepth(float2 uv)
{

    return SAMPLE(uv);

}

float frag(Varyings input) : SV_Depth
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    UNITY_SETUP_INSTANCE_ID(input);
    return SampleDepth(input.uv);
}
float frag2(Varyings input) : SV_Depth
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    UNITY_SETUP_INSTANCE_ID(input);
    return SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, input.uv).a;
}
#endif
