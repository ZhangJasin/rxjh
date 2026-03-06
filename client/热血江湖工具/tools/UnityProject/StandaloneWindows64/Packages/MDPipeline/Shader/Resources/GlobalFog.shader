Shader "MD/Standard/GlobalFog"
{
    SubShader {
        Cull Off
        ZWrite Off
        ZTest Always

        HLSLINCLUDE
        #include "../Library/Core.hlsl"

        TEXTURE2D(_BlitTex);
        SAMPLER(sampler_BlitTex);
        float4 _BlitTex_TexelSize;
        
        sampler2D _MainTex;
        
		half4 _MainTex_TexelSize;
		half _FogDensity;
		half4 _FogColor;
		float _OceanLevel;
		float _FogStart;
		float _FogEnd;
		sampler2D _NoiseTex;
		half _FogXSpeed;
		half _FogYSpeed;
		half _NoiseAmount;
		float4x4 _FrustumCornersRay;
		float _NoiseSampleScale;
        float _NoiseOffset;
        TEXTURE2D(_NormalTex); SAMPLER(sampler_NormalTex);

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.pos = TransformObjectToHClip(v.vertex.xyz);
            o.uv = v.uv;
			o.uv_depth = v.uv;
            int index = 0;
			if (v.uv.x < 0.5 && v.uv.y < 0.5) {
				index = 0;
			} else if (v.uv.x > 0.5 && v.uv.y < 0.5) {
				index = 1;
			} else if (v.uv.x > 0.5 && v.uv.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}
			
            o.interpolatedRay = _FrustumCornersRay[index];
            return o;
        }
        
        half4 frag (v2f i) : SV_Target
        {
            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv_depth.xy);
            #ifndef UNITY_REVERSED_Z
               depth = depth* 0.5+0.5;
            #endif
			float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
            float3 worldPos = _WorldSpaceCameraPos + eyeDepth * i.interpolatedRay.xyz;
            float fogDensity = (_FogEnd - worldPos.z) / (_FogEnd - _FogStart);
            fogDensity = saturate(fogDensity * _FogDensity);
            half4 finalColor =  SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,i.uv);
            finalColor.rgba = lerp( _FogColor.rgba, finalColor.rgba, fogDensity);
            return finalColor;
        }
    
        
          half4 frag_RealDepth (v2f i) : SV_Target
        {
            float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uv_depth.xy);
			float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
            float3 worldPos = _WorldSpaceCameraPos + eyeDepth * i.interpolatedRay.xyz;
            if(worldPos.y < _OceanLevel) {  //低于海平面，计算与海平面的交点
                worldPos.xyz = lerp(worldPos,_WorldSpaceCameraPos,(_OceanLevel - worldPos.y)/(_WorldSpaceCameraPos.y - worldPos.y));
            }
            
            float2 speed = _Time.x * float2(_FogXSpeed, _FogYSpeed);
            
            float fogDensity = 0;
            //噪点计算
            if(abs(worldPos.x) < 1008611 && abs( worldPos.z) < 1008611)
            {
                float2 noiseSampleUV = float2(worldPos.x/8000 , worldPos.z / 8000);
                float noise = ( tex2D(_NoiseTex, noiseSampleUV * _NoiseSampleScale + speed).r +_NoiseOffset) ;
                float noise2 = ( tex2D(_NoiseTex, noiseSampleUV * _NoiseSampleScale * 2 + speed).r +_NoiseOffset) ;
                _FogEnd += (noise * 0.5 + noise2 * 0.25) * _NoiseAmount;
            }
            
            if(_WorldSpaceCameraPos.y < _OceanLevel){
                fogDensity = 0;
            }
            else if(_WorldSpaceCameraPos .y < _FogEnd){
                float y = _FogEnd - worldPos.y;
                if(y < 0) {
                    y =_WorldSpaceCameraPos.y - _FogEnd;
                    float3 viewDir = normalize(-i.interpolatedRay.xyz);
                    float xp = viewDir.x; 
                    float yp = viewDir.y;
                    float zp = viewDir.z;
                    float Lp = length(viewDir);
                    float L = Lp * y / yp;
                    float x = xp * L / Lp;
                    float z = zp * L / Lp;
                    fogDensity = length(float3(x,y,z));
                }
                else{

                    fogDensity = length(_WorldSpaceCameraPos - worldPos);

                }
            }
            else{
                float y = _FogEnd - worldPos.y;
                y = max(y,0);
                float3 viewDir = normalize(-i.interpolatedRay.xyz);
                float xp = viewDir.x; 
                float yp = viewDir.y;
                float zp = viewDir.z;
                float Lp = length(viewDir);
                float L = Lp * y / yp;
                float x = xp * L / Lp;
                float z = zp * L / Lp;
                //float3 realWorldPos = worldPos + float3(x,y,z);
                
                fogDensity = length(float3(x,y,z));
            }
            fogDensity =fogDensity / (_FogEnd - _FogStart) *_FogDensity;
            fogDensity = saturate(fogDensity);
            half4 finalColor =  SAMPLE_TEXTURE2D(_BlitTex,sampler_BlitTex,i.uv);
            finalColor.rgba = lerp(finalColor.rgba, _FogColor.rgba, fogDensity * _FogColor.a);
            return finalColor;
        }

        ENDHLSL

        Pass {  //普通版本
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            ENDHLSL
        }
        Pass {      //常用版本
            Blend One Zero
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag_RealDepth
            ENDHLSL
        }
    }
}
