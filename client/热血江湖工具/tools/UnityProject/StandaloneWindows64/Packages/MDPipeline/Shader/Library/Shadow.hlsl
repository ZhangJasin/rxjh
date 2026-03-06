#ifndef _SHADOW_H
    #define _SHADOW_H

    #define SHADOWS_SCREEN 0
    #define MAX_SHADOW_CASCADES 4

    #if !defined(_RECEIVE_SHADOWS_OFF)
        #if defined(_MAIN_LIGHT_SHADOWS) ||  defined(_SCREENSPACE_SHADOW_ON)
            #define MAIN_LIGHT_CALCULATE_SHADOWS
            #if !defined(_MAIN_LIGHT_SHADOWS_CASCADE)
                #define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
            #endif
        #endif
        #if defined(_ADDITIONAL_LIGHT_SHADOWS)
            #define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
        #endif
    #endif
    #if defined(_ADDITIONAL_LIGHTS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE)
        #define REQUIRES_WORLD_SPACE_POS_INTERPOLATOR
    #endif

    TEXTURE2D_SHADOW(_MainLightShadowmapTexture);
    SAMPLER_CMP(sampler_MainLightShadowmapTexture);

    // GLES3 causes a performance regression in some devices when using CBUFFER.
    #ifndef SHADER_API_GLES3
        CBUFFER_START(MainLightShadows)
    #endif
    #include "ShadowCores.hlsl"
    #include "CharacterShadow.hlsl"
    // Last cascade is initialized with a no-op matrix. It always transforms
    // shadow coord to half3(0, 0, NEAR_PLANE). We use this trick to avoid
    // branching since ComputeCascadeIndex can return cascade index = MAX_SHADOW_CASCADES
    float4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
    float4      _CascadeShadowSplitSpheres0;
    float4      _CascadeShadowSplitSpheres1;
    float4      _CascadeShadowSplitSpheres2;
    float4      _CascadeShadowSplitSpheres3;
    float4      _CascadeShadowSplitSphereRadii;
    half4       _MainLightShadowOffset0;
    half4       _MainLightShadowOffset1;
    half4       _MainLightShadowOffset2;
    half4       _MainLightShadowOffset3;
    half4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, shadowFadeScale, shadowFadeBias)
    float4      _MainLightShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
    #ifndef SHADER_API_GLES3
        CBUFFER_END
    #endif


    TEXTURE2D (_ScreenSpaceShadowmapTexture);
    SAMPLER(sampler_ScreenSpaceShadowmapTexture);

    TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);
    SAMPLER_CMP(sampler_AdditionalLightsShadowmapTexture);
    
    #define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0
//#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    //StructuredBuffer<float4>   _AdditionalShadowParams_SSBO;        // Per-light data - TODO: test if splitting _AdditionalShadowParams_SSBO[lightIndex].w into a separate StructuredBuffer<int> buffer is faster
    //StructuredBuffer<float4x4> _AdditionalLightsWorldToShadow_SSBO; // Per-shadow-slice-data - A shadow casting light can have 6 shadow slices (if it's a point light)
    //half4       _AdditionalShadowOffset0;
    //half4       _AdditionalShadowOffset1;
    //half4       _AdditionalShadowOffset2;
    //half4       _AdditionalShadowOffset3;
    //half4       _AdditionalShadowFadeParams; // x: additional light fade scale, y: additional light fade bias, z: 0.0, w: 0.0)
    //float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
