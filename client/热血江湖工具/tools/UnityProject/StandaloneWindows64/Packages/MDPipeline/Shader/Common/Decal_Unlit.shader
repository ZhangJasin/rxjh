Shader "MD/Standard/Decal_Unlit"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        [HDR]_Color("_Color", Color) = (1,1,1,1)

        [Toggle(_UseZScale)] _UseZScale("根据深度缩放适配贴花(用于垂直墙面，适合无指向性效果)", Float) = 0
        [Toggle(_ClipByZ)] _ClipByZ("非目标方向(或垂直墙面）直接裁剪 (适合指向性效果)", Float) = 1

        _ProjectionAngleDiscardThreshold("非目标方向贴花裁剪程度", range(0.01,0.99)) = 0.01
        [Header(Support Orthographic camera)]
        [Toggle(_SupportOrthographicCamera)] _SupportOrthographicCamera("用于UI正交相机(default = off)", Float) = 0

         [Header(Stencil Masking)]
        _StencilRef("_StencilRef", Float) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp("_StencilComp (default = Disable)", Float) = 0 //0 = disable
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull Mode", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend Mode", Float) = 10
    }

    SubShader
    {
        //"Queue" = "AlphaTest" 如果和树叶草之类的冲突，外面调整下顺序
        Tags { "RenderType" = "TransparentCutout" "Queue" = "Transparent-100" "DisableBatching" = "True" }
        Pass
        {
            Stencil
            {
                Ref[_StencilRef]
                Comp[_StencilComp]
            }
            Cull[_Cull]
            //ZTest[_ZTest]
            ZWrite off
            Blend[_SrcBlend][_DstBlend]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #pragma shader_feature _ProjectionAngleDiscardEnable
            #pragma shader_feature _SupportOrthographicCamera
            #pragma shader_feature _ _UseZScale _ClipByZ

            #include "Packages/com.sh.md_pipeline/Shader/Library/Core.hlsl"
            struct appdata
            {
                float4 vertex : POSITION;
            };
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;
                float4 viewRayOS : TEXCOORD1; // xyz: viewRayOS, w: extra copy of positionVS.z 
                float3 cameraPosOS : TEXCOORD2;
            };
            sampler2D _MainTex;

            CBUFFER_START(UnityPerMaterial)               
                float4 _MainTex_ST;
                float _ProjectionAngleDiscardThreshold;
                half4 _Color;
            CBUFFER_END

            v2f vert(appdata input)
            {
                v2f o;
                float3 worldPos = TransformObjectToWorld(input.vertex.xyz);
                o.pos = TransformWorldToHClip(worldPos);
                float3 positionVS = TransformWorldToView(worldPos);
                o.screenPos = ComputeScreenPos(o.pos);
                // get "camera to vertex" ray in View space
                float3 viewRay = positionVS;
                o.viewRayOS.w = viewRay.z;
                // unity's camera space is right hand coord(negativeZ pointing into screen), we want positive z ray in fragment shader, so negate it
                viewRay *= -1;
                float4x4 ViewToObjectMatrix = mul(UNITY_MATRIX_I_M, UNITY_MATRIX_I_V);
                // transform everything to object space(decal space) in vertex shader first, so we can skip all matrix mul() in fragment shader
                o.viewRayOS.xyz = mul((float3x3)ViewToObjectMatrix, viewRay);
                o.cameraPosOS.xyz = mul(ViewToObjectMatrix, float4(0,0,0,1)).xyz; // hard code 0 or 1 can enable many compiler optimization

                return o;
            }

            float LinearDepthToEyeDepth(float rawDepth)
            {
                #if UNITY_REVERSED_Z
                    return _ProjectionParams.z - (_ProjectionParams.z - _ProjectionParams.y) * rawDepth;
                #else
                    return _ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y) * rawDepth;
                #endif
            }

            half4 frag(v2f i) : SV_Target
            {
                i.viewRayOS.xyz /= i.viewRayOS.w;
                float2 screenSpaceUV = i.screenPos.xy / i.screenPos.w;
                float sceneRawDepth = SampleSceneDepth(screenSpaceUV);
                float3 decalSpaceScenePos;
#if _SupportOrthographicCamera
                // we have to support both orthographic and perspective camera projection
                // static uniform branch depends on unity_OrthoParams.w
                // (should we use UNITY_BRANCH here?) decided NO because https://forum.unity.com/threads/correct-use-of-unity_branch.476804/
                if(unity_OrthoParams.w)
                {
                    float sceneDepthVS = LinearDepthToEyeDepth(sceneRawDepth);
                    // Edit: The copied Lux URP stopped working at some point, and no one even knew why it worked in the first place 
                    //----------------------------------------------------------------------------
				    float2 viewRayEndPosVS_xy = float2(unity_OrthoParams.xy * (i.screenPos.xy - 0.5) * 2 /* to clip space */);  // Ortho near/far plane xy pos 
				    float4 vposOrtho = float4(viewRayEndPosVS_xy, -sceneDepthVS, 1);  // Constructing a view space pos
				    float3 wposOrtho = mul(UNITY_MATRIX_I_V, vposOrtho).xyz; // Trans. view space to world space
                    //----------------------------------------------------------------------------
                    // transform world to object space(decal space)
                    decalSpaceScenePos = mul(UNITY_MATRIX_I_M, float4(wposOrtho, 1)).xyz;
                }
                else
                {
#endif
                    // if perspective camera, LinearEyeDepth will handle everything for user
                    float sceneDepthVS = LinearEyeDepth(sceneRawDepth,_ZBufferParams);
                    // scene depth in any space = rayStartPos + rayDir * rayLength
                    // be careful, viewRayOS is not a unit vector, so don't normalize it, it is a direction vector which view space z's length is 1
                    decalSpaceScenePos = i.cameraPosOS.xyz + i.viewRayOS.xyz * sceneDepthVS;
                    
#if _SupportOrthographicCamera
                }
#endif
                float3 decalSpaceHardNormal = normalize(cross(ddx(decalSpaceScenePos), ddy(decalSpaceScenePos)));

               // return decalSpaceHardNormal.y;
               //return 0.5 - decalSpaceScenePos.z;

                float shouldClip = 0;
                #ifdef _ClipByZ
                    shouldClip = decalSpaceHardNormal.z > _ProjectionAngleDiscardThreshold ? 0 : 1;
                #endif
               //discard "out of cube volume" and "scene normal not facing decal projector direction" pixels
                //clip(0.5 - abs(decalSpaceScenePos) - shouldClip);
                half mask = (0.5 - abs(decalSpaceScenePos.x) - shouldClip) <0 ? 0 : 1;

                // convert unity cube's [-0.5,0.5] vertex pos range to [0,1] uv. Only works if you use a unity cube in mesh filter!
                //float2 decalSpaceUV = decalSpaceScenePos.xy + 0.5;
                float2 ZScaleUV = 0;
                #ifdef _UseZScale
                    ZScaleUV = (0.5- decalSpaceScenePos.z)*decalSpaceScenePos.xy;
                #endif
                float2 decalSpaceUV = decalSpaceScenePos.xy + 0.5 + ZScaleUV;
                // sample the decal texture
                float2 uv = decalSpaceUV.xy * _MainTex_ST.xy + _MainTex_ST.zw;//Texture tiling & offset
                half4 col = tex2D(_MainTex, uv);
                col *= _Color * mask;// tint color

                return col;
            }
            ENDHLSL
        }
    }
}
