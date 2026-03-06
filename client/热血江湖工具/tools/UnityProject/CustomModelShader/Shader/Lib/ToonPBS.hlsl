#ifndef TOONPBS_H
#define TOONPBS_H

#include "ToonBase.hlsl"


#ifdef UNITY_COLORSPACE_GAMMA
#define unity_ColorSpaceGrey fixed4(0.5, 0.5, 0.5, 0.5)
#define unity_ColorSpaceDouble fixed4(2.0, 2.0, 2.0, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.220916301, 0.220916301, 0.220916301, 1.0 - 0.220916301)
#define unity_ColorSpaceLuminance half4(0.22, 0.707, 0.071, 0.0) // Legacy: alpha is set to 0.0 to specify gamma mode
#else // Linear values
#define unity_ColorSpaceGrey fixed4(0.214041144, 0.214041144, 0.214041144, 0.5)
#define unity_ColorSpaceDouble fixed4(4.59479380, 4.59479380, 4.59479380, 2.0)
#define unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)
#define unity_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0) // Legacy: alpha is set to 1.0 to specify linear mode
#endif   

uniform half4 _SkyAOColor;
uniform half4 _RoomAOColor;
    
half3 AddLighting(Light light, half3 normalWS, half3 viewDirectionWS)
{
	half nol = dot(normalWS, light.direction);
	half3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation) ;
	half3 diffuse = attenuatedLightColor * saturate(nol);
	return diffuse;
}


//===========================================暗黑系列=======================
struct indirectLight
{
	float3 diffuse;
	float skyAO;
    float roomAO;
	float specularTerm;
	float3 reflection;
};

uniform half4 E_AmbientSky;
uniform half4 E_AmbientGround;
uniform half4 E_AmbientEquator;
half3 AmbientLight(float y)
{
    float3 c = 0;
    c = E_AmbientGround.rgb * saturate(-y);
    c += E_AmbientSky.rgb * saturate(y);
    c += E_AmbientEquator.rgb * (1-abs(y));
    return c;
}

//ToonBRDF
inline float Unity_GGX(float NdotH, float LdotH, float a)
{
	float d1 = max(0.1f, LdotH * LdotH) * (a + 0.5f) * 4;
	float a2 = a * a;
	float d = NdotH * NdotH * (a2 - 1) + 1;

	return clamp(a2 / (d1 * d *d), 0, 100.0);
}

inline float UE4_GGX(float3 halfDir, float3 normal, float a)
{
	float3 NxH = cross(normal, halfDir);
	float oneMinusNoH = dot(NxH, NxH);
	float NdotH = dot(normal, halfDir) * a;

	float p = a / (oneMinusNoH + dot(NdotH, NdotH));

	return clamp(dot(p, p), 0, 100.0);
}

inline int perceptualRoughnessToMipmapLevelOff(float perceptualRoughness)
{
	return (int)clamp(perceptualRoughness * 6, 0, 6);//UNITY_SPECCUBE_LOD_STEPS = 6
}

inline half OneMinusReflectivityFromMetallic(half metallic) {
	// We'll need oneMinusReflectivity, so
	//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic)
	//                  = lerp(1-dielectricSpec, 0, metallic)
	// store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
	//	 1-reflectivity = lerp(alpha, 0, metallic)
	//                  = alpha + metallic*(0 - alpha)
	//                  = alpha - metallic * alpha
	half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic,out half3 specColor, out half oneMinusReflectivity
) {
	specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
	return albedo * oneMinusReflectivity;
}

inline float4 DecodeDirectionalLightmap(float3 color, float4 dirTex, float3 normal, float3 viewDir, float a)
{
	float3 lightDir = normalize(dirTex.xyz - 0.5);
//#ifdef LIGHT_PLANT
//	float halfLambert = AbsDot(lightDir, normal) * 0.5 + 0.5;
//#else
	float halfLambert = dot(lightDir, normal) * 0.5 + 0.5;
//#endif

	float4 light = float4(color * halfLambert, 0);

#if LIGHTMAP_SPEC
	float3 halfDir = normalize(lightDir + viewDir);
	light.a = UE4_GGX(halfDir, normal, a);
#endif

	return max(light, 0);
}

