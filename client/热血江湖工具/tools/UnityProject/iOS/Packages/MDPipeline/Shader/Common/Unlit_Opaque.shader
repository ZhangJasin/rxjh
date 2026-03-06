Shader "MD/Standard/Unlit_Opaque"
{
    Properties {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1,1,1,1)
        [Space(20)]
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1
    }
    SubShader {
        Tags {  "RenderType" = "Opaque" "Queue" = "Geometry" }
        LOD 100
        ZWrite [_ZWrite]
        // Blend [_SrcBlend][_DstBlend],[_SrcAlphaBlend][_DstAlphaBlend]

        Pass {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "../Library/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float4 _Color;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos:TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (appdata v, uint instanceID: SV_InstanceID)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(o.worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                col *= _Color;
                return col;
            }
            ENDHLSL
        }
    }

}
