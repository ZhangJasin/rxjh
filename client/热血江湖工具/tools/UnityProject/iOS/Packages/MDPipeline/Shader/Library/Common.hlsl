#ifndef _SHADERCOMMON_H
    #define _SHADERCOMMON_H

    #include "Macros.hlsl"
	#include "Random.hlsl"

    SAMPLER(sampler_LinearClamp);
    SAMPLER(sampler_LinearRepeat);
    SAMPLER(sampler_PointClamp);
    SAMPLER(sampler_PointRepeat);

    #define PositivePow(base,power) pow(abs(base), power)

    half DegToRad(half deg)
    {
        return deg * (PI / 180.0);
    }

    half RadToDeg(half rad)
    {
        return rad * (180.0 / PI);
    }

    bool IsPower2(uint x)
    {
        return (x & (x - 1)) == 0;
    }

    half Pow4(half x)
    {
        return (x * x) * (x * x);
    }

    half max3(half a,half b, half c)
    {
        return max(a,max(b,c));
    }

    half min3(half a,half b, half c)
    {
        return min(a,min(b,c));
    }

    half LerpWhiteTo(half b, half t)
    {
        half oneMinusT = 1.0 - t;
        return oneMinusT + b * t;
    }

    #ifndef INTRINSIC_BITFIELD_INSERT
        // Inserts the bits indicated by 'mask' from 'src' into 'dst'.
        uint BitFieldInsert(uint mask, uint src, uint dst)
        {
            return (src & mask) | (dst & ~mask);
        }
    #endif

    // Composes a floating point value with the magnitude of 'x' and the sign of 's'.
    // See the comment about FastSign() below.
    float CopySign(float x, float s, bool ignoreNegZero = true)
    {
        #if !defined(SHADER_API_GLES)
            if (ignoreNegZero)
            {
                return (s >= 0) ? abs(x) : -abs(x);
            }
            else
            {
                uint negZero = 0x80000000u;
                uint signBit = negZero & asuint(s);
                return asfloat(BitFieldInsert(negZero, signBit, asuint(x)));
            }
        #else
            return (s >= 0) ? abs(x) : -abs(x);
        #endif
    }

    // Returns -1 for negative numbers and 1 for positive numbers.
    // 0 can be handled in 2 different ways.
    // The IEEE floating point standard defines 0 as signed: +0 and -0.
    // However, mathematics typically treats 0 as unsigned.
    // Therefore, we treat -0 as +0 by default: FastSign(+0) = FastSign(-0) = 1.
    // If (ignoreNegZero = false), FastSign(-0, false) = -1.
    // Note that the sign() function in HLSL implements signum, which returns 0 for 0.
    float FastSign(float s, bool ignoreNegZero = true)
    {
        return CopySign(1.0, s, ignoreNegZero);
    }

    void FastSinCos(float4 val, out float4 s)
    {
        val = val * 6.408849 - 3.1415927;
        float4 r5 = val * val;
        float4 r1 = r5 * val;
        float4 r2 = r1 * r5;
        float4 r3 = r2 * r5;
        float4 sin7 = { 1, -0.16161616, 0.0083333, -0.00019841 };
        s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
    }

    // The resource that is bound when binding a stencil buffer from the depth buffer is two channel. On D3D11 the stencil value is in the green channel,
    // while on other APIs is in the red channel. Note that on some platform, always using the green channel might work, but is not guaranteed.
    uint GetStencilValue(uint2 stencilBufferVal)
    {
        #if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE)
            return stencilBufferVal.y;
        #else
            return stencilBufferVal.x;
        #endif
    }

    float3 UnpackNormalRGBNoScale(float4 packedNormal)
    {
        return packedNormal.rgb * 2.0 - 1.0;//(0,1) -> (-1,1)
    }

    float3 UnpackNormalAG(float4 packedNormal, float scale = 1.0)
    {
        float3 normal;
        normal.xy = packedNormal.ag * 2.0 - 1.0;
        normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));

        // must scale after reconstruction of normal.z which also
        // mirrors UnpackNormalRGB(). This does imply normal is not returned
        // as a unit length vector but doesn't need it since it will get normalized after TBN transformation.
        // If we ever need to blend contributions with built-in shaders for URP
        // then we should consider using UnpackDerivativeNormalAG() instead like
        // HDRP does since derivatives do not use renormalization and unlike tangent space
        // normals allow you to blend, accumulate and scale contributions correctly.
        normal.xy *= scale;
        return normal;
    }

    // Unpack normal as DXT5nm (1, y, 0, x) or BC5 (x, y, 0, 1)
    float3 UnpackNormalmapRGorAG(float4 packedNormal, float scale = 1.0)
    {
        // Convert to (?, y, 0, x)
        packedNormal.a *= packedNormal.r;
        return UnpackNormalAG(packedNormal, scale);
    }

    float3 UnpackNormalRGB(float4 packedNormal, float scale = 1.0)
    {
        float3 normal;
        normal.xyz = packedNormal.rgb * 2.0 - 1.0;
        normal.xy *= scale;
        return normal;
    }

    float3 UnpackNormal(float4 packedNormal)
    {
        #if defined(UNITY_NO_DXT5nm)
            return UnpackNormalRGBNoScale(packedNormal);
        #else
            // Compiler will optimize the scale away
            return UnpackNormalmapRGorAG(packedNormal, 1.0);
        #endif
    }

    float3 UnpackNormalScale(float4 packedNormal, float scale)
    {
        #if defined(UNITY_NO_DXT5nm)
            return UnpackNormalRGB(packedNormal, scale);
        #else
            return UnpackNormalmapRGorAG(packedNormal, scale);
        #endif
    }

    float3 SafeNormalize(float3 dir)
    {
        float dp3 = max(FLT_MIN, dot(dir, dir));
        return dir * rsqrt(dp3);
    }

    float4x4 OptimizeProjectionMatrix(float4x4 M)
    {
        // Matrix format (x = non-constant value).
        // Orthographic Perspective  Combined(OR)
        // | x 0 0 x |  | x 0 x 0 |  | x 0 x x |
        // | 0 x 0 x |  | 0 x x 0 |  | 0 x x x |
        // | x x x x |  | x x x x |  | x x x x | <- oblique projection row
        // | 0 0 0 1 |  | 0 0 x 0 |  | 0 0 x x |
        // Notice that some values are always 0.
        // We can avoid loading and doing math with constants.
        M._21_41 = 0;
        M._12_42 = 0;
        return M;
    }

	void ClipLOD(float2 positionSS, float fade)
	{
#if defined(LOD_FADE_CROSSFADE)
		float dither = InterleavedGradientNoise(positionSS, 0);
		clip(fade + (fade <= 0.0 ? dither : -dither));
#endif
	}



