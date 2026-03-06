#ifndef _LIGHTING_H
    #define _LIGHTING_H

    #include "Transform.hlsl"
    #include "Shadow.hlsl"
    #include "CharacterShadow.hlsl"

    //#define MAX_VISIBLE_LIGHTS 32
    #define LIGHTMAP_RGBM_MAX_GAMMA     half(5.0)       // NB: Must match value in RGBMRanges.h
    #define LIGHTMAP_RGBM_MAX_LINEAR    half(34.493242) // LIGHTMAP_RGBM_MAX_GAMMA ^ 2.2

    #ifdef UNITY_LIGHTMAP_RGBM_ENCODING
        #ifdef UNITY_COLORSPACE_GAMMA
            #define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_GAMMA
            #define LIGHTMAP_HDR_EXPONENT   half(1.0)   // Not used in gamma color space
        #else
            #define LIGHTMAP_HDR_MULTIPLIER LIGHTMAP_RGBM_MAX_LINEAR
            #define LIGHTMAP_HDR_EXPONENT   half(2.2)
        #endif
    #elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
        #ifdef UNITY_COLORSPACE_GAMMA
            #define LIGHTMAP_HDR_MULTIPLIER half(2.0)
        #else
            #define LIGHTMAP_HDR_MULTIPLIER half(4.59) // 2.0 ^ 2.2
        #endif
        #define LIGHTMAP_HDR_EXPONENT half(0.0)
    #else // (UNITY_LIGHTMAP_FULL_HDR)
        #define LIGHTMAP_HDR_MULTIPLIER half(1.0)
        #define LIGHTMAP_HDR_EXPONENT half(1.0)
    #endif

    #ifndef UNITY_SPECCUBE_LOD_STEPS
        // This is actuall the last mip index, we generate 7 mips of convolution
        #define UNITY_SPECCUBE_LOD_STEPS 6
    #endif

    #if !defined(LIGHTMAP_ON)
        // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
        #if defined(SHADER_API_GLES) || !defined(_NORMALMAP)
            // Evaluates SH fully in vertex
            #define EVALUATE_SH_VERTEX
        #elif !SHADER_HINT_NICE_QUALITY
            // Evaluates L2 SH in vertex and L0L1 in pixel
            #define EVALUATE_SH_MIXED
        #endif
        // Otherwise evaluate SH fully per-pixel
    #endif

    #ifdef LIGHTMAP_ON
        #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
        #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
        #define OUTPUT_SH(normalWS, OUT)
    #else
        #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
        #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
        #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
    #endif

    struct Light
    {
        half3   direction;
        half3   color;
        half    distanceAttenuation;
        half    shadowAttenuation;
    };

    Light GetMainLight()
    {
        Light light;
        light.direction = _MainLightPosition.xyz;
        light.distanceAttenuation = unity_LightData.z;
        //#if defined(LIGHTMAP_ON) || defined(_MIXED_LIGHTING_SUBTRACTIVE)
        //    light.distanceAttenuation *= unity_ProbesOcclusion.x;
        //#endif
        light.shadowAttenuation = 1.0;
        light.color = _MainLightColor.rgb;

        return light;
    }

    Light GetMainLight(float4 shadowCoord)
    {
        Light light = GetMainLight();
        light.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
        return light;
    }
    
    // Matches Unity Vanila attenuation
    // Attenuation smoothly decreases to light range.
    //根据美术在 管线asset里面选项lightFalloffSRP 确认使用物理衰减光照还是 Buildin模式的
    float DistanceAttenuation(float distanceSqr, half2 distanceAttenuation)
    {
        // We use a shared distance attenuation for additional directional and puctual lights
        // for directional lights attenuation will be 1
        #if LIGHT_FALLOFF_SRP
            float lightAtten = rcp(distanceSqr);
            half factor = distanceSqr * distanceAttenuation.x;
            half smoothFactor = saturate(1.0h - factor * factor);
            smoothFactor = smoothFactor * smoothFactor;
            return lightAtten * smoothFactor;
       #else
            // Reconstruct the light range from the Unity shader arguments
            float lightRangeSqr = rcp(distanceAttenuation.x);
            // Calculate the distance attenuation to approximate the built-in Unity curve
            return rcp(1 + 25 * distanceSqr / lightRangeSqr);
       #endif
    }

    half AngleAttenuation(half3 spotDirection, half3 lightDirection, half2 spotAttenuation)
    {
        // Spot Attenuation with a linear falloff can be defined as
        // (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
        // This can be rewritten as
        // invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
        // SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
        // SdotL * spotAttenuation.x + spotAttenuation.y

        // If we precompute the terms in a MAD instruction
        half SdotL = dot(spotDirection, lightDirection);
        half atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
        return atten * atten;
    }

    // Fills a light struct given a perObjectLightIndex
    Light GetAdditionalPerObjectLight(int perObjectLightIndex, float3 positionWS)
    {

        float4 lightPositionWS = _AdditionalLightsPosition[perObjectLightIndex];
        half3 color = _AdditionalLightsColor[perObjectLightIndex].rgb;
        half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[perObjectLightIndex];
        half4 spotDirection = _AdditionalLightsSpotDir[perObjectLightIndex];
      //  half4 lightOcclusionProbeInfo = _AdditionalLightsOcclusionProbes[perObjectLightIndex];

        // Directional lights store direction in lightPosition.xyz and have .w set to 0.0.
        // This way the following code will work for both directional and punctual lights.
        float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
        float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

        half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
        half attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);

        Light light;
        light.direction = lightDirection;
        light.distanceAttenuation = attenuation;
        light.shadowAttenuation = AdditionalLightShadow(perObjectLightIndex, positionWS, lightDirection);
       // light.shadowAttenuation = 1;
        light.color = color;

        //// In case we're using light probes, we can sample the attenuation from the `unity_ProbesOcclusion`
        //#if defined(LIGHTMAP_ON) || defined(_MIXED_LIGHTING_SUBTRACTIVE)
        //    // First find the probe channel from the light.
        //    // Then sample `unity_ProbesOcclusion` for the baked occlusion.
        //    // If the light is not baked, the channel is -1, and we need to apply no occlusion.

        //    // probeChannel is the index in 'unity_ProbesOcclusion' that holds the proper occlusion value.
        //    int probeChannel = lightOcclusionProbeInfo.x;

        //    // lightProbeContribution is set to 0 if we are indeed using a probe, otherwise set to 1.
        //    half lightProbeContribution = lightOcclusionProbeInfo.y;

        //    half probeOcclusionValue = unity_ProbesOcclusion[probeChannel];
        //    light.distanceAttenuation *= max(probeOcclusionValue, lightProbeContribution);
        //#endif

        return light;
    }

    float3 ApplyShadowBias(float3 worldPos, float3 worldNormal, float3 lightDir)
    {
        float invNdotL = 1.0 - saturate(dot(lightDir, worldNormal));
        float scale = invNdotL * _ShadowBias.y;

        // normal bias is negative since we want to apply an inset normal offset
        worldPos = lightDir * _ShadowBias.xxx + worldPos;
        worldPos = worldNormal * scale.xxx + worldPos;
        return worldPos;
    }

    int GetPerObjectLightIndex(uint index)
    {
        /////////////////////////////////////////////////////////////////////////////////////////////
        // UBO path                                                                                 /
        //                                                                                          /
        // We store 8 light indices in float4 unity_LightIndices[2];                                /
        // Due to memory alignment unity doesn't support int[] or float[]                           /
        // Even trying to reinterpret cast the unity_LightIndices to float[] won't work             /
        // it will cast to float4[] and create extra register pressure. :(                          /
        /////////////////////////////////////////////////////////////////////////////////////////////
        #if !defined(SHADER_API_GLES)
            // since index is uint shader compiler will implement
            // div & mod as bitfield ops (shift and mask).

            // TODO: Can we index a float4? Currently compiler is
            // replacing unity_LightIndicesX[i] with a dp4 with identity matrix.
            // u_xlat16_40 = dot(unity_LightIndices[int(u_xlatu13)], ImmCB_0_0_0[u_xlati1]);
            // This increases both arithmetic and register pressure.
            return unity_LightIndices[index / 4][index % 4];
        #else
            // Fallback to GLES2. No bitfield magic here :(.
            // We limit to 4 indices per object and only sample unity_4LightIndices0.
            // Conditional moves are branch free even on mali-400
            // small arithmetic cost but no extra register pressure from ImmCB_0_0_0 matrix.
            half2 lightIndex2 = (index < 2.0h) ? unity_LightIndices[0].xy : unity_LightIndices[0].zw;
            half i_rem = (index < 2.0h) ? index : index - 2.0h;
            return (i_rem < 1.0h) ? lightIndex2.x : lightIndex2.y;
        #endif
    }

    Light GetAdditionalLight(uint i, float3 worldPos)
    {
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        return GetAdditionalPerObjectLight(perObjectLightIndex, worldPos);
        //return GetAdditionalPerObjectLight(i, worldPos);
    }
    int GetAdditionalLightsCount()
    {
        // TODO: we need to expose in SRP api an ability for the pipeline cap the amount of lights
        // in the culling. This way we could do the loop branch with an uniform
        // This would be helpful to support baking exceeding lights in SH as well
        return min(_AdditionalLightsCount.x, unity_LightData.y);
        //return _AdditionalLightsCount.x;
    }

    // Ref: "Efficient Evaluation of Irradiance Environment Maps" from ShaderX 2
    half3 SHEvalLinearL0L1(half3 N, half4 shAr, half4 shAg, half4 shAb)
    {
        half4 vA = half4(N, 1.0);
        half3 x1;
        // Linear (L1) + constant (L0) polynomial terms
        x1.r = dot(shAr, vA);
        x1.g = dot(shAg, vA);
        x1.b = dot(shAb, vA);

        return x1;
    }

    half3 SHEvalLinearL2(half3 N, half4 shBr, half4 shBg, half4 shBb, half4 shC)
    {
        half3 x2;
        // 4 of the quadratic (L2) polynomials
        half4 vB = N.xyzz * N.yzzx;
        x2.r = dot(shBr, vB);
        x2.g = dot(shBg, vB);
        x2.b = dot(shBb, vB);
        // Final (5th) quadratic (L2) polynomial
        half vC = N.x * N.x - N.y * N.y;
        half3 x3 = shC.rgb * vC;

        return x2 + x3;
    }

    half3 SampleSH9(half3 worldNormal)
    {
        // LPPV is not supported in Ligthweight Pipeline
        half3 res = SHEvalLinearL0L1(worldNormal,unity_SHAr,unity_SHAg,unity_SHAb);
        res += SHEvalLinearL2(worldNormal,unity_SHBr,unity_SHBg,unity_SHBb,unity_SHC);

        return max(half3(0, 0, 0), res);
    }

    // SH Vertex Evaluation. Depending on target SH sampling might be
    // done completely per vertex or mixed with L2 term per vertex and L0, L1
    // per pixel. See SampleSHPixel
    half3 SampleSHVertex(half3 worldNormal)
    {
        #if defined(EVALUATE_SH_VERTEX)
            return max(half3(0, 0, 0), SampleSH9(worldNormal));
        #elif defined(EVALUATE_SH_MIXED)
            // no max since this is only L2 contribution
            return SHEvalLinearL2(worldNormal, unity_SHBr, unity_SHBg, unity_SHBb, unity_SHC);
        #endif

        // Fully per-pixel. Nothing to compute.
        return half3(0.0, 0.0, 0.0);
    }

    // SH Pixel Evaluation. Depending on target SH sampling might be done
    // mixed or fully in pixel. See SampleSHVertex
    half3 SampleSHPixel(half3 L2Term, half3 worldNormal)
    {
        #if defined(EVALUATE_SH_VERTEX)
            return L2Term;
        #elif defined(EVALUATE_SH_MIXED)
            half3 L0L1Term = SHEvalLinearL0L1(worldNormal, unity_SHAr, unity_SHAg, unity_SHAb);
            return max(half3(0, 0, 0), L2Term + L0L1Term);
        #endif
        // Default: Evaluate SH fully per-pixel
        return SampleSH9(worldNormal);
    }

    half3 UnpackLightmapRGBM(half4 rgbmInput, half4 decodeInstructions)
    {
        #ifdef UNITY_COLORSPACE_GAMMA
            return rgbmInput.rgb * (rgbmInput.a * decodeInstructions.x);
        #else
            return rgbmInput.rgb * (PositivePow(rgbmInput.a, decodeInstructions.y) * decodeInstructions.x);
        #endif
    }

    half3 UnpackLightmapDoubleLDR(half4 encodedColor, half4 decodeInstructions)
    {
        return encodedColor.rgb * decodeInstructions.x;
    }

    half3 DecodeLightmap(half4 encodedIlluminance, half4 decodeInstructions)
    {
        #if defined(UNITY_LIGHTMAP_RGBM_ENCODING)
            return UnpackLightmapRGBM(encodedIlluminance, decodeInstructions);
        #elif defined(UNITY_LIGHTMAP_DLDR_ENCODING)
            return UnpackLightmapDoubleLDR(encodedIlluminance, decodeInstructions);
        #else // (UNITY_LIGHTMAP_FULL_HDR)
            return encodedIlluminance.rgb;
        #endif
    }

    half3 SampleSingleLightmap(float2 uv, float4 transform, bool encodedLightmap, half4 decodeInstructions)
    {
        // transform is scale and bias
        uv = uv * transform.xy + transform.zw;
        half3 illuminance = half3(0.0, 0.0, 0.0);
        // Remark: baked lightmap is RGBM for now, dynamic lightmap is RGB9E5
        if (encodedLightmap)
        {
            half4 encodedIlluminance = SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, uv).rgba;
            illuminance = DecodeLightmap(encodedIlluminance, decodeInstructions);
        }
        else
        {
            illuminance = SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, uv).rgb;
        }
        return illuminance;
    }
