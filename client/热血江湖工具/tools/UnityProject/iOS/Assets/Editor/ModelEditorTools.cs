using System;
using System.IO;
using System.Collections.Generic;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Runtime.InteropServices;
using TCFramework;

/**
 * 模型散件合批工具
 * 整体流程v1.0
 * 0. 游戏端登录以后F9唤起部件编辑器，第一步选择Unity.exe目录，自动提示
 * 1. 编辑模型套装，编辑以后保存套装描述文件(TCFramework.PersistantDataFile)/__996__/modelEditor/list.json  和   id(xxx).json
 * 2. 保存json以后，cmd调用Tools/BuildVersion/生成模型预制件_(Platform).bat
 * 2.1 生成Prefab、mat、mesh、texture相关文件，目录:Tools/BuildVersion/UnityProject/(Platform)/Assets/Res/game/Model/Suit/(id)/(id).prefab(.mat,.png,.mesh等)
 * 3. 编辑ab打包策略，主要针对Res/Model/Suit下的文件进行编辑
 * 3.1 cmd调用 生成资源_(Platform).bat，打包至目录Tools/BuildVersion/dev/
 * 4.1 cmd调用 移动资源测试_Windows.bat，将上面打包的Windows下的Model/Suit/(id) ab包复制到游戏端 PersistantData/Bundles/dev/Model下
 * 5. 游戏端执行点击测试按钮
 */
public static class ModelEditorTools
{
    [MenuItem("Tools/戚源/刷新子骨骼信息列表")]
    public static void RefreshBoneInfo()
    {
        if (Selection.activeGameObject != null)
        {
            var boneInfo = Selection.activeGameObject.GetComponent<SkinnedMeshBoneData>();
            if (boneInfo == null)
            {
                boneInfo = Selection.activeGameObject.AddComponent<SkinnedMeshBoneData>();
            }
            boneInfo.Init();
            var animtor = Selection.activeGameObject.GetComponent<Animator>();
            if (animtor == null)
            {
                Selection.activeGameObject.AddComponent<Animator>();
            }
        }
    }

    [MenuItem("Tools/戚源/测试代码")]
    public static void TestQiyuan()
    {
        var ____t = GameObject.Find("Bip001");
        var transforms = ____t.GetComponentsInChildren<Transform>();
        var smr = GameObject.Find("11010_A").GetComponent<SkinnedMeshRenderer>();
        var rootBone = GameObject.Find("Bip001 Head").transform;
        var boneList = new List<Transform>();
        for (int z = 0; z < smr.bones.Length; z++)
        {
            var _temp_Transform = smr.bones[z];
            if (transforms != null)
            {
                for (int u = 0; u < transforms.Length; u++)
                {
                    if (_temp_Transform.name == transforms[u].name)
                    {
                        boneList.Add(transforms[u]);
                    }

                    if (rootBone.name == transforms[u].name)
                    {
                        rootBone = transforms[u];
                    }
                }
            }
            else
            {
                boneList.Add(smr.bones[z]);
            }
        }

        smr.bones = boneList.ToArray();
    }

    [MenuItem("Tools/戚源/编译成prefab")]
    public static void BuildPrefabQuick()
    {
        AssetBundle.UnloadAllAssetBundles(true);
        //ModelEditorFunction.BuildAllPrefab(0, "C:/Users/admin/AppData/LocalLow/unity3d/xxengine/Bundles/dev/__996__/modelEditor/", "G:/xianxia/code/xianxia/Assets/Res/game_assets/Model/Parts/", false);

        ModelEditorFunction.BuildAllPrefab(0, "G:/xianxia/9963D_xianxia_Client/win64_Classic/xxengine_Data/PersistantData/Bundles/dev/__996__/modelEditor/", "G:/xianxia/9963D_xianxia_Client/win64_Classic/xxengine_Data/PersistantData/Bundles/game_assets/", false);
        AssetBundle.UnloadAllAssetBundles(true);
    }

