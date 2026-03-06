using System;
using System.Collections.Generic;
using System.IO;

namespace TCFramework
{
    public class VirtualFileSystemBuilder : IDisposable
    {
        class Package
        {
            public short subPackage;
            public FileStream stream;
        }

        string m_Dir;
        Dictionary<short, Package> m_Packages = new Dictionary<short, Package>();

        public VirtualFileSystemBuilder(string dir)
        {
            m_Dir = PathEx.StandardizeDirectory(dir);

            if (Directory.Exists(dir))
            {
                var files = Directory.GetFiles(dir);
                foreach (var file in files)
                {
                    string name = Path.GetFileNameWithoutExtension(file);
                    if (FileSystemUtility.GetPackageIndex(name, out short package, out short subPackage))
                    {
                        if (m_Packages.TryGetValue(package, out var p))
                        {
                            if (p.subPackage < subPackage)
                                p.subPackage = subPackage;
                        }
                        else
                        {
                            m_Packages.Add(package, new Package
                            {
                                subPackage = subPackage,
                            });
                        }
                    }
                }
            }
            else
                Directory.CreateDirectory(dir);
        }

        const int MAX_PACKAGE_SIZE = 64 * 1024 * 1024;
        byte[] m_Buffer = new byte[1024 * 1024];

        public void Write(string file, FileList.Info info)
        {
            short package = info.package;
            if (!m_Packages.TryGetValue(package, out var p))
            {
                p = new Package();
                m_Packages.Add(package, p);
            }

            using (var input = File.OpenRead(file))
            {
                if (p.stream == null)
                {
                    string path = FileSystemUtility.GetPackagePath(m_Dir, package, p.subPackage);
                    p.stream = File.Open(path, FileMode.Append);
                }
                else if (p.stream.Length + input.Length > MAX_PACKAGE_SIZE)
                {
                    p.stream?.Close();
                    ++p.subPackage;
                    string path = FileSystemUtility.GetPackagePath(m_Dir, package, p.subPackage);
                    p.stream = File.Open(path, FileMode.Append);
                }

                info.subPackage = p.subPackage;
                info.offset = (int)p.stream.Length;

                int index = 0;
                while (true)
                {
                    int count = input.Read(m_Buffer, 0, m_Buffer.Length);
                    if (count > 0)
                    {
                        p.stream.Write(m_Buffer, 0, count);
                        index += count;
                    }
                    else
                        break;
                }
            }
            p.stream.Flush();
        }

        public void Dispose()
        {
            foreach (var item in m_Packages)
            {
                item.Value.stream?.Close();
            }
            m_Packages.Clear();
        }
    }
}
