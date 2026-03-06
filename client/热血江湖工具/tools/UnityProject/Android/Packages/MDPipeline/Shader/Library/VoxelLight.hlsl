#ifndef __VOXELLIGHT_INCLUDE__
#define __VOXELLIGHT_INCLUDE__


float3 _FroxelSize;

#define VOXELSIZE uint3(XRES, YRES, ZRES)

struct Capsule
{
    float3 direction;
    float3 position;
    float radius;
};
struct Cone
{
    float3 vertex;
    float height;
    float3 direction;
    float radius;
};

struct PointLight{
    float4 lightColor;
    float4 sphere;
};
struct SpotLight
{
    float3 lightColor;
    Cone lightCone;
    float angle;
    float4x4 vpMatrix;
    float smallAngle;
    float nearClip;
    int shadowIndex;
    int iesIndex;
    float shadowBias;
};

float3 _CameraForward;
float4 _CameraNearPos;
float4 _CameraFarPos;
float4 _VolumetricLightVar; //x: Camera nearclip plane      y: Volume distance - nearclip       z: volume distance      w: indirect intensity

inline uint GetIndex(uint3 id, const uint3 size, const int multiply){
    const uint3 multiValue = uint3(1, size.x, size.x * size.y) * multiply;
    return dot(id, multiValue);
}

half4 _CameraClipDistance;
StructuredBuffer<PointLight> _AllPointLight;
StructuredBuffer<uint> _PointLightIndex;
float3 CalculateLocalLight(float2 uv, float3 WorldPos, float linearDepth, float3 WorldNormal, float3 ViewDir)
{
	float3 ShadingColor = 0;
	float rate = pow(max(0, (linearDepth - _CameraClipDistance.x) / _CameraClipDistance.y), 1.0 / CLUSTERRATE);
    if(rate > 1) return 0;
	uint3 voxelValue = uint3((uint2)(uv * float2(XRES, YRES)), (uint)(rate * ZRES));
	uint sb = GetIndex(voxelValue, VOXELSIZE, (MAXLIGHTPERCLUSTER + 1));
	uint2 LightIndex;// = uint2(sb + 1, _PointLightIndex[sb]);
	uint c;
	float3 JitterPoint = ViewDir;
	LightIndex = uint2(sb + 1, _PointLightIndex[sb]);
	[loop]
	for (c = LightIndex.x; c < LightIndex.y; c++)
	{		
		PointLight Light = _AllPointLight[_PointLightIndex[c]];
		float LightRange = Light.sphere.a;
		float3 LightPos = Light.sphere.rgb;
		float3 LightColor = Light.lightColor.rgb;

		float3 Un_LightDir = LightPos - WorldPos.xyz;
		float Length_LightDir = length(Un_LightDir);
		float3 LightDir = Un_LightDir / Length_LightDir;

        float distanceSqr = max(dot(Un_LightDir, Un_LightDir), HALF_MIN);
        float lightRangeSqr = LightRange * LightRange;
        float fadeStartDistanceSqr = 0.8f * 0.8f * lightRangeSqr;
        float fadeRangeSqr = (fadeStartDistanceSqr - lightRangeSqr);
        float oneOverLightRangeSqr = 1.0f / max(0.0001f, lightRangeSqr);
        float lightRangeSqrOverFadeRangeSqr = -lightRangeSqr / fadeRangeSqr;

        half attenuation = DistanceAttenuation(distanceSqr, half2(oneOverLightRangeSqr, lightRangeSqrOverFadeRangeSqr)) ;

        half nol = dot(WorldNormal, LightDir);
	    half3 attenuatedLightColor = LightColor * attenuation ;
	    half3 diffuse = attenuatedLightColor * saturate(nol);

		ShadingColor += diffuse ;
	}
	return ShadingColor;
}


inline float4 GetPlane(float3 normal, float3 inPoint)
{
return float4(normal, -dot(normal, inPoint));
}
inline float4 GetPlane(float3 a, float3 b, float3 c)
{
float3 normal = normalize(cross(b - a, c - a));
return float4(normal, -dot(normal, a));
}

inline uint From3DTo1D(uint3 id, const uint2 size){
const uint3 multiValue = uint3(1, size.x, size.x * size.y);
return dot(id, multiValue);
}

inline float4 GetPlane(float4 a, float4 b, float4 c)
{
a /= a.w;
b /= b.w;
c /= c.w;
float3 normal = normalize(cross(b.xyz - a.xyz, c.xyz - a.xyz));
return float4(normal, -dot(normal, a.xyz));
}

inline float GetDistanceToPlane(float4 plane, float3 inPoint)
{
return dot(plane.xyz, inPoint) + plane.w;
}

float BoxIntersect(float3 extent, float3 position, float4 planes[6]){
float result = 1;
for(uint i = 0; i < 6; ++i)
{
    float4 plane = planes[i];
    float3 absNormal = abs(plane.xyz);
    result *= ((dot(position, plane.xyz) - dot(absNormal, extent)) < -plane.w) ;
}
return result;
}
float BoxIntersect(float3 extent, float3x3 boxLocalToWorld, float3 position, float4 planes[6])
{
float result = 1;
for(uint i = 0; i < 6; ++i)
{
    float4 plane = planes[i];
    float3 absNormal = abs(mul(plane.xyz, boxLocalToWorld));
    result *= ((dot(position, plane.xyz) - dot(absNormal, extent)) < -plane.w) ;
}
return result;
}

float SphereIntersect(float4 sphere, float4 planes[6])
{
[unroll]
for(uint i = 0; i < 6; ++i)
{
    if (GetDistanceToPlane(planes[i], sphere.xyz) > sphere.w) return 0;
}
return 1;
}

inline float SphereIntersect(float4 sphere, float4 plane)
{
return (GetDistanceToPlane(plane, sphere.xyz) < sphere.w);
}


inline float PointInsidePlane(float3 vertex, float4 plane)
{
    return (dot(plane.xyz, vertex) + plane.w) < 0;
}

inline float SphereInsidePlane(float4 sphere, float4 plane)
{
    return (dot(plane.xyz, sphere.xyz) + plane.w) < sphere.w;
}

inline float ConeInsidePlane(Cone cone, float4 plane)
{
    float3 m = cross(cross(plane.xyz, cone.direction), cone.direction);
    float3 Q = cone.vertex + cone.direction * cone.height + normalize(m) * cone.radius;
    return PointInsidePlane(cone.vertex, plane) + PointInsidePlane(Q, plane);
}

inline float CapsuleInsidePlane(Capsule cap, float4 plane)
{
    float4 sphere0 = float4(cap.position + cap.direction, cap.radius);
    float4 sphere1 = float4(cap.position - cap.direction, cap.radius);
    return SphereInsidePlane(sphere0, plane) + SphereInsidePlane(sphere1, plane);
}

float ConeIntersect(Cone cone, float4 planes[6])
{
[unroll]
for(uint i = 0; i < 6; ++i)
{
    if(ConeInsidePlane(cone, planes[i]) < 0.5) return 0;
}
return 1;
}

inline float ConeIntersect(Cone cone, float4 plane)
{
return ConeInsidePlane(cone, plane);
}


#endif