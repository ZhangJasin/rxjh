Shader "MD/Standard/CloudShadow"
{
   
    SubShader
    {
		Cull Off
		ZWrite Off
		ZTest Always

		HLSLINCLUDE
		#pragma prefer_hlslcc gles
		#pragma exclude_renderers d3d11_9x
		#include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
		
		TEXTURE2D(_BlitTex);
		SAMPLER(sampler_BlitTex);
		float4 _BlitTex_TexelSize;

		TEXTURE2D(_CloudTex); SAMPLER(sampler_CloudTex);
		float4x4 _FrustumCornersRay;
		float4 _CloudFactor;
		float _CloudShadowIntensity;
		half3 _ShadowColor;
		TEXTURE2D(_CloudShadowTex); SAMPLER(sampler_CloudShadowTex);
		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float4 interpolatedRay : TEXCOORD1;
		};
		struct v2f_com
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};
		
		v2f vert_ao(appdata v)
		{
			v2f o;
			o.vertex = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			int index = 0;
			if (v.uv.x < 0.5 && v.uv.y < 0.5) {
				index = 0;
			}
			else if (v.uv.x > 0.5 && v.uv.y < 0.5) {
				index = 1;
			}
			else if (v.uv.x > 0.5 && v.uv.y > 0.5) {
				index = 2;
			}
			else {
				index = 3;
			}
			o.interpolatedRay = _FrustumCornersRay[index];
			return o;
		}

		float4 frag_ao(v2f i) : SV_Target
		{
			float2 uv = i.uv;

			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv.xy);
			//REVERSE_DEPTH
			
			
			float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
			UNITY_BRANCH
			if (eyeDepth >500)
				return 1;
			float3 worldPos = _WorldSpaceCameraPos + eyeDepth * i.interpolatedRay.xyz;
			float2 cloud_uv = float2(worldPos.x, worldPos.z + worldPos.y * 0.5) * 0.005f;
			cloud_uv = (cloud_uv + _CloudFactor.xy) * _CloudFactor.zw;
			half4 atten = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, cloud_uv);
			return 1 - min(1,(atten.r * _CloudShadowIntensity));
		}
			v2f_com vert_composite(appdata v)
		{
			v2f_com o;
			o.vertex = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			return o;
		}
		
		//应用AO贴图
		half4 frag_composite(v2f_com i) : SV_Target
		{
			half4 ori = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv);
			half4 ao = SAMPLE_TEXTURE2D(_CloudShadowTex, sampler_CloudShadowTex, i.uv);
			ori.rgb = lerp(_ShadowColor,ori.rgb ,ao.r);
			return ori;
		}
		ENDHLSL
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert_ao
            #pragma fragment frag_ao
			#pragma multi_compile _ _CLOUD_SHADOW_ON
			#pragma multi_compile _ _HBAO_ON
            ENDHLSL
        }

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert_composite
			#pragma fragment frag_composite
			ENDHLSL
		}
    }
}
