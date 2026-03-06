using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using TCFramework;
using UnityEditor;
using UnityEngine;
using UnityMeshSimplifier;

public static class ModelEditorFunction
{
    // 遮罩1
    // 类型1 上衣G
    // 类型3 裤子B
    private static string mask1 = "Assets/Art/Models/Parts/partmask1.jpg";
    private static Texture2D maskTexture1;
    // 遮罩2
    // 类型6 脸R
    // 类型4 鞋子G
    // 类型2 手B
    // 类型5 头发A
    private static string mask2 = "Assets/Art/Models/Parts/partmask2.tga";
    private static Texture2D maskTexture2;

    static Dictionary<string, AssetBundle> loadList = new Dictionary<string, AssetBundle>();
    public static void CommonelineBuildPrefab()
    {
        AssetBundle.UnloadAllAssetBundles(true);
        string inputDir = null;
        string prefabDir = null;
        int id = 0;
        var commandLineArgs = Environment.GetCommandLineArgs();
        int count = commandLineArgs.Length;
        for (int i = 0; i < count; ++i)
        {
            switch (commandLineArgs[i])
            {
                case "-inputDir":
                    if (i + 1 < count)
                    {
                        inputDir = commandLineArgs[++i];
                    }
                    break;
                case "-buildId":
                    if (i + 1 < count)
                    {
                        id = int.Parse(commandLineArgs[++i]);
                    }
                    break;
                case "-prefabDir":
                    if (i + 1 < count)
                    {
                        prefabDir = commandLineArgs[++i];
                    }
                    break;
            }
        }
        try
        {
            BuildAllPrefab(id, inputDir, prefabDir);
        }
        catch (Exception e)
        {
            Log(e.ToString());
            Log(e.StackTrace);
            DisposeConsole();
        }
    }

    public static void BuildAllPrefab(int id, string inputPath, string prefabDir, bool isUnityEditor = false)
    {
        InitConsole();
        maskTexture1 = AssetDatabase.LoadAssetAtPath<Texture2D>(mask1);
        maskTexture2 = AssetDatabase.LoadAssetAtPath<Texture2D>(mask2);
        Log("准备开始合并, id:" + id);
        loadList = new Dictionary<string, AssetBundle>();
        if (id == 0)
        {
            if (File.Exists(inputPath + "list.json") == false)
            {
                LogError("找不到套装 list.json :");
                return;
            }
            string json = File.ReadAllText(inputPath + "list.json");
            ModelEditorModelsJsonList list = JsonUtility.FromJson<ModelEditorModelsJsonList>(json);
            foreach (int _id in list.idList)
            {
                BuildPrefab(_id, inputPath, prefabDir, isUnityEditor ? ".prefab" : "");
            }
        }
        else
        {
            BuildPrefab(id, inputPath, prefabDir, isUnityEditor ? ".prefab" : "");
        }
    }

    public static CustomAssetBundleManifest LoadManifest(FileList fList, string fileName, string rootPath)
    {
        PathID id = new PathID(fileName);
        if (fList.Contains(id))
        {
            var fInfo = fList.GetFileInfo(id);
            var fDir = fInfo.hash.ToString().Substring(0, 2);
            var path = rootPath + fDir + "/" + fInfo.hash;
            //path = rootPath + fileName;
            if (File.Exists(path))
            {
                CustomAssetBundleManifest m = new CustomAssetBundleManifest(File.OpenRead(path), true);

                return m;
            }
        }
        return null;
    }

    public static AssetBundle LoadAssetFromAB(CustomAssetBundleManifest mani, FileList fList, PathID name, string rootPath, ref Dictionary<string, AssetBundle> loadList)
    {
        if (loadList.ContainsKey(name.ToString()))
        {
            return loadList[name.ToString()];
        }
        if (mani != null)
        {
            foreach (string s in mani.GetAllDependencies(name.ToString()))
            {
                LoadAssetFromAB(mani, fList, new PathID(s), rootPath, ref loadList);
            }
        }
        if (fList.Contains(name))
        {
            var fInfo = fList.GetFileInfo(name);
            var fDir = fInfo.hash.ToString().Substring(0, 2);
            var path = rootPath + fDir + "/" + fInfo.hash;
            //path = rootPath + name.ToString();
            if (File.Exists(path))
            {
                var ab = AssetBundle.LoadFromFile(path);
                loadList.Add(name.ToString(), ab);
                return ab;
            }
        }
        return null;
    }