#if defined(LIGHTMAP_ON_BATCHRENDERGROUP)
    half3 SampleSingleLightmap_BRG(float2 uv, float4 transform, bool encodedLightmap, half4 decodeInstructions)
    {
        // transform is scale and bias
        uv = uv * transform.xy + transform.zw;
        half3 illuminance = half3(0.0, 0.0, 0.0);
        // Remark: baked lightmap is RGBM for now, dynamic lightmap is RGB9E5
        if (encodedLightmap)
        {
            half4 encodedIlluminance = SAMPLE_TEXTURE2D(unity_Lightmap_BRG, samplerunity_Lightmap_BRG, uv).rgba;
            illuminance = DecodeLightmap(encodedIlluminance, decodeInstructions);
        }
        else
        {
            illuminance = SAMPLE_TEXTURE2D(unity_Lightmap_BRG, samplerunity_Lightmap_BRG, uv).rgb;
        }
        return illuminance;
    }
    #endif
    
    half3 SampleDirectionalLightmap( float2 uv, float4 transform, float3 worldNormal, bool encodedLightmap, half4 decodeInstructions)
    {
        // In directional mode Enlighten bakes dominant light direction
        // in a way, that using it for half Lambert and then dividing by a "rebalancing coefficient"
        // gives a result close to plain diffuse response lightmaps, but normalmapped.

        // Note that dir is not unit length on purpose. Its length is "directionality", like
        // for the directional specular lightmaps.

        // transform is scale and bias
        uv = uv * transform.xy + transform.zw;

        half4 direction = SAMPLE_TEXTURE2D(unity_LightmapInd, samplerunity_Lightmap, uv);
        // Remark: baked lightmap is RGBM for now, dynamic lightmap is RGB9E5
        half3 illuminance = half3(0.0, 0.0, 0.0);
        if (encodedLightmap)
        {
            half4 encodedIlluminance = SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, uv).rgba;
            illuminance = DecodeLightmap(encodedIlluminance, decodeInstructions);
        }
        else
        {
            illuminance = SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, uv).rgb;
        }
        half halfLambert = dot(worldNormal, direction.xyz - 0.5) + 0.5;
        return illuminance * halfLambert / max(1e-4, direction.w);
    }

    // Sample baked lightmap. Non-Direction and Directional if available.
    // Realtime GI is not supported.
    half3 SampleLightmap(float2 lightmapUV, half3 worldNormal)
    {
        #ifdef UNITY_LIGHTMAP_FULL_HDR
            bool encodedLightmap = false;
        #else
            bool encodedLightmap = true;
        #endif

        half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);

        // The shader library sample lightmap functions transform the lightmap uv coords to apply bias and scale.
        // However, universal pipeline already transformed those coords in vertex. We pass half4(1, 1, 0, 0) and
        // the compiler will optimize the transform away.
        half4 transformCoords = half4(1, 1, 0, 0);//to do: 就是说URP烘光照贴图的时候已经处理了uv？这里可能会粗问题
        #ifdef DIRLIGHTMAP_COMBINED
            return SampleDirectionalLightmap(lightmapUV, transformCoords,worldNormal, encodedLightmap, decodeInstructions);
        #elif defined(LIGHTMAP_ON)
            return SampleSingleLightmap(lightmapUV, transformCoords, encodedLightmap, decodeInstructions);
        #elif defined(LIGHTMAP_ON_BATCHRENDERGROUP)
            return SampleSingleLightmap_BRG(lightmapUV, transformCoords, encodedLightmap, decodeInstructions);
        #else
            return half3(0.0, 0.0, 0.0);
        #endif
    }
