using System;
using System.IO;

namespace TCFramework
{
    public static class PathEx
    {
        static readonly char[] PATH_SLASH = "/\\".ToCharArray();

        public static string GetRootDir(string path)
        {
            int index = path.IndexOfAny(PATH_SLASH);
            return index == -1 ? path : path.Substring(0, index);
        }

        public static string RemoveExtension(string path)
        {
            int index = path.LastIndexOf('.');
            return index >= 0 ? path.Substring(0, index) : path;
        }

        public static string SplitExtenstion(string path, out string extension)
        {
            int index = path.LastIndexOf('.');
            if (index < 0)
            {
                extension = null;
                return path;
            }

            extension = path.Substring(index);
            return path.Substring(0, index);
        }

        public static string RemoveBack(string path, int time = 1)
        {
            int index = path.Length - 1;
            for (int i = 0; i < time; ++i)
            {
                int index2 = path.LastIndexOfAny(PATH_SLASH, index);
                if (index2 == -1)
                    return string.Empty;
                else if (index2 == index)
                    --i;

                index = index2 - 1;
            }
            return path.Substring(0, index + 1);
        }

        public static string RemoveFront(string path, int time = 1)
        {
            int index = 0;
            for (int i = 0; i < time; ++i)
            {
                int index2 = path.IndexOfAny(PATH_SLASH, index);
                if (index2 == -1)
                    return string.Empty;
                else if (index2 == index)
                    --i;

                index = index2 + 1;
            }
            return path.Substring(index);
        }

        public static string Combine(string dir, string path)
        {
            if (string.IsNullOrEmpty(dir))
                return path;

            if (dir[dir.Length - 1] == '/')
                return dir + path;
            else
                return Global.stringBuilder.Append(dir).Append('/').Append(path).ToString();
        }

        public static string Combine(string dir, string dir2, string path)
        {
            if (string.IsNullOrEmpty(dir))
                return Combine(dir2, path);

            if (string.IsNullOrEmpty(dir2))
                return Combine(dir, path);

            bool slash1 = dir[dir.Length - 1] == '/';
            bool slash2 = dir2[dir2.Length - 1] == '/';
            int length = dir.Length + dir2.Length + path.Length;
            if (!slash1) ++length;
            if (!slash2) ++length;

            var builder = Global.stringBuilder;
            builder.Append(dir);
            if (!slash1) builder.Append('/');
            builder.Append(dir2);
            if (!slash2) builder.Append('/');
            builder.Append(path);
            return builder.ToString();
        }

        public static bool InDirectory(string path, string dir)
        {
            if (path.Length > dir.Length && path.StartsWith(dir, StringComparison.Ordinal) && (dir[dir.Length - 1] == '/' || path[dir.Length] == '/'))
                return true;
            return false;
        }

        public static string Standardize(string path)
        {
            return path != null ? path.Replace('\\', '/') : string.Empty;
        }

        public static string StandardizeDirectory(string dir)
        {
            if (dir == null) return null;

            int length = dir.Length;
            if (length > 0)
            {
                dir = dir.Replace('\\', '/');
                if (dir[length - 1] != '/')
                {
                    dir += "/";
                }
            }
            return dir;
        }

        public static string GetRelativePath(string path)
        {
            return GetRelativePath(path, Directory.GetCurrentDirectory());
        }

        public static string GetRelativePath(string path, string relativeTo)
        {
            path = Standardize(path);
            relativeTo = Standardize(relativeTo);

            int i = 0;
            int index = -1;
            int length = Math.Min(path.Length, relativeTo.Length);
            for (; i < length; ++i)
            {
                if (path[i] != relativeTo[i])
                    break;

                if (path[i] == '/')
                {
                    index = i;
                }
            }

            if (i == length)
            {
                if (path.Length > i)
                {
                    if (path[i] == '/')
                    {
                        index = i;
                    }
                }
                else if (relativeTo.Length > i)
                {
                    if (relativeTo[i] == '/')
                    {
                        index = i;
                    }
                }
                else
                    return string.Empty;
            }

            if (index == -1)
                return path;

            var builder = Global.stringBuilder;
            for (i = index; i < relativeTo.Length; ++i)
            {
                if (relativeTo[i] == '/')
                {
                    if (builder.Length > 0) builder.Append('/');
                    builder.Append("..");
                }
            }

            if (index + 1 < path.Length)
            {
                if (builder.Length > 0) builder.Append('/');
                builder.Append(path.Substring(index + 1));
            }

            return builder.ToString();
        }

        public static bool InAssetsFolder(string path)
        {
            return path.StartsWith("Assets/", StringComparison.Ordinal) || path.StartsWith("Packages/", StringComparison.Ordinal);
        }
    }
}