#ifndef _SPACETRANSFORM_H
    #define _SPACETRANSFORM_H

    #include "Instancing.hlsl"

    float4x4 GetObjectToWorldMatrix()
    {
        return UNITY_MATRIX_M;
    }

    float4x4 GetWorldToHClipMatrix()
    {
        return UNITY_MATRIX_VP;
    }

    float4x4 GetViewToHClipMatrix()
    {
        return UNITY_MATRIX_P;
    }

    float4x4 GetWorldToViewMatrix()
    {
        return UNITY_MATRIX_V;
    }


    float3 TransformObjectToWorld(float4 vertex)
    {
        return mul(UNITY_MATRIX_M, vertex).xyz;
    }

    float3 TransformObjectToWorld(float3 vertex)//兼容URP...
    {
        return mul(UNITY_MATRIX_M, float4(vertex,1.0)).xyz;
    }

    float3 TransformWorldToObject(float3 worldPos)
    {
        return mul(UNITY_MATRIX_I_M, float4(worldPos, 1.0)).xyz;
    }

    float3 TransformWorldToView(float3 worldPos)
    {
        return mul(UNITY_MATRIX_V, float4(worldPos, 1.0)).xyz;
    }
    //useCameraRelativeRendering--------------------
    float4 TransformObjectToHClip(float3 vertex)
    {
       #if CAMERA_RELATIVE_RENDERING
            float4x4 objectToWorld = mul(relative_MinusCameraMatrix, UNITY_MATRIX_M); 
            float4 relativeWPos = mul(objectToWorld, float4(vertex.xyz, 1.0)); // 相对相机坐标
            float4x4 worldToClip = mul(UNITY_MATRIX_VP, relative_AddCameraMatrix);
            float4 clipPos = mul(worldToClip, relativeWPos);//转回去
            return clipPos;
        #else
            return mul(UNITY_MATRIX_VP, mul(UNITY_MATRIX_M, float4(vertex.xyz, 1.0)));
        #endif

    }
    float4 TransformObjectToWorldRS(float3 vertex)//relativeSpace
    {
        #if CAMERA_RELATIVE_RENDERING
            float4x4 objectToWorld = mul(relative_MinusCameraMatrix, UNITY_MATRIX_M); 
            float4 relativeWPos = mul(objectToWorld, float4(vertex.xyz, 1.0)); // 相对相机坐标
            return relativeWPos;
        #else
            return mul(UNITY_MATRIX_M, float4(vertex,1.0));
        #endif
    } 
    float4 TransformWorldToHClipRS(float4 worldPos)//relativeSpace
    {
        #if CAMERA_RELATIVE_RENDERING
            float4x4 worldToClip = mul(UNITY_MATRIX_VP, relative_AddCameraMatrix);
            float4 clipPos = mul(worldToClip, worldPos);//转回去
            return clipPos;
        #else
            return mul(UNITY_MATRIX_VP, float4(worldPos.xyz, 1.0));
        #endif
    }

    float4 TransformWorldToHClip(float3 worldPos)
    {
        return mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
    }

    float4 TransformViewToHClip(float3 positionVS)
    {
        return mul(UNITY_MATRIX_P, float4(positionVS, 1.0));
    }

float3 TransformObjectToWorldDir(float3 dirOS, bool doNormalize = true)
    {
    float3 dirWS = mul((float3x3) UNITY_MATRIX_M, dirOS);
    if (doNormalize)
        return SafeNormalize(dirWS);

    return dirWS;
        //return mul((float3x3)UNITY_MATRIX_M, dir);
    }
float3 TransformWorldToObjectDir(float3 dirWS, bool doNormalize = true)
{
    float3 dirOS = mul((float3x3) UNITY_MATRIX_I_M, dirWS);
    if (doNormalize)
        return normalize(dirOS);

    return dirOS;
}
    //float3 TransformWorldToObjectDir(float3 dir)
    //{
    //    return  mul((float3x3)UNITY_MATRIX_I_M, dir);
    //}

    float3 TransformWorldToViewDir(float3 dir)
    {
        return mul((float3x3)UNITY_MATRIX_V, dir).xyz;
    }

    float3 TransformWorldToHClipDir(float3 dir)
    {
        return mul((float3x3)UNITY_MATRIX_VP, dir).xyz;
    }

float3 TransformObjectToWorldNormal(float3 normalOS, bool doNormalize = true)
    {
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return TransformObjectToWorldDir(normalOS, doNormalize);
#else
    // Normal need to be multiply by inverse transpose
    float3 normalWS = mul(normalOS, (float3x3) UNITY_MATRIX_I_M);
    if (doNormalize)
        return SafeNormalize(normalWS);

    return normalWS;
#endif
        //return mul(normal, (float3x3)UNITY_MATRIX_I_M);// Normal need to be multiply by inverse transpose
    }

float3 TransformWorldToObjectNormal(float3 normalWS, bool doNormalize = true)
    {
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return TransformWorldToObjectDir(normalWS, doNormalize);
#else
    // Normal need to be multiply by inverse transpose
    float3 normalOS = mul(normalWS, (float3x3) UNITY_MATRIX_M);
    if (doNormalize)
        return SafeNormalize(normalOS);

    return normalOS;
#endif
        //return mul(worldNormal, (float3x3)UNITY_MATRIX_M);// Normal need to be multiply by inverse transpose
    }

    inline float3 UnityWorldSpaceViewDir(float3 worldPos){
        return _WorldSpaceCameraPos - worldPos;
    }

    inline float3 UnityWorldSpaceLightDir(float3 worldPos){
        return _MainLightPosition.xyz;//to do
    }

    inline float3 ObjSpaceLightDir(half3 lightDir){
        return TransformWorldToObjectDir(lightDir);
    }

    inline float3 ObjSpaceViewDir(in float4 vertex)
    {
        float3 objSpaceCameraPos = TransformWorldToObject(_WorldSpaceCameraPos.xyz).xyz;
        return objSpaceCameraPos - vertex.xyz;
    }
    
    float3 UnityObjectToViewPos(in float3 pos) // overload for float4; avoids "implicit truncation" warning for existing shaders
    {
        return mul(UNITY_MATRIX_V, mul(UNITY_MATRIX_M, float4(pos,1.0))).xyz;
    }

    float4 UnityObjectToViewPos(float4 pos) // overload for float4; avoids "implicit truncation" warning for existing shaders
    {
        return mul(UNITY_MATRIX_V, mul(UNITY_MATRIX_M, pos));
    }

#endif