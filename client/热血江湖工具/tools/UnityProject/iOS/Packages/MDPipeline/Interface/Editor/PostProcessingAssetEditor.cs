using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.ProjectWindowCallback;

namespace CustomPipeline
{
    [CustomEditor(typeof(PostProcessingAsset))]
    public class PostProcessingAssetEditor : MDPipelineEffectProfileEditor
    {
        [MenuItem("Assets/Create/Rendering/ForwardRenderer Render Pipeline/PostProcessingAsset")]
        static void CreateEffectProfile()
        {
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreateMDPipelineProfile>(), "PostProcessingAsset.asset", null, null);
        }
        class CreateMDPipelineProfile : EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var instance = CreateInstance<PostProcessingAsset>();
                AssetDatabase.CreateAsset(instance, pathName);
            }
        }
    }

}
