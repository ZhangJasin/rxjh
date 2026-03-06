using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using UnityEditor;
using UnityEditor.ProjectWindowCallback;
namespace CustomPipeline
{
    [CustomEditor(typeof(ForwardRendererPipeAsset))]
    public class ForwardRendererPipeAssetEditor : MDRenderPipelineAssetEditor
    {

        [MenuItem("Assets/Create/Rendering/ForwardRenderer Render Pipeline/PipelineAsset")]
        static void CreatPipelineAsset()
        {
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreateMDPipelineAsset>(), "ForwardRendererPipeAsset.asset", null, null);
        }


        class CreateMDPipelineAsset : EndNameEditAction
        {
            public override void Action(int instanceId, string pathName, string resourceFile)
            {
                var instance = CreateInstance<ForwardRendererPipeAsset>();
                AssetDatabase.CreateAsset(instance, pathName);
            }
        }
    }

}
