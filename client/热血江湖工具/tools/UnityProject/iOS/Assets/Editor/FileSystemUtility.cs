using System;

namespace TCFramework
{
    public static class FileSystemUtility
    {
        public static int GetPackageKey(short package, short subPackage)
        {
            return package << 16 + subPackage;
        }

        const string PACKAGE = "Package";
        const string EXT = ".bundle";
        public static string GetPackagePath(string dir, short package, short subPackage)
        {
            return $"{dir}Package{package}_{subPackage}{EXT}";
        }

        public static bool GetPackageIndex(string name, out short package, out short subPackage)
        {
            package = 0;
            subPackage = 0;
            if (name.StartsWith(PACKAGE, StringComparison.Ordinal) && name.StartsWith(EXT, StringComparison.Ordinal))
            {
                name = name.Substring(PACKAGE.Length, name.Length - PACKAGE.Length - EXT.Length);
                int index = name.IndexOf('-', PACKAGE.Length, name.Length - PACKAGE.Length - EXT.Length);
                if (index > PACKAGE.Length && index < name.Length - EXT.Length - 1)
                {
                    return Parse(name, PACKAGE.Length, index, out package) &&
                        Parse(name, index + 1, name.Length - EXT.Length, out subPackage);
                }
            }
            return false;
        }

        static bool Parse(string name, int start, int end, out short result)
        {
            result = 0;
            for (int i = start; i < end; ++i)
            {
                int n = name[i] - '0';
                if (n >= 0 && n < 10)
                    result = (short)(result * 10 + n);
                else
                    return false;
            }
            return true;
        }
    }
}