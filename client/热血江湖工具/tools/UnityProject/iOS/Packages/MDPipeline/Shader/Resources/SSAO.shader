Shader "MD/Standard/SSAO"
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

		#define MAX_SAMPLE_KERNEL_COUNT 64
		//TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
		TEXTURE2D(_BlitTex);
		SAMPLER(sampler_BlitTex);
		float4 _BlitTex_TexelSize;
		float4x4 _FrustumCornersRay;
		float4x4 _InverseProjectionMatrix;
		float4 _SampleKernelArray[MAX_SAMPLE_KERNEL_COUNT];
		float _SampleKernelCount;
		float _SampleKeneralRadius;
		float4 _BlurRadius;
		//float _BilaterFilterFactor;
		TEXTURE2D(_AOTex); SAMPLER(sampler_AOTex);
		TEXTURE2D(_NoiseTex); SAMPLER(sampler_NoiseTex);

		float Height;//屏幕的高
		float Width;//屏幕的宽

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
			float3 viewRay : TEXCOORD1;
		};

		float3 reconstructCSFaceNormal(float3 world_p) {
			return normalize(cross(ddx(world_p), ddy(world_p)));
		}

		v2f vert_ao(appdata v)
		{
			v2f o;
			o.vertex = TransformObjectToHClip(v.vertex.xyz);
			o.uv = v.uv;
			float4 clipPos = float4(v.uv * 2 - 1.0, 1.0, 1.0);
			float4 viewRay = mul(_InverseProjectionMatrix, clipPos);
			o.viewRay = viewRay.xyz / viewRay.w;
			return o;
		}
		inline float2 EncodeViewNormalStereo(float3 n)
		{
			float kScale = 1.7777;
			float2 enc;
			enc = n.xy / (n.z + 1);
			enc /= kScale;
			enc = enc * 0.5 + 0.5;
			return enc;
		}
		//计算AO贴图
		half4 frag_ao(v2f i) : SV_Target
		{
			

			

			float depthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv.xy);
			//采样获得深度值和法线值
			//DecodeDepthNormal(cdn, linear01Depth, viewNormal);
			//float linearDepth = LinearEyeDepth(depthSample, _ZBufferParams);
			float linear01Depth = Linear01Depth(depthSample, _ZBufferParams);
			float3 viewPos = linear01Depth * i.viewRay;
			float3 viewNormal = reconstructCSFaceNormal(viewPos);
			viewNormal = viewNormal * float3(1, 1, -1);
			//return float4(viewNormal, 1);
			//铺平纹理
			float2 noiseScale = float2(Height / 4.0,Width / 4.0);
			//float2 noiseUV = i.uv * noiseScale;
			float2 noiseUV = float2(i.uv.x * noiseScale.x,i.uv.y * noiseScale.y);
			//采样噪声图
			float3 randvec = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex,noiseUV).xyz;
			//Gramm-Schimidt处理创建正交基
			float3 tangent = normalize(randvec - viewNormal * dot(randvec,viewNormal));
			float3 bitangent = cross(viewNormal,tangent);
			float3x3 TBN = float3x3(tangent,bitangent,viewNormal);

			int sampleCount = _SampleKernelCount;

			float oc = 0.0;
			for (int i = 0; i < sampleCount; i++)
			{
				//1.注意不要把矩阵乘反了，否则得到的结果很黑;CG语言构造矩阵是"行优先"，OpenGL是"列优先"，两者之间是转置的关系,所以请把learnOpenGL中的顺序反过来
				//float3 randomVec = mul(TBN, _SampleKernelArray[i].xyz);
				float3 randomVec = mul(_SampleKernelArray[i].xyz,TBN);
				//2.
				//float3 randomVec = _SampleKernelArray[i].xyz;
				////如果随机点的位置与法线反向，那么将随机方向取反，使之保证在法线半球
				//randomVec = dot(randomVec, viewNormal) < 0 ? -randomVec : randomVec;

				float3 randomPos = viewPos + randomVec * _SampleKeneralRadius;
				float3 rclipPos = mul((float3x3)unity_CameraProjection, randomPos);
				float2 rscreenPos = (rclipPos.xy / rclipPos.z) * 0.5 + 0.5;

				float randomDepth;
				float3 randomNormal;
				float rDepthSample = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, rscreenPos);
				//float4 rcdn = tex2D(_CameraDepthNormalsTexture, rscreenPos);
				//DecodeDepthNormal(rcdn, randomDepth, randomNormal);
				randomDepth = Linear01Depth(rDepthSample, _ZBufferParams);

				//1.range check & accumulate
				float rangeCheck = smoothstep(0.0,1.0,_SampleKeneralRadius / abs(randomDepth - linear01Depth));
				oc += (randomDepth >= linear01Depth ? 1.0 : 0.0) * rangeCheck;

				//2.
				//float range = abs(randomDepth - linear01Depth) * _ProjectionParams.z < _SampleKeneralRadius ? 1.0 : 0.0;
				//float ao = randomDepth + _DepthBiasValue < linear01Depth  ? 1.0 : 0.0;
				//oc += ao * range;
			}
			//2.
			//oc /= sampleCount;
			//oc = max(0.0, 1 - oc * _AOStrength);

			//1.
			oc = oc / sampleCount;

			//col.rgb = oc;
			return oc;
		}

		//双边滤波（Bilateral Filter）
		half4 frag_blur(v2f i) : SV_Target
		{
			float2 delta = _BlitTex_TexelSize.xy * _BlurRadius.xy;

			float2 uv = i.uv;
			float2 uv0a = i.uv - delta;
			float2 uv0b = i.uv + delta;
			float2 uv1a = i.uv - 2.0 * delta;
			float2 uv1b = i.uv + 2.0 * delta;
			float2 uv2a = i.uv - 3.0 * delta;
			float2 uv2b = i.uv + 3.0 * delta;

			/*float3 normal = GetNormal(uv);
			float3 normal0a = GetNormal(uv0a);
			float3 normal0b = GetNormal(uv0b);
			float3 normal1a = GetNormal(uv1a);
			float3 normal1b = GetNormal(uv1b);
			float3 normal2a = GetNormal(uv2a);
			float3 normal2b = GetNormal(uv2b);*/

			half4 col = SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex, uv);
			half4 col0a = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv0a);
			half4 col0b = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv0b);
			half4 col1a = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv1a);
			half4 col1b = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv1b);
			half4 col2a = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv2a);
			half4 col2b = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, uv2b);

			/*half w = 0.37004405286;
			half w0a = CompareNormal(normal, normal0a) * 0.31718061674;
			half w0b = CompareNormal(normal, normal0b) * 0.31718061674;
			half w1a = CompareNormal(normal, normal1a) * 0.19823788546;
			half w1b = CompareNormal(normal, normal1b) * 0.19823788546;
			half w2a = CompareNormal(normal, normal2a) * 0.11453744493;
			half w2b = CompareNormal(normal, normal2b) * 0.11453744493;*/

			half3 result;
			result =  col.rgb;
			result += col0a.rgb;
			result +=  col0b.rgb;
			result +=  col1a.rgb;
			result +=  col1b.rgb;
			result += col2a.rgb;
			result += col2b.rgb;

			result /= 7;
			return half4(result, 1.0);
		}

		//应用AO贴图
		half4 frag_composite(v2f i) : SV_Target
		{
			half4 ori = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv);
			half4 ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, i.uv);
			ori.rgb *= ao.r;
			return ori;
		}
		ENDHLSL
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert_ao
            #pragma fragment frag_ao


            ENDHLSL
        }

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert_ao
			#pragma fragment frag_blur

			ENDHLSL
		}
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert_ao
			#pragma fragment frag_composite
			ENDHLSL
		}
    }
}