    private static AssetBundle ReadAssetbundleFromFileList(string rootPath, string path)
    {
        var fList = new FileList();
        fList.Load(rootPath + "FileList.md");
        // 依赖
        CustomAssetBundleManifest mani = LoadManifest(fList, "Bundles", rootPath);

        Debug.Log("--------------------------");
        AssetBundle ab = null;
        ab = LoadAssetFromAB(mani, fList, new PathID(path), rootPath, ref loadList);
        return ab;
    }
    public static void BuildPrefab(int id, string inputPath, string prefabDir, string filters = "")
    {
        Log("合并模型开始-----------Start-----------" + " id:" + id);
        if (File.Exists(inputPath + id + ".json") == false)
        {
            LogError("找不到套装 json :" + id + " " + inputPath + id + ".json");
            return;
        }
        Log("inputPath:" + inputPath);
        Log("prefabDir:" + prefabDir);
        string json = File.ReadAllText(inputPath + id + ".json");
        ModelEditorModelJsonData jsonObj = JsonUtility.FromJson<ModelEditorModelJsonData>(json);
        string sex = jsonObj.sex == 0 ? "man" : "woman";
        Log("sex:" + sex);
        GameObject go = new GameObject(id.ToString());
        // 主骨骼
        Transform[] transforms = null;
        Material material = null;
        Transform rootBone = null;
        List<CombineInstance> cis = new List<CombineInstance>();
        List<Transform> boneList = new List<Transform>();
        List<Texture2D> textures = new List<Texture2D>();
        List<int> types = new List<int>();
        List<Texture2D> textures_normal = new List<Texture2D>();
        List<Texture2D> texture2_pbr = new List<Texture2D>();
        int width = 0;
        int height = 0;
        int uvCount = 0;
        List<Vector2[]> uvs = new List<Vector2[]>();
        // 加载全骨骼
        GameObject boneParentGameObject;
        // 在编辑器里用的是prefab
        if (filters == ".prefab")
        {
            boneParentGameObject = GameObject.Instantiate(PrefabUtility.LoadPrefabContents("Assets/Res/game_assets/Model/Bone/" + sex + ".prefab"));
        }
        else
        {
            AssetBundle boneAB = ReadAssetbundleFromFileList(prefabDir, "Model/Bone/" + sex + ".prefab.bundle");
            boneParentGameObject = GameObject.Instantiate(boneAB.LoadAsset<GameObject>("Model/Bone/" + sex + ".prefab"));
        }
        transforms = boneParentGameObject.GetComponentsInChildren<Transform>();
        Dictionary<string, Transform> m_TargetBones = new Dictionary<string, Transform>();
        var data = boneParentGameObject.GetComponent<SkinnedMeshBoneData>();
        if (data)
        {
            var names = data.boneNames;
            var bones = data.boneTfs;
            if (names != null && bones != null && names.Length > 0 && names.Length == bones.Length)
            {
                for (int z = 0; z < names.Length; ++z)
                {
                    m_TargetBones[names[z]] = bones[z];
                }
            }
        }

        List<SkinnedMeshRenderer> skmrs = new List<SkinnedMeshRenderer>();
        for (int i = 0; i < jsonObj.equipData.Length; i++)
        {
            int modelId = jsonObj.equipData[i].id;
            string res = jsonObj.equipData[i].res;
            int type = jsonObj.equipData[i].type;
            if (jsonObj.equipData[i].save == false) continue;
            if (modelId != 0)
            {
                // 先检查文件是否存在，如果不存在报错吧，下载流程还是在编辑器里去下载
                string _p = prefabDir + sex + "/" + res + filters;
                GameObject _go;
                // 在编辑器里用的是prefab
                if (filters == ".prefab")
                {
                    if (File.Exists(_p) == false)
                    {
                        LogError(_p + "模型部件不存在:" + modelId + " suitId:" + id);
                        return;
                    }
                    _go = PrefabUtility.LoadPrefabContents(_p);
                }
                else
                {
                    // 这里用的是ab包
                    string bundler = "Model/Parts/" + sex + "/" + res + ".prefab.bundle";
                    AssetBundle ab = ReadAssetbundleFromFileList(prefabDir, bundler);
                    _go = ab.LoadAsset<GameObject>("Model/Parts/" + sex + "/" + res + ".prefab");
                }

                var smrd = _go.GetComponent<SkinnedMeshRendererData>();
                var smr = _go.GetComponent<SkinnedMeshRenderer>();
                skmrs.Add(smr);
                string rootBoneName = smrd ? smrd.rootBoneName : smr.rootBone?.name;
                smr.rootBone = m_TargetBones[rootBoneName];

                var boneNames = smrd ? smrd.boneNames : SkinnedMeshRendererData.GetBoneNames(smr);
                var bones = new Transform[boneNames.Length];
                for (int z = 0; z < bones.Length; ++z)
                {
                    var bone = m_TargetBones[boneNames[z]];
                    //这里不要加判断 直接暴露问题 不应该出现骨骼名不在基础骨骼中的情况
                    if (!bone)
                    {
                        Debug.LogError(_go.name + " boneNames[i]=" + boneNames[z] + " i=" + z);
                        bones[z] = null;
                        continue;
                    }
                    bones[z] = bone;
                }
                smr.bones = bones;

                if (material == null)
                {
                    material = UnityEngine.Object.Instantiate(smr.sharedMaterial);
                }
                for (int z = 0; z < smr.sharedMesh.subMeshCount; z++)
                {
                    var ci = new CombineInstance();
                    ci.mesh = smr.sharedMesh;
                    ci.mesh.triangles = smr.sharedMesh.triangles;
                    ci.subMeshIndex = z;
                    cis.Add(ci);
                }

                uvs.Add(smr.sharedMesh.uv);
                uvCount += smr.sharedMesh.uv.Length;

                if (smr.sharedMaterial.mainTexture != null)
                {
                    types.Add(type);
                    textures.Add(smr.sharedMaterial.mainTexture as Texture2D);
                    width = smr.sharedMaterial.mainTexture.width;
                    height = smr.sharedMaterial.mainTexture.height;
                }
                else
                {
                    LogError("主纹理找不到" + modelId + " suitId:" + id);
                    // 没主纹理
                    return;
                }
                if (smr.sharedMaterial.GetTexture("_NormalTex") != null)
                {
                    textures_normal.Add(smr.sharedMaterial.GetTexture("_NormalTex") as Texture2D);
                }
                else
                {
                    // 没normal
                    LogError("法线图找不到" + modelId + " suitId:" + id);
                    return;
                }
                if (smr.sharedMaterial.GetTexture("_PBRTex") != null)
                {
                    texture2_pbr.Add(smr.sharedMaterial.GetTexture("_PBRTex") as Texture2D);
                }
                else
                {
                    LogError("AO图找不到" + modelId + " suitId:" + id);
                    // 没pbr
                    return;
                }

                for (int z = 0; z < smr.bones.Length; z++)
                {
                    var _temp_Transform = smr.bones[z];
                    if (transforms != null)
                    {
                        for (int u = 0; u < transforms.Length; u++)
                        {
                            if (_temp_Transform.name == transforms[u].name)
                            {
                                if (!boneList.Contains(transforms[u]))
                                    boneList.Add(transforms[u]);
                            }
                        }
                    }
                    else
                    {
                        if (!boneList.Contains(smr.bones[z]))
                            boneList.Add(smr.bones[z]);
                    }
                }

            }
        }

        if (rootBone == null)
        {
            rootBone = FindBestRootBone(boneParentGameObject.transform, skmrs.ToArray());
        }

        Log("内存建模成功 suitId:" + id);
        GameObject skinGo = new GameObject("skinmesh");
        SkinnedMeshRenderer meshRenderer = skinGo.AddComponent<SkinnedMeshRenderer>();
        skinGo.transform.SetParent(go.transform);
        Material[] combinedMaterials;
        Transform[] combinedBones;
        //meshRenderer.sharedMesh = new Mesh();
        var mesh = CombineMeshes(boneParentGameObject.transform, skmrs.ToArray(), out combinedMaterials, out combinedBones);
        meshRenderer.sharedMesh = mesh;
        //meshRenderer.sharedMesh.CombineMeshes(cis.ToArray(), true, false);
        meshRenderer.rootBone = rootBone;
        meshRenderer.bones = combinedBones;
        meshRenderer.sharedMaterial = material;
        Log("资源建模开始 suitId:" + id);

        var t2d_diff = new Texture2D(get2Pow(width), get2Pow(height), TextureFormat.RGBA32, false);
        var t2d_normal = new Texture2D(t2d_diff.width, t2d_diff.height, TextureFormat.RGBA32, false);
        var t2d_pbr = new Texture2D(t2d_diff.width, t2d_diff.height, TextureFormat.RGBA32, false);

        MergeTexture(ref t2d_diff, textures, types);
        MergeTexture(ref t2d_normal, textures_normal, types);
        MergeTexture(ref t2d_pbr, texture2_pbr, types);
        //var rects = t2d_diff.PackTextures(textures.ToArray(), 0, 2048);
        //t2d_normal.PackTextures(textures_normal.ToArray(), 0, 2048);
        //t2d_pbr.PackTextures(texture2_pbr.ToArray(), 0, 2048);

        var newUVS = new List<Vector2>();
        for (int i = 0; i < uvs.Count; i++)
        {
            var _uvs = uvs[i];
            //var _uvRect = rects[i];
            for (int j = 0; j < _uvs.Length; j++)
            {
                //var _v = new Vector2();
                //_v.x = Mathf.Lerp(_uvRect.xMin, _uvRect.xMax, _uvs[j].x);
                //_v.y = Mathf.Lerp(_uvRect.yMin, _uvRect.yMax, _uvs[j].y);
                newUVS.Add(_uvs[j]);
            }
        }

        meshRenderer.sharedMaterial.mainTexture = t2d_diff;
        meshRenderer.sharedMaterial.SetTexture("_NormalTex", t2d_normal);
        meshRenderer.sharedMaterial.SetTexture("_PBRTex", t2d_pbr);
        meshRenderer.sharedMesh.SetUVs(0, newUVS);
        meshRenderer.sharedMesh.RecalculateBounds();
        Log("资源建模成功 suitId:" + id);

        MeshUtility.Optimize(meshRenderer.sharedMesh);
        Log("资源建模成功 准备写入纹理 suitId:" + id);
        Log("Application.dataPath:" + Application.dataPath);
        var subOutPath = "Res/game_assets/Model/Suit/" + id + "/";
        if (Directory.Exists(Application.dataPath + "/" + subOutPath) == false)
            Directory.CreateDirectory(Application.dataPath + "/" + subOutPath);
        Log("设置项目临时目录:" + subOutPath);

        meshRenderer.sharedMaterial.shader = Shader.Find("MD/Character/CharacterPBR");
        AssetDatabase.CreateAsset(meshRenderer.sharedMesh, "Assets/" + subOutPath + id + ".mesh");
        AssetDatabase.CreateAsset(meshRenderer.sharedMaterial, "Assets/" + subOutPath + id + ".mat");

        Log("网格 材质球 创建完成 suitId:" + id);
        //t2d_diff.Compress(true);
        //t2d_normal.Compress(true);
        //t2d_pbr.Compress(true);

        Log("写入纹理Diff " + Application.dataPath + "/" + subOutPath + id + "_d.png");
        SavePNG(Application.dataPath + "/" + subOutPath + id + "_d.png", t2d_diff);
        Log("写入纹理Normal " + Application.dataPath + "/" + subOutPath + id + "_n.png");
        SavePNG(Application.dataPath + "/" + subOutPath + id + "_n.png", t2d_normal);
        Log("写入纹理PBR " + Application.dataPath + "/" + subOutPath + id + "_p.png");
        SavePNG(Application.dataPath + "/" + subOutPath + id + "_p.png", t2d_pbr);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Log("纹理写入完成 准备设置材质 suitId:" + id);

        meshRenderer.sharedMesh = AssetDatabase.LoadAssetAtPath<Mesh>("Assets/" + subOutPath + id + ".mesh");
        meshRenderer.sharedMaterial = AssetDatabase.LoadAssetAtPath<Material>("Assets/" + subOutPath + id + ".mat");
        meshRenderer.sharedMaterial.mainTexture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/" + subOutPath + id + "_d.png");
        meshRenderer.sharedMaterial.SetTexture("_NormalTex", AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/" + subOutPath + id + "_n.png"));
        meshRenderer.sharedMaterial.SetTexture("_PBRTex", AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/" + subOutPath + id + "_p.png"));
        AssetDatabase.SaveAssets();
        Log("材质设置成功 创建预制 suitId:" + id);

        var _skmr = go.GetComponent<SkinnedMeshRenderer>();
        if (_skmr)
        {
            GameObject.DestroyImmediate(_skmr);
        }
        // 整合TCFramework的 mesh renderer data
        var modelSkinInfo = go.AddComponent<SkinnedMeshRendererData>();
        modelSkinInfo.Save(meshRenderer);
        UnityEditorInternal.ComponentUtility.CopyComponent(meshRenderer);
        UnityEditorInternal.ComponentUtility.PasteComponentAsNew(go);
        Transform[] childs = go.GetComponentsInChildren<Transform>();
        foreach (Transform t in childs)
        {
            if (t)
            {
                if (t.gameObject.name != id.ToString())
                {
                    GameObject.DestroyImmediate(t.gameObject);
                }
            }
        }

        UnityEngine.Object.DestroyImmediate(skinGo);
        PrefabUtility.SaveAsPrefabAsset(go, Application.dataPath + "/" + subOutPath + id + ".prefab");
        AssetDatabase.SaveAssets();

        SimplifierMesh("Assets/" + subOutPath + id, go.GetComponent<SkinnedMeshRenderer>().sharedMesh, id.ToString(), go);
        //var goIm = AssetImporter.GetAtPath("Assets/" + subOutPath + id + ".prefab");
        //goIm.assetBundleName = "model/suit/" + id;
        //Log("设置prefab-ab标签:" + id);
        //AssetDatabase.SaveAssets();

        AssetDatabase.Refresh();


        UnityEngine.Object.DestroyImmediate(go);
        UnityEngine.Object.DestroyImmediate(boneParentGameObject);
        Log("预制创建成功 suitId:" + id + " Path:" + Application.dataPath + "/" + subOutPath + id + ".prefab");
        Log("开始设置纹理压缩格式");

        TextureImportSetting("Assets/" + subOutPath + id + "_d.png", false, 2048, TextureImporterType.Default);
        TextureImportSetting("Assets/" + subOutPath + id + "_n.png", false, 2048, TextureImporterType.NormalMap);
        TextureImportSetting("Assets/" + subOutPath + id + "_p.png", false, 2048, TextureImporterType.Default);
        Log("纹理压缩格式设置完成");

        AssetDatabase.Refresh();

        Log("合并模型结束-----------End-----------" + " id:" + id);
    }

    private static void SimplifierMesh(string path, Mesh mesh, string name, GameObject go, float mQuality = 0.5f, float lQuality = 0.1f)
    {
        string parent = Application.dataPath + "/" + PathEx.RemoveBack(PathEx.RemoveFront(path)) + "/Compress/";
        if (!Directory.Exists(parent))
        {
            Directory.CreateDirectory(parent);
        }
        SimplifierMeshByQuality(mQuality, "M", path, mesh, name, go);
        SimplifierMeshByQuality(lQuality, "L", path, mesh, name, go);
    }

    private static void SimplifierMeshByQuality(float q, string sq, string path, Mesh mesh, string name, GameObject go)
    {
        var ms = new MeshSimplifier(mesh);
        var option = SimplificationOptions.Default;
        option.PreserveUVSeamEdges = true;
        option.PreserveUVFoldoverEdges = true;
        ms.SimplificationOptions = option;
        ms.SimplifyMesh(q);

        var smesh = ms.ToMesh();
        smesh.bindposes = mesh.bindposes;

        AssetDatabase.CreateAsset(smesh, PathEx.RemoveBack(path) + "/Compress/" + name + "_" + sq + ".mesh");
        AssetDatabase.Refresh();
        GameObject mGo = GameObject.Instantiate(go);
        var mf = mGo.GetComponentInChildren<MeshFilter>();
        if (mf)
        {
            mf.sharedMesh = smesh;
        }
        else
        {
            var smr = mGo.GetComponentInChildren<SkinnedMeshRenderer>();
            smr.sharedMesh = smesh;
        }
        PrefabUtility.SaveAsPrefabAsset(mGo, PathEx.RemoveBack(path) + "/" + name + "_" + sq + ".prefab");
        GameObject.DestroyImmediate(mGo);
    }

    private static Transform FindBestRootBone(Transform transform, SkinnedMeshRenderer[] skinnedMeshRenderers)
    {
        if (skinnedMeshRenderers == null || skinnedMeshRenderers.Length == 0)
            return null;

        Transform bestBone = null;
        float bestDistance = float.MaxValue;
        for (int i = 0; i < skinnedMeshRenderers.Length; i++)
        {
            if (skinnedMeshRenderers[i] == null || skinnedMeshRenderers[i].rootBone == null)
                continue;

            var rootBone = skinnedMeshRenderers[i].rootBone;
            var distance = (rootBone.position - transform.position).sqrMagnitude;
            if (distance < bestDistance)
            {
                bestBone = rootBone;
                bestDistance = distance;
            }
        }

        return bestBone;
    }

    // 遮罩1
    // 类型1 上衣G
    // 类型3 裤子B

    // 遮罩2
    // 类型6 脸R
    // 类型4 鞋子G
    // 类型2 手B
    // 类型5 头发A
    static void MergeTexture(ref Texture2D t, List<Texture2D> textures, List<int> types)
    {
        for (int i = 0; i < types.Count; i++)
        {
            var type = types[i];
            var mask = maskTexture2;
            if (type == 1 || type == 3)
            {
                mask = maskTexture1;
            }

            var source = textures[i];
            for (int j = 0; j < t.height; j++)
            {
                for (int z = 0; z < t.width; z++)
                {
                    var maskColor = mask.GetPixel(z, j);
                    float maskPick = 0;
                    if (type == 6)
                    {
                        maskPick = maskColor.r;
                    }
                    else if (type == 1 || type == 4)
                    {
                        maskPick = maskColor.g;
                    }
                    else if (type == 3 || type == 2)
                    {
                        maskPick = maskColor.b;
                    }
                    else if (type == 5)
                    {
                        maskPick = maskColor.a;
                    }
                    if (maskPick <= 0.1f)
                    {
                        continue;
                    }
                    var sourceColor = source.GetPixel(z, j);
                    t.SetPixel(z, j, sourceColor);
                }
            }
        }
    }

    static void TextureImportSetting(string patch, bool isReadable, int size = 2048, TextureImporterType TexType = TextureImporterType.Default)
    {
        var importer = AssetImporter.GetAtPath(patch) as TextureImporter;

        importer.textureType = TexType;
        importer.isReadable = isReadable;
        importer.mipmapEnabled = true;
        bool _isPowerof2 = isPowerOf2(importer);
        bool _isDivisibleOf4 = isDivisibleOf4(importer);
        TextureImporterPlatformSettings androidSetting = importer.GetPlatformTextureSettings("Android");
        androidSetting.maxTextureSize = size;
        androidSetting.overridden = true;
        androidSetting.textureCompression = TextureImporterCompression.Compressed;
        androidSetting.compressionQuality = 80;
        TextureImporterFormat androidDefaultAlpha = _isDivisibleOf4 ? TextureImporterFormat.ETC2_RGBA8Crunched : TextureImporterFormat.ASTC_4x4;
        TextureImporterFormat androidDefaultNotAlpha = _isDivisibleOf4 ? TextureImporterFormat.ETC_RGB4Crunched : TextureImporterFormat.ASTC_6x6;
        androidSetting.format = importer.DoesSourceTextureHaveAlpha() ? androidDefaultAlpha : androidDefaultNotAlpha;
        importer.SetPlatformTextureSettings(androidSetting);

        TextureImporterPlatformSettings iosSetting = importer.GetPlatformTextureSettings("iPhone");
        iosSetting.maxTextureSize = size;
        iosSetting.overridden = true;
        iosSetting.textureCompression = TextureImporterCompression.Compressed;
        iosSetting.compressionQuality = 80;
        TextureImporterFormat iOSDefaultAlpha = _isPowerof2 ? TextureImporterFormat.PVRTC_RGBA4 : TextureImporterFormat.ASTC_4x4;
        TextureImporterFormat iOSDefaultNotAlpha = _isPowerof2 ? TextureImporterFormat.PVRTC_RGB4 : TextureImporterFormat.ASTC_6x6;
        iosSetting.format = importer.DoesSourceTextureHaveAlpha() ? iOSDefaultAlpha : iOSDefaultNotAlpha;
        importer.SetPlatformTextureSettings(iosSetting);

        TextureImporterPlatformSettings pcSetting = importer.GetPlatformTextureSettings("Standalone");
        pcSetting.maxTextureSize = size;
        pcSetting.overridden = true;
        pcSetting.textureCompression = TextureImporterCompression.Compressed;
        pcSetting.compressionQuality = 80;

        if (importer.textureType == TextureImporterType.NormalMap)
        {
            pcSetting.format = TextureImporterFormat.DXT5Crunched;
        }
        else
        {
            pcSetting.format = importer.DoesSourceTextureHaveAlpha() ? TextureImporterFormat.DXT5Crunched : TextureImporterFormat.DXT1Crunched;
        }
        importer.SetPlatformTextureSettings(pcSetting);
        AssetDatabase.ImportAsset(patch, ImportAssetOptions.ForceUpdate);
    }

    // 整除4
    private static bool isDivisibleOf4(TextureImporter importer)
    {
        (int width, int height) = getTextureImporterSize(importer);
        return (width % 4 == 0 && height % 4 == 0);
    }

    // 2的整数次幂
    private static bool isPowerOf2(TextureImporter importer)
    {
        (int width, int height) = getTextureImporterSize(importer);
        return (width == height) && (width > 0) && ((width & (width - 1)) == 0);
    }

    private static (int, int) getTextureImporterSize(TextureImporter importer)
    {
        object[] args = new object[2];
        MethodInfo methodInfo = typeof(TextureImporter).GetMethod("GetWidthAndHeight", BindingFlags.NonPublic | BindingFlags.Instance);
        methodInfo.Invoke(importer, args);
        return ((int)args[0], (int)args[1]);
    }

    public static Texture2D LoadImg(string path)
    {
        FileStream sr = new FileStream(path, FileMode.Open, FileAccess.Read);
        byte[] r = new byte[4];
        sr.Read(r, 0, 4);
        var w = BitConverter.ToInt32(r);
        r = new byte[4];
        sr.Read(r, 0, 4);
        var h = BitConverter.ToInt32(r);
        r = new byte[4];
        sr.Read(r, 0, 4);
        var format = BitConverter.ToInt32(r);
        r = new byte[(int)sr.Length - 12];
        sr.Read(r, 0, r.Length);
        sr.Close();
        sr.Dispose();
        var data = new Texture2D(w, h, (TextureFormat)format, false);
        data.LoadImage(r);
        data.Apply();
        return data;
    }

    private static void SavePNG(string path, Texture2D t2d)
    {
        byte[] bytes = t2d.EncodeToPNG();
        File.WriteAllBytes(path, bytes);

        /**byte[] imgW = BitConverter.GetBytes(t2d.width);
        byte[] imgH = BitConverter.GetBytes(t2d.height);
        byte[] imgFormat = BitConverter.GetBytes((int)t2d.format);
        byte[] imgData = t2d.GetRawTextureData();
        FileStream fs = new FileStream(path, FileMode.OpenOrCreate, FileAccess.ReadWrite);
        fs.Seek(0, SeekOrigin.Begin);
        fs.Write(imgW, 0, 4);
        fs.Seek(4, SeekOrigin.Begin);
        fs.Write(imgH, 0, 4);
        fs.Seek(8, SeekOrigin.Begin);
        fs.Write(imgFormat, 0, 4);
        fs.Seek(12, SeekOrigin.Begin);
        fs.Write(imgData, 0, imgData.Length);
        fs.Close();
        fs.Dispose();**/
    }

    private static int get2Pow(int intV)
    {
        int o = 1;
        for (int i = 0; i < 12; i++)
        {
            o *= 2;
            if (o >= intV)
            {
                break;
            }
        }
        return o;
    }

    static StreamWriter m_ConsoleOutStreamWriter;
    [DllImport("kernel32.dll")]
    public static extern bool AttachConsole(uint processId);
    [DllImport("kernel32.dll", EntryPoint = "GetStdHandle", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    private static extern IntPtr GetStdHandle(int nStdHandle);
    static System.Diagnostics.Stopwatch m_StopWatch = new System.Diagnostics.Stopwatch();
    static Microsoft.Win32.SafeHandles.SafeFileHandle m_SafeStdOutputHandle;
    const int STD_OUTPUT_HANDLE = -11;
    static FileStream m_ConsoleOutStream;

    public static void InitConsole()
    {

        if (Application.isBatchMode)
        {
            AttachConsole(0xFFFFFFFF);
            IntPtr stdHandle = GetStdHandle(STD_OUTPUT_HANDLE);
            m_SafeStdOutputHandle = new Microsoft.Win32.SafeHandles.SafeFileHandle(stdHandle, true);
            m_ConsoleOutStream = new FileStream(m_SafeStdOutputHandle, FileAccess.Write);
            m_ConsoleOutStreamWriter = new StreamWriter(m_ConsoleOutStream, Encoding.GetEncoding("GB2312"));
            m_ConsoleOutStreamWriter.AutoFlush = true;
        }
    }

    static void DisposeConsole()
    {
        if (Application.isBatchMode)
        {
            m_ConsoleOutStreamWriter.Dispose();
            m_ConsoleOutStream.Dispose();
            m_SafeStdOutputHandle.Dispose();
        }
    }

    static void Log(string message)
    {
        m_ConsoleOutStreamWriter?.WriteLine(GetTimeStr() + message);
        Debug.Log(message);
    }

    static void LogError(string message)
    {
        Console.ForegroundColor = ConsoleColor.Red;
        m_ConsoleOutStreamWriter?.WriteLine(GetTimeStr() + message);
        Console.ForegroundColor = ConsoleColor.White;
        Debug.LogError(message);
    }

    static string GetTimeStr()
    {
        return DateTime.Now.ToString("[HH:mm:ss]");
    }

    [Serializable]
    private class ModelEditorModelJsonData
    {
        public int createTime;
        public int sex;
        public int job;
        public ModelEditorModelsJsonData[] equipData;
    }

    [Serializable]
    private class ModelEditorModelsJsonData
    {
        public int type;
        public int id;
        public string res;
        public bool save;
    }

    [Serializable]
    private class ModelEditorModelsJsonList
    {
        public int[] idList;
    }


    //=======================================================================combinemesh

    public static Mesh CombineMeshes(Transform rootTransform, SkinnedMeshRenderer[] renderers, out Material[] resultMaterials, out Transform[] resultBones)
    {
        var meshes = new Mesh[renderers.Length];
        var transforms = new Matrix4x4[renderers.Length];
        var materials = new Material[renderers.Length][];
        var bones = new Transform[renderers.Length][];

        for (int i = 0; i < renderers.Length; i++)
        {
            var renderer = renderers[i];

            var rendererTransform = renderer.transform;
            meshes[i] = renderer.sharedMesh;
            transforms[i] = rendererTransform.worldToLocalMatrix * rendererTransform.localToWorldMatrix;
            materials[i] = renderer.sharedMaterials;
            bones[i] = renderer.bones;
        }

        return CombineMeshes(meshes, transforms, materials, bones, out resultMaterials, out resultBones);
    }

    public static Mesh CombineMeshes(Mesh[] meshes, Matrix4x4[] transforms, Material[][] materials, Transform[][] bones, out Material[] resultMaterials, out Transform[] resultBones)
    {
        int totalVertexCount = 0;
        int totalSubMeshCount = 0;
        for (int meshIndex = 0; meshIndex < meshes.Length; meshIndex++)
        {
            var mesh = meshes[meshIndex];

            totalVertexCount += mesh.vertexCount;
            totalSubMeshCount += mesh.subMeshCount;
        }

        var combinedVertices = new List<Vector3>(totalVertexCount);
        var combinedIndices = new List<int[]>(totalSubMeshCount);
        List<Vector3> combinedNormals = null;
        List<Vector4> combinedTangents = null;
        List<BoneWeight> combinedBoneWeights = null;

        List<Matrix4x4> usedBindposes = null;
        List<Transform> usedBones = null;
        var usedMaterials = new List<Material>(totalSubMeshCount);
        var materialMap = new Dictionary<Material, int>(totalSubMeshCount);

        int currentVertexCount = 0;
        for (int meshIndex = 0; meshIndex < meshes.Length; meshIndex++)
        {
            var mesh = meshes[meshIndex];
            var meshTransform = transforms[meshIndex];
            var meshMaterials = materials[meshIndex];
            var meshBones = (bones != null ? bones[meshIndex] : null);

            int subMeshCount = mesh.subMeshCount;
            int meshVertexCount = mesh.vertexCount;
            var meshVertices = mesh.vertices;
            var meshNormals = mesh.normals;
            var meshTangents = mesh.tangents;
            var meshBoneWeights = mesh.boneWeights;
            var meshBindposes = mesh.bindposes;

            // Transform vertices with bones to keep only one bindpose
            if (meshBones != null && meshBoneWeights != null && meshBoneWeights.Length > 0 && meshBindposes != null && meshBindposes.Length > 0 && meshBones.Length == meshBindposes.Length)
            {
                if (usedBindposes == null)
                {
                    usedBindposes = new List<Matrix4x4>(meshBindposes);
                    usedBones = new List<Transform>(meshBones);
                }

                int[] boneIndices = new int[meshBones.Length];
                for (int i = 0; i < meshBones.Length; i++)
                {
                    int usedBoneIndex = usedBones.IndexOf(meshBones[i]);
                    if (usedBoneIndex == -1 || meshBindposes[i] != usedBindposes[usedBoneIndex])
                    {
                        usedBoneIndex = usedBones.Count;
                        usedBones.Add(meshBones[i]);
                        usedBindposes.Add(meshBindposes[i]);
                    }
                    boneIndices[i] = usedBoneIndex;
                }

                for (int i = 0; i < meshBoneWeights.Length; i++)
                {
                    if (meshBoneWeights[i].weight0 > 0)
                    {
                        meshBoneWeights[i].boneIndex0 = boneIndices[meshBoneWeights[i].boneIndex0];
                    }
                    if (meshBoneWeights[i].weight1 > 0)
                    {
                        meshBoneWeights[i].boneIndex1 = boneIndices[meshBoneWeights[i].boneIndex1];
                    }
                    if (meshBoneWeights[i].weight2 > 0)
                    {
                        meshBoneWeights[i].boneIndex2 = boneIndices[meshBoneWeights[i].boneIndex2];
                    }
                    if (meshBoneWeights[i].weight3 > 0)
                    {
                        meshBoneWeights[i].boneIndex3 = boneIndices[meshBoneWeights[i].boneIndex3];
                    }
                }
            }

            // Transforms the vertices, normals and tangents using the mesh transform
            TransformVertices(meshVertices, ref meshTransform);
            TransformNormals(meshNormals, ref meshTransform);
            TransformTangents(meshTangents, ref meshTransform);

            // Copy vertex positions & attributes
            CopyVertexPositions(combinedVertices, meshVertices);
            CopyVertexAttributes(ref combinedNormals, meshNormals, currentVertexCount, meshVertexCount, totalVertexCount, new Vector3(1f, 0f, 0f));
            CopyVertexAttributes(ref combinedTangents, meshTangents, currentVertexCount, meshVertexCount, totalVertexCount, new Vector4(0f, 0f, 1f, 1f));
            CopyVertexAttributes(ref combinedBoneWeights, meshBoneWeights, currentVertexCount, meshVertexCount, totalVertexCount, new BoneWeight());

            for (int subMeshIndex = 0; subMeshIndex < subMeshCount; subMeshIndex++)
            {
                var subMeshMaterial = meshMaterials[subMeshIndex];
                var subMeshIndices = mesh.GetTriangles(subMeshIndex, true);

                if (currentVertexCount > 0)
                {
                    for (int index = 0; index < subMeshIndices.Length; index++)
                    {
                        subMeshIndices[index] += currentVertexCount;
                    }
                }

                int existingSubMeshIndex;
                if (materialMap.TryGetValue(subMeshMaterial, out existingSubMeshIndex))
                {
                    combinedIndices[existingSubMeshIndex] = MergeArrays(combinedIndices[existingSubMeshIndex], subMeshIndices);
                }
                else
                {
                    int materialIndex = combinedIndices.Count;
                    materialMap.Add(subMeshMaterial, materialIndex);
                    combinedIndices.Add(subMeshIndices);
                }
            }

            currentVertexCount += meshVertexCount;
        }

        var resultVertices = combinedVertices.ToArray();
        var resultIndices = combinedIndices.ToArray();
        var resultNormals = (combinedNormals != null ? combinedNormals.ToArray() : null);
        var resultTangents = (combinedTangents != null ? combinedTangents.ToArray() : null);
        var resultBoneWeights = (combinedBoneWeights != null ? combinedBoneWeights.ToArray() : null);
        var resultBindposes = (usedBindposes != null ? usedBindposes.ToArray() : null);
        resultMaterials = usedMaterials.ToArray();
        resultBones = (usedBones != null ? usedBones.ToArray() : null);
        var returnMesh = new Mesh();
        CreateMesh(returnMesh, resultVertices, resultIndices, resultNormals, resultTangents, resultBoneWeights, resultBindposes);
        return returnMesh;
    }

    private static T[] MergeArrays<T>(T[] arr1, T[] arr2)
    {
        var newArr = new T[arr1.Length + arr2.Length];
        System.Array.Copy(arr1, 0, newArr, 0, arr1.Length);
        System.Array.Copy(arr2, 0, newArr, arr1.Length, arr2.Length);
        return newArr;
    }

    private static void CopyVertexPositions(ICollection<Vector3> list, Vector3[] arr)
    {
        if (arr == null || arr.Length == 0)
            return;

        for (int i = 0; i < arr.Length; i++)
        {
            list.Add(arr[i]);
        }
    }

    private static void CopyVertexAttributes<T>(ref List<T> dest, T[] src, int previousVertexCount, int meshVertexCount, int totalVertexCount, T defaultValue)
    {
        if (src == null || src.Length == 0)
        {
            if (dest != null)
            {
                for (int i = 0; i < meshVertexCount; i++)
                {
                    dest.Add(defaultValue);
                }
            }
            return;
        }

        if (dest == null)
        {
            dest = new List<T>(totalVertexCount);
            for (int i = 0; i < previousVertexCount; i++)
            {
                dest.Add(defaultValue);
            }
        }

        dest.AddRange(src);
    }
    private static void TransformVertices(Vector3[] vertices, ref Matrix4x4 transform)
    {
        for (int i = 0; i < vertices.Length; i++)
        {
            vertices[i] = transform.MultiplyPoint3x4(vertices[i]);
        }
    }

    private static void TransformNormals(Vector3[] normals, ref Matrix4x4 transform)
    {
        if (normals == null)
            return;

        for (int i = 0; i < normals.Length; i++)
        {
            normals[i] = transform.MultiplyVector(normals[i]);
        }
    }

    private static void TransformTangents(Vector4[] tangents, ref Matrix4x4 transform)
    {
        if (tangents == null)
            return;

        Vector3 tengentDir;
        for (int i = 0; i < tangents.Length; i++)
        {
            tengentDir = transform.MultiplyVector(new Vector3(tangents[i].x, tangents[i].y, tangents[i].z));
            tangents[i] = new Vector4(tengentDir.x, tengentDir.y, tengentDir.z, tangents[i].w);
        }
    }

    public static void CreateMesh(Mesh newMesh, Vector3[] vertices, int[][] indices, Vector3[] normals, Vector4[] tangents, BoneWeight[] boneWeights, Matrix4x4[] bindposes)
    {
        if (bindposes != null && bindposes.Length > 0)
        {
            newMesh.bindposes = bindposes;
        }

        newMesh.vertices = vertices;
        if (normals != null && normals.Length > 0)
        {
            newMesh.normals = normals;
        }
        if (tangents != null && tangents.Length > 0)
        {
            newMesh.tangents = tangents;
        }
        if (boneWeights != null && boneWeights.Length > 0)
        {
            newMesh.boneWeights = boneWeights;
        }

        List<int> t = new List<int>();
        for (int subMeshIndex = 0; subMeshIndex < indices.Length; subMeshIndex++)
        {
            var subMeshTriangles = indices[subMeshIndex];
            t.AddRange(subMeshTriangles);
        }
        newMesh.SetTriangles(t.ToArray(), 0, false, 0);

        newMesh.RecalculateBounds();
    }
}
