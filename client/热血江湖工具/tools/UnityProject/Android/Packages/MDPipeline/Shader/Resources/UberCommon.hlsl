#ifndef UBER_COMMON_INCLUDED
#define UBER_COMMON_INCLUDED

#include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"



#ifdef RADIALBLUR_ENABLE

half _RadialBlurAmount;
int _RadialBlurSamples;
half2 _RadialBlurCenter;
half _RadialBlurType;
half _RadialBlurRadius;
half4 RadialBlur(float2 uv, TEXTURE2D_PARAM(_MainTex, sampler_MainTex))
{
    half2 coord = uv - _RadialBlurCenter;
	float dis = distance(uv, _RadialBlurCenter);
    dis = smoothstep(0.0, _RadialBlurRadius, dis)-_RadialBlurType;
    half4 color = 0;
    half scale;
    half factor = _RadialBlurSamples - 1;
    for (int i = 0; i < _RadialBlurSamples; i++)
    {
	    scale = _RadialBlurAmount * (i / factor) * dis;
	    color += SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, coord * (1 + scale) + _RadialBlurCenter);
    }
    color /= _RadialBlurSamples;
    return color;

}
#endif


#if defined(COLORGRADING_ENABLE)
    TEXTURE2D(_InternalLut);
    float4 _LutScaleOffset;
    float3 ApplyColorGrading(float3 c)
	{
		c *= _LutScaleOffset.w;
		float3 uvw = saturate(LinearToLogC(c)); // LUT space is in LogC
		// Strip format where `height = sqrt(width)`
		uvw.z *= _LutScaleOffset.z;
		float shift = floor(uvw.z);
		uvw.xy = uvw.xy * _LutScaleOffset.z * _LutScaleOffset.xy + _LutScaleOffset.xy * 0.5;
		uvw.x += shift * _LutScaleOffset.y;
		uvw.xyz = lerp(
		SAMPLE_TEXTURE2D_LOD(_InternalLut, sampler_LinearClamp, uvw.xy, 0.0).rgb,
		SAMPLE_TEXTURE2D_LOD(_InternalLut, sampler_LinearClamp, uvw.xy + float2(_LutScaleOffset.y, 0.0), 0.0).rgb,uvw.z - shift);

		return uvw;
	}
#endif


#endif