//#else
//    #if defined(SHADER_API_MOBILE) || (defined(SHADER_API_GLCORE) && !defined(SHADER_API_SWITCH)) || defined(SHADER_API_GLES) || defined(SHADER_API_GLES3) 
    //Workaround because SHADER_API_GLCORE is also defined when SHADER_API_SWITCH is
    // Point lights can use 6 shadow slices, but on some mobile GPUs performance decrease drastically with uniform blocks bigger than 8kb. This number ensures size of buffer AdditionalLightShadows stays reasonable.
    // It also avoids shader compilation errors on SHADER_API_GLES30 devices where max number of uniforms per shader GL_MAX_FRAGMENT_UNIFORM_VECTORS is low (224)
    // Keep in sync with MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO in AdditionalLightsShadowCasterPass.cs
    #define MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO (MAX_VISIBLE_LIGHTS)
    //#else
    //// Point lights can use 6 shadow slices, but on some platforms max uniform block size is 64kb. This number ensures size of buffer AdditionalLightShadows does not exceed this 64kb limit.
    //// Keep in sync with MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO in AdditionalLightsShadowCasterPass.cs
    //    #define MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO 545
    //#endif

    // GLES3 causes a performance regression in some devices when using CBUFFER.
    #ifndef SHADER_API_GLES3
    CBUFFER_START(AdditionalLightShadows)
    #endif
    half4       _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];                              // Per-light data
    float4x4    _AdditionalLightsWorldToShadow[MAX_PUNCTUAL_LIGHT_SHADOW_SLICES_IN_UBO];  // Per-shadow-slice-data

    half4       _AdditionalShadowOffset0;
    half4       _AdditionalShadowOffset1;
    half4       _AdditionalShadowOffset2;
    half4       _AdditionalShadowOffset3;
    half4       _AdditionalShadowFadeParams; // x: additional light fade scale, y: additional light fade bias, z: 0.0, w: 0.0)
    float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)

    #ifndef SHADER_API_GLES3
    CBUFFER_END
    #endif

