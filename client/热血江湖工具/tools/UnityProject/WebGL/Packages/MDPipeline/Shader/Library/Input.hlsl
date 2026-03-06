#ifndef _INPUT_H
    #define _INPUT_H

    #include "Common.hlsl"
    #include "CustomInput.hlsl"

    //cbfr 参数定义, Unity2020.1.0a9 版本前只能这样了，computershader的后面keyword可行，MAXLIGHTPERCLUSTER很关键得约定死了
    #define XRES 32
    #define YRES 16
    #define ZRES 64
    #define MAXLIGHTPERCLUSTER 16   
    #define CLUSTERRATE 1.5

    half4 _GlossyEnvironmentColor;
    half4 _SubtractiveShadowColor;

    half4 _LightShadowData;
    float4 unity_ShadowFadeCenterAndDistance;

    float4 _ScaledScreenParams;

    float4 _MainLightPosition;
    half4 _MainLightColor;
    float4 _LightDirection;

    // Global object render pass data containing various settings.
    // x,y,z are currently unused
    // w is used for knowing whether the object is opaque(1) or alpha blended(0)
    half4 _DrawObjectPassData;

    // GLES3 causes a performance regression in some devices when using CBUFFER.
    half4 _AdditionalLightsCount;
//#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
//    StructuredBuffer<LightData> _AdditionalLightsBuffer;
//    StructuredBuffer<int> _AdditionalLightsIndices;
//#else

    #ifndef SHADER_API_GLES3
        CBUFFER_START(AdditionalLights)
    #endif
    float4 _AdditionalLightsPosition[MAX_VISIBLE_LIGHTS];
    half4 _AdditionalLightsColor[MAX_VISIBLE_LIGHTS];
    half4 _AdditionalLightsAttenuation[MAX_VISIBLE_LIGHTS];
    half4 _AdditionalLightsSpotDir[MAX_VISIBLE_LIGHTS];
   // half4 _AdditionalLightsOcclusionProbes[MAX_VISIBLE_LIGHTS];
    #ifndef SHADER_API_GLES3
        CBUFFER_END
    #endif
