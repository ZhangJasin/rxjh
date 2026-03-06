Shader "Hidden/CombineLowResTransparent" {
    
    SubShader {
        Pass {
            Cull Off
            ZWrite Off
            ZTest Always            
            Blend One OneMinusSrcAlpha

            HLSLPROGRAM
           
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_LowResTransparentHandleTexture);
            SAMPLER(sampler_LowResTransparentHandleTexture);

            v2f vert(appdata v) {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                half4 lowResTransparentColor = SAMPLE_TEXTURE2D(_LowResTransparentHandleTexture, sampler_LowResTransparentHandleTexture, i.uv);
                return lowResTransparentColor;
            }

            ENDHLSL
        }
    }
}