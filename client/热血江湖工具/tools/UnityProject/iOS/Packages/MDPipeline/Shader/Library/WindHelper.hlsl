#include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"


uniform float4 _WindDirectionAndStrength;


float4 TriangleWave(float4 t) {
	return abs(frac(t+0.5)*2.0-1.0);
}

float4 SmoothCurve(float4 t) {
	return t * t * (3.0-2.0*t);
}

float4 SmoothTriangleWave(float4 t) {
	return SmoothCurve(TriangleWave(t))-0.5;
}

float2 TriangleWave(float2 t) {
	return abs(frac(t+0.5)*2.0-1.0);
}

float2 SmoothCurve(float2 t) {
	return t * t * (3.0-2.0*t);
}

float2 SmoothTriangleWave(float2 t) {
	return SmoothCurve(TriangleWave(t))-0.5;
}

float3 vertexWindPos(float4 vertex,float3 posWorld, float3 pivot, float3 normalWorld, float3 tangentWorld,
float4 _WindDirectionAndStrength,float _ShakeWindspeed,float _ShakeBending,float _ShakeRange)
{
    float3 wdf = SafeNormalize(_WindDirectionAndStrength.xyz);
    float3 up= float3(0,1,0);
	float3 wdr = cross( up, wdf );

   vertex.y = max(vertex.y,0.0001);
   float animfade = step(_ShakeRange, vertex.y) * (vertex.y - _ShakeRange)/vertex.y;

    //float4 phase = _WindDirectionRight.z * float4(1, 1.8, 1.5, 3.66);
	float4 time = _Time.y * _ShakeWindspeed * float4(1, 1.8, 0.5, 2.4) ;
	float4 pos = (pivot.x + pivot.z) * float4(0.5, 0.8, 0.3, 0.7);
	float4 wave = SmoothTriangleWave(time+pos);
	float3 bend = (wave.x + _ShakeBending * 0.12) * wdf+ (wave.z * 0.3) * wdr ;
	bend *= _ShakeBending * animfade;
	bend *= _WindDirectionAndStrength.w;
	float l = length(posWorld-pivot);
	float3 p = posWorld + bend;
	 #if !DATA_TYPE_TRUNKS
        float3 binormalWorld = cross(normalWorld, tangentWorld);
        float detailStr = min(l * 0.2, _ShakeBending * 0.12);
        float3 detailBend = (wdf * wave.y + wdr * wave.w)  * detailStr;
        detailBend *= animfade;
        p += detailBend;
    #endif
	p = normalize(p-pivot) * l + pivot;
	return p;
}