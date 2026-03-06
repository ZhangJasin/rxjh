using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine;

namespace TCFramework
{
    public class FileList
    {
        static int ParseInt(string str, int start, int length)
        {
            int n = 0;
            for (int i = start; i < start + length; ++i)
            {
                n = n * 10 + (str[i] - '0');
            }
            return n;
        }

        public class Info
        {
            public PathID path;
            public uint version;
            public short package;
            public short subPackage;
            public int offset;
            public int length;
            public Hash128 hash;

            public Info()
            { }

            public Info(string text, int start, int count)
            {
                path = default;
                version = 0;
                package = 0;
                subPackage = 0;
                offset = 0;
                length = 0;
                hash = default;

                int startIndex = start + count - 1;
                for (int i = 6; i > 0; --i)
                {
                    int index = text.LastIndexOf('|', startIndex);
                    if (index == -1)
                    {
                        Debug.LogError("FileInfo format error:" + text);
                        return;
                    }

                    switch (i)
                    {
                        case 1:
                            version = (uint)ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 2:
                            package = (short)ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 3:
                            subPackage = (short)ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 4:
                            offset = ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 5:
                            length = ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 6:
                            hash = Hash128Ex.Parse(text, index + 1);
                            break;
                    }
                    startIndex = index - 1;
                }
                path = new PathID(text, start, startIndex - start + 1);
            }

            public override string ToString()
            {
                return $"{path}|{version}|{package}|{subPackage}|{offset}|{length}|{hash}";
            }
        }

        public class SubPackage
        {
            public uint version;
            public short package;
            public short subPackage;
            public int size;
            public Hash128 hash;

            public SubPackage()
            { }

            public SubPackage(string text, int start, int count)
            {
                version = 0;
                package = 0;
                subPackage = 0;
                size = 0;
                hash = default;

                int startIndex = start + count - 1;
                for (int i = 4; i > 0; --i)
                {
                    int index = text.LastIndexOf('|', startIndex);
                    if (index == -1)
                    {
                        Debug.LogError("SubPackage format error:" + text);
                        return;
                    }

                    switch (i)
                    {
                        case 1:
                            package = (short)ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 2:
                            subPackage = (short)ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 3:
                            size = ParseInt(text, index + 1, startIndex - index);
                            break;
                        case 4:
                            hash = Hash128Ex.Parse(text, index + 1);
                            break;
                    }
                    startIndex = index - 1;
                }

                version = (uint)ParseInt(text, start, startIndex - start + 1);
            }

            public override string ToString()
            {
                return $"{version}|{package}|{subPackage}|{size}|{hash}";
            }
        }

        List<Info> m_Infos = new List<Info>();
        public int count => m_Infos.Count;
        public Info this[int index] => m_Infos[index];

        Dictionary<PathID, int> m_Name2Index = new Dictionary<PathID, int>();
        public int packageCount = 0;

        struct SubPackageKey : IEquatable<SubPackageKey>
        {
            public uint verison;
            public short package;
            public short subPackage;

            public SubPackageKey(SubPackage subPackage)
            {
                verison = subPackage.version;
                package = subPackage.package;
                this.subPackage = subPackage.subPackage;
            }

            public SubPackageKey(Info info)
            {
                verison = info.version;
                package = info.package;
                subPackage = info.subPackage;
            }

            public bool Equals(SubPackageKey other)
            {
                return verison == other.verison && package == other.package && subPackage == other.subPackage;
            }

            public override int GetHashCode()
            {
                return verison.GetHashCode() ^ package.GetHashCode() ^ subPackage.GetHashCode();
            }
        }

        List<SubPackage> m_SubPackages = new List<SubPackage>();
        Dictionary<SubPackageKey, int> m_SubPackageIndexMap;