half3 DecodeLightmapDLDR(half3 color)
{
    return color * 4.595;
}

inline indirectLight IndirectData(half3 normal, half4 gi, half3 viewDir, half a)
{
	indirectLight data;

    #ifdef LIGHTMAP_ON
	    half4 bakedColorTex = SAMPLE_TEXTURE2D(unity_Lightmap,samplerunity_Lightmap, gi.xy);
        half4 decodeInstructions = half4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0h, 0.0h);
	    half3 bakedColor = DecodeLightmapDLDR(bakedColorTex.rgb);
       // half3 bakedColor = DecodeLightmap(bakedColorTex, decodeInstructions);

        #ifdef DIRLIGHTMAP_COMBINED
            half4 bakedDirTex = SAMPLE_TEXTURE2D(unity_LightmapInd, samplerunity_LightmapInd,  gi.xy);
	        half4 lightData = DecodeDirectionalLightmap(bakedColor, bakedDirTex, normal, viewDir, a);
	        data.diffuse = lightData.rgb * _BakeParam.z;
	        data.specularTerm = lightData.a;
	        data.roomAO = bakedDirTex.w;
        #else
            data.diffuse = bakedColor.rgb * _BakeParam.z;
	        data.specularTerm = 0;
	        data.roomAO = 1;
        #endif
        data.skyAO = bakedColorTex.a;
    #else
        data.diffuse = 0;
	    data.specularTerm = 0;
	    data.skyAO = 1;
        data.roomAO = 1;
    #endif

#if REFLECTION_ON
	half3 reflectDir = reflect(-viewDir, normal);
	//half r = a * (1.7 - 0.7 * a);
//	int mip = perceptualRoughnessToMipmapLevelOff(r);
 //   half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip);
 //   #if !defined(UNITY_USE_NATIVE_HDR)
 //       half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
 //   #else
 //       half3 irradiance = encodedIrradiance.rbg;
 //   #endif
	//data.reflection = irradiance;
   //  data.reflection =SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDir, mip).rgb;
   data.reflection = SampleReflectionProbe(reflectDir, a);

//#elif defined(RAIN_ON)
//	half r = a * (1.7 - 0.7 * a);
//	int mip = perceptualRoughnessToMipmapLevelOff(r);
//	half3 reflectDir = reflect(-viewDir, normal);
//	data.reflection = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectDir, mip).rgb;
#else
	data.reflection = half3(0.19, 0.27, 0.33);
#endif

	//data.reflection *= unity_SpecCube0_HDR.x;

	return data;
}


inline half3 FresnelLerpFast (half3 F0, half3 F90, half cosA)
{
    half t = Pow4 (1 - cosA);
    return lerp (F0, F90, t);
}

half3 BRDF_GGX(half3 diffuse, half3 specular, half a, half oneMinusReflectivity, half3 normal, half3 viewDir, Light light, indirectLight indirect, half shadow)
{
	half NdotV = dot(normal, viewDir);
	half3 halfDir = normalize(light.direction + viewDir);
	half NdotL = max(0,dot(normal, light.direction));
	half NdotH = dot(normal, halfDir);
	half LdotH = dot(light.direction, halfDir);
	half specularTerm = Unity_GGX(NdotH, LdotH, a);
	//取个简单线性代替
	half surfaceReduction = (1 - 0.7 * a);
	//float surfaceReduction = 0.6 - 0.08 * a;
	//surfaceReduction = 1.0 - a * surfaceReduction;
	half3 grazingTerm = saturate(2 - a - oneMinusReflectivity);
    half3 ambientLight = AmbientLight(normal.y);

	half3 color = ambientLight * diffuse * lerp(_SkyAOColor.rgb, 1, indirect.skyAO)
                + (diffuse + specular * specularTerm) * NdotL * light.color.rgb * shadow
    #if LIGHTMAP_SPEC
		    + (diffuse + indirect.specularTerm * specular) * indirect.diffuse
    #else
		    +  diffuse * indirect.diffuse 
    #endif
		    + surfaceReduction * indirect.reflection * FresnelLerpFast(specular, grazingTerm, NdotV) ;
	return color;
}

