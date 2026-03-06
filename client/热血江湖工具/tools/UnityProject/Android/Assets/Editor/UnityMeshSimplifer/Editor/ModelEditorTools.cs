using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using UnityMeshSimplifier;

public class ModelEditorTools : ScriptableObject
{
    
    //[MenuItem("Tools/角色工具/选中目录所有角色自动化减面到30%并自动切换_DM的shader")]
    static void CreatePlayerLODAsset()
    {
        string objAssetPath = AssetDatabase.GetAssetPath(Selection.activeObject);
        string fullPath = Application.dataPath + objAssetPath.Substring("Assets".Length);
        if (Directory.Exists(fullPath))
        {
            List<string> material = new List<string>();
            string[] prefabPaths = Directory.GetFiles(objAssetPath, "*.prefab", SearchOption.AllDirectories);
            
            if (prefabPaths.Length > 0)
            {
                int count = 0, part = 0, num = prefabPaths.Length;
                foreach (var p in prefabPaths)
                {
                    float progress = (float)part / (float)num;
                    EditorUtility.DisplayProgressBar("Hold on", "正在处理"+ part + " ，总"+ prefabPaths.Length, progress);
                    string path = p.Replace("\\", "/");
                    if (path.Contains("_DM.prefab"))
                        continue;
                    GameObject preafab = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                    part++;
                    if (preafab != null)
                    {
                        GameObject targetObj = PrefabUtility.InstantiatePrefab(preafab) as GameObject;
                        //LODGenerator.CreateLODAssets(targetObj, 0.3f, SimplificationOptions.Default);
                        //MantisLODEditorProfessional mantisLODEditorProfessional = targetObj.AddComponent<MantisLODEditorProfessional>();
                        //mantisLODEditorProfessional.CreateLODAssets(30, true);
                        GameObject.DestroyImmediate(targetObj);
                        AssetDatabase.SaveAssets();
                        AssetDatabase.Refresh();
                    }
                }
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
                Debug.Log(count);
                EditorUtility.ClearProgressBar();
            }
        }
    }



}

