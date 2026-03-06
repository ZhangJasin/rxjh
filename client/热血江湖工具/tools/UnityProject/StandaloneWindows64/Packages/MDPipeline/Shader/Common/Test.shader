Shader "MD/Common/Test"
{
    Properties{
        _MainTex("Main Texture", 2D) = "white" {}
        _Cutoff("低于此值会被裁剪", float) = 0.5
    }
    SubShader {
        Pass {
            ZTest LEqual
            ZWrite On
            Cull Back
            Tags{ "LightMode" = "UniversalForward" "RenderType" = "Transparent" "Queue" = "Transparent" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #include "UnityCG.cginc"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
            // #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
            // #include "Packages/com.unity.postprocessing/PostProcessing/Shaders/Builtins/DiskKernels.hlsl"

            // TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
            // UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            // SAMPLER(sampler_CameraDepthTexture);
            // TEXTURE2D(_DepthTargetBuffer);
            // SAMPLER(sampler_DepthTargetBuffer);
            // TEXTURE2D(_MainTex);
            // SAMPLER(sampler_MainTex);
            // TEXTURE2D(_CameraOpaqueTexture);
            // SAMPLER(sampler_CameraOpaqueTexture);
            // TEXTURE2D(_CharacterShadowMap);
            // SAMPLER(sampler_CharacterShadowMap);
            // TEXTURE2D(_MainLightShadowmapTexture);
            // SAMPLER(sampler_MainLightShadowmapTexture);
            // TEXTURE2D(_CameraDepthTexture);
            // SAMPLER(sampler_CameraDepthTexture);
            // TEXTURE2D_SAMPLER2D(_CameraDepthTexture, sampler_CameraDepthTexture);
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            uniform float4 _CameraDepthTexture_ST;
            UNITY_DECLARE_DEPTH_TEXTURE(_DepthTex);
            uniform float4 _DepthTex_ST;
            // TEXTURE2D_SHADOW(depthTargetBuffer);
            // SAMPLER(sampler_depthTargetBuffer);

            float _Cutoff;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                // o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                // #if UNITY_UV_STARTS_AT_TOP
                //     o.uv.y = 1-o.uv.y;
                // #endif
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(v);
                half4 col;
                // half4 col = SAMPLE_TEXTURE2D(_DepthTargetBuffer,sampler_DepthTargetBuffer,i.uv);
                // half4 col = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,i.uv);
                // half4 col = SAMPLE_RAW_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                // half4 col = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,i.uv);
                // half4 col = _CameraDepthTexture.Sample(sampler_CameraDepthTexture,i.uv);
                // half4 col = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
                // float3 coord = float3(i.uv,_Cutoff);
                // half4 col = SAMPLE_TEXTURE2D_SHADOW(_CameraDepthTexture,sampler_CameraDepthTexture,coord);
                // half4 col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,i.uv);
                // half4 col = SAMPLE_TEXTURE2D(_CharacterShadowMap,sampler_CharacterShadowMap,i.uv);
                // half4 col = SAMPLE_TEXTURE2D(_MainLightShadowmapTexture,sampler_MainLightShadowmapTexture,i.uv);
                // col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,i.uv);
                // return col;
                // half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                // col = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,i.uv);
                col = SAMPLE_RAW_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                // col = SAMPLE_RAW_DEPTH_TEXTURE(_DepthTex, i.uv);
                // float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv);
                // return depth*100;
                float c = col.r*100;
                // float c = col;
                // clip(c - _Cutoff);
                // return col;
                return c;
            }
            ENDHLSL
        }
    }
}
