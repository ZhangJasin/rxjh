using System.IO;
using UnityEngine;

namespace TCFramework
{
    public static class LuaBytecodeGen
    {
        static string m_LuacPath;
        static string luacPath
        {
            get
            {
                if (m_LuacPath == null)
                {
                    m_LuacPath = PathEx.RemoveBack(Application.dataPath, 2) + "/Tools/Lua/luac";
                    if (Application.platform == RuntimePlatform.WindowsEditor)
                        m_LuacPath += ".exe";
                }
                return m_LuacPath;
            }
        }
        public static bool enabled => File.Exists(luacPath);

        public static void GenerateBytecode(string srcFile, string dstFile, CmdRunner cmdRunner)
        {
            DirectoryEx.CreateDirectoryForFile(dstFile);
            cmdRunner.Run(luacPath + $" -o \"{dstFile}\" \"{srcFile}\"");
        }
    }
}