        public SubPackage GetSubPackage(Info info)
        {
            if (m_SubPackageIndexMap == null)
            {
                m_SubPackageIndexMap = new Dictionary<SubPackageKey, int>(m_SubPackages.Count);
                for (int i = 0; i < m_SubPackages.Count; ++i)
                {
                    m_SubPackageIndexMap.Add(new SubPackageKey(m_SubPackages[i]), i);
                }
            }

            if (m_SubPackageIndexMap.TryGetValue(new SubPackageKey(info), out int index))
                return m_SubPackages[index];
            else
                return null;
        }

        public void AddSubPackage(SubPackage subPackage)
        {
            m_SubPackages.Add(subPackage);
            m_SubPackageIndexMap = null;
        }

        public FileList()
        { }

        public FileList(List<Info> infos)
        {
            m_Infos = infos;
            Refresh();
        }

        public Info GetFileInfo(PathID name)
        {
            return m_Name2Index.TryGetValue(name, out int index) ? m_Infos[index] : default;
        }

        public bool Contains(PathID name)
        {
            return m_Name2Index.ContainsKey(name);
        }

        public bool Contains(Info info)
        {
            return info != null && Contains(info.path, info.hash);
        }

        public bool Contains(PathID name, Hash128 hash)
        {
            return m_Name2Index.TryGetValue(name, out int index) && m_Infos[index].hash == hash;
        }

        public void Load(byte[] bytes)
        {
            m_Infos.Clear();
            m_SubPackages.Clear();

            if (bytes != null)
            {
                string text = Encoding.UTF8.GetString(GZip.DecompressWithSize(bytes));
                int start = 0;

                // read infos
                ReadHeader(text, ref start);
                while (GetLine(text, ref start, out int index, out int count))
                {
                    m_Infos.Add(new Info(text, index, count));
                }

                // read packages
                if (ReadHeader(text, ref start))
                {
                    while (GetLine(text, ref start, out int index, out int count))
                    {
                        m_SubPackages.Add(new SubPackage(text, index, count));
                    }
                }
            }

            Refresh();
        }

        bool GetLine(string text, ref int start, out int index, out int count)
        {
            index = start;

            if (start >= text.Length)
            {
                count = 0;
                return false;
            }

            int i = text.IndexOf('\n', start);
            if (i == -1)
                count = text.Length - index;
            else
                count = i - index;

            start = index + count + 1;
            return count > 0;
        }

        bool GetLine(string text, ref int start)
        {
            return GetLine(text, ref start, out _, out _);
        }

        bool ReadHeader(string text, ref int start)
        {
            return GetLine(text, ref start) && GetLine(text, ref start);
        }

        public void Load(string path)
        {
            Load(FileEx.ReadAllBytes(path));
        }

        public byte[] Save()
        {
            StringBuilder strb = new StringBuilder();
            strb.Append("Name|Version|Package|SubPackage|Offset|Size|Hash\n-|-|-|-|-|-|-");

            foreach (var info in m_Infos)
            {
                strb.Append('\n').Append(info.ToString());
            }

            if (m_SubPackages.Count > 0)
            {
                strb.Append("\n\nVersion|Package|SubPackage|Size|Hash\n-|-|-|-|-");

                foreach (var subPackage in m_SubPackages)
                {
                    strb.Append('\n').Append(subPackage.ToString());
                }
            }

            string text = strb.ToString();
            var buffer = GZip.CompressWithSize(Encoding.UTF8.GetBytes(text));
            return buffer;
        }

        public void Save(string path)
        {
            FileEx.WriteAllBytes(path, Save());
        }

        void Refresh()
        {
            m_Name2Index.Clear();
            packageCount = 0;

            for (int i = 0; i < m_Infos.Count; ++i)
            {
                m_Name2Index.Add(m_Infos[i].path, i);
                if (packageCount < m_Infos[i].package)
                {
                    packageCount = m_Infos[i].package;
                }
            }

            m_SubPackageIndexMap = null;
        }

        public void Add(Info info)
        {
            if (m_Name2Index.TryGetValue(info.path, out int index))
            {
                m_Infos[index] = info;
            }
            else
            {
                m_Name2Index[info.path] = m_Infos.Count;
                m_Infos.Add(info);
            }
        }
    }
}
