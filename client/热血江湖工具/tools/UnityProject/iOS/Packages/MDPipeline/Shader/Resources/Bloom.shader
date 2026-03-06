Shader "MD/Standard/Bloom"
{
    SubShader {
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
        #include "../Library/Core.hlsl"
        #include "UberCommon.hlsl"

        TEXTURE2D(_BlitTex);
        SAMPLER(sampler_BlitTex);
        half4 _BlitTex_TexelSize;

        half4 _Tint;
        half4 _Params;// x: scatter, y: clamp, z: threshold (linear), w: threshold knee
        half4 _Weights;
        half4 _AlphaBloomIntenisy;//x,强度，y范围
        #define _Scatter             _Params.x
        #define _ClampMax            _Params.y
        #define _Threshold           _Params.z
        #define _ThresholdKnee       _Params.w
        #define _Intensity           _Tint.w

        struct appdata
        {
            float4 vertex : POSITION;
            half4 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            half4 uv : TEXCOORD0;
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.pos = TransformObjectToHClip(v.vertex.xyz);
            o.uv = v.uv;
            return o;
        }

        half4 DownSample(half2 uv, half weight)
        {
            half4 d = _BlitTex_TexelSize.xyxy*half4(-1,-1,1,1)*_Scatter;
            half4 sum = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv)*4;
            sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv + d.xy);
            sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv + d.xz);
            sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv + d.zy);
            sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv + d.zw);

            half alpha = 0;
                
            #ifdef BLOOMALPHA_ENABLE
                alpha = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uv).a;
                if(alpha > 0)
                    weight = min(1, 0.8*_AlphaBloomIntenisy.y);
            #endif

            return sum * (1.0/8.0) * weight;
        }


        half4 ApplyBloomThreshold(half4 col, half alpha)
        {
            half brightness = max3(col.r,col.g,col.b);
            half softness = clamp(brightness - _Threshold + _ThresholdKnee + alpha*_AlphaBloomIntenisy.x, 0.0, 2.0 * _ThresholdKnee);
            softness = (softness * softness) / (4.0 * _ThresholdKnee + 1e-4);
            half multiplier = max(brightness - _Threshold, softness) / max(brightness, 1e-4);
            col *= multiplier;

            col = max(0, col);
            return col;
        }

        ENDHLSL

        Pass {
            //Pass 0:提取亮部
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ BLOOMALPHA_ENABLE 
            #pragma multi_compile _ COLORGRADING_ENABLE
            #pragma multi_compile _ BLOOM_WITH_COLOR_GRADING
            #pragma multi_compile _ BLOOM_AA
            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(v);
                half alpha = 0;
                #ifdef BLOOM_AA               
                    half4 col = 0.0;
                    half2 offsets[] = {
		                half2( 0.0,  0.0),
		                half2(-2.0, -2.0),
                        half2(-2.0,  2.0), 
                        half2( 2.0, -2.0), 
                        half2( 2.0,  2.0)};
                    half weightSum = 0.0;                  
                
                    #ifdef BLOOMALPHA_ENABLE
                        alpha = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv.xy).a;
                    #endif

	                for (int j = 0; j < 5; j++) 
                    {
                        half4 c = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + offsets[j] *_BlitTex_TexelSize.xy);
                        #if defined(COLORGRADING_ENABLE) && defined(BLOOM_WITH_COLOR_GRADING)
                            c.rgb = ApplyColorGrading(c.rgb);
                        #endif
		                c = ApplyBloomThreshold(c, alpha);
		                half w = 1.0 / (Luminance(c.rgb) + 1.0) ;
		                col.rgb += c.rgb * w;
		                weightSum += w;
	                }
	                col.rgb /= weightSum;
                    return col;
               #else
                    #ifdef BLOOMALPHA_ENABLE
                        alpha = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, i.uv.xy).a;
                    #endif
                    half4 c = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy);
                    #if defined(COLORGRADING_ENABLE) && defined(BLOOM_WITH_COLOR_GRADING)
                        c.rgb = ApplyColorGrading(c.rgb);
                    #endif
                    c = ApplyBloomThreshold(c, alpha);
                    return c;
               #endif


            }
            ENDHLSL
        }
        // https://zhuanlan.zhihu.com/p/125744132
        // https://community.arm.com/cfs-file/__key/communityserver-blogs-components-weblogfiles/00-00-00-20-66/siggraph2015_2D00_mmg_2D00_marius_2D00_notes.pdf
        Pass {
            //Pass 1:降采样1
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             #pragma multi_compile _ BLOOMALPHA_ENABLE 
            half4 frag (v2f i) : SV_Target
            {
                return DownSample(i.uv.xy,_Weights.x);
            }
            ENDHLSL
        }
        Pass {
            //Pass 2:降采样2
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             #pragma multi_compile _ BLOOMALPHA_ENABLE 
            half4 frag (v2f i) : SV_Target
            {
                return DownSample(i.uv,_Weights.y);
            }
            ENDHLSL
        }
        Pass {
            //Pass 3:降采样3
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             #pragma multi_compile _ BLOOMALPHA_ENABLE 
            half4 frag (v2f i) : SV_Target
            {
                return DownSample(i.uv,_Weights.z);
            }
            ENDHLSL
        }
        Pass {
            //Pass 4:降采样4
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
             #pragma multi_compile _ BLOOMALPHA_ENABLE 
            half4 frag (v2f i) : SV_Target
            {
                return DownSample(i.uv,_Weights.w);
            }
            ENDHLSL
        }
        Pass {
            //Pass 5:升采样
            Blend One One
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (v2f i) : SV_Target
            {
                half4 sum = 0;
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2(-2, 0)*_BlitTex_TexelSize.xy);
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2(-1, 1)*_BlitTex_TexelSize.xy) * 2;
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2( 0, 2)*_BlitTex_TexelSize.xy);
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2( 1, 1)*_BlitTex_TexelSize.xy) * 2;
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2( 2, 0)*_BlitTex_TexelSize.xy);
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2( 1,-1)*_BlitTex_TexelSize.xy) * 2;
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2( 0,-2)*_BlitTex_TexelSize.xy);
                sum += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv.xy + float2(-1,-1)*_BlitTex_TexelSize.xy) * 2;

                return sum * (1.0/12.0);
            }
            ENDHLSL
        }

        Pass {
            //Pass 6:合并至原图
            Blend One One
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (v2f i) : SV_Target
            {
                half2 uv = i.uv.xy;
                half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,uv);
                col.rgb  *= _Tint.rgb * _Intensity;
                return col;
            }
            ENDHLSL
        }
    }
}
