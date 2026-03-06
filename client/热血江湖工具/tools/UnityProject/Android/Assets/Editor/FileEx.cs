using System;
using System.IO;
using System.Text;
using UnityEngine;

namespace TCFramework
{
    public static class FileEx
    {
        public static void Delete(string path)
        {
            if (File.Exists(path))
                File.Delete(path);
        }

        public static void Copy(string srcFile, string dstFile)
        {
            if (File.Exists(srcFile))
            {
                Delete(dstFile);
                DirectoryEx.CreateDirectoryForFile(dstFile);
                File.Copy(srcFile, dstFile);
            }
        }

        public static void Move(string srcFile, string dstFile)
        {
            if (srcFile == dstFile)
                return;

            if (File.Exists(srcFile))
            {
                Delete(dstFile);
                DirectoryEx.CreateDirectoryForFile(dstFile);
                File.Move(srcFile, dstFile);
            }
        }

        public static int GetSize(string path)
        {
            try
            {
                var fileInfo = new FileInfo(path);
                return (int)fileInfo.Length;
            }
            catch
            {
                return 0;
            }
        }

        public static FileStream OpenRead(string path)
        {
            try
            {
                return File.OpenRead(path);
            }
            catch
            {
                return null;
            }
        }

        public static byte[] ReadAllBytes(string path)
        {
            try
            {
                return File.ReadAllBytes(path);
            }
            catch
            {
                return null;
            }
        }

        public static string ReadAllText(string path, Encoding encoding = null)
        {
            try
            {
                return encoding != null ? File.ReadAllText(path, encoding) : File.ReadAllText(path);
            }
            catch
            {
                return null;
            }
        }

        public static void WriteAllBytes(string path, byte[] bytes)
        {
            try
            {
                DirectoryEx.CreateDirectoryForFile(path);
                File.WriteAllBytes(path, bytes);
            }
            catch (Exception e)
            {
                Debug.LogError(e.ToString());
            }
        }

        public static void WriteAllText(string path, string text, Encoding encoding = null)
        {
            try
            {
                DirectoryEx.CreateDirectoryForFile(path);
                if (encoding == null)
                    File.WriteAllText(path, text);
                else
                    File.WriteAllText(path, text, encoding);
            }
            catch (Exception e)
            {
                Debug.LogError(e.ToString());
            }
        }
    }
}