half3 Anhei_PBS(SurfaceInput surface)
{
	BRDFInput brdf = GetBRDF(surface);
    //#ifdef RAIN_ON
	   // surface.worldNormal.xy *= brdf.roughness2;
	   // brdf.roughness2 *= 0.25;
    //#endif
	indirectLight indirect = IndirectData(surface.worldNormal, surface.ambientOrLightmapUV, brdf.viewDir, brdf.roughness2); 
	indirect.reflection *= surface.occlusion;
    half3 specular;
	float oneMinusReflectivity;
	half3 diffuse = DiffuseAndSpecularFromMetallic(surface.albedo, surface.metallic, specular, oneMinusReflectivity);
    float4 shadowCoord = TransformWorldToShadowCoord(surface.worldPos);
    Light light = GetMainLight(shadowCoord);

    half3 col = BRDF_GGX(diffuse, specular, brdf.roughness2, oneMinusReflectivity, surface.worldNormal,brdf.viewDir, light, indirect, light.shadowAttenuation);
    #ifdef LIGHTMAP_ON
	    col.rgb =lerp(col.rgb* _RoomAOColor.rgb, col.rgb, pow(indirect.roomAO,2-_RoomAOColor.a));
    #endif
    return col;

}


//===================== _Character=================
half3 _CharacterLightDir;
half4 _CharacterLightSideAmbientColor;
half3 Anhei_PBS_C(SurfaceInput surface)
{
	BRDFInput brdf = GetBRDF(surface);
	indirectLight indirect = IndirectData(surface.worldNormal, surface.ambientOrLightmapUV, brdf.viewDir, brdf.roughness2); 
	indirect.reflection *= surface.occlusion;
    half3 specular;
	float oneMinusReflectivity;
	half3 diffuse = DiffuseAndSpecularFromMetallic(surface.albedo, surface.metallic, specular, oneMinusReflectivity);
    float4 shadowCoord = TransformWorldToShadowCoord(surface.worldPos);
    Light light = GetMainLight();
    indirect.reflection = lerp(0, indirect.reflection, surface.metallic);
    light.direction = _CharacterLightDir;
    light.color = _CharacterLightSideAmbientColor;

    half3 col = BRDF_GGX(diffuse, specular, brdf.roughness2, oneMinusReflectivity, surface.worldNormal, brdf.viewDir, light, indirect, 1);
    #ifdef LIGHTMAP_ON
	    col.rgb =lerp(col.rgb* _RoomAOColor.rgb, col.rgb, pow(indirect.roomAO,2-_RoomAOColor.a));
    #endif
    return col;

}
//========================_Character end==============

//terrain---

inline float3 UnpackSmoothedScaledNormalTerrain(sampler2D normalTex, float2 uv, float scale, out float height)
{
	float4 tNormal = tex2D(normalTex, uv);
	height = tNormal.b;
	return UnpackNormalScale(float4(tNormal.xy, 1, 1), scale);
}



