Shader "Hidden/ScreenSpaceShadowmap"
{   Properties {
        //[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        //[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
        }
    SubShader
    {
        Cull Off
        ZWrite Off
        Blend One One
        BlendOp  Min
       // Blend [_SrcBlend] [_DstBlend]
        Pass
		{
			Name "Resolve"

			HLSLPROGRAM
			#pragma vertex ResolvePassVertex
			#pragma fragment ResolvePassFragment
			#pragma multi_compile_instancing
			#include "../Library/Core.hlsl"
			#include "../Library/Instancing.hlsl"

			struct Attributes
			{
				float3 positionOS : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
				UNITY_DEFINE_INSTANCED_PROP(float4x4, _PerObjectWorldToUVMatrix)
				UNITY_DEFINE_INSTANCED_PROP(float4, _PerObjectSliceUVOffsetExtend) // todo: use it!
			UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

			// todo: find a way to support both srp batcher and gpu instancing

			// set in material inspector.
			half _PerObjectSSShadowBias;

			half4 _PerObjectShadowAtlasTexelSize; // xy: texel size, zw: not used.

			TEXTURE2D_SHADOW(_PerObjectShadowMap);
			SAMPLER_CMP(sampler_PerObjectShadowMap);

            const half4 shadowOffset0 = half4(-0.5, -0.5, 0, 0);
			const half4 shadowOffset1 = half4(0.5, -0.5, 0, 0);
			const half4 shadowOffset2 = half4(-0.5, 0.5, 0, 0);
			const half4 shadowOffset3 = half4(0.5, 0.5, 0, 0);


			Varyings ResolvePassVertex (Attributes input) 
			{
				Varyings output = (Varyings)0; // todo: should we use ZERO_INITIALIZE?

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);

				//float3 positionWS = TransformObjectToWorld(input.positionOS);
				//output.positionHCS = TransformWorldToHClip(positionWS);

			    output.positionHCS = TransformObjectToHClip(input.positionOS);

				return output;
			}

            half4 ResolvePassFragment(Varyings input) : SV_TARGET
            {
            
				UNITY_SETUP_INSTANCE_ID(input);

				// screen-space uv
				float2 uv = input.positionHCS.xy / _ScaledScreenParams.xy ;

				//float z = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
                float z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv.xy);

                #if !UNITY_REVERSED_Z
                    z = z* 2.0 -1.0;
                #endif
                
				// ComputeWorldSpacePosition from Common.hlsl
				float3 sceneWorldPos = ComputeWorldSpacePosition(uv, z, UNITY_MATRIX_I_VP);

				float3 shadowCoords = mul(UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _PerObjectWorldToUVMatrix), float4(sceneWorldPos, 1.0)).xyz;

				float4 wrap = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _PerObjectSliceUVOffsetExtend);

#if UNITY_UV_STARTS_AT_TOP
				// shadowCoords.y = 1 - shadowCoords.y; // error: slice not occupying whole v-axis
				shadowCoords.y = wrap.y + wrap.y + wrap.w - shadowCoords.y;
#endif

				//// discard sample outside range
				//// todo: performance? branch / pre-z
				
				if (shadowCoords.x < wrap.x || shadowCoords.x > wrap.x + wrap.z || shadowCoords.y < wrap.y || shadowCoords.y > wrap.y + wrap.w) {
					return 1;
				}

				// cmp compensation
                #if UNITY_REVERSED_Z
                    shadowCoords.z = max(shadowCoords.z, 0.00001);
                #else
                    shadowCoords.z = max(shadowCoords.z, -1);
                #endif
				
#if UNITY_REVERSED_Z
                    shadowCoords.z += _PerObjectSSShadowBias;// + _ShadowBias;  for DX, //todo: test opengl, remove hard-coded bias
#else
                    shadowCoords.z -= _PerObjectSSShadowBias;
#endif
              
				//float shadow = SampleShadow(shadowCoords);

                ShadowSamplingData shadowSamplingData;
                // shadowOffsets are used in SampleShadowmapFiltered #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
                shadowSamplingData.shadowOffset0 = shadowOffset0;
                shadowSamplingData.shadowOffset1 = shadowOffset1;
                shadowSamplingData.shadowOffset2 = shadowOffset2;
                shadowSamplingData.shadowOffset3 = shadowOffset3;
                // shadowmapSize is used in SampleShadowmapFiltered for other platforms
                shadowSamplingData.shadowmapSize = _PerObjectShadowAtlasTexelSize;

                float shadow = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_PerObjectShadowMap, sampler_PerObjectShadowMap),float4(shadowCoords,1), shadowSamplingData);

                // return half4(0,0,0, shadow);
				// float4 _ShadowColor = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _ShadowColor);
				return shadow;
			}

			ENDHLSL

		}

        //blit
        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "../Library/Core.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            TEXTURE2D(_BlitTex);
		    SAMPLER(sampler_BlitTex);

            TEXTURE2D(_PerObjectShadowMap);
		    SAMPLER(sampler_PerObjectShadowMap);
            

            Varyings vert(Attributes i) 
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(i.positionOS);
                o.uv = i.uv;
                return o;
            }

            float4 TransformWorldToShadowCoordCascade(float4 worldPos)
            {
                half cascadeIndex = ComputeCascadeIndex(worldPos.xyz);
                float4 finalCoord = mul(_MainLightWorldToShadow[cascadeIndex], worldPos);
                finalCoord.z /= finalCoord.w;
                //finalCoord.w = cascadeIndex;//¥Êindex∫Û√Ê”√
                return finalCoord;
            }

            
            float4 ComputeWorldSpacePositionCS(float2 positionNDC, float deviceDepth, float4x4 invViewProjMatrix)
            {
                float4 positionCS  = ComputeClipSpacePosition(positionNDC, deviceDepth);
                float4 hpositionWS = mul(invViewProjMatrix, positionCS);
                hpositionWS /=  hpositionWS.w;
                return hpositionWS;
            }


            half4 frag(Varyings i) : SV_TARGET
            {

            	float2 uv = i.positionHCS.xy / _ScaledScreenParams.xy ;
                //float2 uv = i.uv.xy ;

				//float z = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uv).r;
                float z = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv.xy);

                #if !UNITY_REVERSED_Z
                    z = z* 2 -1;
                #endif

                float4 sceneWorldPos = ComputeWorldSpacePositionCS(uv.xy , z, unity_MatrixInvVP);

                float4 shadowCoords = TransformWorldToShadowCoordCascade(sceneWorldPos);
                //ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                //half4 shadowParams = GetMainLightShadowParams();
                //return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), coords, shadowSamplingData, shadowParams, false);

               // return shadowCoords.z;
                ShadowSamplingData shadowSamplingData;
                // shadowOffsets are used in SampleShadowmapFiltered #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
                shadowSamplingData.shadowOffset0 = _MainLightShadowOffset0;
                shadowSamplingData.shadowOffset1 = _MainLightShadowOffset1;
                shadowSamplingData.shadowOffset2 = _MainLightShadowOffset2;
                shadowSamplingData.shadowOffset3 = _MainLightShadowOffset3;
                // shadowmapSize is used in SampleShadowmapFiltered for other platforms
                shadowSamplingData.shadowmapSize = _MainLightShadowmapSize;
                float shadow = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoords, shadowSamplingData);

                //float shadow = sampleMainLight(shadowCoords);
            //    float shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoords.xyz);

                return (shadowCoords.z <= 0.0 || shadowCoords.z >= 1.0) ? 1.0 : shadow;
            }

            ENDHLSL
        }
    }
}
