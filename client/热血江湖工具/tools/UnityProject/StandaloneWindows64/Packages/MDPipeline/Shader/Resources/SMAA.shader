Shader "Hidden/Custom/SMAA"
{
	SubShader
	{
		ZTest Always Cull Off ZWrite Off

		HLSLINCLUDE
		#include "../Library/Core.hlsl"

		TEXTURE2D(_BlitTex);
		TEXTURE2D(_BlendTex);
		TEXTURE2D(_AreaTex);
		TEXTURE2D(_SearchTex);
		//TEXTURE2D(_TargetTexture);
		SAMPLER(sampler_BlitTex);
		SAMPLER(sampler_BlendTex);
		SAMPLER(sampler_AreaTex);
		SAMPLER(sampler_SearchTex);
		//SAMPLER(sampler_TargetTexture);
		//float4 _BlitTex_TexelSize;

		float4 _Metrics; // 1f / width, 1f / height, width, height
		float4 _Params1; // SMAA_THRESHOLD, SMAA_DEPTH_THRESHOLD, SMAA_MAX_SEARCH_STEPS, SMAA_MAX_SEARCH_STEPS_DIAG
		float2 _Params2; // SMAA_CORNER_ROUNDING, SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR
		float3 _Params3; // SMAA_PREDICATION_THRESHOLD, SMAA_PREDICATION_SCALE, SMAA_PREDICATION_STRENGTH

		#define SMAA_RT_METRICS _Metrics
		#define SMAA_THRESHOLD _Params1.x
		#define SMAA_DEPTH_THRESHOLD _Params1.y
		#define SMAA_MAX_SEARCH_STEPS _Params1.z
		#define SMAA_MAX_SEARCH_STEPS_DIAG _Params1.w
		#define SMAA_CORNER_ROUNDING _Params2.x
		#define SMAA_LOCAL_CONTRAST_ADAPTATION_FACTOR _Params2.y
		#define SMAA_PREDICATION_THRESHOLD _Params3.x
		#define SMAA_PREDICATION_SCALE _Params3.y
		#define SMAA_PREDICATION_STRENGTH _Params3.z

		#define LinearSampler sampler_LinearClamp
		#define PointSampler sampler_PointClamp

		// Can't use SMAA_HLSL_3 as it won't compile with OpenGL, so lets make our own set of defines for Unity
		#define SMAA_CUSTOM_SL
		#define mad(a, b, c) (a * b + c)
		//#define SMAATexture2D(tex) sampler2D tex
		//#define SMAATexturePass2D(tex) tex
		//#define SMAASampleLevelZero(tex, coord) tex2Dlod(tex, float4(coord, 0.0, 0.0))
		//#define SMAASampleLevelZeroPoint(tex, coord) tex2Dlod(tex, float4(coord, 0.0, 0.0))
		//#define SMAASampleLevelZeroOffset(tex, coord, offset) tex2Dlod(tex, float4(coord + offset * SMAA_RT_METRICS.xy, 0.0, 0.0))
		//#define SMAASample(tex, coord) tex2D(tex, coord)
		//#define SMAASamplePoint(tex, coord) tex2D(tex, coord)
		//#define SMAASampleOffset(tex, coord, offset) tex2D(tex, coord + offset * SMAA_RT_METRICS.xy)

		#define SMAATexture2D(tex) TEXTURE2D(tex)
		#define SMAATexturePass2D(tex) tex
		#define SMAASampleLevelZero(tex, coord) SAMPLE_TEXTURE2D_LOD(tex, LinearSampler, coord, 0)
		#define SMAASampleLevelZeroNoRescale(tex, coord) tex.SampleLevel(LinearSampler, coord, 0)
		#define SMAASampleLevelZeroPoint(tex, coord) SAMPLE_TEXTURE2D_LOD(tex, PointSampler, coord, 0) 
		#define SMAASampleLevelZeroOffset(tex, coord, offset) SAMPLE_TEXTURE2D_LOD(tex, LinearSampler, coord + offset * SMAA_RT_METRICS.xy, 0)
		#define SMAASample(tex, coord) SAMPLE_TEXTURE2D(tex, LinearSampler, coord)
		#define SMAASamplePoint(tex, coord) SAMPLE_TEXTURE2D(tex, PointSampler, coord)
		#define SMAASampleOffset(tex, coord, offset) SAMPLE_TEXTURE2D(tex, LinearSampler, coord + offset * SMAA_RT_METRICS.xy)


		#define SMAA_FLATTEN UNITY_FLATTEN
		#define SMAA_BRANCH UNITY_BRANCH

		#define SMAA_AREATEX_SELECT(sample) sample.rg
		#define SMAA_SEARCHTEX_SELECT(sample) sample.a
		#define SMAA_INCLUDE_VS 0

		struct vInput
		{
			float4 pos : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct fInput_edge
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 offset[3] : TEXCOORD1;
		};

		fInput_edge vert_edge(vInput i)
		{
			fInput_edge o;
			o.pos = TransformObjectToHClip(i.pos.xyz);
			o.uv = i.uv.xy;

			//#if UNITY_UV_STARTS_AT_TOP
			//if (_BlitTex_TexelSize.y < 0)
			//	o.uv.y = 1.0 - o.uv.y;
			//#endif

			o.offset[0] = mad(SMAA_RT_METRICS.xyxy, float4(-1.0, 0.0, 0.0, -1.0), o.uv.xyxy);
			o.offset[1] = mad(SMAA_RT_METRICS.xyxy, float4(1.0, 0.0, 0.0,  1.0), o.uv.xyxy);
			o.offset[2] = mad(SMAA_RT_METRICS.xyxy, float4(-2.0, 0.0, 0.0, -2.0), o.uv.xyxy);
			return o;
		}

		ENDHLSL

			// (0) Color
			Pass
			{
			// TODO: Stencil not working
		//	Stencil
		//	{
		//		Pass replace
		//		Ref 1
		//	}

			HLSLPROGRAM

				#pragma vertex vert_edge
				#pragma fragment frag

				#if USE_PREDICATION
				#define SMAA_PREDICATION 1
				#else
				#define SMAA_PREDICATION 0
				#endif

				#include "SMAA.hlsl"

				float4 frag(fInput_edge i) : COLOR
				{
					return float4(SMAAColorEdgeDetectionPS(i.uv, i.offset, _BlitTex), 0.0, 0.0);
				}

			ENDHLSL
		}

			// -----------------------------------------------------------------------------
			// Blend Weights Calculation

			// (1) 
			Pass
			{
					// TODO: Stencil not working
				//	Stencil
				//	{
				//		Pass keep
				//		Comp equal
				//		Ref 1
				//	}

					HLSLPROGRAM

						#pragma vertex vert
						#pragma fragment frag
						#pragma multi_compile __ USE_DIAG_SEARCH
						#pragma multi_compile __ USE_CORNER_DETECTION

						#if !defined(USE_DIAG_SEARCH)
						#define SMAA_DISABLE_DIAG_DETECTION
						#endif

						#if !defined(USE_CORNER_DETECTION)
						#define SMAA_DISABLE_CORNER_DETECTION
						#endif
						#include "SMAA.hlsl"


						struct fInput
						{
							float4 pos : SV_POSITION;
							float2 uv : TEXCOORD0;
							float2 pixcoord : TEXCOORD1;
							float4 offset[3] : TEXCOORD2;
						};

						fInput vert(vInput i)
						{
							fInput o;
							o.pos = TransformObjectToHClip(i.pos.xyz);
							o.uv = i.uv;
							o.pixcoord = o.uv * SMAA_RT_METRICS.zw;

							// We will use these offsets for the searches later on (see @PSEUDO_GATHER4):
							o.offset[0] = mad(SMAA_RT_METRICS.xyxy, float4(-0.25, -0.125,  1.25, -0.125), o.uv.xyxy);
							o.offset[1] = mad(SMAA_RT_METRICS.xyxy, float4(-0.125, -0.25, -0.125,  1.25), o.uv.xyxy);

							// And these for the searches, they indicate the ends of the loops:
							o.offset[2] = mad(SMAA_RT_METRICS.xxyy, float4(-2.0, 2.0, -2.0, 2.0) * float(SMAA_MAX_SEARCH_STEPS),
											float4(o.offset[0].xz, o.offset[1].yw));

							return o;
						}

						float4 frag(fInput i) : COLOR
						{
							return SMAABlendingWeightCalculationPS(i.uv, i.pixcoord, i.offset, _BlitTex, _AreaTex, _SearchTex,
											float4(0.0, 0.0, 0.0, 0.0));
						}

					ENDHLSL
				}


					// -----------------------------------------------------------------------------
					// Neighborhood Blending

					// (2)
					Pass
					{
						HLSLPROGRAM

							#pragma vertex vert
							#pragma fragment frag
							#include "SMAA.hlsl"

							struct fInput
							{
								float4 pos : SV_POSITION;
								float2 uv : TEXCOORD0;
								float4 offset : TEXCOORD1;
							};

							fInput vert(vInput i)
							{
								fInput o;
								o.pos = TransformObjectToHClip(i.pos.xyz);
								o.uv = i.uv;
								o.offset = mad(SMAA_RT_METRICS.xyxy, float4(1.0, 0.0, 0.0, 1.0), o.uv.xyxy);
								return o;
							}

							float4 frag(fInput i) : COLOR
							{
								return SMAANeighborhoodBlendingPS(i.uv, i.offset, _BlitTex, _BlendTex);
							}

						ENDHLSL
					}

							// (3) debug
							//Pass
							//{
							//	HLSLPROGRAM

							//		#pragma vertex vert
							//		#pragma fragment frag
							//		#include "SMAA.hlsl"

							//		struct fInput
							//		{
							//			float4 pos : SV_POSITION;
							//			float2 uv : TEXCOORD0;
							//		};
							//		TEXTURE2D(_BlitTex);
							//		SAMPLER(sampler_BlitTex);
							//		fInput vert(vInput i)
							//		{
							//			fInput o;
							//			o.pos = TransformObjectToHClip(i.pos);
							//			o.uv = i.uv;
							//			return o;
							//		}

							//		float4 frag(fInput i) : COLOR
							//		{
							//			half4 col = SAMPLE_TEXTURE2D(_TargetTexture,sampler_TargetTexture,i.uv);
							//			//half4 col1 = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,i.uv);
							//			//half4 col2 = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,i.uv);
							//			//return col+col1+col2;
							//			return col;
							//		}

							//	ENDHLSL
							//}

	}
}