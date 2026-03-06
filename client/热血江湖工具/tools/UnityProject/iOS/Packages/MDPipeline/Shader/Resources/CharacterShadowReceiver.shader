Shader "MD/Standard/CharacterShadowReceiver"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
    }

    SubShader {
        Pass{
            LOD 200
            Name "CharacterShadowReceiver"
            Tags{ "LightMode" = "UniversalForward" "RenderType" = "Transparent" "Queue" = "Transparent" }
            Cull [_Cull]
            ZWrite On ZTest LEqual
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
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            v2f vert(a2v  v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);

                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 c = half4(1,1,1,1);
                half atten = SampleCharacterShadow(i.worldPos);
                c *= atten;
                return c;
            }
            ENDHLSL
        }
    }
}