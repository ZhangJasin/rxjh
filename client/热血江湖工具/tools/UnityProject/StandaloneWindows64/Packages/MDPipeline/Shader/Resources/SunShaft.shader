Shader "MD/Standard/SunShaft"
{

    SubShader
    {
		Cull Off
		ZWrite Off
		ZTest Always

		HLSLINCLUDE
		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x
		#include "../Library/Core.hlsl"

		/*#define SAMPLES_FLOAT 6.0f
		#define SAMPLES_INT 6*/
		//TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
		//TEXTURE2D(_BluredTexture);
		//TEXTURE2D(_SunShaftMaskedTex);
		TEXTURE2D(_BlitTex);
		SAMPLER(sampler_BlitTex);
		float4 _BlitTex_TexelSize;
		//float4 _SunShaftParams;
		half4 _SunColor;
		half4 _SunScreenPos;
		int _SunShaftSampleDistance;
		//float _SunShaftAtten;

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
			return o;
		}

		/*half Luminance(half3 rgb) {
			return dot(rgb, float3(0.2126,0.7152,0.0722));
		}*/

		

		
		ENDHLSL
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag_depth


			half4 frag_depth(v2f i) : SV_Target
			{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv.xy);
				float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
				if (eyeDepth < 500) {
					return 0;
				}
				half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, i.uv);
				float2 d = i.uv - _SunScreenPos.xy;
				float limit = 1 - saturate(saturate(length(d) / 1.414) * 2);
				limit = pow(limit, 3);
				half l = col.r * .299 + col.g * .587 + col.b * .114;
				half4 pixel = lerp(0, col, smoothstep(0.4, 0.5, l));
				return min(pixel, lerp(0, col, limit)) * _SunScreenPos.z;
			}
            ENDHLSL
        }
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag_radial
#if HQ
#define SC 16.0
#elif MQ
#define SC 12.0
#else
#define SC 8.0
#endif
			half4 frag_radial(v2f i) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, i.uv);
				float2 d = i.uv - _SunScreenPos.xy;
				float p = 0.01;
				float2 uvd = d * p * _SunShaftSampleDistance / SC;
				for (int idx = 1; idx <= SC; idx++) {
					col += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv - uvd * idx);
				}
				col /= (SC + 1);
				return col;
			}
			ENDHLSL
		}
		//Pass
		//{
		//	HLSLPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag_result

		//	

		//	half4 frag_result(v2f i) : SV_Target
		//	{
		//		//half4 origin = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, i.uv);
		//		half4 blured = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv) * _SunColor;
		//		half mask = SAMPLE_TEXTURE2D(_SunShaftMaskedTex, sampler_BlitTex, i.uv).r;
		//		return half4(blured.rgb *  (1 - mask), blured.a);
		//	}
		//	ENDHLSL
		//}
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag_mask
			half4 frag_mask(v2f i) : SV_Target
			{
				half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, i.uv);
				half l = (col.r * .299 + col.g * .587 + col.b * .114);
				return half4(l, 0, 0, 0);
			}

			ENDHLSL
		}
    }
}
