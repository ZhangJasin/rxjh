Shader "MD/Character/CharacterPBR"
{
	Properties
	{
		_MainTex("Albedo(RGB)", 2D) = "white" {}
		[HDR]_Color("Color", Color) = (1, 1, 1, 1)
        [Toggle(ALPHA_TEST_ON)]alphaTestOn("_CutoffOn",float) = 0
		_Cutout("Cutout", Range(0, 1)) = 0.5
        [Toggle(_NORMAL_RG)]useNormalRG("特殊法线图仅用RG通道,BA另有他用",float) = 0
		_NormalTex("Normal Map", 2D) = "bump" {}
		_NormalScale("Normal Scale", Range(0, 3)) = 1
		_PBRTex("Smooth(R), Metallic(G), AO(B)", 2D) = "gray" {}
		[MaterialToggle]_RoughnessMipOffset("Roughness Mip Offset", Float) = 0
		_Occlusion("Occlusion", Range(0, 1)) = 0.5
        
         [Space(20)]
        [Toggle(EMISSION_ON)]EMISSION_ON("EMISSION_ON",float) = 0
		_EmissionTex("Emission Map", 2D) = "black" {}
        [HDR]_EmissionColor ("Emission Color", Color) = (1, 1, 1, 1)

		[HideInInspector]_BlendMode("Blend Mode", Int) = 0
		[Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 0
	}

    SubShader 
    {
        LOD 200
        Tags { "LightMode" = "UniversalForward" "RenderType"="Opaque" "Queue"="Geometry+100" }
		Cull [_Cull]
                 
        HLSLINCLUDE
            #define REFLECTION_ON 1
            #define IS_CHARACTER
            #include "../Lib/ToonPBS.hlsl"
			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			half4 _Color;
			half _EmissionIntensity;
			half _Cutoff;
            half4 _EmissionColor;
            half _NormalScale;
            half _Cutout;
			CBUFFER_END
		ENDHLSL

		Pass
		{ 
		
			Zwrite On
			Cull [_Cull]
   
			HLSLPROGRAM
			#pragma vertex vert_pbr_c
			#pragma fragment frag_pbr_c
			#pragma target 3.0
			#pragma shader_feature _ ALPHA_TEST_ON
			#pragma shader_feature _ EMISSION_ON
            #pragma shader_feature _ _NORMAL_RG
            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);
            TEXTURE2D(_PBRTex); SAMPLER(sampler_PBRTex);

            #ifdef EMISSION_ON
            TEXTURE2D(_EmissionTex); SAMPLER(sampler_EmissionTex);
            #endif

            v2f_pbs vert_pbr_c(appdata_pbs v)
            {
	            v2f_pbs o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                TransTtoW(v,o);
                o.ambientOrLightmapUV = 0;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = TransformObjectToHClip(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos).xyw;
	            return o;
            }

            float4 frag_pbr_c(v2f_pbs i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                #if ALPHA_TEST_ON
	                clip(albedo.a - _Cutout);
                #endif
                half4 bump = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);

                #ifdef _NORMAL_RG
                    float3 N = UnpackNormalmapRGorAG(bump, _NormalScale);
                #else
                    float3 N = UnpackNormalScale(bump, _NormalScale);
                #endif

                ApplyTtoW(i,N);
				half4 pbr = SAMPLE_TEXTURE2D(_PBRTex, sampler_PBRTex, i.uv);
                SurfaceInput surface;
                surface.smoothness = pbr.r;
                surface.metallic = pbr.g;
                surface.occlusion = pbr.b;
                surface.albedo = albedo.rgb*_Color.rgb;
                surface.worldPos = worldPos;
                surface.worldNormal = worldNormal;//float to half here
                surface.ambientOrLightmapUV = i.ambientOrLightmapUV;
                half3 col = Anhei_PBS_C(surface);

                #ifdef EMISSION_ON
                    half3 emission = SAMPLE_TEXTURE2D(_EmissionTex,sampler_EmissionTex,i.uv).rgb;
                    col.rgb += emission*_EmissionColor.rgb;
                #endif
                return half4(col,1.0);
            }

			ENDHLSL		
		}

    }

    FallBack "MD/Common/CharacterDebug"
	CustomEditor "CharacterShaderGUI"
}
