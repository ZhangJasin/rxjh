using UnityEngine;
using UnityEditor;

public class BuildVersionEditor : EditorWindow
{
    const string INPUT_DIR_KEY = "BuildVersionEditor.InputDir";
    const string OUTPUT_DIR_KEY = "BuildVersionEditor.OutputDir";

    string m_InputDir;
    string m_OutputDir;
    bool m_FastMode = false;
    bool m_Rebuild = false;
    bool m_RemoveRes = true;
    bool m_IncludeModelRes = true;

    string inputDir
    {
        get => m_InputDir;
        set
        {
            if (m_InputDir != value)
            {
                m_InputDir = value;
                EditorPrefs.SetString(INPUT_DIR_KEY, m_InputDir);
            }
        }
    }

    string outputDir
    {
        get => m_OutputDir;
        set
        {
            if (m_OutputDir != value)
            {
                m_OutputDir = value;
                EditorPrefs.SetString(OUTPUT_DIR_KEY, m_OutputDir);
            }
        }
    }

    [MenuItem("Tools/Build Version")]
    static void Open()
    {
        var window = GetWindow<BuildVersionEditor>(false, "Build Version", true);
        window.minSize = window.maxSize = new Vector2(600, 180);
    }

    private void OnEnable()
    {
        m_InputDir = EditorPrefs.GetString(INPUT_DIR_KEY);
        m_OutputDir = EditorPrefs.GetString(OUTPUT_DIR_KEY);
    }

    private void OnGUI()
    {
        GUILayout.Space(5);
        inputDir = FolderField("Input", inputDir);
        outputDir = FolderField("Output", outputDir);
        m_FastMode = EditorGUILayout.Toggle("FastMode", m_FastMode);
        m_Rebuild = EditorGUILayout.Toggle("Rebuild", m_Rebuild);
        m_RemoveRes = EditorGUILayout.Toggle("RemoveRes", m_RemoveRes);
        m_IncludeModelRes = EditorGUILayout.Toggle("IncludeModelRes", m_IncludeModelRes);
        GUILayout.Space(5);

        if (GUILayout.Button("Build", GUILayout.ExpandHeight(true)))
        {
            BuildVerison.BuildRes(inputDir, outputDir, m_Rebuild, m_FastMode, m_RemoveRes, m_IncludeModelRes);
            GUIUtility.ExitGUI();
        }
    }

    static string FolderField(string label, string folder)
    {
        bool oldChanged = GUI.changed;
        GUILayout.BeginHorizontal();
        {
            EditorGUILayout.PrefixLabel(label);

            GUILayout.BeginVertical();
            GUILayout.Space(4);
            folder = GUILayout.TextField(folder);
            GUILayout.EndVertical();

            if (GUILayout.Button("Browse", GUILayout.Width(120)))
            {
                string newFolder = EditorUtility.OpenFolderPanel("Select Folder", folder, "");
                if (!string.IsNullOrEmpty(newFolder))
                {
                    if (folder != newFolder)
                        folder = newFolder;
                    else
                        GUI.changed = oldChanged;
                }
                else
                    GUI.changed = oldChanged;
            }
        }
        GUILayout.EndHorizontal();

        return folder;
    }
}
