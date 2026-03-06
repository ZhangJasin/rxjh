#ifndef _SHADERMACROS_H
    #define _SHADERMACROS_H


    #define PI          3.14159265358979323846
    #define TWO_PI      6.28318530717958647693
    #define FOUR_PI     12.5663706143591729538
    #define INV_PI      0.31830988618379067154
    #define INV_TWO_PI  0.15915494309189533577
    #define INV_FOUR_PI 0.07957747154594766788
    #define HALF_PI     1.57079632679489661923
    #define INV_HALF_PI 0.63661977236758134308
    #define LOG2_E      1.44269504088896340736

    #define FLT_INF  asfloat(0x7F800000)
    #define FLT_EPS  5.960464478e-8  // 2^-24, machine epsilon: 1 + EPS = 1 (half of the ULP for 1.0f)
    #define FLT_MIN  1.175494351e-38 // Minimum normalized positive floating-point number
    #define FLT_MAX  3.402823466e+38 // Maximum representable floating-point number
    #define HALF_EPS 4.8828125e-4    // 2^-11, machine epsilon: 1 + EPS = 1 (half of the ULP for 1.0f)
    #define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
    #define HALF_MAX 65504.0
    #define UINT_MAX 0xFFFFFFFFu

    #if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
        #define HAS_HALF 1
    #else
        #define HAS_HALF 0
    #endif

    #if HAS_HALF
        #define half min16float
        #define half2 min16float2
        #define half3 min16float3
        #define half4 min16float4
        #define half2x2 min16float2x2
        #define half2x3 min16float2x3
        #define half3x2 min16float3x2
        #define half3x3 min16float3x3
        #define half3x4 min16float3x4
        #define half4x3 min16float4x3
        #define half4x4 min16float4x4
    #endif

    // Target in compute shader are supported in 2018.2, for now define ours
    // (Note only 45 and above support compute shader)
    #ifdef  SHADER_STAGE_COMPUTE
        #   ifndef SHADER_TARGET
        #       if defined(SHADER_API_METAL)
        #       define SHADER_TARGET 45
        #       else
        #       define SHADER_TARGET 50
        #       endif
        #   endif
    #endif

    // ----------------------------------Include language header-------------------------------------------
#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (disable : 3205) // conversion of larger type to smaller
#endif

    //in fact, we only focus on mobile
    #if defined(SHADER_API_XBOXONE)
        #include "./API/XBoxOne.hlsl"
    #elif defined(SHADER_API_PSSL)
        #include "./API/PSSL.hlsl"
    #elif defined(SHADER_API_D3D11)
        #include "./API/D3D11.hlsl"
    #elif defined(SHADER_API_METAL)
        #include "./API/Metal.hlsl"
    #elif defined(SHADER_API_VULKAN)
        #include "./API/Vulkan.hlsl"
    #elif defined(SHADER_API_SWITCH)
        #include "./API/Switch.hlsl"
    #elif defined(SHADER_API_GLCORE)
        #include "./API/GLCore.hlsl"
    #elif defined(SHADER_API_GLES3)
        #include "./API/GLES3.hlsl"
    #elif defined(SHADER_API_GLES)
        #include "./API/GLES2.hlsl"
    #else
        #error unsupported shader api
    #endif
#if SHADER_API_MOBILE || SHADER_API_GLES || SHADER_API_GLES3
#pragma warning (enable : 3205) // conversion of larger type to smaller
#endif
    //-----------------------------------------------------------------------------------------------------

    //-------------------------------default flow control attributes---------------------------------------
    #ifndef UNITY_BRANCH
        #   define UNITY_BRANCH
    #endif
    #ifndef UNITY_FLATTEN
        #   define UNITY_FLATTEN
    #endif
    #ifndef UNITY_UNROLL
        #   define UNITY_UNROLL
    #endif
    #ifndef UNITY_UNROLLX
        #   define UNITY_UNROLLX(_x)
    #endif
    #ifndef UNITY_LOOP
        #   define UNITY_LOOP
    #endif
    //-----------------------------------------------------------------------------------------------------

    //to do: Macros.hlsl:48
    #define TRANSFORM_TEX(tex, name) ((tex.xy) * name##_ST.xy + name##_ST.zw)
    #define GET_TEXELSIZE_NAME(name) (name##_TexelSize)

    #if UNITY_REVERSED_Z
        # define COMPARE_DEVICE_DEPTH_CLOSER(shadowMapDepth, zDevice)      (shadowMapDepth >  zDevice)
        # define COMPARE_DEVICE_DEPTH_CLOSEREQUAL(shadowMapDepth, zDevice) (shadowMapDepth >= zDevice)
    #else
        # define COMPARE_DEVICE_DEPTH_CLOSER(shadowMapDepth, zDevice)      (shadowMapDepth <  zDevice)
        # define COMPARE_DEVICE_DEPTH_CLOSEREQUAL(shadowMapDepth, zDevice) (shadowMapDepth <= zDevice)
    #endif

    #if UNITY_REVERSED_Z
        #define DEPTH_DEFAULT_VALUE 1.0
        #define DEPTH_OP min
    #else
        #define DEPTH_DEFAULT_VALUE 0.0
        #define DEPTH_OP max
    #endif

    #define CUBEMAPFACE_POSITIVE_X 0
    #define CUBEMAPFACE_NEGATIVE_X 1
    #define CUBEMAPFACE_POSITIVE_Y 2
    #define CUBEMAPFACE_NEGATIVE_Y 3
    #define CUBEMAPFACE_POSITIVE_Z 4
    #define CUBEMAPFACE_NEGATIVE_Z 5



#endif