Shader "Hidden/Debug/OverDrawTransparent"
{
	SubShader
	{
	  Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
	  Fog { Mode Off }
	  ZWrite Off
	  ZTest Always
      ZTest LEqual
  	  Blend One One
      Cull Off 
 
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_instancing

			#include "../Library/Transform.hlsl"
 
			struct appdata
			{
				float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			struct v2f
			{
				float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
 
			v2f vert(appdata v)
			{
				v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				return o;
			}
 
			half4 frag(v2f i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
				return half4(0.1, 0.04, 0.02, 0);
			}
			ENDHLSL
		}
	}
}