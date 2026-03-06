#ifndef TOONBASE_H
    #define TOONBASE_H

    #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
   
    
    uniform half4 _HalfColorRTSize;

    //uniform
    // uniform float4x4 _MATRIX_I_VP;
    //自定义环境光
    uniform half3 _AmbientColor;
    uniform float _AmbientIntensity;
    #define APPLY_AMBIENT(c) c.rgb *= _AmbientIntensity*_AmbientColor;
    #define SCENE_AMBIENT(c,light) c.rgb *= light*_SceneLightSideAmbientColor + (1-light)*_SceneDarkSideAmbientColor;\
   
    //uniform half4 _SunScatterFogColor;
    //uniform float _SunScatterAreaRage;

    uniform float4 _NearFogParam;
    uniform float4 _NearFogColor;

    //场景高度雾
    // uniform half3 _SceneHightFogStartColor;
    // uniform half3 _SceneHightFogEndColor;
    uniform half4 _SceneHightFogColor;
    uniform float _SceneHeightFogThreshold;
    uniform float _SceneHeightFogFearther;
    uniform float _SceneHeightFogIntensity;
    // #define SCENE_HIGHT_FOG(c,hight) c.rgb = lerp(c.rgb,lerp(_SceneHightFogStartColor,_SceneHightFogEndColor,smoothstep(_SceneHeightFogThreshold-_SceneHeightFogFearther,_SceneHeightFogThreshold+_SceneHeightFogFearther,hight)),_SceneHeightFogIntensity);
    #define SCENE_HIGHT_FOG(c,hight) c.rgb = lerp(c.rgb,lerp(_SceneHightFogColor,c.rgb,smoothstep(_SceneHeightFogThreshold-_SceneHeightFogFearther,_SceneHeightFogThreshold+_SceneHeightFogFearther,hight)),_SceneHeightFogIntensity);

    //自身高度雾
    #define SELF_HIGHT_FOG(c,hight) c.rgb = lerp(_HeightFogColor.rgb,c.rgb,smoothstep(_HeightFogThreshold-_HeightFogFeather,_HeightFogThreshold+_HeightFogFeather,hight));

    //烘培参数X-ao强度，Y阴影强度
    uniform half4 _BakeParam;
    //uniform half _GlobalLightmapIntensity;

    //地表融合贴图
    TEXTURE2D(_GroundTex); SAMPLER(sampler_GroundTex);

    inline float2 GetGroundTexUV(float3 worldPos,float4 _GroundTex_ST){
        float4 uv = _GroundTex_ST*0.01;
        return worldPos.xz * uv.xy + uv.zw;
    }

    inline void GetGroundColor(inout half3 col, float3 worldPos,float4 _GroundTex_ST, half threshold, half feather){
        float2 uv = GetGroundTexUV(worldPos,_GroundTex_ST);
        half4 groundCol = SAMPLE_TEXTURE2D(_GroundTex,sampler_GroundTex,uv);
        float blend = smoothstep(threshold-feather,threshold+feather,worldPos.y);
        col.rgb = lerp(groundCol.rgb,col.rgb,blend);
    }

    inline void GetGroundColor(inout half3 col, float3 worldPos,float4 _GroundTex_ST, half threshold, half feather, float height){
        float2 uv = GetGroundTexUV(worldPos,_GroundTex_ST);
        half4 groundCol = SAMPLE_TEXTURE2D(_GroundTex,sampler_GroundTex,uv);
        float blend = smoothstep(threshold-feather,threshold+feather,height);
        col.rgb = lerp(groundCol.rgb,col.rgb,blend);
    }


    //角色扰动
    #define TrailNum 5
    CBUFFER_START(UnityPerFrame)
    uniform float4 _PlayerEffect; //xyz:player current pos, w: time when player arrival there
    uniform float4 _PlayerTrail[TrailNum]; //xyz:player current pos, w: time when player arrival there
    CBUFFER_END

    float2 PlayerEffect(float3 worldPos,float limit,float _Strength,float _EffectRadius)
    {
        float2 dis = worldPos.xz - _PlayerEffect.xz;
        float pushDown = saturate((1 - length(dis) + _EffectRadius) * limit * _Strength);
        float2 direction = normalize(dis);
        direction.y *= 0.5;
        return direction * pushDown;
    }

    float3 PlayerEffect(float3 worldPos,float limit,float _Strength,float _EffectRadius,float YStrength)
    {
        float2 dis = worldPos.xz - _PlayerEffect.xz;
        float pushDown = saturate((1 - length(dis) + _EffectRadius) * limit * _Strength);
        dis = normalize(dis)*pushDown;
        float yOffset = -YStrength*pushDown;
        float3 direction = float3(dis.x,yOffset,dis.y);
        return direction;
    }

    float PlayerEffectEmision(float3 worldPos,float _EmissionRadius)
    {
        float res = 0;
        for(int i=0;i<TrailNum;i++){
            float dis = length(worldPos-_PlayerTrail[i].xyz);
            float timeFade = _Time.y - _PlayerTrail[i].w;
            float emissionFade = smoothstep(_EmissionRadius,0,dis) * (1-smoothstep(0,1.0,timeFade));//渐暗
            // float emissionFade = smoothstep(_EmissionRadius,0,dis) * sin(timeFade);
            res = max(res,emissionFade);
        }
        return res;
    }

    #ifndef _SPACETRANSFORM_H
        // help functions
        inline float3 UnityWorldSpaceViewDir(float3 worldPos){
            return _WorldSpaceCameraPos - worldPos;
        }

        inline float3 UnityWorldSpaceLightDir(float3 worldPos){
            return _MainLightPosition.xyz;
        }

        inline float3 ObjSpaceLightDir(half3 lightDir){
            return TransformWorldToObjectDir(lightDir);
        }

        inline float3 ObjSpaceViewDir(in float4 vertex)
        {
            float3 objSpaceCameraPos = TransformWorldToObject(_WorldSpaceCameraPos.xyz).xyz;
            return objSpaceCameraPos - vertex.xyz;
        }

        void FastSinCos(float4 val, out float4 s)
        {
            val = val * 6.408849 - 3.1415927;
            float4 r5 = val * val;
            float4 r1 = r5 * val;
            float4 r2 = r1 * r5;
            float4 r3 = r2 * r5;
            float4 sin7 = { 1, -0.16161616, 0.0083333, -0.00019841 };
            s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
        }
    #endif



    #ifdef _WORDSPACE_LIGHTMAP
    TEXTURE2D(_WorldSpaceLightMap); SAMPLER(sampler_WorldSpaceLightMap);
    half4 _WorldSpaceLightMapST;

    half2 GetWSLightMapUV(float3 worldPos){
        return (worldPos.xz - _WorldSpaceLightMapST.xy) * _WorldSpaceLightMapST.z / _WorldSpaceLightMapST.w;
    }
    half4 GetWorldSpaceLightMapColor(half2 uv)
    {
         half4 groundCol = SAMPLE_TEXTURE2D(_WorldSpaceLightMap, sampler_WorldSpaceLightMap, uv);
         return groundCol;
    }
    #endif

    //草浪
    float2 WaveGrass (float3 worldPos,float4 _WaveParams)
    {
        float4 _waveXSize = float4(0.012, 0.02, 0.06, 0.024) * _WaveParams.y;
        float4 _waveZSize = float4 (0.006, .02, 0.02, 0.05) * _WaveParams.y;
        float4 waveSpeed = float4 (0.3, .5, .4, 1.2) * 4;

        float4 _waveXmove = float4(0.012, 0.02, -0.06, 0.048) * 2;
        float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);

        float4 waves;
        waves = worldPos.x * _waveXSize;
        waves += worldPos.z * _waveZSize;

        // Add in time to model them over time
        waves += _WaveParams.x * _Time.y * waveSpeed;

        float4 s;
        waves = frac (waves);
        FastSinCos(waves, s);

        s = s * s;
        s = s * s;
        s = s * _WaveParams.w;

        float3 waveMove = float3 (0,0,0);
        waveMove.x = dot (s, _waveXmove);
        waveMove.z = dot (s, _waveZmove);

        return waveMove.xz * _WaveParams.z;
    }

    float Highlights(float roughness, float3 normal, float3 viewDir,float3 lightDir)//水面高光
    {
        float roughness2 = roughness * roughness;
        float3 halfDir = normalize(lightDir + viewDir);
        float NH = saturate(dot(normalize(normal), halfDir));
        float LH = saturate(dot(lightDir, halfDir));
        // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
        // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
        // https://community.arm.com/events/1155
        float d = NH * NH * (roughness2 - 1.0) + 1.0001;
        float LH2 = LH * LH;
        float specularTerm = roughness2 / ((d * d) * max(0.1h, LH2) * (roughness + 0.5h) * 4);
        // on mobiles (where float actually means something) denominator have risk of overflow
        // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
        // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
        #if defined(SHADER_API_MOBILE)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 5.0); // Prevent FP16 overflow on mobiles
        #endif
        return specularTerm;
    }

    half3 ColorMapping(half3 col,half param)
    {
        half3 c = col * param;
        return (c / (c + (half3)(0.187))) * 1.03499996662139892578125;
    }

    inline half3 LinearToSRGBFast(half3 col)
    {
        return pow(col,0.454545454545455);
    }

    inline half3 GammaToLinearFast(half3 col)
    {
        return col * col;
        return pow(col,2.2);
    }


    inline float4 EncodeFloatRGBA(float v)
    {
        float4 kEncodeMul = float4(1.0, 255.0, 65025.0, 16581375.0);
        float kEncodeBit = 1.0 / 255.0;
        float4 enc = kEncodeMul * v;
        enc = frac(enc);
        enc -= enc.yzww * kEncodeBit;
        return enc;
    }
    inline float DecodeFloatRGBA(float4 enc)
    {
        float4 kDecodeDot = float4(1.0, 1 / 255.0, 1 / 65025.0, 1 / 16581375.0);
        return dot(enc, kDecodeDot);
    }