#if defined(LIGHTMAP_ON) && defined(SHADOWS_SHADOWMASK)
half4 SampleShadowMask(float2 lightmapUV)
{
	return SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_Lightmap, lightmapUV);
}
#elif defined(LIGHTMAP_ON_BATCHRENDERGROUP)
half4 SampleShadowMask(float2 lightmapUV)
{
	return SAMPLE_TEXTURE2D(unity_ShadowMask_BRG, samplerunity_Lightmap_BRG, lightmapUV);
}
#endif
    // We either sample GI from baked lightmap or from probes.
    // If lightmap: sampleData.xy = lightmapUV
    // If probe: sampleData.xyz = L2 SH terms
    #ifdef LIGHTMAP_ON
        #define SAMPLE_GI(ambientOrLightmapUV, worldNormal) SampleLightmap(ambientOrLightmapUV.xy, worldNormal)
    #elif defined(LIGHTMAP_ON_BATCHRENDERGROUP)
        #define SAMPLE_GI(ambientOrLightmapUV, worldNormal) SampleLightmap(ambientOrLightmapUV.xy, worldNormal)
    #else
        #define SAMPLE_GI(ambientOrLightmapUV, worldNormal) SampleSHPixel(ambientOrLightmapUV.xyz, worldNormal)
    #endif

    half PerceptualRoughnessToMipmapLevel(half perceptualRoughness)
    {
        perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);
        return perceptualRoughness * UNITY_SPECCUBE_LOD_STEPS;
    }

    half3 DecodeHDREnvironment(half4 encodedIrradiance, half4 decodeInstructions)
    {
        // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
        half alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);
        // If Linear mode is not supported we can skip exponent part
        return (decodeInstructions.x * PositivePow(alpha, decodeInstructions.y)) * encodedIrradiance.rgb;
    }

    inline half3 SampleReflectionProbe(half3 reflectDir, half roughness)
    {
        #if !defined(_ENVIRONMENTREFLECTIONS_OFF)
            half mip = PerceptualRoughnessToMipmapLevel(roughness);
            half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
            #if !defined(UNITY_USE_NATIVE_HDR)
                half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
            #else
                half3 irradiance = encodedIrradiance.rbg;
            #endif
            return irradiance;
        #endif
        // GLOSSY_REFLECTIONS
        return _GlossyEnvironmentColor.rgb;
    }

    half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness, half occlusion)
    {
        return SampleReflectionProbe(reflectVector,perceptualRoughness) * occlusion;
    }

#endif