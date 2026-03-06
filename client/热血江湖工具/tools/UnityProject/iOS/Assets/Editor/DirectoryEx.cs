using System;
using System.IO;

namespace TCFramework
{
    public class DirectoryEx
    {
        public static void CreateDirectory(string dir)
        {
            if (!Directory.Exists(dir))
                Directory.CreateDirectory(dir);
        }

        public static void CreateDirectoryForFile(string path)
        {
            var dir = PathEx.RemoveBack(path);
            if (!string.IsNullOrEmpty(dir))
            {
                CreateDirectory(dir);
            }
        }

        public static void Move(string srcDir, string dstDir)
        {
            Delete(dstDir, true);
            if (Directory.Exists(srcDir))
            {
                CreateDirectoryForFile(dstDir);
                Directory.Move(srcDir, dstDir);
            }
        }

        public static void Delete(string path, bool recursive)
        {
            if (Directory.Exists(path))
                Directory.Delete(path, recursive);
        }

        public static void Copy(string srcDir, string dstDir)
        {
            if (!Directory.Exists(srcDir))
                return;

            var files = Directory.GetFiles(srcDir, "*.*", SearchOption.AllDirectories);
            foreach (var file in files)
            {
                string dstFile = dstDir + file.Substring(srcDir.Length);
                FileEx.Copy(file, dstFile);
            }
        }

        public static bool IsEmpty(string path)
        {
            return Directory.Exists(path) && Directory.GetDirectories(path).Length == 0 && Directory.GetFiles(path).Length == 0;
        }

        public static string[] GetDirectories(string path)
        {
            return Directory.Exists(path) ? Directory.GetDirectories(path) : Array.Empty<string>();
        }
    }
}