#ifdef _DISSOLVE_ON
    half3 DoDissolve(half3 col,half4 dissolveTexColor, half _ClipAmount, half3 _LineColor, half _LineIntensity)
    {
        half amount = (dissolveTexColor.a - _ClipAmount);
        //当前颜色值
        half3 currentColor = dissolveTexColor.rgb * amount;
        if (amount <= 0.01f)
        {
	        clip(-0.1);
        }
        else
        {
	        if (amount < 0.1f)
	        {
		        col.rgb = (currentColor * _LineColor * _LineIntensity).rgb;
	        }
        }
        return col.rgb;
    }
 #endif



        //普通远近景雾
    half3 MixFog(half3 fragColor, half clipZ_01, half4 sunScatterFogColor, float3 posWorld)
    {
        clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(clipZ_01);
        //return MixFogColor(fragColor, unity_FogColor.rgb, fogFactor);
        #if defined(FOG_LINEAR)
            half fogIntensity = 0.0h;
            half fogFactor = 0.0h;
            // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
            fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
            fogIntensity = fogFactor;
            fogIntensity = 1- fogIntensity;
            fogIntensity *= unity_FogColor.a;

            half3 farFogFinalColor = unity_FogColor.rgb;
            //远景，混合太阳光散射
            //half vl = max( dot(normalize(posWorld -_WorldSpaceCameraPos.xyz ), _MainLightPosition.xyz), 0);
            //farFogFinalColor = lerp(farFogFinalColor, sunScatterFogColor.rgb*_NearFogParam.w, 
            //pow(vl, _SunScatterAreaRage)  *saturate(exp2(-_NearFogParam.z))*sunScatterFogColor.a);

            half nearFogIntensity = 1- saturate(clipZ_01 * _NearFogParam.x + _NearFogParam.y);
            nearFogIntensity *= _NearFogColor.a;
            half3 finalIntensity = lerp(nearFogIntensity, fogIntensity, fogIntensity);
            half3 finalFogColor = lerp(_NearFogColor.rgb, farFogFinalColor, fogIntensity);
            fragColor = lerp(fragColor, finalFogColor.rgb, finalIntensity);
        #endif

        return fragColor;
    }

    //场景用，远近景雾+高度雾+太阳散射雾
    half3 CalculateFog(half3 fragColor, half clipZ_01, half3 sunScatterFogColor, float3 posWorld) 
	{
		half3 fogCoord = 0;
        #if FOG_LINEAR 
			half z = UNITY_Z_0_FAR_FROM_CLIPSPACE(clipZ_01);
			half farFogFactor = (1 - saturate(z * unity_FogParams.z + unity_FogParams.w)) * unity_FogColor.a;
			//这部分低配可以关闭
            half heightFogFactor = 1 - smoothstep(_SceneHeightFogThreshold - _SceneHeightFogFearther, _SceneHeightFogThreshold + _SceneHeightFogFearther, posWorld.y) ;
			//half heightFogFactor = saturate(pos.y * _HeightFogParams.x + _HeightFogParams.y) * _HeightFogColor.a;
			heightFogFactor = lerp(heightFogFactor, heightFogFactor ,  _SceneHeightFogIntensity)* _SceneHightFogColor.a;

			fogCoord.xyz = lerp( unity_FogColor.rgb, _SceneHightFogColor.rgb, heightFogFactor);
            fragColor.rgb = lerp(fragColor.rgb, fogCoord.rgb, max(farFogFactor, heightFogFactor));
        #endif

		return fragColor;
	}


TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
uniform sampler2D _heightMap;
float _useHeightMap;
float4 _heightMinMax;


//全局的环境光系数
float _GlobalLightMaptIntensity;
#define UNITY_PI            3.14159265359f
#define RATIO_256               0.00390625
#define GetTerrainLightMapColor(worldPos) SAMPLE_TEXTURE2D(_LightMap,sampler_LightMap,worldPos.xz * RATIO_256) *_GlobalLightMaptIntensity;

float SampleTerrainHeightInVert(float3 worldPos){
    return _heightMinMax.x + tex2Dlod(_heightMap, float4((worldPos.x + _heightMinMax.z) * RATIO_256, (worldPos.z + _heightMinMax.w) * RATIO_256, 0, 0)).x * _heightMinMax.y;
}


float4 GetNormalLight(float4 col, float4 albedo, float3 worldPos, float3 worldNormal, float _LightIntensity, float _LightMapIntensity, float NolValue = 0.5)
{
    //基本主光
    float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
    Light light = GetMainLight(shadowCoord);
    light.color = light.color * light.distanceAttenuation;
    half nol = saturate(dot(worldNormal, light.direction));
    nol = NolValue * nol + (1 - NolValue);
    col.rgb = albedo * light.color * nol * _LightIntensity;
    //基本多光源
#ifdef _ADDITIONAL_LIGHTS
	half3 atten = 1;
	// half3 vertexLightColor = AddLighting(worldNormal, worldPos,NolValue);
    half3 vertexLightColor = AddLighting(worldNormal, worldPos);
	col.rgb += albedo * vertexLightColor * atten * _LightIntensity;
#endif

#ifdef _TERRAINLIGHTMAP
	half3 lightMap = GetTerrainLightMapColor(worldPos);
	col.rgb += albedo * lightMap * _LightMapIntensity;
#endif
    return col;
}

//----------------Scene Grass Wave
float4 ScaleMatrix(float4 scale, float4 vertex)
{
    float4x4 scaleMatrix = float4x4(scale.x, 0, 0, 0,
                                    0, scale.y,0, 0,
                                    0, 0, scale.z, 0,
                                    0, 0, 0, 1);
    return mul(scaleMatrix, vertex);

}

float4 YRotateMatrix(float angle, float4 vertex)
{
    float4 row0 = float4(cos(angle), 0, sin(angle), 0);
    float4 row1 = float4(0, 1, 0, 0);
    float4 row2 = float4(-sin(angle), 0, cos(angle), 0);
    float4 row3 = float4(0, 0, 0, 1);
    float4x4 mat = float4x4(row0, row1, row2, row3);
    return mul(mat,vertex);
}


#endif


