Shader "MD/Standard/Uber"
{
	SubShader{
		Cull Off
		ZWrite Off
		ZTest Always

		HLSLINCLUDE
        #include "UberCommon.hlsl"

		TEXTURE2D(_BlitTex);
		SAMPLER(sampler_BlitTex);
		float4 _BlitTex_TexelSize;
#ifdef BLOOM_ENABLE
		float4 _Tint;
		#define _BloomIntensity           _Tint.w
#endif

		//#ifdef SUNSHAFT_ENABLE
		half4 _SunColor;
		//#endif
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

		v2f vert(appdata v)
		{
			v2f o;
			o.pos = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			// #if UNITY_UV_STARTS_AT_TOP
			//     o.uv.y = 1-o.uv.y;
			// #endif
			return o;
		}

          #ifdef FXAA3_HIGH
                // Notes on FXAA:
                // * We now rely on the official FXAA implementation (authored by Timothy Lottes while at NVIDIA)
                //   with minimal changes made by Unity to integrate with URP.
                // * The following 'Tweakable' defines are used by the FXAA implementation and can be changed if desired:
                //   * FXAA_PC set to 1 is the highest quality implementation ("PC" here is a misnomer, it will run on all platforms).
                //   * FXAA_PC set to 0 is the cheaper 'FXAA_PC_CONSOLE' variant
                //     (it's equivalent to URP's old implementation but less noisy and should run faster than before)
                //   * FXAA_GREEN_AS_LUMA can be set to 0 for an extra performance increase but will only antialias edges that have
                //     some green in them (will be visually equivalent on the vast majority of scenes).
                //   * FXAA_QUALITY__PRESET is used when FXAA_PC is set ot 1. We chose preset 12 as it runs almost as fast on Switch as
                //     our old noisy implementation did.
                //     On all other platforms we could basically get away with preset 15 which has slightly better edge quality.

                // Tweakable params (can be changed to get different performance and quality tradeoffs)
                //16 texSamp
                #define FXAA_PC 1
                #define FXAA_GREEN_AS_LUMA 0
                #define FXAA_QUALITY__PRESET 12

                // Fixed params (should not be changed)
                #define FXAA_HLSL_5 1
                #define FXAA_GATHER4_ALPHA 0
                #define FXAA_PC_CONSOLE !FXAA_PC

                #include "FXAA3_11.hlsl"

                static const FxaaFloat kSubpixelBlendAmount = 0.65;
                static const FxaaFloat kRelativeContrastThreshold = 0.15;
                static const FxaaFloat kAbsoluteContrastThreshold = 0.03;
                half3 ApplyFXAA(half3 color, float2 positionNDC, int2 positionSS, float4 sourceSize, TEXTURE2D(inputTexture))
                {
                    FxaaTex tex = {sampler_LinearClamp, _BlitTex};
                    FxaaFloat4 kUnusedFloat4 = FxaaFloat4(0, 0, 0, 0);

                    FxaaFloat4 fxaaConsolePos = 0;
                    FxaaFloat4 kFxaaConsoleRcpFrameOpt = 0;
                    FxaaFloat4 kFxaaConsoleRcpFrameOpt2 = 0;
                    FxaaFloat kFxaaConsoleEdgeSharpness = 0;
                    FxaaFloat kFxaaConsoleEdgeThreshold = 0;
                    FxaaFloat kFxaaConsoleEdgeThresholdMin = 0;

                    #if FXAA_PC_CONSOLE == 1
                        fxaaConsolePos = FxaaFloat4(positionNDC.xy - 0.5*sourceSize.xy, positionNDC.xy + 0.5*sourceSize.xy);
                        kFxaaConsoleRcpFrameOpt = 0.5*FxaaFloat4(sourceSize.xy, -sourceSize.xy);
                        kFxaaConsoleRcpFrameOpt2 = 2.0*FxaaFloat4(-sourceSize.xy, sourceSize.xy);
                        kFxaaConsoleEdgeSharpness = 8.0;
                        kFxaaConsoleEdgeThreshold = 0.125;
                        kFxaaConsoleEdgeThresholdMin = 0.05;
                    #endif

                    return FxaaPixelShader(
                        positionNDC,
                        FxaaFloat4(color, 0),
                        fxaaConsolePos,
                        tex,
                        tex,
                        tex,
                        sourceSize.xy,
                        kFxaaConsoleRcpFrameOpt,
                        kFxaaConsoleRcpFrameOpt2,
                        kUnusedFloat4,
                        kSubpixelBlendAmount,
                        kRelativeContrastThreshold,
                        kAbsoluteContrastThreshold,
                        kFxaaConsoleEdgeSharpness,
                        kFxaaConsoleEdgeThreshold,
                        kFxaaConsoleEdgeThresholdMin,
                        kUnusedFloat4
                    );
                }
            #endif

               #if defined(RADIALBLUR_ENABLE)
                #undef FXAA
                #undef FXAA3_HIGH
            #endif

			//#pragma enable_d3d11_debug_symbols

			#ifdef BLOOM_ENABLE
			TEXTURE2D(_BloomTex);
			//SAMPLER(sampler_BloomTex);
			#endif
			#ifdef DEPTH_OF_FIELD_ENABLE
			TEXTURE2D(_CocTex); TEXTURE2D(_BokehTexture);
			float _PixelSize;
			#endif
			#ifdef SUNSHAFT_ENABLE
			TEXTURE2D(_SunShaftTex);
			TEXTURE2D(_SunShaftMaskedTex);
			//SAMPLER(sampler_SunShaftTex);
			half _SunShaftIntensity;
			#endif

			#ifdef DISTORTION_ENABLE
			TEXTURE2D(_DistortionMaskTex);
			float _DistortStrength;
			#endif
			#ifdef RIPPLE_ENABLE
				float _distanceFactor;
				float _timeFactor;	
				float _totalFactor;	
				float _waveWidth;
				float _curWaveDis;
				float4 _startPos;
			#endif
            #ifdef FXAA
			    #define FXAA_SPAN_MAX           (8.0)
			    #define FXAA_REDUCE_MUL         (1.0 / 8.0)
			    #define FXAA_REDUCE_MIN         (1.0 / 128.0)

			    half3 Fetch(float2 coords, float2 offset)
			    {
				    float2 uv = coords + offset;
				    return SAMPLE_TEXTURE2D(_BlitTex, sampler_LinearClamp, uv).xyz;
			    }

			    half3 Load(int2 icoords, int idx, int idy)
			    {
				    #if SHADER_API_GLES
				    float2 uv = (icoords + int2(idx, idy)) * _BlitTex_TexelSize.xy;
				    return SAMPLE_TEXTURE2D(_BlitTex, sampler_LinearClamp, uv).xyz;
				    #else
				    return LOAD_TEXTURE2D(_BlitTex, clamp(icoords + int2(idx, idy), 0, _BlitTex_TexelSize.zw - 1.0)).xyz;
				    #endif
			    }
            #endif

			half Min3(half a,half b, half c)
			{
				return min(a,min(b,c));
			}

			half Max3(half a,half b, half c)
			{
				return max(a,max(b,c));
			}


		ENDHLSL

        //Pass 0: 抗锯齿
		Pass {
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile _ FXAA3_HIGH

			half4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(v);
				float2 uv = i.uv;
				// #if UNITY_UV_STARTS_AT_TOP
				//     uv = float2(i.uv.x,1-i.uv.y);
				// #endif
				half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,uv);
                int2  positionSS  = uv * _BlitTex_TexelSize.zw;
                float2 positionNDC = uv;
                #if defined(FXAA3_HIGH)
                    col.rgb = ApplyFXAA(col.rgb, positionNDC, positionSS, _BlitTex_TexelSize, _BlitTex);
                #endif
				return col;
			}
			ENDHLSL
		}

        //pass 1  除高级抗锯齿以外后期
        Pass {
			//Pass 5:合并至原图
			//Blend One One
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ BLOOM_ENABLE
			#pragma multi_compile _ SUNSHAFT_ENABLE
			#pragma multi_compile _ RADIALBLUR_ENABLE FXAA
			#pragma multi_compile _ DISTORTION_ENABLE
			#pragma multi_compile _ DEPTH_OF_FIELD_ENABLE
            #pragma multi_compile _ COLORGRADING_ENABLE
			#pragma multi_compile _ RIPPLE_ENABLE
         
			half4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(v);
				float2 uv = i.uv;
				// #if UNITY_UV_STARTS_AT_TOP
				//     uv = float2(i.uv.x,1-i.uv.y);
				// #endif

#ifdef DISTORTION_ENABLE
								

//采样Mask图获得权重信息
				float4 factor = SAMPLE_TEXTURE2D(_DistortionMaskTex, sampler_LinearClamp, uv);
				float2 offset = factor.rg * _DistortStrength;
				//像素采样时偏移offset，用Mask权重进行修改
				uv = offset + uv;
#endif
#ifdef RIPPLE_ENABLE				
				#if UNITY_UV_STARTS_AT_TOP				
					_startPos.y = 1 - _startPos.y;				
				#endif
				float2 dv = _startPos.xy - uv;
				dv = dv * float2(_ScreenParams.x / _ScreenParams.y, 1);
				float dis = sqrt(dv.x * dv.x + dv.y * dv.y);
				float sinFactor = sin(dis * _distanceFactor  + _Time.y * _timeFactor) * _totalFactor * 0.01;			
				float discardFactor = clamp(_waveWidth - abs(_curWaveDis - dis), 0, 1) / _waveWidth;					
				float2 dv1 = normalize(dv);				
				uv =  dv1  * sinFactor * discardFactor + uv;	
#endif
				half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,uv);

                #ifdef RADIALBLUR_ENABLE
                    col.rgb = RadialBlur(uv, TEXTURE2D_ARGS(_BlitTex, sampler_BlitTex));
                #endif
                
				float2 positionNDC = uv;
				int2   positionSS = uv * _BlitTex_TexelSize.zw;
				//FXAA
                #if defined(FXAA)
				    half3 color = Load(positionSS, 0, 0).xyz;
	                // Edge detection
	                half3 rgbNW = Load(positionSS, -1, -1);
	                half3 rgbNE = Load(positionSS,  1, -1);
	                half3 rgbSW = Load(positionSS, -1,  1);
	                half3 rgbSE = Load(positionSS,  1,  1);

	                rgbNW = saturate(rgbNW);
	                rgbNE = saturate(rgbNE);
	                rgbSW = saturate(rgbSW);
	                rgbSE = saturate(rgbSE);
	                color = saturate(color);

	                half lumaNW = Luminance(rgbNW);
	                half lumaNE = Luminance(rgbNE);
	                half lumaSW = Luminance(rgbSW);
	                half lumaSE = Luminance(rgbSE);
	                half lumaM = Luminance(color);

	                float2 dir;
	                dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	                dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	                half lumaSum = lumaNW + lumaNE + lumaSW + lumaSE;
	                float dirReduce = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
	                float rcpDirMin = rcp(min(abs(dir.x), abs(dir.y)) + dirReduce);

	                dir = min((FXAA_SPAN_MAX).xx, max((-FXAA_SPAN_MAX).xx, dir * rcpDirMin)) * _BlitTex_TexelSize.xy;

	                // Blur
	                half3 rgb03 = Fetch(positionNDC, dir * (0.0 / 3.0 - 0.5));
	                half3 rgb13 = Fetch(positionNDC, dir * (1.0 / 3.0 - 0.5));
	                half3 rgb23 = Fetch(positionNDC, dir * (2.0 / 3.0 - 0.5));
	                half3 rgb33 = Fetch(positionNDC, dir * (3.0 / 3.0 - 0.5));

	                rgb03 = saturate(rgb03);
	                rgb13 = saturate(rgb13);
	                rgb23 = saturate(rgb23);
	                rgb33 = saturate(rgb33);

	                half3 rgbA = 0.5 * (rgb13 + rgb23);
	                half3 rgbB = rgbA * 0.5 + 0.25 * (rgb03 + rgb33);

	                half lumaB = Luminance(rgbB);

	                half lumaMin = Min3(lumaM, lumaNW, Min3(lumaNE, lumaSW, lumaSE));
	                half lumaMax = Max3(lumaM, lumaNW, Max3(lumaNE, lumaSW, lumaSE));

	                color = ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;
	                col.rgb = color;
                #endif

                #ifdef DEPTH_OF_FIELD_ENABLE
	                half4 dof = SAMPLE_TEXTURE2D(_BokehTexture, sampler_LinearClamp,uv);
	                half CoC = SAMPLE_TEXTURE2D(_CocTex, sampler_LinearClamp, uv);
	                half strength = smoothstep(0.1, 1, abs(CoC));
	                col.rgb = lerp(col.rgb, dof.rgb, strength);
                #endif

                #ifdef SUNSHAFT_ENABLE
	                half4 sunShaft = SAMPLE_TEXTURE2D(_SunShaftTex, sampler_LinearClamp, uv);
	                half sunShaftMask = SAMPLE_TEXTURE2D(_SunShaftMaskedTex, sampler_LinearClamp, uv).r;
	                col.rgb += sunShaft.rgb *  _SunShaftIntensity * (1 - sunShaftMask) * _SunColor.rgb;//add
	                //col.rgb = 1.0f - (1.0f - col.rgb) * (1.0f - (sunShaft.rgb * _SunColor.rgb));//screen
                #endif

				#ifdef COLORGRADING_ENABLE
					col.rgb = ApplyColorGrading(col.rgb);
                #endif

				#ifdef BLOOM_ENABLE
					half4 bloom = SAMPLE_TEXTURE2D(_BloomTex, sampler_LinearClamp, uv);
					bloom.rgb *= _Tint.rgb * _BloomIntensity;
					col.rgb += bloom.rgb;
				#endif
                                 
                #if _LINEARTOSRGB
                    col.rgb = GetLinearToSRGB(col.rgb);// pow(col.rgb,1/2.2);
                #endif

				return col;
			}
			ENDHLSL
		}
        //pass 2 安卓用一个批次绘制
		Pass {
			//Pass 5:合并至原图
			//Blend One One
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile _ BLOOM_ENABLE
			#pragma multi_compile _ SUNSHAFT_ENABLE
			#pragma multi_compile _ RADIALBLUR_ENABLE FXAA FXAA3_HIGH
			#pragma multi_compile _ DISTORTION_ENABLE
			#pragma multi_compile _ DEPTH_OF_FIELD_ENABLE
            #pragma multi_compile _ COLORGRADING_ENABLE
			#pragma multi_compile _ RIPPLE_ENABLE

         
			half4 frag(v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(v);
				float2 uv = i.uv;
				// #if UNITY_UV_STARTS_AT_TOP
				//     uv = float2(i.uv.x,1-i.uv.y);
				// #endif

#ifdef DISTORTION_ENABLE
								

//采样Mask图获得权重信息
				float4 factor = SAMPLE_TEXTURE2D(_DistortionMaskTex, sampler_LinearClamp, uv);
				float2 offset = factor.rg * _DistortStrength;
				//像素采样时偏移offset，用Mask权重进行修改
				uv = offset + uv;
#endif
#ifdef RIPPLE_ENABLE				
				#if UNITY_UV_STARTS_AT_TOP				
					_startPos.y = 1 - _startPos.y;				
				#endif
				float2 dv = _startPos.xy - uv;
				dv = dv * float2(_ScreenParams.x / _ScreenParams.y, 1);
				float dis = sqrt(dv.x * dv.x + dv.y * dv.y);
				float sinFactor = sin(dis * _distanceFactor  + _Time.y * _timeFactor) * _totalFactor * 0.01;			
				float discardFactor = clamp(_waveWidth - abs(_curWaveDis - dis), 0, 1) / _waveWidth;					
				float2 dv1 = normalize(dv);				
				uv = dv1  * sinFactor * discardFactor + uv;	
#endif
				half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,uv);

                #ifdef RADIALBLUR_ENABLE
                    col.rgb = RadialBlur(uv, TEXTURE2D_ARGS(_BlitTex, sampler_BlitTex));
                #endif
                
				float2 positionNDC = uv;
				int2   positionSS = uv * _BlitTex_TexelSize.zw;
				//FXAA
                #if defined(FXAA)
				    half3 color = Load(positionSS, 0, 0).xyz;
	                // Edge detection
	                half3 rgbNW = Load(positionSS, -1, -1);
	                half3 rgbNE = Load(positionSS,  1, -1);
	                half3 rgbSW = Load(positionSS, -1,  1);
	                half3 rgbSE = Load(positionSS,  1,  1);

	                rgbNW = saturate(rgbNW);
	                rgbNE = saturate(rgbNE);
	                rgbSW = saturate(rgbSW);
	                rgbSE = saturate(rgbSE);
	                color = saturate(color);

	                half lumaNW = Luminance(rgbNW);
	                half lumaNE = Luminance(rgbNE);
	                half lumaSW = Luminance(rgbSW);
	                half lumaSE = Luminance(rgbSE);
	                half lumaM = Luminance(color);

	                float2 dir;
	                dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
	                dir.y = ((lumaNW + lumaSW) - (lumaNE + lumaSE));

	                half lumaSum = lumaNW + lumaNE + lumaSW + lumaSE;
	                float dirReduce = max(lumaSum * (0.25 * FXAA_REDUCE_MUL), FXAA_REDUCE_MIN);
	                float rcpDirMin = rcp(min(abs(dir.x), abs(dir.y)) + dirReduce);

	                dir = min((FXAA_SPAN_MAX).xx, max((-FXAA_SPAN_MAX).xx, dir * rcpDirMin)) * _BlitTex_TexelSize.xy;

	                // Blur
	                half3 rgb03 = Fetch(positionNDC, dir * (0.0 / 3.0 - 0.5));
	                half3 rgb13 = Fetch(positionNDC, dir * (1.0 / 3.0 - 0.5));
	                half3 rgb23 = Fetch(positionNDC, dir * (2.0 / 3.0 - 0.5));
	                half3 rgb33 = Fetch(positionNDC, dir * (3.0 / 3.0 - 0.5));

	                rgb03 = saturate(rgb03);
	                rgb13 = saturate(rgb13);
	                rgb23 = saturate(rgb23);
	                rgb33 = saturate(rgb33);

	                half3 rgbA = 0.5 * (rgb13 + rgb23);
	                half3 rgbB = rgbA * 0.5 + 0.25 * (rgb03 + rgb33);

	                half lumaB = Luminance(rgbB);

	                half lumaMin = Min3(lumaM, lumaNW, Min3(lumaNE, lumaSW, lumaSE));
	                half lumaMax = Max3(lumaM, lumaNW, Max3(lumaNE, lumaSW, lumaSE));

	                color = ((lumaB < lumaMin) || (lumaB > lumaMax)) ? rgbA : rgbB;
	                col.rgb = color;
                #elif defined(FXAA3_HIGH)
                        col.rgb = ApplyFXAA(col.rgb, positionNDC, positionSS, _BlitTex_TexelSize, _BlitTex);
                #endif

                #ifdef DEPTH_OF_FIELD_ENABLE
	                half4 dof = SAMPLE_TEXTURE2D(_BokehTexture, sampler_LinearClamp,uv);
	                half CoC = SAMPLE_TEXTURE2D(_CocTex, sampler_LinearClamp, uv);
	                half strength = smoothstep(0.1, 1, abs(CoC));
	                col.rgb = lerp(col.rgb, dof.rgb, strength);
                #endif

                #ifdef SUNSHAFT_ENABLE
	                half4 sunShaft = SAMPLE_TEXTURE2D(_SunShaftTex, sampler_LinearClamp, uv);
	                half sunShaftMask = SAMPLE_TEXTURE2D(_SunShaftMaskedTex, sampler_LinearClamp, uv).r;
	                col.rgb += sunShaft.rgb *  _SunShaftIntensity * (1 - sunShaftMask) * _SunColor.rgb;//add
	                //col.rgb = 1.0f - (1.0f - col.rgb) * (1.0f - (sunShaft.rgb * _SunColor.rgb));//screen
                #endif

				#ifdef COLORGRADING_ENABLE
					col.rgb = ApplyColorGrading(col.rgb);
                #endif

				#ifdef BLOOM_ENABLE
					half4 bloom = SAMPLE_TEXTURE2D(_BloomTex, sampler_LinearClamp, uv);
					bloom.rgb *= _Tint.rgb * _BloomIntensity;
					col.rgb += bloom.rgb;
				#endif
                                 
                #if _LINEARTOSRGB
                    col.rgb = GetLinearToSRGB(col.rgb);// pow(col.rgb,1/2.2);
                #endif

				return col;
			}
			ENDHLSL
		}
	}
}