// ----------------------------------------------------------------------------
//          Space transformations
// ----------------------------------------------------------------------------

    static const float3x3 k_identity3x3 = {1, 0, 0,
                                           0, 1, 0,
                                           0, 0, 1};

    static const float4x4 k_identity4x4 = {1, 0, 0, 0,
                                           0, 1, 0, 0,
                                           0, 0, 1, 0,
                                           0, 0, 0, 1};

    
    float4 ComputeClipSpacePosition(float2 positionNDC, float deviceDepth)
    {
        float4 positionCS = float4(positionNDC * 2.0 - 1.0, deviceDepth, 1.0);

    //#if UNITY_UV_STARTS_AT_TOP
    //    // Our world space, view space, screen space and NDC space are Y-up.
    //    // Our clip space is flipped upside-down due to poor legacy Unity design.
    //    // The flip is baked into the projection matrix, so we only have to flip
    //    // manually when going from CS to NDC and back.
    //    positionCS.y = -positionCS.y;
    //#endif
        return positionCS;
    }

    // Use case examples:
    // (position = positionCS) => (clipSpaceTransform = use default)
    // (position = positionVS) => (clipSpaceTransform = UNITY_MATRIX_P)
    // (position = positionWS) => (clipSpaceTransform = UNITY_MATRIX_VP)
    float4 ComputeClipSpacePosition(float3 position, float4x4 clipSpaceTransform = k_identity4x4)
    {
        return mul(clipSpaceTransform, float4(position, 1.0));
    }

    // The returned Z value is the depth buffer value (and NOT linear view space Z value).
    // Use case examples:
    // (position = positionCS) => (clipSpaceTransform = use default)
    // (position = positionVS) => (clipSpaceTransform = UNITY_MATRIX_P)
    // (position = positionWS) => (clipSpaceTransform = UNITY_MATRIX_VP)
    float3 ComputeNormalizedDeviceCoordinatesWithZ(float3 position, float4x4 clipSpaceTransform = k_identity4x4)
    {
        float4 positionCS = ComputeClipSpacePosition(position, clipSpaceTransform);

    //#if UNITY_UV_STARTS_AT_TOP
    //    // Our world space, view space, screen space and NDC space are Y-up.
    //    // Our clip space is flipped upside-down due to poor legacy Unity design.
    //    // The flip is baked into the projection matrix, so we only have to flip
    //    // manually when going from CS to NDC and back.
    //    positionCS.y = -positionCS.y;
    //#endif

        positionCS *= rcp(positionCS.w);
        positionCS.xy = positionCS.xy * 0.5 + 0.5;

        return positionCS.xyz;
    }

    // Use case examples:
    // (position = positionCS) => (clipSpaceTransform = use default)
    // (position = positionVS) => (clipSpaceTransform = UNITY_MATRIX_P)
    // (position = positionWS) => (clipSpaceTransform = UNITY_MATRIX_VP)
    float2 ComputeNormalizedDeviceCoordinates(float3 position, float4x4 clipSpaceTransform = k_identity4x4)
    {
        return ComputeNormalizedDeviceCoordinatesWithZ(position, clipSpaceTransform).xy;
    }

    float3 ComputeViewSpacePosition(float2 positionNDC, float deviceDepth, float4x4 invProjMatrix)
    {
        float4 positionCS = ComputeClipSpacePosition(positionNDC, deviceDepth);
        float4 positionVS = mul(invProjMatrix, positionCS);
        // The view space uses a right-handed coordinate system.
        positionVS.z = -positionVS.z;
        return positionVS.xyz / positionVS.w;
    }

    float3 ComputeWorldSpacePosition(float2 positionNDC, float deviceDepth, float4x4 invViewProjMatrix)
    {
        float4 positionCS  = ComputeClipSpacePosition(positionNDC, deviceDepth);
        float4 hpositionWS = mul(invViewProjMatrix, positionCS);
        return hpositionWS.xyz / hpositionWS.w;
    }

    float3 ComputeWorldSpacePosition(float4 positionCS, float4x4 invViewProjMatrix)
    {
        float4 hpositionWS = mul(invViewProjMatrix, positionCS);
        return hpositionWS.xyz / hpositionWS.w;
    }


    float PackR8G8B8A8To32(float4 rgba)
    {
        float r = floor(rgba.r * 255.0 + 0.5);
        float g = floor(rgba.g * 255.0 + 0.5);
        float b = floor(rgba.b * 255.0 + 0.5);
        float a = floor(rgba.a * 255.0 + 0.5);

        float packed = r * 16777216.0 + g * 65536.0 + b * 256.0 + a;
        return packed / 4294967295.0; // 2^32 - 1
    }

    float4 Unpack32ToR8G8B8A8(float f)
    {
        float expanded = f * 4294967295.0; // 2^32 - 1

        float r = floor(expanded / 16777216.0); // 2^24
        float g = floor((expanded - r * 16777216.0) / 65536.0); // 2^16
        float b = floor((expanded - r * 16777216.0 - g * 65536.0) / 256.0); // 2^8
        float a = floor(expanded - r * 16777216.0 - g * 65536.0 - b * 256.0);

        return float4(r, g, b, a) / 255.0;
    }

    float PackR8G8B8A8To24(float4 rgba)
    {
        float r_scaled = floor(rgba.r * 255.0);
        float g_scaled = floor(rgba.g * 255.0);
        float b_scaled = floor(rgba.b * 255.0);
    
        float packed = r_scaled * 65536.0 + g_scaled * 256.0 + b_scaled;
    
        return packed / 16777215.0;
    }
    
    float4 Unpack24ToR8G8B8A8(float f)
    {
        float expanded = 16777215.0 * f; // 2^24 - 1
    
        float r_expanded = floor(expanded / 65536.0); // 2^16
        float g_expanded = floor((expanded - r_expanded * 65536.0) / 256.0); // 2^8
        float b_expanded = floor(expanded - r_expanded * 65536.0 - g_expanded * 256.0);
        float a_expanded = 255.0;
    
        float r = r_expanded / 255.0;
        float g = g_expanded / 255.0;
        float b = b_expanded / 255.0;
        float a = a_expanded / 255.0;
    
        return float4(r, g, b, a);
    }

#endif