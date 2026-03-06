using UnityEditor;
using UnityEditor.ProjectWindowCallback;

namespace CustomPipeline
{
    [CustomEditor(typeof(MDRenderPipelineEditorResourcesAsset))]
    public class MDRenderPipelineEditorResourcesAssetEditor : MDRenderPipelineEditorResourcesEditor
    {
        [MenuItem("Assets/Create/Rendering/MD Render Pipeline/MD Pipeline Editor Resources")]
        static void CreateMDPipelineEditorResources()
        {
            ProjectWindowUtil.StartNameEditingIfProjectWindowExists(0, CreateInstance<CreateMDRenderPipelineEditorResourcesAsset>(), "MDRenderPipelineEditorResources.asset", null, null);
        }
    }
    
    class CreateMDRenderPipelineEditorResourcesAsset : EndNameEditAction
    {
        public override void Action(int instanceId, string pathName, string resourceFile)
        {
            var instance = CreateInstance<MDRenderPipelineEditorResourcesAsset>();
            ResourceReloader.ReloadAllNullIn(instance, MDRenderPipelineAsset.packagePath);
            AssetDatabase.CreateAsset(instance, pathName);
        }
    }
}