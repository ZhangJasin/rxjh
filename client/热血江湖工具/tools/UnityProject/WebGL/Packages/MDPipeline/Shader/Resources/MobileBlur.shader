Shader "Hidden/FastBlur" {
	Properties {
		_AddAlpha("AddAlpha" , int) = 0
	}
	SubShader {
	    ZTest Off Cull Off ZWrite Off Blend Off

	    HLSLINCLUDE

	    #include "../Library/Core.hlsl"

		TEXTURE2D(_BlitTex);
        SAMPLER(sampler_BlitTex);
        float4 _BlitTex_TexelSize;
		uniform half4 _Parameter;
		int _AddAlpha;

        struct appdata
        {
            float4 vertex : POSITION;
            float2 texcoord : TEXCOORD0;
        };

		struct v2f_tap
		{
			float4 pos : SV_POSITION;
			half2 uv20 : TEXCOORD0;
			half2 uv21 : TEXCOORD1;
			half2 uv22 : TEXCOORD2;
			half2 uv23 : TEXCOORD3;
		};			

		v2f_tap vert4Tap ( appdata v )
		{
			v2f_tap o;

			o.pos = TransformObjectToHClip (v.vertex.xyz);
        	o.uv20 = v.texcoord + _BlitTex_TexelSize.xy;				
			o.uv21 = v.texcoord + _BlitTex_TexelSize.xy * half2(-0.5h,-0.5h);	
			o.uv22 = v.texcoord + _BlitTex_TexelSize.xy * half2(0.5h,-0.5h);		
			o.uv23 = v.texcoord + _BlitTex_TexelSize.xy * half2(-0.5h,0.5h);		

			return o; 
		}					
		
		half4 fragDownsample ( v2f_tap i ) : SV_Target
		{				
			half4 color = SAMPLE_TEXTURE2D (_BlitTex, sampler_BlitTex, i.uv20);
			color += SAMPLE_TEXTURE2D (_BlitTex, sampler_BlitTex, i.uv21);
			color += SAMPLE_TEXTURE2D (_BlitTex, sampler_BlitTex, i.uv22);
			color += SAMPLE_TEXTURE2D (_BlitTex, sampler_BlitTex, i.uv23);
			color = color / 4;
			color.a = color.a + _AddAlpha;
			return color;
		}					
	
		// weight curves

		static const half curve[7] = { 0.0205, 0.0855, 0.232, 0.324, 0.232, 0.0855, 0.0205 };  // gauss'ish blur weights

		static const half4 curve4[7] = { half4(0.0205,0.0205,0.0205,0), half4(0.0855,0.0855,0.0855,0), half4(0.232,0.232,0.232,0),
			half4(0.324,0.324,0.324,1), half4(0.232,0.232,0.232,0), half4(0.0855,0.0855,0.0855,0), half4(0.0205,0.0205,0.0205,0) };

		struct v2f_withBlurCoords8 
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 offs : TEXCOORD1;
		};	
		
		struct v2f_withBlurCoordsSGX 
		{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half4 offs[3] : TEXCOORD1;
		};

		v2f_withBlurCoords8 vertBlurHorizontal (appdata v)
		{
			v2f_withBlurCoords8 o;
			o.pos = TransformObjectToHClip (v.vertex.xyz);
			
			o.uv = half2(v.texcoord.xy);
			o.offs = half2(_BlitTex_TexelSize.x * _Parameter.x, 0.0);

			return o; 
		}
		
		v2f_withBlurCoords8 vertBlurVertical (appdata v)
		{
			v2f_withBlurCoords8 o;
			o.pos = TransformObjectToHClip (v.vertex.xyz);
			
			o.uv = half2(v.texcoord.xy);
			o.offs = half2(0.0, _BlitTex_TexelSize.y * _Parameter.x) ;
			 
			return o; 
		}	

		half4 fragBlur8 ( v2f_withBlurCoords8 i ) : SV_Target
		{
			half2 uv = i.uv.xy; 
			half2 netFilterWidth = i.offs;  
			half2 coords = uv - netFilterWidth * 3.0;  
			
			half4 color = 0;
  			for( int l = 0; l < 7; l++ )  
  			{   
				half4 tap = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, coords);
				color += tap * curve4[l];
				coords += netFilterWidth;
  			}
			color.a = color.a + _AddAlpha;
			return color;
		}

		v2f_withBlurCoordsSGX vertBlurHorizontalSGX (appdata v)
		{
			v2f_withBlurCoordsSGX o;
			o.pos = TransformObjectToHClip (v.vertex.xyz);
			
			o.uv = v.texcoord.xy;
			half2 netFilterWidth = _BlitTex_TexelSize.xy * half2(1.0, 0.0) * _Parameter.x; 
			half4 coords = -netFilterWidth.xyxy * 3.0;
			
			o.offs[0] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
			coords += netFilterWidth.xyxy;
			o.offs[1] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
			coords += netFilterWidth.xyxy;
			o.offs[2] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);

			return o; 
		}		
		
		v2f_withBlurCoordsSGX vertBlurVerticalSGX (appdata v)
		{
			v2f_withBlurCoordsSGX o;
			o.pos = TransformObjectToHClip (v.vertex.xyz);
			
			o.uv = half4(v.texcoord.xy,1,1);
			half2 netFilterWidth = _BlitTex_TexelSize.xy * half2(0.0, 1.0) * _Parameter.x;
			half4 coords = -netFilterWidth.xyxy * 3.0;
			
			o.offs[0] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
			coords += netFilterWidth.xyxy;
			o.offs[1] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);
			coords += netFilterWidth.xyxy;
			o.offs[2] = v.texcoord.xyxy + coords * half4(1.0h,1.0h,-1.0h,-1.0h);

			return o; 
		}	

		half4 fragBlurSGX ( v2f_withBlurCoordsSGX i ) : SV_Target
		{
			half2 uv = i.uv.xy;
			
			half4 color = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.uv) * curve4[3];
			
  			for( int l = 0; l < 3; l++ )  
  			{   
				half4 tapA = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.offs[l].xy);
				half4 tapB = SAMPLE_TEXTURE2D(_BlitTex, sampler_BlitTex, i.offs[l].zw); 
				color += (tapA + tapB) * curve4[l];
  			}
			color.a = color.a + _AddAlpha;

			return color;

		}	

         
        struct v2f
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        v2f vert (appdata v)
        {
            v2f o;
            o.pos = TransformObjectToHClip(v.vertex.xyz);
            o.uv = v.texcoord;
            return o;
        }
        float4 frag (v2f i) : SV_Target
        {
            float4 col = SAMPLE_TEXTURE2D(_BlitTex, sampler_LinearClamp, i.uv);
            return col;
        }
					
	ENDHLSL
	
	

	// 0
	Pass { 
	
		HLSLPROGRAM
		
		#pragma vertex vert4Tap
		#pragma fragment fragDownsample
		
		ENDHLSL
		 
		}

	// 1
	Pass {
		ZTest Always
		Cull Off
		
		HLSLPROGRAM 
		
		#pragma vertex vertBlurVertical
		#pragma fragment fragBlur8
		
		ENDHLSL 
		}	
		
	// 2
	Pass {		
		ZTest Always
		Cull Off
				
		HLSLPROGRAM
		
		#pragma vertex vertBlurHorizontal
		#pragma fragment fragBlur8
		
		ENDHLSL
		}	

	// alternate blur
	// 3
	Pass {
		ZTest Always
		Cull Off
		
		HLSLPROGRAM 
		
		#pragma vertex vertBlurVerticalSGX
		#pragma fragment fragBlurSGX
		
		ENDHLSL
		}	
		
	// 4
	Pass {		
		ZTest Always
		Cull Off
				
		HLSLPROGRAM
		
		#pragma vertex vertBlurHorizontalSGX
		#pragma fragment fragBlurSGX
		
		ENDHLSL
		}	

        
    // 5 Blitback
	Pass {		
		ZTest Always
		Cull Off
				
		HLSLPROGRAM
		
		#pragma vertex vert
		#pragma fragment frag
		
		ENDHLSL
		}

	}	

	FallBack Off
}
