Shader "TCFramework/SimpleLit"
{
    Properties
    {
    }
    SubShader
    {
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "../Library/Core.hlsl"

            struct Attributes
            {
                float3 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
	            float3 positionWS   : VAR_POSITION;
	            float3 normalWS     : VAR_NORMAL;
                half3 ambient       : VAR_AMBIENT;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
	            output.positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(output.positionWS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.ambient = SampleSHVertex(output.normalWS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                SurfaceInput surface;
                surface.smoothness = 0;
                surface.metallic = 0;
                surface.occlusion = 1;
                surface.albedo = 1;
                surface.worldPos = input.positionWS;
                surface.worldNormal = input.normalWS;
                surface.ambientOrLightmapUV = float4(input.ambient, 0);

                half3 col = Toon_PBS(surface);
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
