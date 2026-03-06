Shader "Hidden/Debug/MipmapView"
{
    Properties {
        _MainTex ("Main Texture", 2D) = "white" {}
    }
	SubShader
	{
	  Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_instancing

			#include "../Library/Core.hlsl"
 
			struct appdata
			{
				float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 mipuv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 mipuv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_MipColorsTexture);
            SAMPLER(sampler_MipColorsTexture);
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
			v2f vert(appdata v)
			{
				v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.mipuv = o.uv * _MainTex_TexelSize.zw / 8.0;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				return o;
			}
 
			half4 frag(v2f i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
			    half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                half4 mip = SAMPLE_TEXTURE2D(_MipColorsTexture,sampler_MipColorsTexture, i.mipuv);
				half4 res;
				res.rgb = lerp (col.rgb, mip.rgb, mip.a);
				res.a = col.a;


                return res;
			}
			ENDHLSL
		}
	}
}