Shader "MD/Standard/SRGBToLinear"
{
    SubShader {
        Pass {
            ZTest Always
            ZWrite Off
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Library/Color.hlsl"
            #include "../Library/Transform.hlsl"

            TEXTURE2D(_BlitTex); SAMPLER(sampler_BlitTex);

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
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,i.uv);
                col.rgb = pow(col.rgb,2.2);
                return col;
            }
            ENDHLSL
        }
    }
}
