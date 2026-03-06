#ifndef DEBUG_PBR_INCLUDED
#define DEBUG_PBR_INCLUDED

struct FragmentCommonData
{
    //Metalness_Roughness
    float3 albedo;
    float metallic;

    //Specular

    float3 specular;
};

#define unity_PBRLowColor  half4(1.0f, 0.0f, 0.0f, 0.0f);
#define unity_PBRMiddleColor  half4(0.0f, 0.0f, 1.0f, 0.0f);

float _PBRWorkFlow;
float _isCartoon;

inline half4 Unity_pbrValidate(FragmentCommonData data)
{
    float3 albedo = data.albedo;
    float3 specular = data.specular;

    if (_PBRWorkFlow == 0)
    {
        //Metalness_Roughness 流程  
        half maxAlbedo = max(albedo.r, max(albedo.g, albedo.b));

        bool isMetal = data.metallic >= 0.7;

        if (!isMetal && _isCartoon == 0 && maxAlbedo < 0.031)
        {
            return unity_PBRLowColor;
        }
        
        if (isMetal)
        {
            if (maxAlbedo < 0.127)
            {
                return unity_PBRLowColor;
            }
            if (maxAlbedo > 0.127 && maxAlbedo < 0.456)
            {
                return unity_PBRMiddleColor;
            }
        }
        return half4(albedo, 1);
    }
    else
    {
        //Specular_Glossiness 流程  
        half maxSpec = max(specular.r, max(specular.g, specular.b));

        if (_isCartoon == 0 && maxSpec < 0.15)
        {
            return unity_PBRLowColor;
        }
        if (maxSpec > 0.294 && maxSpec < 0.607)
        {
            return unity_PBRLowColor;
        }

        return half4(specular, 1);
    }
}


#endif