    [MenuItem("Tools/戚源/临时测试编译ab")]
    public static void BuildAB()
    {
        BuildPipeline.BuildAssetBundles("G:/xianxia/code/xianxia/Assets/Res/game/__996__/modelEditor/official/", BuildAssetBundleOptions.None, BuildTarget.StandaloneWindows64);
    }

    [MenuItem("Tools/戚源/创建对象fromeAB_Project")]
    public static void InstanceAB_Project()
    {
        AssetBundle.UnloadAllAssetBundles(true);
        AssetBundle ab = AssetBundle.LoadFromFile("G:/xianxia/code/xianxia/Assets/Res/game/__996__/modelEditor/official/1000001");
        var _go = ab.LoadAsset<GameObject>("1000001");
        UnityEngine.GameObject.Instantiate(_go);
        ab = AssetBundle.LoadFromFile("G:/xianxia/code/xianxia/Assets/Res/game/__996__/modelEditor/official/1000002");
        _go = ab.LoadAsset<GameObject>("1000002");
        UnityEngine.GameObject.Instantiate(_go);
    }

    [MenuItem("Tools/戚源/创建对象fromeAB")]
    public static void InstanceAB()
    {
        AssetBundle.UnloadAllAssetBundles(true);
        AssetBundle ab = AssetBundle.LoadFromFile("G:/xianxia/code/xianxia/Tools/BuildVersion/UnityProject/StandaloneWindows64/Assets/Res/game/__996__/modelEditor/generate/model/prefabs/10000");
        var _go = ab.LoadAsset<GameObject>("10000");
        UnityEngine.GameObject.Instantiate(_go);
    }

    [MenuItem("Tools/戚源/测试读取二进制图片")]
    public static void TestReadByteImg()
    {
        GameObject go = GameObject.Instantiate(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Res/game/__996__/modelEditor/prefab/10000.prefab"));
        Material m = go.GetComponentInChildren<SkinnedMeshRenderer>().sharedMaterial;
        m.mainTexture = ModelEditorFunction.LoadImg("G:/xianxia/code/xianxia/Tools/BuildVersion/UnityProject/StandaloneWindows64/Assets/Res/game/__996__/modelEditor/prefab/10000_d.ddd");
        m.SetTexture("_NormalTex", ModelEditorFunction.LoadImg("G:/xianxia/code/xianxia/Tools/BuildVersion/UnityProject/StandaloneWindows64/Assets/Res/game/__996__/modelEditor/prefab/10000_n.ddd"));
        m.SetTexture("_PBRTex", ModelEditorFunction.LoadImg("G:/xianxia/code/xianxia/Tools/BuildVersion/UnityProject/StandaloneWindows64/Assets/Res/game/__996__/modelEditor/prefab/10000_p.ddd"));
    }

    static Dictionary<string, AssetBundle> loadList = new Dictionary<string, AssetBundle>();
    [MenuItem("Tools/戚源/读取远程vfs列表")]
    public static AssetBundle TestReadFileList()
    {
        AssetBundle.UnloadAllAssetBundles(true);
        loadList = new Dictionary<string, AssetBundle>();
        return ReadAssetbundleFromFileList1("G:/xianxia/9963D_xianxia_Client/win64_Classic/xxengine_Data/PersistantData/Bundles/game_assets/");
    }
    private static AssetBundle ReadAssetbundleFromFileList1(string rootPath)
    {
        var fList = new FileList();
        fList.Load(rootPath + "FileList.md");
        // 依赖
        CustomAssetBundleManifest mani = ModelEditorFunction.LoadManifest(fList, "Bundles", rootPath);

        var f = fList.GetFileInfo(new PathID("Model/Bone/man.prefab.bundle"));
        Debug.Log("--------------------------");
        AssetBundle ab = null;
        string bundler = "Lua/game/game_config/MapInfo.lua";
        ab = ModelEditorFunction.LoadAssetFromAB(mani, fList, new PathID(bundler), rootPath, ref loadList);
        return ab;
    }
}