//#endif


    float4 _ShadowBias; // x: depth bias, y: normal bias

    struct ShadowSamplingData
    {
        half4 shadowOffset0;
        half4 shadowOffset1;
        half4 shadowOffset2;
        half4 shadowOffset3;
        float4 shadowmapSize;
    };

    half ComputeCascadeIndex(float3 worldPos)
    {
        float3 fromCenter0 = worldPos - _CascadeShadowSplitSpheres0.xyz;
        float3 fromCenter1 = worldPos - _CascadeShadowSplitSpheres1.xyz;
        float3 fromCenter2 = worldPos - _CascadeShadowSplitSpheres2.xyz;
        float3 fromCenter3 = worldPos - _CascadeShadowSplitSpheres3.xyz;
        float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));
        half4 weights = half4(distances2 < _CascadeShadowSplitSphereRadii);
        weights.yzw = saturate(weights.yzw - weights.xyz);
        return 4 - dot(weights, half4(4, 3, 2, 1));
    }

    float4 TransformWorldToShadowCoord(float3 worldPos)
    {
        #ifdef _MAIN_LIGHT_SHADOWS_CASCADE
            half cascadeIndex = ComputeCascadeIndex(worldPos);
        #else
            half cascadeIndex = 0;
        #endif
        float4 finalCoord = mul(_MainLightWorldToShadow[cascadeIndex], float4(worldPos, 1.0));
        finalCoord.w = cascadeIndex;//存index后面用
        return finalCoord;
    }

    float4 GetShadowCoord(float3 worldPos)
    {
        #if defined(_SCREENSPACE_SHADOW_ON)
            float4 positionCS1 = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
            float4 ndc = positionCS1* 0.5f;
            float2 ssUV = (float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w) / positionCS1.w;
            //float4 ndc = positionCS * 0.5f;  //莫名其妙这边vs里传过来的会G...自己算一遍得了
            //float2 ssUV = (float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w) / positionCS.w;
            return float4(ssUV,1,1);
        #elif defined(_CHARACTER_SHADOW_ON)
            float4 shadowCoord = mul(_WorldToCharacterLight, float4(worldPos, 1.0));
            return shadowCoord;
        #else
            return TransformWorldToShadowCoord(worldPos);
        #endif

        //#ifdef _SCREENSPACE_SHADOW_ON

        //    float4 positionCS1 = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
        //    float4 ndc = positionCS1* 0.5f;
        //    float2 ssUV = (float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w) / positionCS1.w;

        //    //float4 ndc = positionCS * 0.5f;  //莫名其妙这边vs里传过来的会G...自己算一遍得了
        //    //float2 ssUV = (float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w) / positionCS.w;
        //    
        //    return float4(ssUV,1,1);

        //#else
        //    return TransformWorldToShadowCoord(worldPos);
        //#endif

    }

    #define CUBEMAPFACE_POSITIVE_X 0
    #define CUBEMAPFACE_NEGATIVE_X 1
    #define CUBEMAPFACE_POSITIVE_Y 2
    #define CUBEMAPFACE_NEGATIVE_Y 3
    #define CUBEMAPFACE_POSITIVE_Z 4
    #define CUBEMAPFACE_NEGATIVE_Z 5

    #ifndef INTRINSIC_CUBEMAP_FACE_ID
    float CubeMapFaceID(float3 dir)
    {
        float faceID;

        if (abs(dir.z) >= abs(dir.x) && abs(dir.z) >= abs(dir.y))
        {
            faceID = (dir.z < 0.0) ? CUBEMAPFACE_NEGATIVE_Z : CUBEMAPFACE_POSITIVE_Z;
        }
        else if (abs(dir.y) >= abs(dir.x))
        {
            faceID = (dir.y < 0.0) ? CUBEMAPFACE_NEGATIVE_Y : CUBEMAPFACE_POSITIVE_Y;
        }
        else
        {
            faceID = (dir.x < 0.0) ? CUBEMAPFACE_NEGATIVE_X : CUBEMAPFACE_POSITIVE_X;
        }

        return faceID;
    }
    #endif // INTRINSIC_CUBEMAP_FACE_ID


    ShadowSamplingData GetAdditionalLightShadowSamplingData()
    {
        ShadowSamplingData shadowSamplingData;

        // shadowOffsets are used in SampleShadowmapFiltered #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
        shadowSamplingData.shadowOffset0 = _AdditionalShadowOffset0;
        shadowSamplingData.shadowOffset1 = _AdditionalShadowOffset1;
        shadowSamplingData.shadowOffset2 = _AdditionalShadowOffset2;
        shadowSamplingData.shadowOffset3 = _AdditionalShadowOffset3;

        // shadowmapSize is used in SampleShadowmapFiltered for other platforms
        shadowSamplingData.shadowmapSize = _AdditionalShadowmapSize;

        return shadowSamplingData;
    }
    

    // ShadowParams
    // x: ShadowStrength
    // y: 1.0 if shadow is soft, 0.0 otherwise
    // z: 1.0 if cast by a point light (6 shadow slices), 0.0 if cast by a spot light (1 shadow slice)
    // w: first shadow slice index for this light, there can be 6 in case of point lights. (-1 for non-shadow-casting-lights)
    half4 GetAdditionalLightShadowParams(int lightIndex)
    {
    #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
        return _AdditionalShadowParams_SSBO[lightIndex];
    #else
        return _AdditionalShadowParams[lightIndex];
    #endif
    }

half easeInOutQuart(half x){
return x < 0.5 ? 8 * x * x * x * x : 1 - pow(-2 * x + 2, 4) / 2; }

float SampleShadowmapFiltered(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData)
{
    float attenuation;

#if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
    // 4-tap hardware comparison
    float4 attenuation4;
    attenuation4.x = float(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset0.xyz));
    attenuation4.y = float(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset1.xyz));
    attenuation4.z = float(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset2.xyz));
    attenuation4.w = float(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset3.xyz));
    attenuation = dot(attenuation4, float(0.25));
#else
    float fetchesWeights[9];
    float2 fetchesUV[9];
    SampleShadow_ComputeSamples_Tent_5x5(samplingData.shadowmapSize, shadowCoord.xy, fetchesWeights, fetchesUV);

    attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[0].xy, shadowCoord.z));
    attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[1].xy, shadowCoord.z));
    attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[2].xy, shadowCoord.z));
    attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[3].xy, shadowCoord.z));
    attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[4].xy, shadowCoord.z));
    attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[5].xy, shadowCoord.z));
    attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[6].xy, shadowCoord.z));
    attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[7].xy, shadowCoord.z));
    attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[8].xy, shadowCoord.z));
