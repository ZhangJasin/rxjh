Shader "MD/Standard/Blit"
{
    SubShader {
        Pass {
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Library/Transform.hlsl"
            #include "../Library/Color.hlsl"

            #pragma multi_compile _ _UISCENE_LUT_ENABLE
            #pragma multi_compile _ _IS_LINEAR_SPACE


            TEXTURE2D(_BlitTex); SAMPLER(sampler_BlitTex);
            TEXTURE2D(_UISceneLut); SAMPLER(sampler_UISceneLut);
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

            half4 LUT(half4 color)
		    {
			    half blue = color.b * 63.0;

			    half2 quad1 = half2(0.0, 0.0);
			    quad1.y = floor(floor(blue) * 0.125);
			    quad1.x = floor(blue) - quad1.y * 8.0;

			    half2 quad2 = half2(0.0, 0.0);
			    quad2.y = floor(ceil(blue) * 0.125);
			    quad2.x = ceil(blue) - quad2.y * 8.0;

			    half c1 = 0.0009765625 + (0.123046875 * color.r);
			    half c2 = 0.0009765625 + (0.123046875 * color.g);

			    half2 texPos1 = half2(0.0, 0.0);
			    texPos1.x = quad1.x * 0.125 + c1;
			    texPos1.y = -(quad1.y * 0.125 + c2);

			    half2 texPos2 = half2(0.0, 0.0);
			    texPos2.x = quad2.x * 0.125 + c1;
			    texPos2.y = -(quad2.y * 0.125 + c2);

			    half4 newColor = lerp(SAMPLE_TEXTURE2D(_UISceneLut,sampler_UISceneLut, texPos1),
								      SAMPLE_TEXTURE2D(_UISceneLut,sampler_UISceneLut, texPos2),
								      frac(blue));
			    newColor.a = color.a;
			    return newColor;
		    }


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
                #ifdef _SRGBTOLINEAR  //线性空间，gammaUI时使用
                      col.rgb = GetSRGBToLinear(col.rgb);//pow(col.rgb,2.2);
                #endif

                //UI后的调色，版暑用
                #ifdef _UISCENE_LUT_ENABLE
                    #ifdef _IS_LINEAR_SPACE
                        half4 color =  pow(col, 1/2.2);
			            return pow(LUT(saturate(color)), 2.2);
                    #else
			            return LUT(saturate(col));
                    #endif
                #endif

                return col;
            }
            ENDHLSL
        }
    }
}