//#endif

    #define UNITY_MATRIX_M     unity_ObjectToWorld
    #define UNITY_MATRIX_I_M   unity_WorldToObject
    #define UNITY_MATRIX_V     unity_MatrixV
    #define UNITY_MATRIX_I_V   unity_MatrixInvV
    #define UNITY_MATRIX_P     OptimizeProjectionMatrix(glstate_matrix_projection)
    #define UNITY_MATRIX_I_P   ERROR_UNITY_MATRIX_I_P_IS_NOT_DEFINED
    #define UNITY_MATRIX_VP    unity_MatrixVP
    #define UNITY_MATRIX_I_VP  unity_MatrixInvVP
    #define UNITY_MATRIX_MV    mul(UNITY_MATRIX_V, UNITY_MATRIX_M)
    #define UNITY_MATRIX_T_MV  transpose(UNITY_MATRIX_MV)
    #define UNITY_MATRIX_IT_MV transpose(mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V))
    #define UNITY_MATRIX_MVP   mul(UNITY_MATRIX_VP, UNITY_MATRIX_M)

    //------------------------------------------UnityInput.hlsl--------------------------------------------
    // Time (t = time since current level load)
    float4 _Time; // (t/20, t, t*2, t*3)
    float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
    float4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
    float4 unity_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt
    float4 _TimeParameters; // t, sin(t), cos(t)

    float3 _WorldSpaceCameraPos;

    // x = 1 or -1 (-1 if projection is flipped)
    // y = near plane
    // z = far plane
    // w = 1/far plane
    float4 _ProjectionParams;

    // x = width
    // y = height
    // z = 1 + 1.0/width
    // w = 1 + 1.0/height
    float4 _ScreenParams;

    // Values used to linearize the Z buffer (http://www.humus.name/temp/Linearize%20depth.txt)
    // x = 1-far/near
    // y = far/near
    // z = x/far
    // w = y/far
    // or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1)
    // x = -1+far/near
    // y = 1
    // z = x/far
    // w = 1/far
    float4 _ZBufferParams;

    // x = orthographic camera's width
    // y = orthographic camera's height
    // z = unused
    // w = 1.0 if camera is ortho, 0.0 if perspective
    float4 unity_OrthoParams;
    float4 unity_CameraWorldClipPlanes[6];

    // Projection matrices of the camera. Note that this might be different from projection matrix
    // that is set right now, e.g. while rendering shadows the matrices below are still the projection
    // of original camera.
    float4x4 unity_CameraProjection;
    float4x4 unity_CameraInvProjection;
    float4x4 unity_WorldToCamera;
    float4x4 unity_CameraToWorld;

    // Block Layout should be respected due to SRP Batcher
    CBUFFER_START(UnityPerDraw)
    // Space block Feature
    float4x4 unity_ObjectToWorld;
    float4x4 unity_WorldToObject;
    float4 unity_LODFade; // x is the fade value ranging within [0,1]. y is x quantized into 16 levels
    float4 unity_WorldTransformParams; // w is usually 1.0, or -1.0 for odd-negative scale transforms

    // Light Indices block feature
    // These are set internally by the engine upon request by RendererConfiguration.
    float4 unity_LightData; // unity_LightData.z is 1 when not culled by the culling mask, otherwise 0.
    float4 unity_LightIndices[2];

  //  float4 unity_ProbesOcclusion; // unity_ProbesOcclusion.x is the mixed light probe occlusion data

    // Reflection Probe 0 block feature
    // HDR environment map decode instructions
    float4 unity_SpecCube0_HDR;

    // Lightmap block feature
    float4 unity_LightmapST;
    float4 unity_DynamicLightmapST;

    // SH block feature
    half4 unity_SHAr;
    half4 unity_SHAg;
    half4 unity_SHAb;
    half4 unity_SHBr;
    half4 unity_SHBg;
    half4 unity_SHBb;
    half4 unity_SHC;
    CBUFFER_END

    float4 unity_FogParams;
    float4  unity_FogColor;

    float4 glstate_lightmodel_ambient;
    float4 unity_AmbientSky;
    float4 unity_AmbientEquator;
    float4 unity_AmbientGround;
    float4 unity_IndirectSpecColor;

    float4x4 glstate_matrix_projection;
    float4x4 unity_MatrixV;
    float4x4 unity_MatrixInvV;
    float4x4 unity_MatrixVP;
    float4x4 unity_MatrixInvVP;
    float4 unity_StereoScaleOffset;
    int unity_StereoEyeIndex;

    half4 unity_ShadowColor;

    float4x4 FarClipMatrixVP;//远裁剪

    //-------Unity specific----------------------------------------------------------------
    TEXTURECUBE(unity_SpecCube0);
    SAMPLER(samplerunity_SpecCube0);
    // Main lightmap
    TEXTURE2D(unity_Lightmap);
    SAMPLER(samplerunity_Lightmap);
    // Dual or directional lightmap (always used with unity_Lightmap, so can share sampler)
    TEXTURE2D(unity_LightmapInd);
    SAMPLER(samplerunity_LightmapInd);
    // We can have shadowMask only if we have lightmap, so no sampler
    TEXTURE2D(unity_ShadowMask);

     #ifdef LIGHTMAP_ON_BATCHRENDERGROUP
            //float4 unity_LightmapST_BRG;
            // float4 unity_LightmapST_BRG[1023];
            StructuredBuffer<float4> _LightmapSTBuffer;
            float unity_LightmapST_BRG_Offset;
            TEXTURE2D(unity_Lightmap_BRG); SAMPLER(samplerunity_Lightmap_BRG);
            TEXTURE2D(unity_LightmapInd_BRG);
            TEXTURE2D(unity_ShadowMask_BRG);
    #endif

    SAMPLER(samplerunity_ShadowMask);
    float4x4 _PrevViewProjMatrix;
    float4x4 _ViewProjMatrix;
    float4x4 _NonJitteredViewProjMatrix;
    float4x4 _ViewMatrix;
    float4x4 _ProjMatrix;
    float4x4 _InvViewProjMatrix;
    float4x4 _InvViewMatrix;
    float4x4 _InvProjMatrix;
    float4   _InvProjParam;
    float4   _ScreenSize;       // {w, h, 1/w, 1/h}
    float4   _FrustumPlanes[6]; // {(a, b, c) = N, d = -dot(N, P)} [L, R, T, B, N, F]

    #ifdef CAMERA_RELATIVE_RENDERING
    float4x4  relative_MinusCameraMatrix;
    float4x4 relative_AddCameraMatrix;
    #endif

    // 大世界坐标偏移
    float3 _WorldBasePosition;
#endif