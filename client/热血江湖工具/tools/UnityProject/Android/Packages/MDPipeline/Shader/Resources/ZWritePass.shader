Shader "Hidden/ZWritePass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff _AlphaTest", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Pass {
            Name "OnlyZWriteOn"
            Tags{"LightMode" = "PreZPass"}
            ZWrite On    
            ColorMask 0

            HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
			struct a2v {
				float3 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			v2f vert (a2v v)
			{
				v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v,o);
				o.pos = TransformObjectToHClip(v.vertex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
				return 0;
			}
            ENDHLSL
        }

        Pass {
            Name "LeafZWriteOn"
            Tags{"LightMode" = "PreZPass"}
            ZWrite On    
            ColorMask 0

            HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #pragma multi_compile_instancing
            #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
            #include "Packages/com.sh.md_pipeline/Shader/Library/WindHelper.hlsl"
			struct a2v {
				float4 vertex : POSITION;
                half3 normal : NORMAL;
	            half4 uv : TEXCOORD0;
	            half4 uv1 : TEXCOORD1;
	            half4 tangent :TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            half4 _MainTex_ST;
            half _Cutoff;
            float _ShakeWindspeed;
			float _ShakeBending;
			float _ShakeRange;
			

			v2f vert (a2v v)
			{
				v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
				//o.pos = TransformObjectToHClip(v.vertex);

                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                float3 worldPos = TransformObjectToWorld(v.vertex);
	            half3 tangentWorld = TransformObjectToWorldDir(v.tangent.xyz);
	            float3 pivot = GetObjectToWorldMatrix()._14_24_34 + float3(v.uv.zw, v.uv1.z);
	            float3 windPos = vertexWindPos(v.vertex, worldPos.xyz, pivot, worldNormal.xyz, tangentWorld.xyz,
                        _WindDirectionAndStrength, _ShakeWindspeed, _ShakeBending,_ShakeRange);

                o.pos = TransformWorldToHClip(windPos);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
                half4 col = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
	            clip(col.a - _Cutoff);
				return 0;
			}
            ENDHLSL
        }

		Pass {
            Name "TransParentPreZ"
            Tags{"LightMode" = "TransParentPreZ"}
            ZWrite On    
            ColorMask 0

            HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
			struct a2v {
				float3 vertex : POSITION;
			};

			struct v2f {
				float4 pos : SV_POSITION;
			};

			v2f vert (a2v v)
			{
				v2f o;
				o.pos = TransformObjectToHClip(v.vertex);
				return o;
			}

			float4 frag (v2f i) : SV_Target
			{
				return 0;
			}
            ENDHLSL
        }

		Pass{
		Name "OpaquePreZ"
		Tags{"LightMode" = "OpaquePreZ"}
		ZWrite On
		ColorMask 0

		HLSLPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_instancing
		#include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
		struct a2v {
			float3 vertex : POSITION;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct v2f {
			float4 pos : SV_POSITION;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		v2f vert(a2v v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_TRANSFER_INSTANCE_ID(v,o);
			o.pos = TransformObjectToHClip(v.vertex);
			return o;
		}

		float4 frag(v2f i) : SV_Target
		{
			UNITY_SETUP_INSTANCE_ID(i);
			return 0;
		}
		ENDHLSL
		}
    }
}
