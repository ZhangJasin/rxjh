#ifndef CHARACTERSHADOW_H
    #define CHARACTERSHADOW_H

    #include "ShadowCores.hlsl"
    TEXTURE2D_SHADOW(_CharacterShadowMap);
    SAMPLER_CMP(sampler_CharacterShadowMap);
    float4x4 _WorldToCharacterLight;
    half4 _CharacterShadowOffset0;
    half4 _CharacterShadowOffset1;
    half4 _CharacterShadowOffset2;
    half4 _CharacterShadowOffset3; 
    half4 _characterShadowFadeCenterAndDistance;
    half4 _CharacterShadowMapSize;
    half4 _CharacterShadowLightDir;
    //TODO “ı”∞À•ºı
    /*half GetCharacterShadowFade(float3 positionWS)
    {
        float3 camToPixel = positionWS - _WorldSpaceCameraPos;
        float distanceCamToPixel2 = dot(camToPixel, camToPixel);
        float fade = saturate(distanceCamToPixel2 * float(0.1) + float(0));
        return half(fade);
    }*/ 
    //half CharacterComputeShadowFade(float fadeDist)
    //{
    //    return saturate(fadeDist * _characterShadowFadeCenterAndDistance.w - 2.66666);
    //}



    inline float SampleCharacterShadow_shadowCoord(float3 shadowCoord)
    {
        half attenuation = 1;
    #ifdef _CHARACTER_SHADOWS_SOFT_PC
            float fetchesWeights[9];
            float2 fetchesUV[9];
            SampleShadow_ComputeSamples_Tent_5x5(_CharacterShadowMapSize, shadowCoord.xy, fetchesWeights, fetchesUV);

            attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[0].xy, shadowCoord.z));
            attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[1].xy, shadowCoord.z));
            attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[2].xy, shadowCoord.z));
            attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[3].xy, shadowCoord.z));
            attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[4].xy, shadowCoord.z));
            attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[5].xy, shadowCoord.z));
            attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[6].xy, shadowCoord.z));
            attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[7].xy, shadowCoord.z));
            attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, float3(fetchesUV[8].xy, shadowCoord.z));
    #elif  defined(_SHADOWS_SOFT)
            half4 attenuation4;//to do: »Ì“ı”∞À„∑®
            attenuation4.x = SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, shadowCoord.xyz + _CharacterShadowOffset0.xyz);
            attenuation4.y = SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, shadowCoord.xyz + _CharacterShadowOffset1.xyz);
            attenuation4.z = SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, shadowCoord.xyz + _CharacterShadowOffset2.xyz);
            attenuation4.w = SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, shadowCoord.xyz + _CharacterShadowOffset3.xyz);
            attenuation = dot(attenuation4, 0.25);
    #else
        attenuation = SAMPLE_TEXTURE2D_SHADOW(_CharacterShadowMap, sampler_CharacterShadowMap, shadowCoord.xyz);
    #endif
        attenuation = lerp(1,attenuation, _CharacterShadowLightDir.w);
        return (shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0) ? 1.0 : attenuation;
    }

    inline float SampleCharacterShadow(float3 worldPos){
        #ifndef _CHARACTER_SHADOW_ON
            return 1;
        #endif

        float4 shadowCoord = mul(_WorldToCharacterLight,float4(worldPos,1.0));
        return SampleCharacterShadow_shadowCoord(shadowCoord.xyz);
    }


    //“ı”∞ªÏ∫œ
    half MixCharacterAndRealtimeShadows(half characterShadow, half realtimeShadow)
    {
        return min(characterShadow, realtimeShadow);
    }
    //TODO øº¬«“ı”∞À•ºıµƒ“ı”∞ªÏ∫œ
    //half MixCharacterAndRealtimeShadows_Fade(half characterShadow, half realtimeShadow,half shadowFade)
    //{
    //    return min(lerp(characterShadow, 1, shadowFade), realtimeShadow);
    //}
   
#endif