#endif

    return attenuation;
}

half SampleScreenSpaceShadowmap(float2 shadowCoord)
{
    half attenuation = SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, shadowCoord.xy).x;

    return attenuation;
}

half MainLightRealtimeShadow(float4 shadowCoord)
{
    #if defined(_CHARACTER_SHADOW_ON)
        return SampleCharacterShadow_shadowCoord(shadowCoord);
    #endif

    #if !defined(MAIN_LIGHT_CALCULATE_SHADOWS)
        return 1.0h;
    #endif

    #ifdef _SCREENSPACE_SHADOW_ON
        return SampleScreenSpaceShadowmap(shadowCoord.xy);
    #endif

    half attenuation = 1.0;
        
    #ifdef _SHADOWS_SOFT
       
        #if defined(SHADER_API_MOBILE)

            half4 attenuation4;// mobile soft
            attenuation4.x = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset0.xyz);
            attenuation4.y = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset1.xyz);
            attenuation4.z = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset2.xyz);
            attenuation4.w = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset3.xyz);
            attenuation = dot(attenuation4, 0.25);
        #else
            //if(shadowCoord.w <0.1) //PC soft for cascade 0
            //{
                float fetchesWeights[9];
                float2 fetchesUV[9];
                SampleShadow_ComputeSamples_Tent_5x5(_MainLightShadowmapSize, shadowCoord.xy, fetchesWeights, fetchesUV);

                attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[0].xy, shadowCoord.z));
                attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[1].xy, shadowCoord.z));
                attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[2].xy, shadowCoord.z));
                attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[3].xy, shadowCoord.z));
                attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[4].xy, shadowCoord.z));
                attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[5].xy, shadowCoord.z));
                attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[6].xy, shadowCoord.z));
                attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[7].xy, shadowCoord.z));
                attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, float3(fetchesUV[8].xy, shadowCoord.z));
            //}else
            //{
            //    half4 attenuation4;// mobile soft
            //    attenuation4.x = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset0.xyz);
            //    attenuation4.y = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset1.xyz);
            //    attenuation4.z = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset2.xyz);
            //    attenuation4.w = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz + _MainLightShadowOffset3.xyz);
            //    attenuation = dot(attenuation4, 0.25);
            //}
            
        #endif
    #else
        attenuation = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz);
    #endif
    attenuation = LerpWhiteTo(attenuation, _MainLightShadowParams.x);
    if(shadowCoord.w >0.1)
        attenuation = easeInOutQuart(attenuation);
    return (shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0) ? 1.0 : attenuation; //Shadow coords that fall out of the light frustum volume must always return attenuation 1.0
}

float SampleShadowmap(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData, half4 shadowParams, bool isPerspectiveProjection = true)
{
    // Compiler will optimize this branch away as long as isPerspectiveProjection is known at compile time
    if (isPerspectiveProjection)
        shadowCoord.xyz /= shadowCoord.w;

    float attenuation;
    float shadowStrength = shadowParams.x;

#ifdef _SHADOWS_SOFT
    if(shadowParams.y != 0)
    {
        attenuation = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(ShadowMap, sampler_ShadowMap), shadowCoord, samplingData);
    }
    else
#endif
    {
        // 1-tap hardware comparison
        attenuation = float(SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz));
    }

    attenuation = LerpWhiteTo(attenuation, shadowStrength);

    // Shadow coords that fall out of the light frustum volume must always return attenuation 1.0
    // TODO: We could use branch here to save some perf on some platforms.
    return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
}

// returns 0.0 if position is in light's shadow
// returns 1.0 if position is in light
half AdditionalLightRealtimeShadow(int lightIndex, float3 positionWS, half3 lightDirection)
{
#if !defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
    return half(1.0);
#endif

    ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData();

    half4 shadowParams = GetAdditionalLightShadowParams(lightIndex);

    int shadowSliceIndex = shadowParams.w;


    if (shadowSliceIndex < 0)
        return 1.0;

    half isPointLight = shadowParams.z;

    UNITY_BRANCH
    if (isPointLight)
    {
        // This is a point light, we have to find out which shadow slice to sample from
        float cubemapFaceId = CubeMapFaceID(-lightDirection);
        shadowSliceIndex += cubemapFaceId;
    }

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
    float4 shadowCoord = mul(_AdditionalLightsWorldToShadow_SSBO[shadowSliceIndex], float4(positionWS, 1.0));
#else
    float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[shadowSliceIndex], float4(positionWS, 1.0));
