#ifndef _SIMPLEPHYSICALBASEDSHADING_H
    #define _SIMPLEPHYSICALBASEDSHADING_H

    #include "Lighting.hlsl"
	#include "ProbeBasedGI.hlsl"

    // tangent space to world matrix,store worldPos in last row
    #define TtoW(idx) float4 TangentToWorld[3] : TEXCOORD##idx;

    #define TransTtoW(v,o) \
    float3 worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;\
    float sign = v.tangent.w * unity_WorldTransformParams.w;\
    float3 T = TransformObjectToWorldDir(v.tangent.xyz);\
    float3 N = TransformObjectToWorldNormal(v.normal);\
    float3 B = cross(N, T) * sign;\
    o.TangentToWorld[0] = float4(T.x,B.x,N.x,worldPos.x);\
    o.TangentToWorld[1] = float4(T.y,B.y,N.y,worldPos.y);\
    o.TangentToWorld[2] = float4(T.z,B.z,N.z,worldPos.z);

    #define ApplyTtoW(o,normal) \
    float3 worldPos = float3(o.TangentToWorld[0].w,o.TangentToWorld[1].w,o.TangentToWorld[2].w);\
    half3 worldNormal = normalize(half3(dot(o.TangentToWorld[0].xyz,normal),dot(o.TangentToWorld[1].xyz,normal),dot(o.TangentToWorld[2].xyz,normal)));\

    #define kDieletricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

    struct appdata_pbs
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        half3 normal : NORMAL;
        half4 tangent : TANGENT;
        half4 color : COLOR;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f_pbs
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 ambientOrLightmapUV : TEXCOORD1;
        float2 fogCoord : TEXCOORD2;//x:system fog,y:self fog
        TtoW(3)
        float3 screenPos:TEXCOORD6;
        #ifdef RAIN_ON
            float4 worldPos:TEXCOORD12;
	        float4 rainPos   : TEXCOORD13;
        #endif
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct SurfaceInput
    {
        half  metallic;
        half  occlusion;//need set to 1.0 by defult
        half  smoothness;
        half3 albedo;
        half3 worldNormal;
        float3 worldPos;
        float4 ambientOrLightmapUV;
    };

    struct BRDFInput{
        half roughness;
        half roughness2;
        half grazingTerm;
        half roughness2MinusOne;
        half3 viewDir;
        half3 diffuse;
        half3 specular;
    };

    float3x3 TangentToWorldMatrix(in float3 normal, in float4 tangent)
    {
        float sign = tangent.w * unity_WorldTransformParams.w;
        float3 T = TransformObjectToWorldDir(tangent.xyz);
        float3 N = TransformObjectToWorldNormal(normal);
        float3 B = cross(N, T) * sign;
        float3x3 mat = {
            T.x, B.x, N.x,
            T.y, B.y, N.y,
            T.z, B.z, N.z
        };
        return mat;
    }

    float3 TangentToWorldNormal(in float3 normal,in float4 tangent)
    {
        float sign = tangent.w * unity_WorldTransformParams.w;
        float3 T = TransformObjectToWorldDir(tangent.xyz);
        float3 N = TransformObjectToWorldNormal(normal);
        float3 B = cross(N, T) * sign;
        float3x3 mat ={
            float3(T.x, B.x, N.x),
            float3(T.y, B.y, N.y),
            float3(T.z, B.z, N.z)
        };
        return mul(mat,normal);
    }

    inline float3 UnpackVertexNormal(v2f_pbs i){
        return float3(i.TangentToWorld[0].z,i.TangentToWorld[1].z,i.TangentToWorld[2].z);//顶点法线
    }

    half OneMinusReflectivityMetallic(half metallic)
    {
        // We'll need oneMinusReflectivity, so
        //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
        // store (1-dielectricSpec) in kDieletricSpec.a, then
        //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
        //                  = alpha - metallic * alpha
        half oneMinusDielectricSpec = kDieletricSpec.a;
        return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
    }

	inline half3 CalculateGlobalIllumination(SurfaceInput surface, BRDFInput brdf, out float bakedAtten)
    {
        half3 reflectDir = reflect(-brdf.viewDir,surface.worldNormal);

#if defined(LIGHTMAP_ON) && defined(SHADOWS_SHADOWMASK)  
		bakedAtten = SampleShadowMask(surface.ambientOrLightmapUV);
#elif defined(LIGHTMAP_ON_BATCHRENDERGROUP)
		bakedAtten = SampleShadowMask(surface.ambientOrLightmapUV);
#else
		bakedAtten = 1;
#endif

#if defined(USE_PROBE_BASED_GI)
		half4 indirectDiffuseAndAO = SampleProbeBasedGI(surface.worldPos, surface.worldNormal);
		half3 indirectDiffuse = indirectDiffuseAndAO.xyz * surface.occlusion;
		bakedAtten = indirectDiffuseAndAO.w;
#else
        half3 indirectDiffuse = SAMPLE_GI(surface.ambientOrLightmapUV,surface.worldNormal) * surface.occlusion;
#endif

		half3 indirectSpecular = SampleReflectionProbe(reflectDir, brdf.roughness) * surface.occlusion;
        // indirectDiffuse = half3(1,1,1);
        half fresnelTerm =  Pow4(1.0h - saturate(dot(surface.worldNormal,brdf.viewDir)));
        half3 c = indirectDiffuse * brdf.diffuse;
        half surfaceReduction = 1.0h / (brdf.roughness2 + 1.0h);
        c += surfaceReduction * indirectSpecular * lerp(brdf.specular, brdf.grazingTerm, fresnelTerm);
		return c;
    }

    // Based on Minimalist CookTorrance BRDF: http://www.thetenthplanet.de/archives/ 255
    inline half3 ToonBRDF(BRDFInput brdf, half noh, half loh){
        half normalizationTerm = brdf.roughness * 4.0h + 2.0h;
        half d = noh * noh * brdf.roughness2MinusOne + 1.00001h;
        half loh2 = loh * loh;
        half specularTerm = brdf.roughness2 / ((d*d)*max(0.1h,loh2) * normalizationTerm);
        specularTerm = clamp(specularTerm,0.0h,100.0h);// Prevent FP16 overflow on mobiles

        return specularTerm * brdf.specular + brdf.diffuse;
    }


