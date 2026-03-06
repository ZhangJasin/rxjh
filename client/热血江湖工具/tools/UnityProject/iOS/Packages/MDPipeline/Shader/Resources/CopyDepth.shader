Shader "MD/Standard/CopyDepth"
{
    // Properties { _DepthTex ("Texture", any) = "" {} }
    SubShader
    {
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Library/Core.hlsl"
            TEXTURE2D_FLOAT(_BlitTex); SAMPLER(sampler_BlitTex);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                #if DEPTH_FORMAT_ARGB32 == 32
                    float depth = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv).r;
                    return Unpack32ToR8G8B8A8(depth);
                #elif DEPTH_FORMAT_ARGB32 == 24
                    float depth = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv).r;
                    return Unpack24ToR8G8B8A8(depth);
                #else
                    return SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv);
                #endif
            }
            ENDHLSL
        }

        Pass
        {
            ZTest Always
            Cull Off
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Library/Core.hlsl"
            TEXTURE2D_FLOAT(_BlitTex); SAMPLER(sampler_BlitTex);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            struct output
            {
                // float color : SV_TARGET;
                float depth : SV_DEPTH;
            };


            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            output frag(v2f i)
            {
                float4 result = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv);
                output o;
                // o.color = result.x;
                o.depth = result.x;
                return o;
            }
            ENDHLSL
        }
    }
    Fallback Off
}
