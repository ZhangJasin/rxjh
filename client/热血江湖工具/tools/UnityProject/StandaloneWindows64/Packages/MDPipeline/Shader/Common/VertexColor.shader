Shader "MD/Standard/VertexColor"
{
    Properties {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color("Main Color", Color) = (1,1,1,1)
        // _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Enum(Off, 0, On, 1)] _ZWrite("ZWrite", Float) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp("BlendOp", Float) = 0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcAlphaBlend("Src Alpha Blend Mode", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstAlphaBlend("Dst Alpha Blend Mode", Float) = 10
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        // Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Cull [_Cull]
        BlendOp[_BlendOp]
        ZWrite [_ZWrite]
        Blend [_SrcBlend] [_DstBlend]
        Blend [_SrcBlend][_DstBlend],[_SrcAlphaBlend][_DstAlphaBlend]

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
            // float _Cutoff;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float fogCoord : TEXCOORD1;
                float4 color : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fogCoord = ComputeFogFactor(o.pos.z);
                o.color = v.color;
                // o.color = v.vertex;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                // clip(col.a-_Cutoff);
                col *= i.color;
                col *= _Color;
                col.rgb = MixFog(col.rgb,i.fogCoord);
                return col;
            }
            ENDHLSL
        }
    }
}