// ------------------------------------------------------------------

float ShadowFadeDistance(float3 worldPos)
{
    #if defined(_CHARACTER_SHADOW_ON)
        return distance(worldPos, _characterShadowFadeCenterAndDistance.xyz);
    #else
        return distance(worldPos, unity_ShadowFadeCenterAndDistance.xyz);
    #endif
}

half UnityComputeShadowFade(float fadeDist)
{

#if defined(_CHARACTER_SHADOW_ON)
    return saturate(fadeDist * _characterShadowFadeCenterAndDistance.w - 2.66666);
#else
    return saturate(fadeDist * unity_ShadowFadeCenterAndDistance.w - 2.66666);
#endif

}

    inline half3 ToonPBSLighting(SurfaceInput surface, BRDFInput brdf, Light light,float bakedAtten)
    {
        half nol = saturate(dot(surface.worldNormal,light.direction));
        half3 h  = normalize(brdf.viewDir + light.direction);
        half noh = saturate(dot(surface.worldNormal,h));
        half loh = saturate(dot(light.direction,h));
    #if defined(_MIXED_LIGHTING_SHADOWMASK)
        float fadeDist = distance(surface.worldPos, unity_ShadowFadeCenterAndDistance.xyz);
        half fade = UnityComputeShadowFade(fadeDist);
        half atten = lerp(light.shadowAttenuation, bakedAtten,fade);
    #else
        half atten = min(bakedAtten, light.shadowAttenuation);
    #endif
    return ToonBRDF(brdf, noh, loh) * light.color * light.distanceAttenuation * atten * nol;
}

	BRDFInput GetBRDF(SurfaceInput surface)
	{
		BRDFInput brdf;
		half oneMinusReflectivity = OneMinusReflectivityMetallic(surface.metallic);

		brdf.roughness = 1.0h - surface.smoothness;
		brdf.roughness2 = brdf.roughness * brdf.roughness + 0.0002h;
		brdf.roughness2MinusOne = brdf.roughness2 - 1.0h;
		brdf.viewDir = normalize(UnityWorldSpaceViewDir(surface.worldPos));
		brdf.grazingTerm = saturate(surface.smoothness + (1.0h - oneMinusReflectivity));
		brdf.diffuse = surface.albedo * oneMinusReflectivity;
		brdf.specular = lerp(kDieletricSpec.rgb, surface.albedo, surface.metallic);
		return brdf;
	}

    //URP简化版金属度光滑度工作流PBR
    // Stats for Vertex shader:
    //        d3d11: 45 avg math (43..48)
    // Stats for Fragment shader:
    //        d3d11: 75 avg math (73..78), 3 avg texture (3..4)
    half3 Toon_PBS(SurfaceInput surface)
    {
		BRDFInput brdf = GetBRDF(surface);
        float bakedAtten;
		half3 gi = CalculateGlobalIllumination(surface, brdf, bakedAtten);
        float4 shadowCoord = GetShadowCoord(surface.worldPos);
        Light light = GetMainLight(shadowCoord);
		return gi + ToonPBSLighting(surface, brdf, light, bakedAtten);
    }

    half3 AddLighting(float3 normalWS, float3 worldPos)
    {
        half3 vertexLightColor = half3(0.0, 0.0, 0.0);
        uint pixelLightCount = GetAdditionalLightsCount();
        for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
        {
            Light light = GetAdditionalLight(lightIndex, worldPos);
            half3 lightColor = light.color * light.distanceAttenuation * light.shadowAttenuation;
            half NdotL = saturate(dot(normalWS, light.direction));
            vertexLightColor += lightColor * NdotL;
        }
        return vertexLightColor;
    }
#endif