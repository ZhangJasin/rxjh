Shader "MD/Standard/ColorGrade"
{
    SubShader {
        Pass {
            Tags { "RenderType" = "Opaque"}
            LOD 100
            ZTest Always
            ZWrite Off
            Cull Off
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Library/Core.hlsl"

            TEXTURE2D(_BlitTex);
            TEXTURE2D(_InternalLut);
            float4 _LutScaleOffset; // (1 / lut_width, 1 / lut_height, lut_height - 1)

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

            float3 ApplyColorGrading(float3 c)
            {
                c *= _LutScaleOffset.w;
                float3 uvw = saturate(LinearToLogC(c)); // LUT space is in LogC
                // Strip format where `height = sqrt(width)`
                uvw.z *= _LutScaleOffset.z;
                float shift = floor(uvw.z);
                uvw.xy = uvw.xy * _LutScaleOffset.z * _LutScaleOffset.xy + _LutScaleOffset.xy * 0.5;
                uvw.x += shift * _LutScaleOffset.y;
                uvw.xyz = lerp(
                SAMPLE_TEXTURE2D_LOD(_InternalLut, sampler_LinearClamp, uvw.xy, 0.0).rgb,
                SAMPLE_TEXTURE2D_LOD(_InternalLut, sampler_LinearClamp, uvw.xy + float2(_LutScaleOffset.y, 0.0), 0.0).rgb,uvw.z - shift);

                return uvw;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = SAMPLE_TEXTURE2D(_BlitTex, sampler_LinearClamp, i.uv).rgb;
                col = ApplyColorGrading(col);
                // col = ToonColorMapping(col,1);

                return float4(col, 1.0);
            }
            ENDHLSL
        }
    }
}
