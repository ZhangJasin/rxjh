Shader "MD/Standard/DepthOfField"
{
    SubShader {
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
		#define KERNEL_VERY_SMALL
        #include "../Library/Core.hlsl"
		#include "../Library/DiskKernel.hlsl"
        TEXTURE2D(_BlitTex);
        SAMPLER(sampler_BlitTex);
        float4 _BlitTex_TexelSize;
		TEXTURE2D(_CocTex);
		SAMPLER(sampler_CocTex);
		float4 _CocTex_TexelSize;
		TEXTURE2D(_BokehTexture);
		float _BokehRadius, _FocusDistance, _FocusRange;

		struct appdata_img
		{
			float4 vertex : POSITION;
			half2 texcoord : TEXCOORD0;
		};

		struct v2f_img
		{
			float4 vertex : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f_img vert_img(appdata_img v) {
			v2f_img o;
			o.uv = v.texcoord;
			o.vertex = TransformObjectToHClip(v.vertex.xyz);
			return o;
		}

		half frag_coc(v2f_img i) : SV_Target
		{
			float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture,i.uv),_ZBufferParams);
			float coc = (depth - _FocusDistance) / _FocusRange;
			coc = clamp(coc, -1, 1) * _BokehRadius;
			return coc;
		}
		
		half4 frag_filterCoc(v2f_img i) : SV_Target
		{
			float4 offset = _BlitTex_TexelSize.xyxy * float4(0.5, 0.5, -0.5,-0.5);
			half coc0 = SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex, i.uv + offset.xy).x;
			half coc1 = SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex, i.uv + offset.zy).x;
			half coc2 = SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex, i.uv + offset.xw).x;
			half coc3 = SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex, i.uv + offset.zw).x;
			half cocMin = min(min(min(coc0, coc1), coc2), coc3);
			half cocMax = max(max(max(coc0, coc1), coc2), coc3);
			half coc = cocMax >= -cocMin ? cocMax : cocMin;
			return half4(SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv).rgb, coc);
		}

		half4 frag_blur(v2f_img i) : SV_Target
		{
			float4 offset = _BlitTex_TexelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0);
			half4 color = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv + offset.xy) * 0.25;
			color += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv + offset.zy) * 0.25;
			color += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv + offset.xw) * 0.25;
			color += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv + offset.zw) * 0.25;
			return color;
		}

		half Weigh(half coc, half radius) {
			return saturate((coc - radius + 2) / 2);
		}
		half4 frag_bokeh(v2f_img i) : SV_Target
		{
			half coc = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv).a;

			half3 bgColor = 0, fgColor = 0;
			half bgWeight = 0, fgWeight = 0;
			UNITY_LOOP for (int k = 0; k < kSampleCount; k++) {
				float2 o = kDiskKernel[k] * _BokehRadius;
				half radius = length(o);
				o *= _BlitTex_TexelSize.xy;
				half4 s = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv + o);

				half bgw = Weigh(max(0, min(s.a, coc)), radius);
				bgColor += s.rgb * bgw;
				bgWeight += bgw;

				half fgw = Weigh(-s.a, radius);
				fgColor += s.rgb * fgw;
				fgWeight += fgw;
			}
			bgColor *= 1 / (bgWeight + (bgWeight == 0));
			fgColor *= 1 / (fgWeight + (fgWeight == 0));
			half bgfg = min(1, fgWeight * PI / kSampleCount);
			half3 color = lerp(bgColor, fgColor, bgfg);
			return half4(color, bgfg);
		}
		ENDHLSL

		// No culling or depth
		Cull Off ZWrite Off ZTest Always
		//filter
		Pass{
			HLSLPROGRAM
			#pragma vertex vert_img 
			#pragma fragment frag_coc
			ENDHLSL
		}

		Pass{
			HLSLPROGRAM
			#pragma vertex vert_img 
			#pragma fragment frag_filterCoc 
			ENDHLSL
		}

		Pass{
			HLSLPROGRAM
			#pragma vertex vert_img 
			#pragma fragment frag_bokeh 
			ENDHLSL
		}

		Pass{
			HLSLPROGRAM
			#pragma vertex vert_img 
			#pragma fragment frag_blur 
			ENDHLSL
		}

		/*Pass{
			HLSLPROGRAM
			#pragma vertex vert_img 
			#pragma fragment frag_combine 
			ENDHLSL
		}*/
	}
}
