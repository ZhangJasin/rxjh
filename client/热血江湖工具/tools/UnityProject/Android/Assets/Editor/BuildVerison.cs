using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using TCFramework;
using UnityEditor;
using UnityEditor.Build.Content;
using UnityEditor.Build.Pipeline;
using UnityEditor.Build.Pipeline.Interfaces;
using UnityEditor.Build.Pipeline.Utilities;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using BuildCompression = UnityEngine.BuildCompression;
using Object = UnityEngine.Object;

public class BuildVerison
{
    class CustomBundleBuildParameters : BundleBuildParameters
    {
        public CustomBundleBuildParameters(BuildTarget target, BuildTargetGroup group, string outputFolder)
            : base(target, group, outputFolder)
        { }

        public override BuildCompression GetCompressionForIdentifier(string identifier)
        {
            return IsVideoClip(identifier) ? BuildCompression.Uncompressed : BuildCompression.LZ4;
        }

        static readonly string[] VIDEO_CLIP_EXTENSIONS =
        {
                ".mov",
                ".mpg",
                ".mpeg",
                ".mp4",
                ".avi",
                ".asf",
            };

        static bool IsVideoClip(string identifier)
        {
            foreach (var ext in VIDEO_CLIP_EXTENSIONS)
            {
                if (identifier.Contains(ext))
                    return true;
            }
            return false;
        }
    }

    const string RES_DIR = "Assets/TempRes/";
    const string BUILD_CONFIG_FILE = "../Config/BuildConfig.json";
    const string BUNDLES = "Bundles";
    const string FILELIST_FILE = "FileList.md";
    const string BUNDLE_EXT = ".bundle";
    const string PLACEMENT_DIR_NAME = "Placements";
    const string SAVED_META_FILES_DIR = "SavedMetaFiles/";
    const string SAVED_META_FILES_DIR_SLASH = "/" + SAVED_META_FILES_DIR;
    const string META_FILE_EXT = ".meta";

    // Model Shader Dir Path
    const string PATH_MODEL_SHADER_DIR = "CustomModelShader/Shader";

    // Model Shader
    const string MODEL_SHADER = "Character/CharacterPBR.shader";
    static string PATH_MODEL_SHADER = string.Empty;
    static Shader Character_Shader = null;

    static readonly string[] IGNORE_FILE_NAMES =
    {
        "AtlasConfig.json",
    };

    static readonly string[] IGNORE_DIR_NAMES =
    {
        "/Placements/",
        "/__RULE__/",
    };

#pragma warning disable 0649
    [Serializable]
    struct DirectoryConfig
    {
        public string dir;
        public string extensions;
        public string build;
        public string type;
        public int package;
        public string textureCompression;
        public string ignoreExtensions;// 忽略的文件格式
    }

    [Serializable]
    struct BuildConfig
    {
        public bool disableTypeTree;
        public DirectoryConfig[] directories;
    }

    [Serializable]
    class SpriteConfig
    {
        public string name;
        public int borderLeft;
        public int borderRight;
        public int borderTop;
        public int borderBottom;
        public float pixelsPerUnit = -1;

        public static readonly SpriteConfig Default = new SpriteConfig
        {
            pixelsPerUnit = 100,
        };
    }

    [Serializable]
    class AtlasConfig
    {
        public float pixelsPerUnit = 100;
        public SpriteConfig[] sprites;
    }

    [Serializable]
    class ImageAnimationConfig
    {
        public string name;
        public float width;
        public float height;
        public string atlas;
        public int frameRate = 30;
        public int loop;
        public float interval;
    }

    [Serializable]
    class SpriteAnimationConfig
    {
        public string name;
        public string atlas;
        public int frameRate = 30;
        public int loop;
        public float interval;
    }

    [Serializable]
    struct PrefabConfig
    {
        public ImageAnimationConfig[] imageAnimations;
        public SpriteAnimationConfig[] spriteAnimations;
    }
#pragma warning restore 0649

    struct BundleInfo
    {
        public List<string> names;
        public int package;
    }

    struct CopyInfo
    {
        public string name;
        public int package;
    }

    static readonly string[] CUSTOM_DIRS =
    {
        "Lua",
        "data_config",
    };

    static bool IsCustomDir(string dir)
    {
        foreach (var item in CUSTOM_DIRS)
        {
            if (dir.Contains(item))
            {
                return true;
            }
        }
        return false;
    }

