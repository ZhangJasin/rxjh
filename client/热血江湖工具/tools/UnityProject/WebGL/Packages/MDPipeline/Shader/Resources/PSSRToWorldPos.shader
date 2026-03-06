
Shader "MD/Standard/PSSRToWorldPos"
{
	SubShader
	{
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#include "UnityCG.cginc"
            #include "../Library/Core.hlsl"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			    float3 ray : TEXCOORD1;
			};

			uniform float4x4	frustumCorners;
			v2f vert (appdata v)
			{
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                uint x = (uint)(o.uv.x * 1.5);
                uint y = (uint)(o.uv.y * 1.5);
                half index = y * 2 + x;//取得索引
                o.ray = frustumCorners[index].xyz;//根据在程序中计算好的顶点z值作为索引
                return o;
			}
			
			float4 frag (v2f i) : SV_Target
			{
	            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,sampler_CameraDepthTexture, i.uv.xy);
                depth = Linear01Depth(depth, _ZBufferParams);
                float4 worldPos = float4(depth*i.ray, 1);
                worldPos.xyz += _WorldSpaceCameraPos;
                if (depth > 0.99) return 0;
 
                return worldPos;
			}
			ENDHLSL
		}
	}
}
