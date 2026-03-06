#ifndef _COLOR_H
    #define _COLOR_H

    #include "ACES.hlsl"

    #define USE_PRECISE_LOGC 0
    struct ParamsLogC
    {
        half cut;
        half a, b, c, d, e, f;
    };
    static const ParamsLogC LogC =
    {
        0.011361, // cut
        5.555556, // a
        0.047996, // b
        0.244161, // c
        0.386036, // d
        5.301883, // e
        0.092819  // f
    };

    //让颜色看起来偏卡通
    half3 ToonColorMapping(half3 col,half param)
    {
        half3 c = col * param;
        return (c / (c + (half3)(0.187))) * 1.03499996662139892578125;
    }

    inline half3 Gamma20ToLinear(half3 c)
    {
        return c.rgb * c.rgb;
    }

    half3 LinearToGamma20(half3 c)
    {
        return sqrt(c.rgb);
    }

    half3 Gamma22ToLinear(half3 c)
    {
        return PositivePow(c.rgb, (half3)(2.2));
    }

    half3 LinearToGamma22(half3 c)
    {
        return PositivePow(c.rgb, (half3)(0.454545454545455));
    }

    half3 SRGBToLinear(half3 c)
    {
        //half3 linearRGBLo  = c / 12.92;
        //half3 linearRGBHi  = PositivePow((c + 0.055) / 1.055, half3(2.4, 2.4, 2.4));
        //half3 linearRGB    = (c <= 0.04045) ? linearRGBLo : linearRGBHi;
        //return linearRGB;

        // 0.04045以下的太黑了，忽略掉了
        half3 linearRGB  = (c < 1.0) ? PositivePow((c + 0.055) / 1.055, half3(2.4, 2.4, 2.4)) : PositivePow(c, half3(2.2, 2.2, 2.2));
        return linearRGB;
    }

    half3 LinearToSRGB(half3 c)
    {
        half3 sRGBLo = c * 12.92;
        half3 sRGBHi = (PositivePow(c, half3(1.0/2.4, 1.0/2.4, 1.0/2.4)) * 1.055) - 0.055;
        half3 sRGB   = (c <= 0.0031308) ? sRGBLo : sRGBHi;
        return sRGB;
    }

    half3 FastSRGBToLinear(half3 c)
    {
        return c * (c * (c * 0.305306011 + 0.682171111) + 0.012522878);
    }

    half3 FastLinearToSRGB(half3 c)
    {
        return saturate(1.055 * PositivePow(c, 0.416666667) - 0.055);
    }

    half3 GetSRGBToLinear(half3 c)
    {
        #if _USE_FAST_SRGB_LINEAR_CONVERSION
            return FastSRGBToLinear(c);
        #else
            return SRGBToLinear(c);
        #endif
    }

    half3 GetLinearToSRGB(half3 c)
    {
        #if _USE_FAST_SRGB_LINEAR_CONVERSION
            return FastLinearToSRGB(c);
        #else
            return LinearToSRGB(c);
        #endif
    }

    half3 FastTonemap(half3 c)
    {
        return c * rcp(max3(c.r, c.g, c.b) + 1.0);
    }

    half3 FastTonemapInvert(half3 c)
    {
        return c * rcp(1.0 - max3(c.r, c.g, c.b));
    }
    // Filmic tonemapping (ACES fitting, unless TONEMAPPING_USE_FULL_ACES is set to 1)
    // Input is ACES2065-1 (AP0 w/ linear encoding)
    #define TONEMAPPING_USE_FULL_ACES 0
    float3 AcesTonemap(float3 aces)
    {
        #if TONEMAPPING_USE_FULL_ACES
            float3 oces = RRT(aces);
            float3 odt = ODT_RGBmonitor_100nits_dim(oces);
            return odt;
        #else
            // --- Glow module --- //
            float saturation = rgb_2_saturation(aces);
            float ycIn = rgb_2_yc(aces);
            float s = sigmoid_shaper((saturation - 0.4) / 0.2);
            float addedGlow = 1.0 + glow_fwd(ycIn, RRT_GLOW_GAIN * s, RRT_GLOW_MID);
            aces *= addedGlow;
            // --- Red modifier --- //
            float hue = rgb_2_hue(aces);
            float centeredHue = center_hue(hue, RRT_RED_HUE);
            float hueWeight;
            {
                //hueWeight = cubic_basis_shaper(centeredHue, RRT_RED_WIDTH);
                hueWeight = smoothstep(0.0, 1.0, 1.0 - abs(2.0 * centeredHue / RRT_RED_WIDTH));
                hueWeight *= hueWeight;
            }
            aces.r += hueWeight * saturation * (RRT_RED_PIVOT - aces.r) * (1.0 - RRT_RED_SCALE);
            // --- ACES to RGB rendering space --- //
            float3 acescg = max(0.0, ACES_to_ACEScg(aces));
            // --- Global desaturation --- //
            //acescg = mul(RRT_SAT_MAT, acescg);
            acescg = lerp(dot(acescg, AP1_RGB2Y).xxx, acescg, RRT_SAT_FACTOR.xxx);
            // Luminance fitting of *RRT.a1.0.3 + ODT.Academy.RGBmonitor_100nits_dim.a1.0.3*.
            // https://github.com/colour-science/colour-unity/blob/master/Assets/Colour/Notebooks/CIECAM02_Unity.ipynb
            // RMSE: 0.0012846272106
            #if defined(SHADER_API_SWITCH) // Fix floating point overflow on extremely large values.
                const float a = 2.785085 * 0.01;
                const float b = 0.107772 * 0.01;
                const float c = 2.936045 * 0.01;
                const float d = 0.887122 * 0.01;
                const float e = 0.806889 * 0.01;
                float3 x = acescg;
                float3 rgbPost = ((a * x + b)) / ((c * x + d) + e/(x + FLT_MIN));
            #else
                const float a = 2.785085;
                const float b = 0.107772;
                const float c = 2.936045;
                const float d = 0.887122;
                const float e = 0.806889;
                float3 x = acescg;
                float3 rgbPost = (x * (a * x + b)) / (x * (c * x + d) + e);
            #endif
            // Scale luminance to linear code value
            // float3 linearCV = Y_2_linCV(rgbPost, CINEMA_WHITE, CINEMA_BLACK);

            // Apply gamma adjustment to compensate for dim surround
            float3 linearCV = darkSurround_to_dimSurround(rgbPost);

            // Apply desaturation to compensate for luminance difference
            //linearCV = mul(ODT_SAT_MAT, color);
            linearCV = lerp(dot(linearCV, AP1_RGB2Y).xxx, linearCV, ODT_SAT_FACTOR.xxx);

            // Convert to display primary encoding
            // Rendering space RGB to XYZ
            float3 XYZ = mul(AP1_2_XYZ_MAT, linearCV);

            // Apply CAT from ACES white point to assumed observer adapted white point
            XYZ = mul(D60_2_D65_CAT, XYZ);

            // CIE XYZ to display primaries
            linearCV = mul(XYZ_2_REC709_MAT, XYZ);

            return linearCV;
        #endif
    }

    // Returns the default value for a given position on a 2D strip-format color lookup table
    // params = (lut_height, 0.5 / lut_width, 0.5 / lut_height, lut_height / lut_height - 1)
    half3 GetLutStripValue(float2 uv, float4 params)
    {
        uv -= params.yz;
        half3 color;
        color.r = frac(uv.x * params.x);
        color.b = uv.x - color.r / params.x;
        color.g = uv.y;
        return color * params.w;
    }

    half Luminance(half3 c)
    {
        return dot(c, half3(0.2126729, 0.7151522, 0.0721750));
    }

    half AcesLuminance(half3 c)
    {
        return dot(c, AP1_RGB2Y);
    }

    half GetLuminance(half3 colorLinear)
    {
        #if _TONEMAP_ACES
            return AcesLuminance(colorLinear);
        #else
            return Luminance(colorLinear);
        #endif
    }

    half3 RgbToHsv(half3 c)
    {
        const half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
        half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
        half d = q.x - min(q.w, q.y);
        const half e = 1.0e-4;
        return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    half3 HsvToRgb(half3 c)
    {
        const half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
    }

    half LinearToLogC_Precise(half x)
    {
        half o;
        if (x > LogC.cut)
        o = LogC.c * log10(LogC.a * x + LogC.b) + LogC.d;
        else
        o = LogC.e * x + LogC.f;
        return o;
    }

    half3 LinearToLogC(half3 x)
    {
        #if USE_PRECISE_LOGC
            return half3(
            LinearToLogC_Precise(x.x),
            LinearToLogC_Precise(x.y),
            LinearToLogC_Precise(x.z)
            );
        #else
            return LogC.c * log10(LogC.a * x + LogC.b) + LogC.d;
        #endif
    }

    half3 LogCToLinear(half3 x)
    {
        #if USE_PRECISE_LOGC
            return half3(
            LogCToLinear_Precise(x.x),
            LogCToLinear_Precise(x.y),
            LogCToLinear_Precise(x.z)
            );
        #else
            return (pow(10.0, (x - LogC.d) / LogC.c) - LogC.b) / LogC.a;
        #endif
    }

    half3 LinearToLMS(half3 x)
    {
        const half3x3 LIN_2_LMS_MAT = {
            3.90405e-1, 5.49941e-1, 8.92632e-3,
            7.08416e-2, 9.63172e-1, 1.35775e-3,
            2.31082e-2, 1.28021e-1, 9.36245e-1
        };
        return mul(LIN_2_LMS_MAT, x);
    }

    half3 LMSToLinear(half3 x)
    {
        const half3x3 LMS_2_LIN_MAT = {
            2.85847e+0, -1.62879e+0, -2.48910e-2,
            -2.10182e-1,  1.15820e+0,  3.24281e-4,
            -4.18120e-2, -1.18169e-1,  1.06867e+0
        };
        return mul(LMS_2_LIN_MAT, x);
    }

    half RotateHue(half value, half low, half hi)
    {
        return (value < low)
        ? value + hi
        : (value > hi)
        ? value - hi
        : value;
    }

    // Soft-light blending mode use for split-toning. Works in HDR as long as `blend` is [0;1] which is
    // fine for our use case.
    float3 SoftLight(float3 base, float3 blend)
    {
        float3 r1 = 2.0 * base * blend + base * base * (1.0 - 2.0 * blend);
        float3 r2 = sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend);
        float3 t = step(0.5, blend);
        return r2 * t + (1.0 - t) * r1;
    }

// Neutral tonemapping (Hable/Hejl/Frostbite)
// Input is linear RGB
#if defined(SHADER_API_SWITCH) // We need more accuracy on Nintendo Switch to avoid NaN on extremely high values.
float3 NeutralCurve(float3 x, half a, half b, half c, half d, half e, half f)
#else
half3 NeutralCurve(half3 x, half a, half b, half c, half d, half e, half f)
#endif
{
    return ((x * (a * x + c * b) + d * e) / (x * (a * x + b) + d * f)) - e / f;
}

half3 NeutralTonemap(half3 x)
{
    // Tonemap
    const half a = 0.2;
    const half b = 0.29;
    const half c = 0.24;
    const half d = 0.272;
    const half e = 0.02;
    const half f = 0.3;
    const half whiteLevel = 5.3;
    const half whiteClip = 1.0;

    half3 whiteScale = (1.0).xxx / NeutralCurve(whiteLevel, a, b, c, d, e, f);
    x = NeutralCurve(x * whiteScale, a, b, c, d, e, f);
    x *= whiteScale;

    // Post-curve white point adjustment
    x /= whiteClip.xxx;

    return x;
}
#endif