    static private int TempQuality = 81;
    internal static void BuildRes(string _inputDir, string outputDir, bool rebuild, bool fastMode, bool removeRes, bool includeModel)
    {
        try
        {
            InitConsole();
            if (string.IsNullOrEmpty(_inputDir))
            {
                throw new ArgumentNullException("inputDir");
            }

            if (string.IsNullOrEmpty(outputDir))
            {
                throw new ArgumentNullException("outputDir");
            }

            Log("打包开始，平台:" + EditorUserBuildSettings.activeBuildTarget, 0);

            List<string> inputDirList = new List<string>();

            string modelSuitInputDir = Application.dataPath + "/Res/game_assets/";

            string _s = StandardDir(_inputDir);
            if (Directory.Exists(_s))
                inputDirList.Add(_s);
            else
                LogError($"{_inputDir}目录不存在----------------");

            if (includeModel)
            {
                _s = StandardDir(modelSuitInputDir);
                if (Directory.Exists(_s))
                {
                    if (!inputDirList.Contains(StandardDir(modelSuitInputDir)))
                    {
                        inputDirList.Add(StandardDir(modelSuitInputDir));
                    }
                    else
                    {
                        Log("小tips:模型目录相同了哦");
                    }
                }
            }

            //inputDir = StandardDir(inputDir);
            outputDir = StandardDir(outputDir);

            for (int z = 0; z < inputDirList.Count; z++)
            {
                string inputDir = inputDirList[z];
                if (!fastMode && Directory.Exists(outputDir))
                {
                    string[] tdirs = Directory.GetDirectories(outputDir);
                    foreach (string dir in tdirs)
                    {
                        if (!IsCustomDir(dir))
                        {
                            string name = StandardDir(dir);
                            //Log($"delete dir {name}");
                            Directory.Delete(name, true);
                        }
                    }

                    string[] tfiles = Directory.GetFiles(outputDir);
                    foreach (string file in tfiles)
                    {
                        string name = StandardDir(file);
                        //Log($"delete file {name}");
                        File.Delete(name);
                    }
                }
            }

            if (!Directory.Exists(outputDir))
            {
                Directory.CreateDirectory(outputDir);
            }

            string android = outputDir + "/~当前是安卓~.tips";
            if (File.Exists(android))
                File.Delete(android);
            string iOS = outputDir + "/~当前是iOS~.tips";
            if (File.Exists(iOS))
                File.Delete(iOS);
            string win = outputDir + "/~当前是Windows~.tips";
            if (File.Exists(win))
                File.Delete(win);
            string h5 = outputDir + "/~当前是H5~.tips";
            if (File.Exists(h5))
                File.Delete(h5);
#if UNITY_ANDROID
            File.Create(android);
#elif UNITY_IOS
            File.Create(iOS);
#elif UNITY_STANDALONE
            File.Create(win);
#elif UNITY_WEBGL
            File.Create(h5);
#endif

            string json = File.ReadAllText(BUILD_CONFIG_FILE);
            BuildConfig buildConfig = JsonUtility.FromJson<BuildConfig>(json);
            ClearAtlasConfigs();

            Dictionary<string, bool> readableDic = GetReadableDic(_inputDir);
            Dictionary<string, bool> webGLSizeDic = GetWebGLSizeDic(_inputDir);
            Dictionary<string, bool> webFormatDic = GetWebFormatDic(_inputDir);
            int buildType = GetBuildType();

            Dictionary<string, BundleInfo> name2Bundles = new Dictionary<string, BundleInfo>();
            List<CopyInfo> copys = new List<CopyInfo>();
            HashSet<string> allFiles = new HashSet<string>();
            HashSet<string> allBundles = new HashSet<string>();

            List<AssetBundleBuild> builds = new List<AssetBundleBuild>();

            //Copy MDPipeline To Package and Shader To Assets
            Log("复制模型shader文件");
            CopyShaderDir();

            Log($"正在刷新文件...", 1);
            AssetDatabase.Refresh();

            //get shader
            PATH_MODEL_SHADER = $"{RES_DIR}Shader/{MODEL_SHADER}";
            Character_Shader = AssetDatabase.LoadAssetAtPath<Shader>(PATH_MODEL_SHADER);
            Log($"加载shader<{Character_Shader}>,如尖括号内shader为Null,说明模型shader未加载到,请重新生成");

            bool luacEnabled = LuaBytecodeGen.enabled;
            foreach (string inputDir in inputDirList)
            {
                List<string> prefabNames = new List<string>();
                HashSet<string> assetSet = new HashSet<string>();

                HashSet<string> changedNames = new HashSet<string>();

                Dictionary<string, List<string>> atlas2Sprites = new Dictionary<string, List<string>>();

                var files = Directory.GetFiles(inputDir, "*.*", SearchOption.AllDirectories);
                //Log($"正在导入{files.Length}个文件...", 0);
                int pindex = 0;
                int count10 = files.Length / 10;

                using (var cmdRunner = luacEnabled ? new CmdRunner(LogError) : null)
                {
                    for (int i = 0; i < files.Length; ++i)
                    {
                        var file = files[i];
                        if (count10 > 0 && pindex % count10 == 0)
                        {
                            Log($"正在导入{files.Length}个文件({pindex / count10 * 10}%)...", 0);
                        }

                        if (pindex++ % 100 == 0)
                        {
                            EditorUtility.DisplayProgressBar("Build Version", "Import " + file, (float)(pindex) / files.Length);
                        }

                        string name = file.Substring(inputDir.Length + 1).Replace('\\', '/');
                        if (IsIgnoreFile(name)) continue;

                        string oldName = name;
                        bool luaBytecode = ChangeLuaPath(ref name) && luacEnabled;
                        string assetPath = RES_DIR + name;
                        if (!luaBytecode && fastMode)
                        {
                            if (CompareFile(file, assetPath))
                                continue;
                            else
                                changedNames.Add(oldName);
                        }

                        ApplySavedMetaFile(inputDir, name);
                        if (luaBytecode)
                            LuaBytecodeGen.GenerateBytecode(file, assetPath, cmdRunner);
                        else
                            CopyFile(file, assetPath);
                    }
                }
                Log($"导入{files.Length}个文件完毕", 1);

                if (fastMode && changedNames.Count == 0)
                {
                    Log("没有文件需要生成。");
                    return;
                }

                AssetDatabase.Refresh();
                AssetDatabase.StartAssetEditing();
                pindex = 0;
                foreach (var file in files)
                {
                    if (count10 > 0 && pindex % count10 == 0)
                    {
                        Log($"正在处理{files.Length}个文件({pindex / count10 * 10}%)...", 0);
                    }

                    string name = file.Substring(inputDir.Length + 1).Replace('\\', '/');
                    if (pindex++ % 100 == 0)
                    {
                        EditorUtility.DisplayProgressBar("Build Version", "Process " + name, (float)(pindex) / files.Length);
                    }

                    if (file.EndsWith(META_FILE_EXT)) continue;
                    if (IsIgnoreFile(name)) continue;

                    if (IsPrefabFile(name))
                    {
                        prefabNames.Add(name);
                        continue;
                    }

                    string assetPath = RES_DIR + name;
                    bool webFormatBool = false;
                    foreach (var kvp in webFormatDic)
                    {
                        if (assetPath.Contains(kvp.Key))
						{
                            webFormatBool = true;
                            break;
                        }
                    }
                    var config = GetDirectoryConfig(buildConfig, name);
                    if (config.build != "copy")
                    {
                        Type assetType = AssetDatabase.GetMainAssetTypeAtPath(assetPath);
                        if (assetType == typeof(DefaultAsset))
                        {
                            LogError($"文件错误，跳过生成：{name}");
                            continue;
                        }
                    }
                    if (!string.IsNullOrEmpty(config.ignoreExtensions))
                    {
                        continue;
                    }

                    assetSet.Add(assetPath);
                    Log($"正在处理->{assetPath} {config.type}");
                    switch (config.type)
                    {
                        case "sprite":
                            {
                                int index = name.LastIndexOf('/');
                                var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                                if (index != -1 && importer != null)
                                {
                                    string dir = name.Substring(0, index);

                                    bool dirty = false;
                                    if (importer.sRGBTexture)
                                    {
                                        importer.sRGBTexture = false;
                                        dirty = true;
                                    }

                                    if (importer.textureType != TextureImporterType.Sprite)
                                    {
                                        importer.textureType = TextureImporterType.Sprite;
                                        dirty = true;
                                    }

                                    Vector2 pivot = new Vector2(0.5f, 0.5f);
                                    string spriteName = Path.GetFileNameWithoutExtension(name);
                                    string placementPath = $"{inputDir}/{dir}/{PLACEMENT_DIR_NAME}/{spriteName}.txt";
                                    if (File.Exists(placementPath))
                                    {
                                        string[] lines = File.ReadAllLines(placementPath);
                                        if (lines.Length == 2 && float.TryParse(lines[0].Trim(), out float x) && float.TryParse(lines[1].Trim(), out float y))
                                        {
                                            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
                                            x /= texture.width;
                                            y /= texture.height;
                                            pivot = new Vector2(-x, 1 + y);
                                        }
                                        else
                                        {
                                            LogError("文件格式错误：" + placementPath);
                                        }
                                    }

                                    if (importer.spritePivot != pivot)
                                    {
                                        TextureImporterSettings tis = new TextureImporterSettings();
                                        importer.ReadTextureSettings(tis);
                                        tis.textureType = TextureImporterType.Sprite;
                                        tis.spriteMode = (int)SpriteImportMode.Single;
                                        tis.spriteAlignment = (int)SpriteAlignment.Custom;
                                        tis.spritePivot = pivot;
                                        importer.SetTextureSettings(tis);
                                        importer.SaveAndReimport();
                                        dirty = true;
                                    }

                                    if (dirty)
                                    {
                                        importer.SaveAndReimport();
                                    }

                                    string atlasName = GetSpriteAtlasPathV1(dir);
                                    if (!atlas2Sprites.TryGetValue(atlasName, out List<string> sprites))
                                    {
                                        sprites = new List<string>();
                                        atlas2Sprites.Add(atlasName, sprites);
                                    }
                                    sprites.Add(assetPath);
                                }
                            }
                            break;
                        case "singleSprite":
                            {
                                int index = name.LastIndexOf('/');
                                var importer = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                                if (index != -1 && importer != null)
                                {
                                    string dir = name.Substring(0, index);

                                    bool dirty = false;
                                    if (importer.sRGBTexture)
                                    {
                                        importer.sRGBTexture = false;
                                        dirty = true;
                                    }

                                    // 设置为精灵并压缩
                                    if (importer.textureType != TextureImporterType.Sprite)
                                    {
                                        importer.textureType = TextureImporterType.Sprite;
                                        bool isHaveAplha = importer.DoesSourceTextureHaveAlpha();
                                        dirty = true;
                                    }

                                    Vector2 pivot = new Vector2(0.5f, 0.5f);
                                    string spriteName = Path.GetFileNameWithoutExtension(name);
                                    string placementPath = $"{inputDir}/{dir}/{PLACEMENT_DIR_NAME}/{spriteName}.txt";
                                    if (File.Exists(placementPath))
                                    {
                                        string[] lines = File.ReadAllLines(placementPath);
                                        if (lines.Length == 2 && float.TryParse(lines[0].Trim(), out float x) && float.TryParse(lines[1].Trim(), out float y))
                                        {
                                            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
                                            x /= texture.width;
                                            y /= texture.height;
                                            pivot = new Vector2(-x, 1 + y);
                                        }
                                        else
                                        {
                                            LogError("文件格式错误：" + placementPath);
                                        }
                                    }

                                    if (importer.spritePivot != pivot)
                                    {
                                        TextureImporterSettings tis = new TextureImporterSettings();
                                        importer.ReadTextureSettings(tis);
                                        tis.textureType = TextureImporterType.Sprite;
                                        tis.spriteMode = (int)SpriteImportMode.Single;
                                        tis.spriteAlignment = (int)SpriteAlignment.Custom;
                                        tis.spritePivot = pivot;
                                        importer.SetTextureSettings(tis);
                                        dirty = true;
                                    }
                                    if (dirty)
                                    {
                                        importer.SaveAndReimport();
                                    }
                                }
                            }
                            break;
                        case "model":
                            {
                                var obj = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
                                if (obj != null && Character_Shader != null)
                                {
                                    Log("正在处理路径" + assetPath + "的模型shader...");
                                    Component[] allFilters = (Component[])obj.GetComponentsInChildren(typeof(MeshRenderer));
                                    Component[] allRenderers = (Component[])obj.GetComponentsInChildren(typeof(SkinnedMeshRenderer));
                                    int mesh_count = allFilters.Length + allRenderers.Length;
                                    if (mesh_count > 0)
                                    {
                                        foreach (Component child in allFilters)
                                        {
                                            for (int k = 0; k < ((MeshRenderer)child).sharedMaterials.Length; k++)
                                            {
                                                if (((MeshRenderer)child).sharedMaterials[k])
                                                {
                                                    ((MeshRenderer)child).sharedMaterials[k].shader = Character_Shader;
                                                }
                                            }
                                        }
                                        foreach (Component child in allRenderers)
                                        {
                                            for (int k = 0; k < ((SkinnedMeshRenderer)child).sharedMaterials.Length; k++)
                                            {
                                                if (((SkinnedMeshRenderer)child).sharedMaterials[k])
                                                {
                                                    ((SkinnedMeshRenderer)child).sharedMaterials[k].shader = Character_Shader;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            break;
                    }

                    var importer2 = AssetImporter.GetAtPath(assetPath) as TextureImporter;
                    if (importer2 != null)
                    {
                        bool isHaveAplha = importer2.DoesSourceTextureHaveAlpha();

                        Log($"正在压缩1->{assetPath} {config.type} {webFormatBool}");
                        if (readableDic.ContainsKey(name))
                        {
                            Log($"Readable png:{name}");
                            importer2.isReadable = true;
                        }
                        importer2.sRGBTexture = importer2.textureType != TextureImporterType.NormalMap;
                        importer2.mipmapEnabled = false;

                        TextureImporterPlatformSettings androidSetting = importer2.GetPlatformTextureSettings("Android");
                        TextureImporterPlatformSettings iosSetting = importer2.GetPlatformTextureSettings("iPhone");
                        TextureImporterPlatformSettings pcSetting = importer2.GetPlatformTextureSettings("Standalone");
                        TextureImporterPlatformSettings webGLSetting = importer2.GetPlatformTextureSettings("WebGL");
                        // 安卓端
                        androidSetting.maxTextureSize = 2048;
                        androidSetting.overridden = true;
                        androidSetting.textureCompression = TextureImporterCompression.Compressed;
                        androidSetting.compressionQuality = TempQuality;
                        if (webFormatBool)
                        {
                            androidSetting.format = isHaveAplha ? TextureImporterFormat.RGBA32 : TextureImporterFormat.RGB24;
                        }
                        else
                        {
                            androidSetting.format = isHaveAplha ? TextureImporterFormat.ASTC_4x4 : TextureImporterFormat.ASTC_6x6;
                        }
                        //androidSetting.format = isHaveAplha ? TextureImporterFormat.ASTC_4x4 : TextureImporterFormat.ASTC_6x6;
                        importer2.SetPlatformTextureSettings(androidSetting);
                        // iOS端
                        iosSetting.maxTextureSize = 2048;
                        iosSetting.overridden = true;
                        iosSetting.textureCompression = TextureImporterCompression.Compressed;
                        iosSetting.compressionQuality = TempQuality;
                        if (webFormatBool)
                        {
                            iosSetting.format = isHaveAplha ? TextureImporterFormat.RGBA32 : TextureImporterFormat.RGB24;
                        }
                        else
                        {
                            iosSetting.format = isHaveAplha ? TextureImporterFormat.ASTC_4x4 : TextureImporterFormat.ASTC_6x6;
                        }
                        //iosSetting.format = isHaveAplha ? TextureImporterFormat.ASTC_4x4 : TextureImporterFormat.ASTC_6x6;
                        importer2.SetPlatformTextureSettings(iosSetting);
                        // PC端
                        pcSetting.maxTextureSize = 2048;
                        pcSetting.overridden = true;
                        pcSetting.textureCompression = TextureImporterCompression.Compressed;
                        pcSetting.compressionQuality = TempQuality;
                        pcSetting.format = isHaveAplha ? TextureImporterFormat.DXT5 : TextureImporterFormat.DXT1;
                        importer2.SetPlatformTextureSettings(pcSetting);
                        // webGL端 (暂时只考虑微信小游戏，PC浏览器需要使用DXT压缩)
                        webGLSetting.overridden = true;
                        webGLSetting.textureCompression = TextureImporterCompression.Compressed;
                        webGLSetting.compressionQuality = TempQuality;
                        webGLSetting.maxTextureSize = 2048;
                        if (webFormatBool)
                        {
                            webGLSetting.format = isHaveAplha ? TextureImporterFormat.RGBA32 : TextureImporterFormat.RGB24;
                        }
                        else
                        {
                            webGLSetting.format = isHaveAplha ? TextureImporterFormat.ASTC_4x4 : TextureImporterFormat.ASTC_6x6;
                        }
                        importer2.SetPlatformTextureSettings(webGLSetting);
                        importer2.SaveAndReimport();
                    }

                    if (config.type == "sprite")
                        continue;

                    string bundleName = null;
                    switch (config.build)
                    {
                        case "copy":
                            if (!fastMode || changedNames.Contains(name))
                            {
                                copys.Add(new CopyInfo
                                {
                                    name = name,
                                    package = config.package,
                                });
                            }
                            break;
                        case "folder":
                            {
                                bundleName = config.dir + BUNDLE_EXT;
                                AddBuild(name2Bundles, bundleName, name, config.package);
                            }
                            break;
                        case "eachFolder":
                            {
                                int index = name.LastIndexOf('/');
                                bundleName = name.Substring(0, index) + BUNDLE_EXT;
                                AddBuild(name2Bundles, bundleName, name, config.package);
                            }
                            break;
                        case "eachSubFolder":
                            {
                                int index = name.IndexOf('/', config.dir.Length + 1);
                                bundleName = (index == -1 ? config.dir : name.Substring(0, index)) + BUNDLE_EXT;
                                AddBuild(name2Bundles, bundleName, name, config.package);
                            }
                            break;
                        default:
                            bundleName = name + BUNDLE_EXT;
                            if (!fastMode || changedNames.Contains(name))
                            {
                                AddBuild(name2Bundles, bundleName, name, config.package);
                            }
                            break;
                    }

                    if (fastMode)
                    {
                        if (bundleName != null)
                        {
                            if (!allFiles.Contains(bundleName)) allFiles.Add(bundleName);
                            if (!allBundles.Contains(bundleName)) allBundles.Add(bundleName);
                        }
                        else
                        {
                            if (!allFiles.Contains(name)) allFiles.Add(name);
                        }
                    }
                }
                Log($"处理{files.Length}个文件完毕", 0);
                Log($"正在刷新文件...", 1);
                AssetDatabase.StopAssetEditing();

                Log($"正在重新生成图集...");
                AssetDatabase.StartAssetEditing();
                foreach (var item in atlas2Sprites)
                {
                    string atlasName = item.Key;
                    ApplySavedFile(inputDir, atlasName);
                    ApplySavedMetaFile(inputDir, atlasName);
                }
                AssetDatabase.StopAssetEditing();

                AssetDatabase.StartAssetEditing();
                foreach (var item in atlas2Sprites)
                {
                    string atlasName = item.Key;
                    bool webFormatBool = false;
                    foreach (var kvp in webFormatDic)
                    {
                        if (atlasName.Contains(kvp.Key))
						{
                            webFormatBool = true;
                            break;
                        }
                    }
                    Log($"正在重新生成图集：{atlasName} {webFormatBool}");
                    List<string> spritePaths = item.Value;

                    var spriteAtlas = new SpriteAtlas();
                    var settings = spriteAtlas.GetPackingSettings();
                    if (readableDic.ContainsKey(atlasName))
                    {
                        Log($"Readable spriteatlas:{atlasName}");
                        settings.enableAlphaDilation = true;
                    }
                    settings.enableTightPacking = false;
                    spriteAtlas.SetPackingSettings(settings);

                    var textureSetting = spriteAtlas.GetTextureSettings();
                    textureSetting.sRGB = false;
                    textureSetting.generateMipMaps = false;
                    if (readableDic.ContainsKey(atlasName))
                    {
                        textureSetting.readable = true;
                    }
                    spriteAtlas.SetTextureSettings(textureSetting);

                    Object[] sprites = new Object[spritePaths.Count];
                    for (int i = 0; i < spritePaths.Count; i++)
                    {
                        sprites[i] = AssetDatabase.LoadAssetAtPath<Sprite>(spritePaths[i]);
                    }
                    spriteAtlas.Add(sprites);

                    TextureImporterPlatformSettings androidSetting = spriteAtlas.GetPlatformSettings("Android");
                    TextureImporterPlatformSettings iosSetting = spriteAtlas.GetPlatformSettings("iPhone");
                    TextureImporterPlatformSettings pcSetting = spriteAtlas.GetPlatformSettings("Standalone");
                    TextureImporterPlatformSettings webGLSetting = spriteAtlas.GetPlatformSettings("WebGL");

                    // 安卓端
                    androidSetting.maxTextureSize = 2048;
                    androidSetting.overridden = true;
                    androidSetting.textureCompression = TextureImporterCompression.Compressed;
                    androidSetting.compressionQuality = TempQuality;
                    if (webFormatBool)
                    {
                        androidSetting.format = TextureImporterFormat.RGBA32;
                    }
                    else
                    {
                        androidSetting.format = TextureImporterFormat.ASTC_4x4;
                    }
                    //androidSetting.format = TextureImporterFormat.ASTC_4x4;
                    spriteAtlas.SetPlatformSettings(androidSetting);
                    // iOS端
                    iosSetting.maxTextureSize = 2048;
                    iosSetting.overridden = true;
                    iosSetting.textureCompression = TextureImporterCompression.Compressed;
                    iosSetting.compressionQuality = TempQuality;
                    if (webFormatBool)
                    {
                        iosSetting.format = TextureImporterFormat.RGBA32;
                    }
                    else
                    {
                        iosSetting.format = TextureImporterFormat.ASTC_4x4;
                    }
                    //iosSetting.format = TextureImporterFormat.ASTC_4x4;
                    spriteAtlas.SetPlatformSettings(iosSetting);
                    // PC端
                    pcSetting.maxTextureSize = 2048;
                    pcSetting.overridden = true;
                    pcSetting.textureCompression = TextureImporterCompression.Compressed;
                    pcSetting.compressionQuality = TempQuality;
                    pcSetting.format = TextureImporterFormat.DXT5;
                    spriteAtlas.SetPlatformSettings(pcSetting);
                    // webGL端 (暂时只考虑微信小游戏，PC浏览器需要使用DXT压缩)
                    webGLSetting.maxTextureSize = 2048;
                    webGLSetting.overridden = true;
                    webGLSetting.textureCompression = TextureImporterCompression.Compressed;
                    webGLSetting.compressionQuality = TempQuality;
                    if (webFormatBool)
                    {
                        webGLSetting.format = TextureImporterFormat.RGBA32;
                    }
                    else
                    {
                        webGLSetting.format = TextureImporterFormat.ASTC_4x4;
                    }
                    spriteAtlas.SetPlatformSettings(webGLSetting);

                    string atlasPath = RES_DIR + atlasName;
                    AssetDatabase.CreateAsset(spriteAtlas, atlasPath);

                    AddBuild(name2Bundles, atlasName + BUNDLE_EXT, atlasName, GetDirectoryPackage(buildConfig, atlasName));
                }
                AssetDatabase.StopAssetEditing();

                AssetDatabase.StartAssetEditing();
                foreach (var name in prefabNames)
                {
                    string prefabName = GetPrefabPath(name);
                    ApplySavedFile(inputDir, prefabName);
                    ApplySavedMetaFile(inputDir, prefabName);
                }
                AssetDatabase.StopAssetEditing();
                AssetDatabase.Refresh();

                AssetDatabase.StartAssetEditing();
                count10 = prefabNames.Count / 10;
                pindex = 0;
                foreach (string name in prefabNames)
                {
                    if (count10 > 0 && pindex % count10 == 0)
                    {
                        Log($"正在创建{prefabNames.Count}个预制体({pindex / count10 * 10}%)...");
                    }

                    if (pindex++ % 10 == 0)
                    {
                        EditorUtility.DisplayProgressBar("Build Version", "Create Prefab " + name, (float)(pindex) / prefabNames.Count);
                    }

                    string assetPath = RES_DIR + name;
                    var prefabConfig = JsonUtility.FromJson<PrefabConfig>(File.ReadAllText(assetPath));

                    bool isUI = false;
                    List<GameObject> children = new List<GameObject>();

                    if (prefabConfig.imageAnimations != null && prefabConfig.imageAnimations.Length > 0)
                    {
                        isUI = true;
                        for (int j = 0; j < prefabConfig.imageAnimations.Length; ++j)
                        {
                            var imageAnimationConfig = prefabConfig.imageAnimations[j];
                            Sprite[] sprites = GetSprites(imageAnimationConfig.atlas, assetSet);
                            if (sprites == null)
                            {
                                LogError($"SpriteAnimationConfig {name}:{imageAnimationConfig.name} {imageAnimationConfig.atlas}下没有图集，跳过生成");
                                continue;
                            }

                            string gameObjectName = String.IsNullOrEmpty(imageAnimationConfig.name) ? "ImageAnimation_" + j : imageAnimationConfig.name;
                            var go = new GameObject(gameObjectName, typeof(RectTransform));
                            go.layer = LayerMask.NameToLayer("UI");
                            children.Add(go);

                            var image = go.AddComponent<Image>();
                            image.sprite = sprites[0];
                            image.raycastTarget = false;
                            image.SetNativeSize();

                            var rc = go.GetComponent<RectTransform>();
                            var sizeDelta = rc.sizeDelta;
                            if (imageAnimationConfig.width != 0)
                            {
                                sizeDelta.x = imageAnimationConfig.width;
                            }
                            if (imageAnimationConfig.height != 0)
                            {
                                sizeDelta.y = imageAnimationConfig.height;
                            }
                            rc.sizeDelta = sizeDelta;

                            var spriteAnimation = go.AddComponent<SpriteAnimation>();
                            spriteAnimation.sprites = sprites;
                            spriteAnimation.frameRate = imageAnimationConfig.frameRate;
                            spriteAnimation.loop = imageAnimationConfig.loop;
                            spriteAnimation.interval = imageAnimationConfig.interval;
                            spriteAnimation.nativeSize = Directory.Exists($"{inputDir}/{imageAnimationConfig.atlas}/{PLACEMENT_DIR_NAME}");
                        }
                    }

                    if (prefabConfig.spriteAnimations != null && prefabConfig.spriteAnimations.Length > 0)
                    {
                        for (int j = 0; j < prefabConfig.spriteAnimations.Length; ++j)
                        {
                            var spriteAnimationConfig = prefabConfig.spriteAnimations[j];
                            Sprite[] sprites = GetSprites(spriteAnimationConfig.atlas, assetSet);
                            if (sprites == null)
                            {
                                LogError($"SpriteAnimationConfig {name}:{spriteAnimationConfig.name} {spriteAnimationConfig.atlas}下没有图集，跳过生成");
                                continue;
                            }

                            string gameObjectName = String.IsNullOrEmpty(spriteAnimationConfig.name) ? "SpriteAnimation_" + j : spriteAnimationConfig.name;
                            var go = new GameObject(gameObjectName);
                            children.Add(go);

                            var spriteRenderer = go.AddComponent<SpriteRenderer>();
                            spriteRenderer.sprite = sprites[0];

                            var spriteAnimation = go.AddComponent<SpriteAnimation>();
                            spriteAnimation.sprites = sprites;
                            spriteAnimation.frameRate = spriteAnimationConfig.frameRate;
                            spriteAnimation.loop = spriteAnimationConfig.loop;
                            spriteAnimation.interval = spriteAnimationConfig.interval;
                            spriteAnimation.nativeSize = Directory.Exists($"{inputDir}/{spriteAnimationConfig.atlas}/{PLACEMENT_DIR_NAME}");
                        }
                    }

                    GameObject prefab = null;
                    if (children.Count == 1)
                    {
                        prefab = children[0];
                    }
                    else if (children.Count > 1)
                    {
                        if (isUI)
                        {
                            prefab = new GameObject("", typeof(RectTransform));
                            prefab.layer = LayerMask.NameToLayer("UI");
                        }
                        else
                            prefab = new GameObject();

                        foreach (var child in children)
                        {
                            child.transform.SetParent(prefab.transform, false);
                        }
                    }

                    if (prefab)
                    {
                        string prefabName = GetPrefabPath(name);
                        string prefabPath = RES_DIR + prefabName;
                        bool changed = true;
                        if (fastMode)
                        {
                            Hash128 md51 = File.Exists(prefabPath) ? MD5File(prefabPath, prefabName) : default;
                            PrefabUtility.SaveAsPrefabAsset(prefab, prefabPath);
                            Hash128 md52 = MD5File(prefabPath, prefabName);
                            changed = md51 != md52;
                        }
                        else
                        {
                            PrefabUtility.SaveAsPrefabAsset(prefab, prefabPath);
                        }

                        string bundleName = prefabName + BUNDLE_EXT;
                        if (changed)
                        {
                            AddBuild(name2Bundles, bundleName, prefabName, GetDirectoryPackage(buildConfig, prefabName));
                        }
                        if (fastMode)
                        {
                            if (!allFiles.Contains(bundleName)) allFiles.Add(bundleName);
                            if (!allBundles.Contains(bundleName)) allBundles.Add(bundleName);
                        }
                    }
                }
                AssetDatabase.StopAssetEditing();
                Log($"创建{prefabNames.Count}个预制体完毕");

                Log($"正在保存meta文件...");
                foreach (var file in files)
                {
                    string name = file.Substring(inputDir.Length + 1);
                    ChangeLuaPath(ref name);
                    SaveMetaFile(inputDir, name);
                }
                foreach (var name in prefabNames)
                {
                    string prefabName = GetPrefabPath(name);
                    SaveFile(inputDir, prefabName);
                    SaveMetaFile(inputDir, prefabName);
                }
                foreach (var item in atlas2Sprites)
                {
                    string atlasName = item.Key;
                    SaveFile(inputDir, atlasName);
                    SaveMetaFile(inputDir, atlasName);
                }

                Log($"正在拷贝{copys.Count}个文件...", 0);
                foreach (var copy in copys)
                {
                    string name = copy.name;
                    Debug.Log($"copy {RES_DIR}{name}->{outputDir}/{name}");
                    CopyFile(RES_DIR + ChangeLuaPath(name), outputDir + "/" + name);
                }

                Log("正在生成打包配置...", 0);
                foreach (var item in name2Bundles)
                {
                    string bundleName = item.Key;
                    var bundle = item.Value;

                    if (fastMode)
                    {
                        bool changed = false;
                        foreach (var name in bundle.names)
                        {
                            if (changedNames.Contains(name))
                            {
                                changed = true;
                                break;
                            }
                        }

                        if (!changed) continue;
                    }

                    string[] assetNames = new string[bundle.names.Count];
                    for (int j = 0; j < assetNames.Length; ++j)
                    {
                        string name = bundle.names[j];
                        ChangeLuaPath(ref name);
                        assetNames[j] = RES_DIR + name;
                    }

                    foreach (var assetName in assetNames)
                    {
                        Debug.Log($"build {assetName}->{bundleName}");
                    }

                    var has = false;
                    foreach (AssetBundleBuild b in builds)
                    {
                        if (b.assetBundleName == bundleName)
                        {
                            has = true;
                            break;
                        }
                    }
                    if (!has)
                    {
                        builds.Add(new AssetBundleBuild
                        {
                            assetBundleName = bundleName,
                            assetNames = assetNames,
                            addressableNames = bundle.names.ToArray(),
                        });
                    }
                }
            }

            if (rebuild)
            {
                Log("正在清理缓存...", 0);
                BuildCache.PurgeCache(false);
            }

            // build assetbundles
            IBundleBuildResults results;
            string groupName;
            {
                int index = outputDir.LastIndexOf('/');
                string bundlesDir = outputDir.Substring(0, index);
                groupName = outputDir.Substring(index + 1) + "/";

                var parameters = new CustomBundleBuildParameters(
                            EditorUserBuildSettings.activeBuildTarget,
                            EditorUserBuildSettings.selectedBuildTargetGroup, bundlesDir);

                if (buildConfig.disableTypeTree)
                {
                    parameters.ContentBuildFlags |= ContentBuildFlags.DisableWriteTypeTree;
                }

                AssetBundleBuild[] buildsWithGroup = new AssetBundleBuild[builds.Count];
                for (int i = 0; i < buildsWithGroup.Length; ++i)
                {
                    var build = builds[i];
                    build.assetBundleName = groupName + build.assetBundleName;
                    buildsWithGroup[i] = build;
                }

                Log($"正在打包{builds.Count}个资源...", 0);
                var content = new BundleBuildContent(buildsWithGroup);
                var ret = ContentPipeline.BuildAssetBundles(parameters, content, out results);
                if (ret < 0)
                {
                    LogError("打包失败:" + ret);
                    return;
                }

                PrintBuildLog(bundlesDir);
                File.Delete(bundlesDir + "/buildlog.txt");
                File.Delete(bundlesDir + "/buildlogtep.json");
            }

            Log("正在生成清单文件...", 0);
            string bundlesPath = outputDir + "/" + BUNDLES;
            Dictionary<string, CustomAssetBundleManifest.BundleDetails> details = null;
            if (fastMode && File.Exists(bundlesPath))
            {
                var oldManifest = new CustomAssetBundleManifest(File.OpenRead(bundlesPath));
                details = oldManifest.details;

                List<string> removes = new List<string>();
                foreach (var item in details)
                {
                    if (!allBundles.Contains(item.Key))
                    {
                        removes.Add(item.Key);
                    }
                }

                foreach (var remove in removes)
                {
                    details.Remove(remove);
                }
            }
            else
                details = new Dictionary<string, CustomAssetBundleManifest.BundleDetails>(builds.Count);

            var bundleInfos = results.BundleInfos;
            foreach (var build in builds)
            {
                string key = groupName + build.assetBundleName;
                if (bundleInfos.TryGetValue(key, out var detail))
                {
                    var dependencies = new string[detail.Dependencies.Length];
                    for (int i = 0; i < detail.Dependencies.Length; ++i)
                    {
                        dependencies[i] = PathEx.RemoveFront(detail.Dependencies[i]);
                    }

                    string bundle = build.assetBundleName;
                    string bundlePath = outputDir + "/" + bundle;
                    details[build.assetBundleName] = new CustomAssetBundleManifest.BundleDetails
                    {
                        crc = detail.Crc,
                        hash = MD5File(bundlePath, bundle),
                        dependencies = dependencies,
                        assets = build.addressableNames,
                    };
                }
            }

            var manifest = new CustomAssetBundleManifest(details);
            using (var stream = File.Create(outputDir + "/" + BUNDLES))
            {
                manifest.Save(stream);
            }

            Log("正在生成资源包...", 0);
            string fileListPath = outputDir + "/" + FILELIST_FILE;
            var fileList = new FileList();
            if (fastMode && File.Exists(fileListPath))
            {
                var oldFileList = new FileList();
                oldFileList.Load(fileListPath);
                for (int i = 0; i < oldFileList.count; ++i)
                {
                    if (allFiles.Contains(oldFileList[i].path.ToString()))
                    {
                        fileList.Add(oldFileList[i]);
                    }
                }
            }

            {
                var file = outputDir + "/" + BUNDLES;
                var info = new FileList.Info()
                {
                    path = new PathID(BUNDLES),
                    package = 0,
                    hash = MD5File(file, BUNDLES),
                    length = GetFileSize(file),
                };
                fileList.Add(info);
            }

            foreach (var copy in copys)
            {
                var file = outputDir + "/" + copy.name;
                var info = new FileList.Info()
                {
                    path = new PathID(copy.name),
                    package = (short)copy.package,
                    hash = MD5File(file, copy.name),
                    length = GetFileSize(file),
                };
                fileList.Add(info);
            }

            for (int i = 0; i < builds.Count; ++i)
            {
                string bundle = builds[i].assetBundleName;
                string bundlePath = outputDir + "/" + bundle;

                var info = new FileList.Info()
                {
                    path = new PathID(bundle),
                    package = (short)name2Bundles[bundle].package,
                    hash = manifest.GetAssetBundleHash(bundle),
                    length = GetFileSize(bundlePath),
                };
                fileList.Add(info);
            }

            if (fastMode)
            {
                allFiles.Add(BUNDLES);
                allFiles.Add(FILELIST_FILE);

                var dirs = Directory.GetDirectories(outputDir);
                foreach (var dir in dirs)
                {
                    if (!IsCustomDir(dir))
                    {
                        RemoveFiles(Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories), outputDir, allFiles);
                    }
                }
                RemoveFiles(Directory.GetFiles(outputDir), outputDir, allFiles);
            }

            // BuildVirtualFileSystem(fileList, outputDir + "/");
            File.WriteAllBytes(outputDir + "/" + FILELIST_FILE, fileList.Save());

            if (removeRes)
            {
                Directory.Delete(RES_DIR, true);
                AssetDatabase.Refresh();
            }

            Log("生成完毕。");
        }
        catch (Exception e)
        {
            LogError("生成失败：" + e.ToString());
        }
        finally
        {
            EditorUtility.ClearProgressBar();
            DisposeConsole();
        }
    }

    static void CopyShaderDir()
    {
        var ShaderPath = Directory.GetParent(Path.GetDirectoryName(Application.dataPath)) + "/" + PATH_MODEL_SHADER_DIR;
        var ShaderToPath = Path.GetDirectoryName(Application.dataPath) + "/" + RES_DIR + "/" + "Shader";
        CopyDir(ShaderPath, ShaderToPath);
        AssetDatabase.SaveAssets();
    }

    static void RemoveFiles(string[] files, string outputDir, HashSet<string> allFiles)
    {
        foreach (var file in files)
        {
            string name = file.Substring(outputDir.Length + 1);
            if (!allFiles.Contains(name))
            {
                File.Delete(file);
            }
        }
    }

    static bool CompareFile(string srcFile, string dstFile)
    {
        var dstInfo = new FileInfo(dstFile);
        if (!dstInfo.Exists) return false;

        var srcInfo = new FileInfo(srcFile);
        return srcInfo.LastWriteTimeUtc == dstInfo.LastWriteTimeUtc;
    }

    static Sprite[] GetSprites(string atlas, HashSet<string> assetSet)
    {
        if (string.IsNullOrEmpty(atlas))
        {
            return null;
        }

        string[] guids = AssetDatabase.FindAssets("t:Sprite", new string[] { RES_DIR + atlas });
        if (guids.Length == 0)
        {
            return null;
        }

        List<Sprite> sprites = new List<Sprite>();
        for (int k = 0; k < guids.Length; ++k)
        {
            string path = AssetDatabase.GUIDToAssetPath(guids[k]);
            if (assetSet.Contains(path))
            {
                var sprite = AssetDatabase.LoadAssetAtPath<Sprite>(path);
                sprites.Add(sprite);
            }
        }

        return sprites.ToArray();
    }

    static string StandardDir(string dir)
    {
        dir = dir.Replace('\\', '/');
        return dir[dir.Length - 1] != '/' ? dir : dir.Substring(0, dir.Length - 1);
    }

    static DirectoryConfig GetDirectoryConfig(BuildConfig buildConfig, string name)
    {
        foreach (var config in buildConfig.directories)
        {
            string dir = config.dir;
            if (dir.Length < name.Length && name[dir.Length] == '/' &&
                name.StartsWith(dir, StringComparison.Ordinal) &&
                CheckExtension(name, config.extensions) &&
                CheckIgnore(name, config.ignoreExtensions))
            {
                return config;
            }
        }
        return default;
    }

    static bool CheckIgnore(string name, string ignoreExtensions)
    {
        if (string.IsNullOrEmpty(ignoreExtensions))
            return true;

        int start = 0;
        for (int i = 0; i < ignoreExtensions.Length; ++i)
        {
            if (ignoreExtensions[i] == ',' || ignoreExtensions[i] == ' ')
            {
                if (EndsWith(name, ignoreExtensions, start, i - start))
                    return true;

                start = i + 1;
            }
        }

        return EndsWith(name, ignoreExtensions, start, ignoreExtensions.Length - start);
    }

    static bool CheckExtension(string name, string extensions)
    {
        if (string.IsNullOrEmpty(extensions))
            return true;

        int start = 0;
        for (int i = 0; i < extensions.Length; ++i)
        {
            if (extensions[i] == ',' || extensions[i] == ' ')
            {
                if (EndsWith(name, extensions, start, i - start))
                    return true;

                start = i + 1;
            }
        }

        return EndsWith(name, extensions, start, extensions.Length - start);
    }

    static bool EndsWith(string name, string extensions, int start, int count)
    {
        if (count == 0) return false;

        int nameStart = name.Length - count;
        if (nameStart < 0) return false;

        for (int i = 0; i < count; ++i)
        {
            if (name[nameStart + i] != extensions[start + i])
                return false;
        }
        return true;
    }

    static int GetDirectoryPackage(BuildConfig buildConfig, string name)
    {
        return GetDirectoryConfig(buildConfig, name).package;
    }

    static void AddBuild(Dictionary<string, BundleInfo> bundles, string bundleName, string assetName, int package)
    {
        if (!bundles.TryGetValue(bundleName, out var bundle))
        {
            bundle = new BundleInfo();
            bundle.names = new List<string>();
            bundle.package = package;
            bundles.Add(bundleName, bundle);
        }
        bundle.names.Add(assetName);
    }

    static void CopyFile(string srcFile, string dstFile)
    {
        if (File.Exists(dstFile))
            File.Delete(dstFile);
        else
            CreateDirectoryForFile(dstFile);
        File.Copy(srcFile, dstFile);
    }

    static void CopyDir(string srcDir, string dstDir)
    {
        if (!Directory.Exists(dstDir))
        {
            Log("正在复制文件夹" + srcDir);

            string newPath;
            FileInfo fileInfo;
            DirectoryInfo directoryInfo;
            Directory.CreateDirectory(dstDir);

            string[] strs = Directory.GetFiles(srcDir);
            foreach (string str in strs)
            {
                fileInfo = new FileInfo(str);
                newPath = dstDir + "\\" + fileInfo.Name;
                File.Copy(str, newPath);
            }

            string[] dirs = Directory.GetDirectories(srcDir);
            foreach (string dir in dirs)
            {
                directoryInfo = new DirectoryInfo(dir);
                newPath = dstDir + "\\" + directoryInfo.Name;
                CopyDir(dir, newPath);
            }
        }
    }

    static void CreateDirectoryForFile(string file)
    {
        string dir = Path.GetDirectoryName(file);
        if (!Directory.Exists(dir))
        {
            Directory.CreateDirectory(dir);
        }
    }

    const int BUFFER_SIZE = 4096;
    static byte[] m_Buffer = new byte[BUFFER_SIZE];

    static Hash128 MD5File(string file, string name)
    {
        using (var fs = new FileStream(file, FileMode.Open))
        {
            using (var md5 = new MD5CryptoServiceProvider())
            {
                while (true)
                {
                    int size = fs.Read(m_Buffer, 0, BUFFER_SIZE);
                    if (size > 0)
                    {
                        md5.TransformBlock(m_Buffer, 0, size, null, 0);
                    }
                    else
                    {
                        break;
                    }
                }

                var bytes = Encoding.UTF8.GetBytes(name);
                md5.TransformFinalBlock(bytes, 0, bytes.Length);
                var hash = md5.Hash;
                return new Hash128(
                    MakeUint(hash[0], hash[1], hash[2], hash[3]),
                    MakeUint(hash[4], hash[5], hash[6], hash[7]),
                    MakeUint(hash[8], hash[9], hash[10], hash[11]),
                    MakeUint(hash[12], hash[13], hash[14], hash[15]));
            }
        }
    }

    static uint MakeUint(byte b1, byte b2, byte b3, byte b4)
    {
        return b1 + (uint)(b2 << 8) + (uint)(b3 << 16) + (uint)(b4 << 24);
    }

    static int GetFileSize(string file)
    {
        var fileInfo = new FileInfo(file);
        return (int)fileInfo.Length;
    }

    static uint GetBundleOffset(string name)
    {
        return (uint)name.GetHashCode() % 64 + 64;
    }

    static Dictionary<string, AtlasConfig> m_AtlasConfigs = new Dictionary<string, AtlasConfig>();
    static void ClearAtlasConfigs()
    {
        m_AtlasConfigs.Clear();
    }

    static bool IsIgnoreFile(string name)
    {
        if (name.EndsWith(META_FILE_EXT))
            return true;

        if (name.StartsWith(SAVED_META_FILES_DIR))
            return true;

        foreach (var item in IGNORE_FILE_NAMES)
        {
            if (name.EndsWith(item, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        foreach (var item in IGNORE_DIR_NAMES)
        {
            if (name.Contains(item))
            {
                return true;
            }
        }
        return false;
    }

    static bool IsPrefabFile(string name)
    {
        return name.EndsWith(".prefab.json");
    }

    static string GetPrefabPath(string path)
    {
        return path.Substring(0, path.Length - ".json".Length);
    }

    static SpriteConfig GetSpriteConfig(string name, string inputDir)
    {
        int index = name.LastIndexOf("/");
        string atlasName = name.Substring(0, index);
        if (!m_AtlasConfigs.TryGetValue(atlasName, out var atlasConfig))
        {
            string atlasPath = $"{inputDir}/{atlasName}/AtlasConfig.json";
            if (File.Exists(atlasPath))
            {
                atlasConfig = JsonUtility.FromJson<AtlasConfig>(File.ReadAllText(atlasPath));
            }

            if (atlasConfig != null && atlasConfig.sprites != null)
            {
                foreach (var sprite in atlasConfig.sprites)
                {
                    if (sprite.pixelsPerUnit < 0)
                    {
                        sprite.pixelsPerUnit = atlasConfig.pixelsPerUnit;
                    }
                }

            }

            m_AtlasConfigs.Add(atlasName, atlasConfig);
        }

        if (atlasConfig != null && atlasConfig.sprites != null)
        {
            string spriteName = Path.GetFileNameWithoutExtension(name);
            foreach (var spriteConfig in atlasConfig.sprites)
            {
                if (string.Equals(spriteConfig.name, spriteName))
                {
                    return spriteConfig;
                }
            }
        }
        return SpriteConfig.Default;
    }

    static void BuildVirtualFileSystem(FileList fileList, string outputDir)
    {
        if (fileList.count == 0 || !Directory.Exists(outputDir)) return;

        using (var builder = new VirtualFileSystemBuilder(outputDir))
        {
            int count = fileList.count;
            for (int i = 0; i < count; ++i)
            {
                var file = fileList[i];
                builder.Write(outputDir + file.path, file);
                File.Delete(outputDir + file.path);
            }
        }

        var dirs = Directory.GetDirectories(outputDir);
        foreach (var dir in dirs)
        {
            Directory.Delete(dir, true);
        }
    }

    class BuildLog
    {
        [Serializable]
        public class Item
        {
            public string name;
            public double dur;
        }

        public Item[] items;
    }

    static void PrintBuildLog(string outputDir)
    {
        const double MICROSECOND_UNIT = 1000000;

        string json = File.ReadAllText(outputDir + "/buildlogtep.json");
        json = "{\"items\": " + json + "}";
        var buildLog = JsonUtility.FromJson<BuildLog>(json);
        if (buildLog == null) return;

        int copyFromCacheCount = 0;
        double copyFromCacheTime = 0;
        foreach (var item in buildLog.items)
        {
            if (item.name.StartsWith("Copying From Cache "))
            {
                ++copyFromCacheCount;
                copyFromCacheTime += item.dur;
            }
            else
            {
                if (item.dur > MICROSECOND_UNIT * 10)
                {
                    Log($"{item.name}:{item.dur / MICROSECOND_UNIT:0.0}s");
                }
            }
        }
        Log($"CopyFromCache Count:{copyFromCacheCount} Time:{copyFromCacheTime / MICROSECOND_UNIT:0.0}s");
    }

    const int STD_OUTPUT_HANDLE = -11;

    [DllImport("kernel32.dll")]
    public static extern bool AttachConsole(uint processId);
    [DllImport("kernel32.dll", EntryPoint = "GetStdHandle", SetLastError = true, CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
    private static extern IntPtr GetStdHandle(int nStdHandle);

    static System.Diagnostics.Stopwatch m_StopWatch = new System.Diagnostics.Stopwatch();
    static Microsoft.Win32.SafeHandles.SafeFileHandle m_SafeStdOutputHandle;
    static FileStream m_ConsoleOutStream;
    static StreamWriter m_ConsoleOutStreamWriter;

    static void InitConsole()
    {
        m_StopWatch.Start();
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

    static void Log(string message, float progress)
    {
        EditorUtility.DisplayProgressBar("Build Version", message, progress);
        Log(message);
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

    static void ApplySavedFile(string inputDir, string name)
    {
        string assetPath = RES_DIR + name;
        string savedPath = inputDir + SAVED_META_FILES_DIR_SLASH + name;
        if (File.Exists(savedPath))
        {
            FileEx.Copy(savedPath, assetPath);
        }
    }

    static void ApplySavedMetaFile(string inputDir, string name)
    {
        string assetPath = RES_DIR + name;
        string savedMethPath = inputDir + SAVED_META_FILES_DIR_SLASH + name + META_FILE_EXT;
        if (File.Exists(savedMethPath))
        {
            string metaPath = assetPath + META_FILE_EXT;
            FileEx.Copy(savedMethPath, metaPath);
        }
    }

    static void SaveFile(string inputDir, string name)
    {
        string assetPath = RES_DIR + name;
        if (File.Exists(assetPath))
        {
            string savedPath = inputDir + SAVED_META_FILES_DIR_SLASH + name;
            FileEx.Copy(assetPath, savedPath);
        }
    }

    static void SaveMetaFile(string inputDir, string name)
    {
        string assetPath = RES_DIR + name;
        string metaPath = assetPath + META_FILE_EXT;
        if (File.Exists(metaPath))
        {
            string savedMetaPath = inputDir + SAVED_META_FILES_DIR_SLASH + name + META_FILE_EXT;
            FileEx.Copy(metaPath, savedMetaPath);
        }
    }

    static string GetSpriteAtlasPathV1(string folder)
    {
        int index = folder.LastIndexOf('/');
        StringBuilder builder = Global.stringBuilder;
        return builder.Append(folder).Append(folder, index, folder.Length - index).Append(".spriteatlas").ToString();
    }

    const string LUA_EXT = ".lua";
    const string BYTES_EXT = ".bytes";

    static bool IsLua(string path)
    {
        return path.EndsWith(LUA_EXT);
    }

    static string ChangeLuaPath(string path)
    {
        ChangeLuaPath(ref path);
        return path;
    }

    static bool ChangeLuaPath(ref string path)
    {
        if (IsLua(path))
        {
            path = path.Substring(0, path.Length - LUA_EXT.Length) + BYTES_EXT;
            return true;
        }
        return false;
    }

    static Dictionary<string, bool> GetReadableDic(string inputDir)
    {
        var readableDic = new Dictionary<string, bool>();
        var readablePath = Path.Combine(inputDir, "__RULE__/Readable.txt");
        if (File.Exists(readablePath))
        {
            Log($"readablePath已读取");
            var itemDescStr = File.ReadAllText(readablePath, System.Text.Encoding.Default);
            var strArray = itemDescStr.Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var str in strArray)
            {
                if (str.Length < 3) continue;
                if (str[0] == '/' && str[1] == '/') continue;
                readableDic[str.Replace('\\', '/')] = true;
            }
        }
        else
        {
            Log($"readablePath不存在");
        }
        return readableDic;
    }
    static Dictionary<string, bool> GetWebGLSizeDic(string inputDir)
    {
        var webGLSizeDic = new Dictionary<string, bool>();
        var txtPath = Path.Combine(inputDir, "__RULE__/web_size.txt");
        if (File.Exists(txtPath))
        {
            Log("web_size.txt已读取");
            var itemDescStr = File.ReadAllText(txtPath, System.Text.Encoding.Default);
            var strArray = itemDescStr.Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var str in strArray)
            {
                if (str.Length < 3) continue;
                if (str[0] == '/' && str[1] == '/') continue;
                var dirSpriteatlas = str.Replace('\\', '/') + $"/{Path.GetFileName(str) + ".spriteatlas"}";
                webGLSizeDic[dirSpriteatlas] = true;
                var wDirPath = Path.Combine(inputDir, str);
                if (Directory.Exists(wDirPath))
                {
                    var dirList = Directory.GetDirectories(wDirPath, "*.*", SearchOption.AllDirectories);
                    foreach (var dirPath in dirList)
                    {
                        var addDirName = dirPath.Replace(inputDir + "\\", "").Replace('\\', '/') + $"/{Path.GetFileName(dirPath) + ".spriteatlas"}";
                        webGLSizeDic[addDirName] = true;
                    }
                }
            }
            foreach (var item in webGLSizeDic)
            {
                Log("webglSize:" + item.Key);
            }
        }
        else
        {
            Log("web_size.txt不存在");
        }
        return webGLSizeDic;
    }

    static Dictionary<string, bool> GetWebFormatDic(string inputDir)
    {
        var webFormatDic = new Dictionary<string, bool>();
        var txtPath = Path.Combine(inputDir, "__RULE__/web_format.txt");
        Log(txtPath);
        if (File.Exists(txtPath))
        {
            Log("web_format.txt已读取");
            var itemDescStr = File.ReadAllText(txtPath, System.Text.Encoding.Default);
            var strArray = itemDescStr.Split(new[] { "\r\n", "\n" }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var str in strArray)
            {
                if (str.Length < 3) continue;
                if (str[0] == '/' && str[1] == '/') continue;
                webFormatDic[str] = true;
            }
            foreach (var item in webFormatDic)
            {
                Log("webFormat:" + item.Key);
            }
        }
        else
        {
            Log("web_format.txt不存在");
        }
        return webFormatDic;
    }

    static int GetBuildType()
    {
        return 1;
        var txtPath = "../Config/build_type.txt";
        if (File.Exists(txtPath))
        {
            var str = File.ReadAllText(txtPath, System.Text.Encoding.Default);
            if (int.TryParse(str, out var buildType))
            {
                Log("build_type:" + str);
                return buildType;
            }
        }
        else
        {
            Log("web_format.txt不存在");
        }
        return 0;
    }
}
