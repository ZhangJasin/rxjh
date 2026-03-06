Shader "MDPipeline/Terrain/Lit"
{
    Properties
    {
        [HideInInspector] [ToggleUI] _EnableHeightBlend("EnableHeightBlend", Float) = 1.0
        _HeightTransition("Height Transition", Range(0, 1.0)) = 0.5 // _Hightthreshold("Hight Threshold", Range(0,1)) = 0.5
        // Layer count is passed down to guide height-blend enable/disable, due
        // to the fact that heigh-based blend will be broken with multipass.
        [HideInInspector] [PerRendererData] _NumLayersCount ("Total Layer Count", Float) = 1.0
    
        // set by terrain engine
        [HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
        //[HideInInspector] _Splat3("Layer 3 (A)", 2D) = "grey" {}
        [HideInInspector] _Splat2("Layer 2 (B)", 2D) = "grey" {}
        [HideInInspector] _Splat1("Layer 1 (G)", 2D) = "grey" {}
        [HideInInspector] _Splat0("Layer 0 (R)", 2D) = "grey" {}
        //[HideInInspector] _Normal3("Normal 3 (A)", 2D) = "bump" {}
        [HideInInspector] _Normal2("Normal 2 (B)", 2D) = "bump" {}
        [HideInInspector] _Normal1("Normal 1 (G)", 2D) = "bump" {}
        [HideInInspector] _Normal0("Normal 0 (R)", 2D) = "bump" {}
        //[HideInInspector] _Mask3("Mask 3 (A)", 2D) = "grey" {}
        //[HideInInspector] _Mask2("Mask 2 (B)", 2D) = "grey" {}
        //[HideInInspector] _Mask1("Mask 1 (G)", 2D) = "grey" {}
        //[HideInInspector] _Mask0("Mask 0 (R)", 2D) = "grey" {}
        //[HideInInspector][Gamma] _Metallic0("Metallic 0", Range(0.0, 1.0)) = 0.0
        //[HideInInspector][Gamma] _Metallic1("Metallic 1", Range(0.0, 1.0)) = 0.0
        //[HideInInspector][Gamma] _Metallic2("Metallic 2", Range(0.0, 1.0)) = 0.0
        //[HideInInspector][Gamma] _Metallic3("Metallic 3", Range(0.0, 1.0)) = 0.0
        //[HideInInspector] _Smoothness0("Smoothness 0", Range(0.0, 1.0)) = 0.5
        //[HideInInspector] _Smoothness1("Smoothness 1", Range(0.0, 1.0)) = 0.5
        //[HideInInspector] _Smoothness2("Smoothness 2", Range(0.0, 1.0)) = 0.5
        //[HideInInspector] _Smoothness3("Smoothness 3", Range(0.0, 1.0)) = 0.5

        ////used in fallback on old cards & base map
        //[HideInInspector] _MainTex("BaseMap (RGB)", 2D) = "grey" {}
        //[HideInInspector] _BaseColor("Main Color", Color) = (1,1,1,1)
        //[HideInInspector] _TerrainHolesTexture("Holes Map (RGB)", 2D) = "white" {}

        [ToggleUI] _EnableInstancedPerPixelNormal("Enable Instanced per-pixel normal", Float) = 1.0
        [Space(20)]
        [Toggle(_HeightFog_ON)]_HeightFog_ON("_HeightFog_ON",float) = 0
        _HeightFogColor("Height Fog Color", Color) = (0,0,0,0)
        _HeightFogThreshold("_HeightFogThreshold", Float) = 0.0
        _HeightFogFeather("_HeightFogFeather", Float) = 0.0
    }
    HLSLINCLUDE

    #pragma multi_compile __ _ALPHATEST_ON

    ENDHLSL

    SubShader
    {
        Tags { "Queue" = "Geometry-100" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "False"}

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ _MIXED_LIGHTING_SHADOWMASK
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fog

            #pragma target 3.0
           
             #include "Libs/TerrainLitCore.hlsl"
			#include "../../Library/Core.hlsl"

            //贴图及纹理
            //sampler2D _Splat0;
            TEXTURE2D(_Splat0);
            SAMPLER(sampler_Splat0);
            half4 _Splat0_ST;

            //sampler2D _Splat1;
            TEXTURE2D(_Splat1);
            SAMPLER(sampler_Splat1);
            half4 _Splat1_ST;

            //sampler2D _Splat2;
            TEXTURE2D(_Splat2);
            SAMPLER(sampler_Splat2);
            half4 _Splat2_ST;

            //法线贴图及纹理
            //sampler2D _Normal0;
            TEXTURE2D(_Normal0);
            SAMPLER(sampler_Normal0);
            half4 _Normal0_ST;

            //sampler2D _Normal1;
            TEXTURE2D(_Normal1);
            SAMPLER(sampler_Normal1);
            half4 _Normal1_ST;

            //sampler2D _Normal2;
            TEXTURE2D(_Normal2);
            SAMPLER(sampler_Normal2);
            half4 _Normal2_ST;

            //sampler2D _Control;
            TEXTURE2D(_Control);
            SAMPLER(sampler_Control);
            half4 _Control_ST;
            float _HeightTransition;
            
            half3 _HeightFogColor;
			half _HeightFogThreshold;
			half _HeightFogFeather;

            struct v2f
            {
                float4	pos : SV_POSITION;
				float3 worldnormal:NORMAL;
                half4  uv_Tex0:TEXCOORD0;
                half4  uv_Tex1:TEXCOORD1;
                half4  uv_Tex2:TEXCOORD2;
                half2  uv_Control:TEXCOORD4;
				float3 worldpos : TEXCOORD5;
                float2 fogCoord : TEXCOORD6;//x:system fog,y:self fog

            };

            struct appdata
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal:NORMAL;
            };

            inline half3 Blend(half high1, half high2, half high3, half3 control)
            {
                half3 blend;
                blend.r = high1 * control.r;
                blend.g = high2 * control.g;
                blend.b = high3 * control.b;

                half ma = max(blend.r, max(blend.g, blend.b));
                blend = max(blend - ma + _HeightTransition, 1e-5) * control;
                return blend / (blend.r + blend.g + blend.b);
            }

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex);
                o.fogCoord.x = ComputeFogFactor(o.pos.z);

                o.fogCoord.y = v.vertex.y;
				o.worldnormal = TransformObjectToWorldNormal(v.normal);
				o.worldpos = TransformObjectToWorld(v.vertex.xyz);
                o.uv_Control = v.texcoord.xy;
                o.uv_Tex0.xy = TRANSFORM_TEX(v.texcoord , _Splat0);
                o.uv_Tex0.zw = TRANSFORM_TEX(v.texcoord ,_Normal0);

                o.uv_Tex1.xy = TRANSFORM_TEX(v.texcoord , _Splat1);
                o.uv_Tex1.zw = TRANSFORM_TEX(v.texcoord ,_Normal1);

                o.uv_Tex2.xy = TRANSFORM_TEX(v.texcoord, _Splat2);
                o.uv_Tex2.zw = TRANSFORM_TEX(v.texcoord ,_Normal2);
                
              
                return o;
            }
            half4 frag(v2f i) :SV_Target
            {
                half4 albedo0 = SAMPLE_TEXTURE2D(_Splat0, sampler_Splat0,i.uv_Tex0);
				half4 albedo1 = SAMPLE_TEXTURE2D(_Splat1, sampler_Splat1, i.uv_Tex1);
				half4 albedo2 = SAMPLE_TEXTURE2D(_Splat2, sampler_Splat1, i.uv_Tex2);
				half4 mask = SAMPLE_TEXTURE2D(_Control, sampler_Control, i.uv_Control.xy);

				half4 normal0 = SAMPLE_TEXTURE2D(_Normal0, sampler_Normal0,i.uv_Tex0.zw);
				half4 normal1 = SAMPLE_TEXTURE2D(_Normal1, sampler_Normal1, i.uv_Tex1.zw);
				half4 normal2 = SAMPLE_TEXTURE2D(_Normal2, sampler_Normal2, i.uv_Tex2.zw);

                half3 blend = Blend(albedo0.a, albedo1.a, albedo2.a, mask.rgb);
                half4 albedo = blend.x * albedo0 + blend.y * albedo1 + blend.z * albedo2;
                //half4 bump = blend.x * normal0 + blend.y * normal1 + blend.z * normal2;

				half4 col = albedo;
				float4 shadowCoord = TransformWorldToShadowCoord(i.worldpos);
				Light light = GetMainLight(shadowCoord);
				light.color = light.color * light.shadowAttenuation ;//* light.distanceAttenuation;
				col.rgb = col.rgb*light.color * dot(light.direction,i.worldnormal);
				#ifdef _ADDITIONAL_LIGHTS
				half3 vertexLightColor = AddLighting(i.worldnormal, i.worldpos);
				col.rgb += vertexLightColor * albedo;
				#endif
				
				#ifdef _HeightFog_ON
                    float hightFog = smoothstep(_HeightFogThreshold-_HeightFogFeather,_HeightFogThreshold+_HeightFogFeather,i.fogCoord.y);
                    col.rgb = lerp(_HeightFogColor.rgb,col.rgb,hightFog);
                #endif
                col.rgb = MixFog(col.rgb,i.fogCoord.x);

                return col;
            }
            ENDHLSL
        }
    }
    //Dependency "AddPassShader" = "Hidden/MDPipeline/Terrain/Lit (Add Pass)"
    //Dependency "BaseMapShader" = "Hidden/MDPipeline/Terrain/Lit (Base Pass)"
    //Dependency "BaseMapGenShader" = "Hidden/MDPipeline/Terrain/Lit (Basemap Gen)"
    
    CustomEditor "CustomPipeline.TerrainLitShaderGUI"
    //Fallback "Hidden/Universal Render Pipeline/FallbackError"
}