#endif

    return SampleShadowmap(TEXTURE2D_ARGS(_AdditionalLightsShadowmapTexture, sampler_AdditionalLightsShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, true);
}

half GetMainLightShadowFade(float3 positionWS)
{
    float3 camToPixel = positionWS - _WorldSpaceCameraPos;
    float distanceCamToPixel2 = dot(camToPixel, camToPixel);

    float fade = saturate(distanceCamToPixel2 * float(_MainLightShadowParams.z) + float(_MainLightShadowParams.w));
    return half(fade);
}

half MixRealtimeAndBakedShadows(half realtimeShadow, half bakedShadow, half shadowFade)
{
#if defined(LIGHTMAP_SHADOW_MIXING)
    return min(lerp(realtimeShadow, 1, shadowFade), bakedShadow);
#else
    return lerp(realtimeShadow, bakedShadow, shadowFade);
#endif
}


half GetAdditionalLightShadowFade(float3 positionWS)
{
    float3 camToPixel = positionWS - _WorldSpaceCameraPos;
    float distanceCamToPixel2 = dot(camToPixel, camToPixel);

    float fade = saturate(distanceCamToPixel2 * float(_AdditionalShadowFadeParams.x) + float(_AdditionalShadowFadeParams.y));
    return half(fade);
}


half BakedShadow(half4 shadowMask, half4 occlusionProbeChannels)
{
    // Here occlusionProbeChannels used as mask selector to select shadows in shadowMask
    // If occlusionProbeChannels all components are zero we use default baked shadow value 1.0
    // This code is optimized for mobile platforms:
    // half bakedShadow = any(occlusionProbeChannels) ? dot(shadowMask, occlusionProbeChannels) : 1.0h;
    half bakedShadow = half(1.0) + dot(shadowMask - half(1.0), occlusionProbeChannels);
    return bakedShadow;
}

half MainLightShadow(float4 shadowCoord, float3 positionWS)
{
    half realtimeShadow = MainLightRealtimeShadow(shadowCoord);

#ifdef MAIN_LIGHT_CALCULATE_SHADOWS
    half shadowFade = GetMainLightShadowFade(positionWS);
#else
    half shadowFade = half(1.0);
#endif

    return MixRealtimeAndBakedShadows(realtimeShadow, 1, shadowFade);
}


half AdditionalLightShadow(int lightIndex, float3 positionWS, half3 lightDirection)
{
    half realtimeShadow = AdditionalLightRealtimeShadow(lightIndex, positionWS, lightDirection);
#ifdef ADDITIONAL_LIGHT_CALCULATE_SHADOWS
    half shadowFade = GetAdditionalLightShadowFade(positionWS);
#else
    half shadowFade = half(1.0);
#endif

    return MixRealtimeAndBakedShadows(realtimeShadow, 1, shadowFade);
}

half AdditionalLightShadow(int lightIndex, float3 positionWS, half3 lightDirection, half4 shadowMask, half4 occlusionProbeChannels)
{
    half realtimeShadow = AdditionalLightRealtimeShadow(lightIndex, positionWS, lightDirection);

#ifdef CALCULATE_BAKED_SHADOWS
    half bakedShadow = BakedShadow(shadowMask, occlusionProbeChannels);
#else
    half bakedShadow = half(1.0);
#endif

#ifdef ADDITIONAL_LIGHT_CALCULATE_SHADOWS
    half shadowFade = GetAdditionalLightShadowFade(positionWS);
#else
    half shadowFade = half(1.0);
#endif

    return MixRealtimeAndBakedShadows(realtimeShadow, bakedShadow, shadowFade);
}



#endif