Shader "MD/Standard/ShadowCaster"
{
    Properties
    {
        [Toggle(SHADOWALPHACLIP_ON)]SHADOWALPHACLIP_ON("SHADOWALPHACLIP_ON",float) = 0
        _MainTex ("Main Texture", 2D) = "white" {}
        _Cutoff("_Cutoff",Range(0,1)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
    }

    SubShader {
        Pass{
            Offset 1,1 //绘制深度时候偏移一点位置
            LOD 200
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            
            Cull [_Cull]
            ZWrite On ZTest LEqual
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ SHADOWALPHACLIP_ON
			#pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "../Library/Lighting.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _Cutoff;
            CBUFFER_END
            float3 _LightPosition;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                #ifdef SHADOWALPHACLIP_ON
                    half2 uv : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                #ifdef SHADOWALPHACLIP_ON
                    half2 uv : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert(a2v  v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                #ifdef SHADOWALPHACLIP_ON
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                #endif
                float3 worldPos = TransformObjectToWorld(v.vertex);

                #ifdef VERTEXWAVE_ON
                    worldPos.xz -= WaveGrass(worldPos,_WaveParams);
                #endif
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - worldPos);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif

                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.pos = TransformWorldToHClip(ApplyShadowBias(worldPos, worldNormal, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    o.pos.z = min(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.pos.z = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
				ClipLOD(i.pos.xy, unity_LODFade.x);

                #ifdef SHADOWALPHACLIP_ON
                    half alpha = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }

    
        Pass{
            //Offset 1,1 //绘制深度时候偏移一点位置
            LOD 200
            Name "PerObjectShadow"
            Tags { "LightMode" = "ShadowCaster" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "../Library/Lighting.hlsl"

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert(a2v  v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
               // o.pos = TransformWorldToHClip(worldPos);
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.pos = TransformWorldToHClip(worldPos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Offset 2,2 //绘制深度时候偏移一点位置
            LOD 200
            Name "CharacterShadowCaster"
            Tags { "LightMode" = "CharacterShadowCaster" }


            Cull[_Cull]
            ZWrite On ZTest LEqual
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #pragma multi_compile _ SHADOWALPHACLIP_ON
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #include "../Library/Lighting.hlsl"

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half _Cutoff;
            CBUFFER_END
            float3 _LightPosition;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                #ifdef SHADOWALPHACLIP_ON
                    half2 uv : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                #ifdef SHADOWALPHACLIP_ON
                    half2 uv : TEXCOORD0;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert(a2v  v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                #ifdef SHADOWALPHACLIP_ON
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                #endif
                float3 worldPos = TransformObjectToWorld(v.vertex);

                #ifdef VERTEXWAVE_ON
                    worldPos.xz -= WaveGrass(worldPos,_WaveParams);
                #endif
                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                float3 lightDirectionWS = normalize(_LightPosition - worldPos);
                #else
                float3 lightDirectionWS = _LightDirection;
                #endif

                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.pos = TransformWorldToHClip(ApplyShadowBias(worldPos, worldNormal, lightDirectionWS));

                #if UNITY_REVERSED_Z
                    o.pos.z = min(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    o.pos.z = max(o.pos.z, o.pos.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                ClipLOD(i.pos.xy, unity_LODFade.x);

                #ifdef SHADOWALPHACLIP_ON
                    half alpha = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }

    }
}