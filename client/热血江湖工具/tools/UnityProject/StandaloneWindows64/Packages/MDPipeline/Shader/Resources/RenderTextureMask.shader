Shader "MD/Standard/RenderTextureMask"
{
SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

        HLSLINCLUDE
        #include "../Library/Core.hlsl"

        ENDHLSL
        
        Pass
        {
            //Name "MaskColor"
            Tags { "LightMode" = "UniversalForward" }

            Cull Off

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
			{
				float4 positionOS   : POSITION;
				float2 uv           : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS   : SV_POSITION;
				float2 uv           : TEXCOORD0;
			};


            Varyings vert(Attributes input)
            {
                Varyings output;
				output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 frag(Varyings i): SV_Target
            {
                return float4(1, 1, 1, 1);
            }
            ENDHLSL

        }
       
    }
}
