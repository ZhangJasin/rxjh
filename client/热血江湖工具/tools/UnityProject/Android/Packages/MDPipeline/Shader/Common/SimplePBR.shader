Shader "MD/Standard/SimplePBR"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        // unity_Lightmap_BRG("unity_Lightmap",2D) = "white"{}
        //  unity_LightmapInd_BRG("unity_LightmapInd",2D) = "white"{}
        //   unity_ShadowMask_BRG("unity_ShadowMask",2D) = "white"{}
        //   _unity_LightmapST_BRG("unity_LightmapST_BRG",Vector) = (0,0,0,0)
        _Color ("Color", Color) = (1, 1, 1, 1)
        [Toggle(SHADOWALPHACLIP_ON)]SHADOWALPHACLIP_ON("SHADOWALPHACLIP_ON",float) = 0
        _Cutoff("_Cutoff",Range(0,1)) = 0.5
        _NormalTex ("Normal Map", 2D) = "bump" {}
        _PBRTex ("Smooth(R), Metallic(G), AO(B)", 2D) = "gray" {}
        [Space(20)]
        [Toggle(_EmissionTex_ON)]_EmissionTex_ON("_EmissionTex_ON",float) = 0
        _EmissionTex ("Emission Map", 2D) = "black" {}
        _EmissionIntensity("_EmissionIntensity",float) = 1
        // [Space(20)]
        // [Toggle(_GroundTex_ON)]_GroundTex_ON("_GroundTex_ON",float) = 0
        // _GroundTex("_GroundTex",2D) = "black" {}
        // _Groundthreshold("_Groundthreshold",float) = 0
        // _GroundthresholdFeather("_GroundthresholdFeather",float) = 0.1
        [Space(20)]
        [Toggle(_HeightFog_ON)]_HeightFog_ON("_HeightFog_ON",float) = 0
        _HeightFogColor("Height Fog Color", Color) = (0,0,0,0)
        _HeightFogThreshold("_HeightFogThreshold", Float) = 0.0
        _HeightFogFeather("_HeightFogFeather", Float) = 0.0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
		[Toggle(_PROBE_BASED_GI)] _ProbeBasedGI("Probe Based GI", Float) = 1
        _StencilRef("Stencil Reference", Float) = 128.0
    }

    SubShader {
        LOD 200
        Stencil
		{
			Ref [_StencilRef]
			Comp Always
			Pass Replace
		}
        Cull [_Cull]
		HLSLINCLUDE
            #define _MAIN_LIGHT_SHADOWS_CASCADE 1
            #define _SHADOWS_SOFT 1
           //  #define _SCREENSPACE_SHADOW_ON 1
			#include "../Library/Core.hlsl"
            // #include "../Library/SimplePBS.hlsl"
			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			half3 _Color;
			half _EmissionIntensity;
			half _Cutoff;
			// #ifdef _GroundTex_ON
			// float4 _GroundTex_ST;
			// half _Groundthreshold;
			// half _GroundthresholdFeather;
			// #endif
			half3 _HeightFogColor;
			half _HeightFogThreshold;
			half _HeightFogFeather;
			CBUFFER_END
		ENDHLSL
      //  UsePass "Hidden/ZWritePass/OnlyZWriteOn"
        Pass {
            Tags { "LightMode" = "UniversalForward" "RenderType"="Opaque" "Queue"="Geometry" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            
            #pragma shader_feature _ _EmissionTex_ON
            #pragma multi_compile _ LIGHTMAP_ON _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            // #pragma multi_compile _ LIGHTMAP_ON_BATCHRENDERGROUP
            #pragma shader_feature _ RAIN_ON
			#pragma shader_feature _ SHADOWS_SHADOWMASK
			#pragma shader_feature _ _MIXED_LIGHTING_SHADOWMASK
            #pragma shader_feature _ _HeightFog_ON
            #pragma shader_feature _ _USE_CBFR
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _CHARACTER_SHADOW_ON _SCREENSPACE_SHADOW_ON
            #pragma shader_feature _ _CHARACTER_SHADOWS_SOFT_PC
			#pragma shader_feature _ LOD_FADE_CROSSFADE
            #pragma shader_feature_local_fragment _ _PROBE_BASED_GI
            #pragma shader_feature_fragment _ PROBE_BASED_GI_MODE_ON PROBE_BASED_GI_MODE_DEBUG

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);
            TEXTURE2D(_PBRTex); SAMPLER(sampler_PBRTex);
            TEXTURE2D(_EmissionTex); SAMPLER(sampler_EmissionTex);
            
            #ifdef RAIN_ON
            TEXTURE2D(_FallRainTexture);SAMPLER(sampler_FallRainTexture);
            TEXTURE2D(_RippleTexture);SAMPLER(sampler_RippleTexture);
            float _FallSpeed;

            #define VERTEX_RAIN \
			float4 localPos = o.worldPos; \
			float horizon = abs(v.normal.x); \
			float vertical = dot(wNormal, float3(0, 1, 0)); \
			o.rainPos = float4(lerp(localPos.xy, localPos.zy, horizon) * 0.25 + float2(0, _Time.x * _FallSpeed), vertical, 0)

            #define PIXEL_RAIN \
			float3 rippleNormal = SAMPLE_TEXTURE2D(_RippleTexture,sampler_RippleTexture, i.worldPos.xz * 0.25).rgb * 2 - 1; \
			float3 fallNormal = SAMPLE_TEXTURE2D(_FallRainTexture,sampler_FallRainTexture, i.rainPos.xy).rgb; \
			float2 uvBias = lerp(fallNormal.xy * 0.2, rippleNormal.xy * 0.4, i.rainPos.z)
            #endif      
            // StructuredBuffer<float4> _LightmapSTBuffer;
             #ifdef LIGHTMAP_ON_BATCHRENDERGROUP
            v2f_pbs vert (appdata_pbs v, uint instanceID: SV_InstanceID)
            #else
            v2f_pbs vert (appdata_pbs v)
            #endif
            {
                v2f_pbs o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                TransTtoW(v,o);

                o.ambientOrLightmapUV = 0;
                // #ifdef LIGHTMAP_ON_BATCHRENDERGROUP
                //o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST_BRG.xy + unity_LightmapST_BRG.zw;
                   //o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                // #endif
                #ifdef LIGHTMAP_ON_BATCHRENDERGROUP
                    // float4 st = unity_LightmapST_BRG[instanceID];
                    //unity_LightmapST_BRG_Offset
                     float4 st = _LightmapSTBuffer[unity_LightmapST_BRG_Offset+instanceID];
                    // o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST_BRG.xy + unity_LightmapST_BRG.zw;
                    o.ambientOrLightmapUV.xy = v.uv1.xy * st.xy + st.zw;
                #elif defined(LIGHTMAP_ON)
                    o.ambientOrLightmapUV.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #else
                     o.ambientOrLightmapUV.rgb = SampleSHVertex(N);
                 #endif
                 
                
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.pos = TransformObjectToHClip(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos).xyw;
                o.fogCoord.x = ComputeFogFactor(o.pos.z);
                o.fogCoord.y = v.vertex.y;
                #ifdef RAIN_ON
                float3 wNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = float4(worldPos,1);
	                VERTEX_RAIN;
                #endif  
                return o;
            }

            half4 frag (v2f_pbs i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                ClipLOD(i.pos.xy, unity_LODFade.x);
                #ifdef RAIN_ON
	                PIXEL_RAIN;
	                i.uv += uvBias;
                #endif
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                half4 bump = SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv);
                float3 N = UnpackNormal(bump);

                ApplyTtoW(i,N);

				half4 pbr = SAMPLE_TEXTURE2D(_PBRTex, sampler_PBRTex, i.uv);
				APPLY_PROBE_BASED_GI_MODE(worldPos, worldNormal)

                SurfaceInput surface;
                surface.smoothness = pbr.r;
                surface.metallic = pbr.g;
                surface.occlusion = pbr.b;
                surface.albedo = albedo.rgb*_Color.rgb;
                surface.worldPos = worldPos;
                surface.worldNormal = worldNormal;//float to half here
                surface.ambientOrLightmapUV = i.ambientOrLightmapUV;

                half3 col = Toon_PBS(surface);

                #ifdef _EmissionTex_ON
                    half3 emission = SAMPLE_TEXTURE2D(_EmissionTex,sampler_EmissionTex,i.uv).rgb;
                    col.rgb += emission*_EmissionIntensity;
                #endif

                // #ifdef _GroundTex_ON
                //     GetGroundColor(col.rgb,worldPos,_GroundTex_ST,_Groundthreshold,_GroundthresholdFeather);
                // #endif

                #ifdef _HeightFog_ON
                    float hightFog = smoothstep(_HeightFogThreshold-_HeightFogFeather,_HeightFogThreshold+_HeightFogFeather,i.fogCoord.y);
                    col.rgb = lerp(_HeightFogColor.rgb,col.rgb,hightFog);
                #endif

                #ifdef _ADDITIONAL_LIGHTS
                    #ifdef _USE_CBFR
                        half3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                        float2 screenUV = i.screenPos.xy / i.screenPos.z;
                        half3 addColor = CalculateLocalLight(screenUV, worldPos.xyz, LinearEyeDepth(i.pos.z, _ZBufferParams), worldNormal.xyz, viewDir);
                        col.rgb += addColor  * albedo.rgb;
                    #else
                        half3 vertexLightColor = AddLighting(worldNormal, worldPos);
                        col.rgb += vertexLightColor * albedo;
                    #endif
                #endif

                col.rgb = MixFog(col.rgb,i.fogCoord.x);
                return half4(col,1.0);
            }
            ENDHLSL
        }
		/*Pass
		{
			LOD 200
			Name "ShadowCaster"
			Tags{"LightMode" = "ShadowCaster"}
			Cull[_Cull]
			ZWrite On ZTest LEqual

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#pragma multi_compile _ SHADOWALPHACLIP_ON
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
			#include "../Library/ShadowCasterPass.hlsl"

			ENDHLSL
		}*/
        UsePass "MD/Standard/ShadowCaster/ShadowCaster"
        // UsePass "MD/Standard/ShadowCaster/CharacterShadowCaster"
       // UsePass "MD/Standard/ShadowCaster/PerObjectShadow"
		Pass
		{
			Name "Meta"
			Tags{"LightMode" = "Meta"}

			Cull Off

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex MetaPassVertex
			#pragma fragment MetaPassFragment
            #pragma shader_feature _ _EmissionTex_ON

			#include "../Library/Core.hlsl"

			TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
			TEXTURE2D(_PBRTex); SAMPLER(sampler_PBRTex);
			TEXTURE2D(_EmissionTex); SAMPLER(sampler_EmissionTex);

            bool4 unity_MetaFragmentControl;
            float unity_OneOverOutputBoost;
            float unity_MaxOutputValue;

		    struct Attributes
		    {
	            float3 positionOS : POSITION;
	            float2 baseUV : TEXCOORD0;
	            float2 lightmapUV : TEXCOORD1;
			};

            struct Varyings
            {
	            float4 positionCS_SS : SV_POSITION;
	            float2 baseUV : VAR_BASE_UV;
            };

            Varyings MetaPassVertex(Attributes input)
            {
            	Varyings output;
            	input.positionOS.xy = input.lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
            	input.positionOS.z = input.positionOS.z > 0.0 ? FLT_MIN : 0.0;
            	output.positionCS_SS = TransformWorldToHClip(input.positionOS);
            	output.baseUV = TRANSFORM_TEX(input.baseUV, _MainTex);
            	return output;
            }

            half4 MetaPassFragment(Varyings input) : SV_Target
            {
				SurfaceInput surface;
				ZERO_INITIALIZE(SurfaceInput, surface);
				half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.baseUV);
				surface.albedo = albedo.rgb * _Color.rgb;
				half4 pbr = SAMPLE_TEXTURE2D(_PBRTex,sampler_PBRTex, input.baseUV);
				surface.metallic = pbr.g;
				surface.smoothness = pbr.r;

	            BRDFInput brdf = GetBRDF(surface);
	            half4 meta = 0.0;
	            if (unity_MetaFragmentControl.x)
	            {
	            	meta = float4(brdf.diffuse, 1.0);
	            	meta.rgb += brdf.specular * brdf.roughness * 0.5;
	            	meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
	            }
	            else if (unity_MetaFragmentControl.y)
	            {
                #ifdef _EmissionTex_ON
                    half3 emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_EmissionTex, input.baseUV).rgb;
                    emission *= _EmissionIntensity;
                    meta = half4(emission, 1.0);
                #endif
	            }
	            return meta;
            }
			ENDHLSL
		}
    }
}
