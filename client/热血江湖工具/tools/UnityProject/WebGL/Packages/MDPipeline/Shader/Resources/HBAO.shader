Shader "MD/Standard/HBAO"
{
    Properties
    {
        [HideInInspector] _StencilRef("Stencil Reference", Float) = 128.0
	    [HideInInspector][Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", Float) = 8 // Set to Always as default
    }

    SubShader
    {
		Cull Off
		ZWrite Off
		ZTest Always

		HLSLINCLUDE
		#include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
		TEXTURE2D(_BlitTex);
		SAMPLER(sampler_BlitTex);
		float4 _BlitTex_TexelSize;
		#define DIRECTIONS      4  
		#define STEPS           3
		#define WEIGHT        0.125 
        //2.0 / (STEPS * DIRECTIONS) 
		#define ALPHA          1.57
        //6.28 / DIRECTIONS

		float4 _ScreenToView;
		half4 _Radius;
		half _MaxRadiusPixels;
		half _AngleBias;
		half _AOIntensity;
		half _MaxDistance;

		TEXTURE2D(_AOTex); SAMPLER(sampler_AOTex);
		float4 _BlurRadius;
		//float _BilaterFilterFactor;

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};

		struct v2f_blur
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float2 uvs[4] : TEXCOORD1;
		};
		inline float3 GetViewPos(float2 uv)
		{
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv.xy);
			//REVERSE_DEPTH;
			float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);

			return float3((uv * _ScreenToView.xy + _ScreenToView.zw) * eyeDepth, eyeDepth);
		}

		inline float3 GetViewNormal(float2 uv)
		{
			float3 vpos = GetViewPos(uv);
			float3 normal = normalize(cross(ddx(vpos), ddy(vpos)));
			//float4 gbuffer0 = tex2D(_GBuffer0, uv);
			//float3 normal = DecodeGBufferNormal(gbuffer0.ba);
			//normal = mul((float3x3)unity_WorldToCamera, normal);
			//normal.y = -normal.y;
			return (normal);
		}

		inline float2 RotateDirections(float2 dir, float2 rot)
		{
			return float2(dir.x * rot.x - dir.y * rot.y,
				dir.x * rot.y + dir.y * rot.x);
		}

		inline float Falloff(float distanceSquare)
		{
			// 1 scalar mad instruction
			return distanceSquare * _Radius.y + 1.0;
		}

		inline float ComputeAO(float3 P, float3 N, float3 S)
		{
			float3 V = S - P;
			float VdotV = dot(V, V);
			float NdotV = dot(N, V) * rsqrt(VdotV);

			// Use saturate(x) instead of max(x,0.f) because that is faster on Kepler
			return saturate(NdotV - _AngleBias) * saturate(Falloff(VdotV));
		}
        inline float random(float2 uv) {
            return frac(sin(dot(uv.xy, float2(12.9898, 78.233))) * 4375.85453);
        }

		v2f vert_ao(appdata v)
		{
			v2f o;
			o.vertex = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			return o;
		}

		float4 frag_ao(v2f i) : SV_Target
		{
        
			const float2 InvScreenParams = _ScreenParams.zw - 1.0;
			float2 uv = i.uv;
            uv -= InvScreenParams* _Radius.w;
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv.xy);
			//REVERSE_DEPTH;
			float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
			//float3 worldPos = _WorldSpaceCameraPos + eyeDepth * i.interpolatedRay.xyz;
			float3 P = float3((uv * _ScreenToView.xy + _ScreenToView.zw) * eyeDepth, eyeDepth);
            
            //return float4((uv ), 0,1);
			//float3 P = GetViewPos(uv);

			//UNITY_BRANCH
			if (eyeDepth > _Radius.z)
				return 1;

			//float3 normal = normalize(cross(ddx(vpos), ddy(vpos)));
			float3 N = normalize(cross(ddx(P), ddy(P)));
            //return float4(N, 1);

			float stepSize = min((_Radius.x / P.z), _MaxRadiusPixels) / (STEPS + 1.0);

			float stepSizePlus = stepSize + 1.0;
			//float3 rand = tex2D(_NoiseTexture, uv / NOISE_SIZE).rgb;
            float rand = random(uv.xy * 10);

			const float alpha = ALPHA ;//6.28 / DIRECTIONS
			float ao = 0;

			UNITY_UNROLL
			for (int d = 0; d < DIRECTIONS; ++d)
			{
				float angle = alpha * float(d +rand);

				// Compute normalized 2D direction
				float cosA, sinA;
				sincos(angle, sinA, cosA);
				float2 direction = float2(cosA, sinA);// RotateDirections(float2(cosA, sinA), rand.xy);
				float rayPixels = stepSizePlus;//(rand.z * stepSize + 1.0);

				UNITY_UNROLL
				for (int s = 0; s < STEPS; ++s)
				{
					float2 snappedUV = round(rayPixels * direction) * InvScreenParams + uv;
					float3 S = GetViewPos(snappedUV);
					rayPixels += stepSize;

					ao += ComputeAO(P, N, S);
				}
			}

			ao *= WEIGHT * _AOIntensity;//2.0 / (STEPS * DIRECTIONS) * _AOIntensity;

			//float fallOffStart = _MaxDistance - _DistanceFalloff;
			//ao = lerp(saturate(1.0 - ao), 1.0, saturate((P.z - fallOffStart) / (_MaxDistance - fallOffStart)));

            //half distanceIntensity = 1+ saturate(eyeDepth/(_Radius.z * 0.5));
			//ao = lerp(1, 0, ao*distanceIntensity);

			ao = lerp(1, 0, ao);
			//ao = min(ao, 1);

			/*float history = tex2D(_HistoryAOTexture, i.uv).r;
			return lerp(ao, history, 0.5);*/
			return ao;
		}

		v2f_blur vert_blur(appdata v)
		{
			v2f_blur o;
			o.vertex = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			float2 st = _BlitTex_TexelSize.xy* _BlurRadius.xy;
			o.uvs[0] = o.uv + float2(1, 1) * st;
			o.uvs[1] = o.uv + float2(-1, 1) * st;
			o.uvs[2] = o.uv + float2(1, -1) * st;
			o.uvs[3] = o.uv + float2(-1, -1) * st;
			return o;
		}
		float4 frag_blur(v2f_blur i) : SV_Target
		{
			float4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, i.uv);
			for (int k = 0; k < 4; ++k)
			{
				col += SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uvs[k]);
			}
			return col * 0.2;
		}

		//双边滤波（Bilateral Filter）
		//half4 frag_blur(v2f i) : SV_Target
		//{
		//	float2 delta = _BlitTex_TexelSize.xy * _BlurRadius.xy;

		//	float2 uv = i.uv;
		//	float2 uv0a = i.uv - delta;
		//	float2 uv0b = i.uv + delta;
		//	float2 uv1a = i.uv - 2.0 * delta;
		//	float2 uv1b = i.uv + 2.0 * delta;
		//	float2 uv2a = i.uv - 3.0 * delta;
		//	float2 uv2b = i.uv + 3.0 * delta;

		//	/*float3 normal = GetNormal(uv);
		//	float3 normal0a = GetNormal(uv0a);
		//	float3 normal0b = GetNormal(uv0b);
		//	float3 normal1a = GetNormal(uv1a);
		//	float3 normal1b = GetNormal(uv1b);
		//	float3 normal2a = GetNormal(uv2a);
		//	float3 normal2b = GetNormal(uv2b);*/

		//	half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, uv);
		//	half4 col0a = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv0a);
		//	half4 col0b = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv0b);
		//	half4 col1a = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv1a);
		//	half4 col1b = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv1b);
		//	half4 col2a = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv2a);
		//	half4 col2b = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv2b);

		//	/*half w = 0.37004405286;
		//	half w0a = CompareNormal(normal, normal0a) * 0.31718061674;
		//	half w0b = CompareNormal(normal, normal0b) * 0.31718061674;
		//	half w1a = CompareNormal(normal, normal1a) * 0.19823788546;
		//	half w1b = CompareNormal(normal, normal1b) * 0.19823788546;
		//	half w2a = CompareNormal(normal, normal2a) * 0.11453744493;
		//	half w2b = CompareNormal(normal, normal2b) * 0.11453744493;*/

		//	half3 result;
		//	result =  col.rgb;
		//	result += col0a.rgb;
		//	result +=  col0b.rgb;
		//	result +=  col1a.rgb;
		//	result +=  col1b.rgb;
		//	result += col2a.rgb;
		//	result += col2b.rgb;

		//	result /= 7;
		//	return half4(result, 1.0);
		//}

        half4 _AOColor;
		//应用AO贴图
		half4 frag_composite(v2f i) : SV_Target
		{
			half4 ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, i.uv);
            half3 finalColor = lerp(_AOColor.rgb, 1, ao.r);
		    return half4(finalColor, 1);
		}
		ENDHLSL

        //0 AO
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert_ao
            #pragma fragment frag_ao
            ENDHLSL
        }
        //blur
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur

			ENDHLSL
		}
        //combine
		Pass
		{
            Stencil {
			    Ref[_StencilRef]
			    Comp[_StencilComp]
			    Pass Keep
		    }
            
            Blend DstColor Zero
			HLSLPROGRAM
			#pragma vertex vert_ao
			#pragma fragment frag_composite
			ENDHLSL
		}
    }
}
