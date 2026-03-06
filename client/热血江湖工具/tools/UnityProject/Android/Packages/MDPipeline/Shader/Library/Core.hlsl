//Reference this library in shader : #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
#ifndef _SHADERLIBRARYCORE_H
    #define _SHADERLIBRARYCORE_H

    #include "Color.hlsl"
    #include "SimplePBS.hlsl"
    #include "VoxelLight.hlsl"

    TEXTURE2D(_CameraOpaqueTexture);    SAMPLER(sampler_CameraOpaqueTexture);
    TEXTURE2D_FLOAT(_CameraDepthTexture);     SAMPLER(sampler_CameraDepthTexture);

    float4 ComputeScreenPos(float4 pos)
    {
        float4 o = pos * 0.5f;
        o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
        o.zw = pos.zw;
        return o;
    }

    float3 SampleSceneColor(float2 uv)
    {
        return SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv).rgb;
    }

    //--------------------------------------------Depth----------------------------------------------------
    float SampleSceneDepth(float2 uv)
    {
        return SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
    }

    // Z buffer to linear 0..1 depth (0 at near plane, 1 at far plane).
    // Does NOT correctly handle oblique view frustums.
    // Does NOT work with orthographic projection.
    // zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
    float Linear01DepthFromNear(float depth, float4 zBufferParam)
    {
        return 1.0 / (zBufferParam.x + zBufferParam.y / depth);
    }

    // Z buffer to linear 0..1 depth (0 at camera position, 1 at far plane).
    // Does NOT work with orthographic projections.
    // Does NOT correctly handle oblique view frustums.
    // zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
    float Linear01Depth(float depth, float4 zBufferParam)
    {
        return 1.0 / (zBufferParam.x * depth + zBufferParam.y);
    }

    // Z buffer to linear depth.
    // Does NOT correctly handle oblique view frustums.
    // Does NOT work with orthographic projection.
    // zBufferParam = { (f-n)/n, 1, (f-n)/n*f, 1/f }
    float LinearEyeDepth(float depth, float4 zBufferParam)
    {
        return 1.0 / (zBufferParam.z * depth + zBufferParam.w);
    }

    // Z buffer to linear depth.
    // Correctly handles oblique view frustums.
    // Does NOT work with orthographic projection.
    // Ref: An Efficient Depth Linearization Method for Oblique View Frustums, Eq. 6.
    float LinearEyeDepth(float2 positionNDC, float deviceDepth, float4 invProjParam)
    {
        float4 positionCS = float4(positionNDC * 2.0 - 1.0, deviceDepth, 1.0);
        float  viewSpaceZ = rcp(dot(positionCS, invProjParam));

        // If the matrix is right-handed, we have to flip the Z axis to get a positive value.
        return abs(viewSpaceZ);
    }

    // Z buffer to linear depth.
    // Works in all cases.
    // Typically, this is the cheapest variant, provided you've already computed 'positionWS'.
    // Assumes that the 'positionWS' is in front of the camera.
    float LinearEyeDepth(float3 positionWS, float4x4 viewMatrix)
    {
        float viewSpaceZ = mul(viewMatrix, float4(positionWS, 1.0)).z;

        // If the matrix is right-handed, we have to flip the Z axis to get a positive value.
        return abs(viewSpaceZ);
    }

    //正交相机用的
    float RawToLinearDepth(float rawDepth)
    {
        if(unity_OrthoParams.w > 0.1)
        {
            #if UNITY_REVERSED_Z
                rawDepth = (1.0 - rawDepth);
            #endif
            return ((_ProjectionParams.z - _ProjectionParams.y) * (rawDepth) + _ProjectionParams.y);
        }else
            return LinearEyeDepth(rawDepth, _ZBufferParams);
    }

    //---------------------------------------------------------------------------------------------------------

    //------------------------------------System Fog-----------------------------------------------------------
    #if UNITY_REVERSED_Z
        #if SHADER_API_OPENGL || SHADER_API_GLES || SHADER_API_GLES3
            //GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
            #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
        #else
            //D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
            //max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
            #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z),0)
        #endif
    #elif UNITY_UV_STARTS_AT_TOP
        //D3d without reversed z => z clip range is [0, far] -> nothing to do
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
    #else
        //Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
    #endif

    half ComputeFogFactor(float z)
    {
        float clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);

        #if defined(FOG_LINEAR)
            // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
            float fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
            return half(fogFactor);
        #elif defined(FOG_EXP) || defined(FOG_EXP2)
            // factor = exp(-(density*z)^2)
            // -density * z computed at vertex
            return half(unity_FogParams.x * clipZ_01);
        #else
            return 0.0h;
        #endif
    }

    half ComputeFogIntensity(half fogFactor)
    {
        half fogIntensity = 0.0h;
        #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
            #if defined(FOG_EXP)
                // factor = exp(-density*z)
                // fogFactor = density*z compute at vertex
                fogIntensity = saturate(exp2(-fogFactor));
            #elif defined(FOG_EXP2)
                // factor = exp(-(density*z)^2)
                // fogFactor = density*z compute at vertex
                fogIntensity = saturate(exp2(-fogFactor * fogFactor));
            #elif defined(FOG_LINEAR)
                fogIntensity = fogFactor;
            #endif
        #endif
        return fogIntensity;
    }

    half3 MixFogColor(half3 fragColor, half3 fogColor, half fogFactor)
    {
        #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
            half fogIntensity = ComputeFogIntensity(fogFactor);
            fragColor = lerp(fogColor, fragColor, fogIntensity);
        #endif
        return fragColor;
    }

    half3 MixFog(half3 fragColor, half fogFactor)
    {
        return MixFogColor(fragColor, unity_FogColor.rgb, fogFactor);
    }
    //-----------------------------------------------------------------------------------------------------

#endif