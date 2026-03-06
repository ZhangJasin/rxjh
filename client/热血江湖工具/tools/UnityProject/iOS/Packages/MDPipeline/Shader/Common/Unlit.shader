Shader "MD/Standard/Unlit"
{
    Properties {
        _MainTex ("Main Texture", 2D) = "white" {}
        [HDR]_Color("Main Color", Color) = (1,1,1,1)
        [Space(20)]
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }
    SubShader {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull [_Cull]
        ZWrite [_ZWrite]
        Blend [_SrcBlend] [_DstBlend]
        // Blend [_SrcBlend][_DstBlend],[_SrcAlphaBlend][_DstAlphaBlend]

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ _USE_COLOR_ARRAY
            #include "../Library/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;
            half4 _Color;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                half2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                half3 tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                float3 worldPos:TEXCOORD2;
                half4 color    : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            #ifdef _USE_COLOR_ARRAY
                UNITY_INSTANCING_BUFFER_START(Props)
                    UNITY_DEFINE_INSTANCED_PROP(half4, _Colors)
                UNITY_INSTANCING_BUFFER_END(Props)
            #endif

            v2f vert (appdata v, uint instanceID: SV_InstanceID)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(o.worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = 1;
                #ifdef _USE_COLOR_ARRAY
                    o.color = UNITY_ACCESS_INSTANCED_PROP(Props, _Colors);
                #else
                    o.color = 1;
                #endif
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                col *= _Color;
                #ifdef _USE_COLOR_ARRAY
                    col *= UNITY_ACCESS_INSTANCED_PROP(Props, _Colors);
                #endif
                return col;
            }
            ENDHLSL
        }
    }

}