float4 BRDF_GGX_TERRAIN(float3 diffuse, float3 specular, float a, float3 normal, float3 viewDir, Light light, indirectLight indirect, float shadow)
{
	float3 halfDir = normalize(light.direction + viewDir);
	float NdotL = dot(normal, light.direction);
	float NdotH = dot(normal, halfDir);
	float LdotH = dot(light.direction, halfDir);
	float specularTerm = clamp(Unity_GGX(NdotH, LdotH, a), 0, 80);
	//float NdotV = Dot(normal, viewDir);

//#ifdef RAIN_ON
//	float surfaceReduction = 1 - 0.7 * a;
//	float grazingTerm = 2 - a;
//#endif
    half3 ambientLight = AmbientLight(normal.y);
	float3 color = ambientLight + (diffuse + specular * specularTerm) * NdotL *light.color.rgb * shadow
		+ (diffuse + indirect.specularTerm * specular) * indirect.diffuse;
//#ifdef RAIN_ON
//		+ surfaceReduction * indirect.reflection * FresnelLerpFast(specular, grazingTerm, NdotV);
//#else
//		;
//#endif
    #ifdef LIGHTMAP_ON
        color.rgb =lerp(color.rgb* _RoomAOColor.rgb, color.rgb, pow(indirect.roomAO,2-_RoomAOColor.a));
    #endif
	return float4(color, 1);
}





//===========================================暗黑系列End=======================

////// 
////unity_ShadowMask unity_ShadowMask1都不行，塞不进去有毒
// #if defined(SHADOWS_SHADOWMASK)
//TEXTURE2D(_SceneShadowMask);
//SAMPLER(sampler_SceneShadowMask);
//#endif

//half3 GIDiffuse(float3 normal, float2 ambientOrLightmapUV,float3 worldpos,  inout half bakedAO, inout half atten)
//{
//    half3 diffColor = 0;
//	//bakedAO = 1;
//    //#if defined(LIGHTMAP_ON)
//	    //half bakedAtten = FantasySampleBakedOcclusionAOFromMaskG(ambientOrLightmapUV.xy, worldpos, bakedAO);
//	    //#if defined(SHADOWS_SCREEN)
//	    //    //计算阴影
//	    //    float zDist = dot(_WorldSpaceCameraPos - worldpos, UNITY_MATRIX_V[2].xyz);
//	    //    float fadeDist = UnityComputeShadowFadeDistance(worldpos, zDist);
//	    //    atten = UnityMixRealtimeAndBakedShadows(atten, bakedAtten, UnityComputeShadowFade(fadeDist));
//	    //#else
//    //#endif
//    #if defined(LIGHTMAP_ON)
//        half4 bakedColorTex =  SAMPLE_TEXTURE2D(unity_Lightmap, samplerunity_Lightmap, ambientOrLightmapUV.xy);
//        half3 bakedColor = bakedColorTex.rgb * (PositivePow(bakedColorTex.a, 2.2) * 34.5)* _BakeParam.z;//2.2  34.493242 34.5
//       // half3 bakedColor = DecodeLightmap(bakedColorTex).rgb;


//        #ifdef DIRLIGHTMAP_COMBINED
//	        half4 bakedDirTex = SAMPLE_TEXTURE2D(unity_LightmapInd, samplerunity_Lightmap,  ambientOrLightmapUV.xy);
//            //half diffBaked = dot(normal,bakedDirTex.xyz * 2 - 1) ;
//	        half diffBaked = dot(normal, normalize(bakedDirTex.xyz - 0.5));
//            //half diffBaked = (dot(normal, bakedDirTex.xyz - 0.5) + 0.5) / max(1e-4h, bakedDirTex.w);
//	       // half diffBaked = dot (normal, normalize(bakedDirTex));
//	        bakedColor = bakedColor * diffBaked ;
//        #endif

//        #if defined(SHADOWS_SHADOWMASK)
//            half4 rawOcclusionMask = SAMPLE_TEXTURE2D(_SceneShadowMask, sampler_SceneShadowMask, ambientOrLightmapUV.xy);
//            atten = rawOcclusionMask.r;
//            bakedAO = rawOcclusionMask.g;
//	    #endif

//	    diffColor.rgb = bakedColor;
//        //diffColor = bakedColor.rgb;

//    #endif
//    //diffColor = pow(diffColor,_GlobalLightmapIntensity);
    
//	//暂不考虑动态光照贴图
//	return max(0.001, diffColor);
//}

#endif