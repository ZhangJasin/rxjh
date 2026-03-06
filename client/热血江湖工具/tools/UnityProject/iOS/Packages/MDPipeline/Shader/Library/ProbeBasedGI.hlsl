#ifndef PROBE_BASED_GI_H
#define PROBE_BASED_GI_H

TEXTURE3D(_ProbeBasedGI_RT);
SAMPLER(sampler_ProbeBasedGI_RT);

float3 _ProbeBasedGI_BoundsMin;
float3 _ProbeBasedGI_BoundsSize;
half4 _ProbeBasedGI_XYNormalOffset_ZStrengthen_WMinColor;

TEXTURE2D(_ProbeBasedGI_RT_Far);
SAMPLER(sampler_ProbeBasedGI_RT_Far);
float4 _ProbeBasedGI_Rect_Far;

float3 _ProbeBasedGI_HalfInvTextureSize;
float2 _ProbeBasedGI_HalfInvTextureSize_Far;

#if defined(PROBE_BASED_GI_MODE_ON) && defined(_PROBE_BASED_GI)
#define USE_PROBE_BASED_GI
#endif

half3 ColorToCoefficient(half3 value, half maxValue)
{
	value = value * (255.0 / 128.0) - 1;
	return value * maxValue;
}

half4 GetColor(half4 rgb0ao, half4 l1l2l3, half3 normalWS)
{
	half maxValue = l1l2l3.w * 255;
	half3 rgb0 = ColorToCoefficient(rgb0ao.xyz, maxValue);
	half ao = rgb0ao.w;
	half3 l312 = ColorToCoefficient(l1l2l3.zxy, maxValue);
	half3 color = max(0.0, dot(l312, normalWS) + rgb0) * _ProbeBasedGI_XYNormalOffset_ZStrengthen_WMinColor.z;
	color = lerp(_ProbeBasedGI_XYNormalOffset_ZStrengthen_WMinColor.w, 1, color);
	return half4(color, ao);
}

bool IsFarEnabled()
{
	return _ProbeBasedGI_Rect_Far.w != 0;
}

half4 GetMinColor()
{
	half minColor = _ProbeBasedGI_XYNormalOffset_ZStrengthen_WMinColor.w;
	return half4(minColor, minColor, minColor, 1);
}


#if defined(SHADER_API_GLES) 
    #define SAMPLE_PROBE_BASED_GI_TEXTURE2D(tex, uv) tex2D(tex, uv)
    #define SAMPLE_PROBE_BASED_GI_TEXTURE3D(tex, uvw) tex3D(tex, uvw)
#else 
	#define SAMPLE_PROBE_BASED_GI_TEXTURE2D(tex, uv) (half4)SAMPLE_TEXTURE2D_LOD(tex, sampler_ProbeBasedGI_RT_Far, uv, 0)
	#define SAMPLE_PROBE_BASED_GI_TEXTURE3D(tex, uvw) (half4)SAMPLE_TEXTURE3D_LOD(tex, sampler_ProbeBasedGI_RT, uvw, 0)
#endif

half4 SampleProbeBasedGIFar(float2 uv, half3 normalWS)
{
	uv = clamp(uv, _ProbeBasedGI_HalfInvTextureSize_Far, 1 - _ProbeBasedGI_HalfInvTextureSize_Far);

	float2 uv1 = float2(uv.x * 0.5, uv.y);
	float2 uv2 = float2(uv1.x + 0.5, uv.y);
	half4 rgb0ao = SAMPLE_PROBE_BASED_GI_TEXTURE2D(_ProbeBasedGI_RT_Far, uv1);
	half4 l1l2l3 = SAMPLE_PROBE_BASED_GI_TEXTURE2D(_ProbeBasedGI_RT_Far, uv2);
	return GetColor(rgb0ao, l1l2l3, normalWS);
}

half4 SampleProbeBasedGIFar(float3 positionWS, half3 normalWS)
{
	if (!IsFarEnabled())
	{
		return GetMinColor();
	}

	float3 position = positionWS + normalWS * _ProbeBasedGI_XYNormalOffset_ZStrengthen_WMinColor.xyx;
	float2 uvf = (position.xz - _ProbeBasedGI_Rect_Far.xy) / _ProbeBasedGI_Rect_Far.zw;
	return SampleProbeBasedGIFar(uvf, normalWS);
}

half4 SampleProbeBasedGI(float3 positionWS, half3 normalWS)
{
	float3 position = positionWS + normalWS * _ProbeBasedGI_XYNormalOffset_ZStrengthen_WMinColor.xyx;
	float3 uvw = ((position - _ProbeBasedGI_BoundsMin) / _ProbeBasedGI_BoundsSize).xzy;
	if (uvw.x < 0 || uvw.y < 0 || uvw.z < 0 || uvw.x > 1 || uvw.y > 1 || uvw.z > 1)
	{
		if (IsFarEnabled())
		{
			float2 uvf = (position.xz - _ProbeBasedGI_Rect_Far.xy) / _ProbeBasedGI_Rect_Far.zw;
			if (uvf.x >= 0 && uvf.y >= 0 && uvf.x <= 1 && uvf.y <= 1)
			{
				return SampleProbeBasedGIFar(uvf, normalWS);		
			}
		}
		
		return GetMinColor();
	}

	uvw = clamp(uvw, _ProbeBasedGI_HalfInvTextureSize, 1 - _ProbeBasedGI_HalfInvTextureSize);
	float3 uvw1 = float3(uvw.x * 0.5, uvw.y, uvw.z);
	float3 uvw2 = float3(uvw1.x + 0.5, uvw.y, uvw.z);
	half4 rgb0ao = SAMPLE_PROBE_BASED_GI_TEXTURE3D(_ProbeBasedGI_RT, uvw1);
	half4 l1l2l3 = SAMPLE_PROBE_BASED_GI_TEXTURE3D(_ProbeBasedGI_RT, uvw2);
	return GetColor(rgb0ao, l1l2l3, normalWS);
}

#if defined(_PROBE_BASED_GI)

#if defined(PROBE_BASED_GI_MODE_DEBUG)
uint _ProbeBasedGI_DebugMode;

half4 SampleProbeBasedGIDebug(float3 worldPos, half3 worldNormal)
{
	switch (_ProbeBasedGI_DebugMode)
	{
		case 0: return half4(SampleProbeBasedGI(worldPos, worldNormal).rgb, 1);
		case 1: return half4(SampleProbeBasedGI(worldPos, worldNormal).aaa, 1);
		case 2: return half4(SampleProbeBasedGIFar(worldPos, worldNormal).rgb, 1);
		case 3: return half4(SampleProbeBasedGIFar(worldPos, worldNormal).aaa, 1);
	}
	return 0;
}

#define APPLY_PROBE_BASED_GI_MODE(worldPos, worldNormal) return SampleProbeBasedGIDebug(worldPos, worldNormal);
#else
#define APPLY_PROBE_BASED_GI_MODE(worldPos, worldNormal)
#endif

#else
#define APPLY_PROBE_BASED_GI_MODE(worldPos, worldNormal)
#endif

#endif