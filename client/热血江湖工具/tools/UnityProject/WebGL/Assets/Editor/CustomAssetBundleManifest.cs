using ICSharpCode.SharpZipLib.GZip;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;

namespace TCFramework
{
    public class CustomAssetBundleManifest
    {
        public struct BundleDetails
        {
            public uint crc;
            public Hash128 hash;
            public string[] dependencies;
            public string[] assets;
        }

        Dictionary<string, BundleDetails> m_Details;
        public Dictionary<string, BundleDetails> details => m_Details;

        public CustomAssetBundleManifest(Dictionary<string, BundleDetails> bundleInfos)
        {
            m_Details = bundleInfos;
        }

        public CustomAssetBundleManifest(Stream stream, bool zip = false)
        {
            Load(stream, zip);
        }

        public void Save(Stream stream)
        {
            using (var bw = new BinaryWriter(stream))
            {
                if (m_Details == null)
                {
                    bw.Write(0);
                    return;
                }

                bw.Write(m_Details.Count);
                foreach (var item in m_Details)
                {
                    bw.Write(item.Key);
                    WriteBundle(bw, item.Value);
                }
            }
        }

        void WriteBundle(BinaryWriter bw, BundleDetails bd)
        {
            bw.Write(bd.crc);
            bw.Write(bd.hash.ToString());
            WriteStringArray(bw, bd.dependencies);
            WriteStringArray(bw, bd.assets);
        }

        void WriteStringArray(BinaryWriter bw, string[] strs)
        {
            if (strs == null)
            {
                bw.Write(0);
            }
            else
            {
                bw.Write(strs.Length);
                for (int i = 0; i < strs.Length; ++i)
                {
                    bw.Write(strs[i]);
                }
            }
        }

        public void Load(Stream stream, bool gzip)
        {
            if (stream == null)
            {
                m_Details = new Dictionary<string, BundleDetails>();
                return;
            }

            if (gzip)
            {
                try
                {
                    using (var inputStream = new GZipInputStream(stream))
                    {
                        inputStream.IsStreamOwner = false;
                        using (var br = new BinaryReader(inputStream, Encoding.UTF8, true))
                        {
                            Load(br);
                        }
                    }
                }
                catch
                {
                    stream.Position = 0;
                    using (var br = new BinaryReader(stream, Encoding.UTF8, true))
                    {
                        Load(br);
                    }
                }
            }
            else
            {
                using (var br = new BinaryReader(stream))
                {
                    Load(br);
                }
            }
        }
        void Load(BinaryReader br)
        {
            int count = br.ReadInt32();
            m_Details = new Dictionary<string, BundleDetails>(count);
            for (int i = 0; i < count; ++i)
            {
                m_Details.Add(br.ReadString(), ReadBundle(br));
            }
        }

        BundleDetails ReadBundle(BinaryReader br)
        {
            return new BundleDetails
            {
                crc = br.ReadUInt32(),
                hash = Hash128.Parse(br.ReadString()),
                dependencies = ReadStringArray(br),
                assets = ReadStringArray(br),
            };
        }

        string[] ReadStringArray(BinaryReader br)
        {
            int count = br.ReadInt32();
            string[] strs = new string[count];
            for (int i = 0; i < count; ++i)
            {
                strs[i] = br.ReadString();
            }
            return strs;
        }
        
        public string[] GetAllAssetBundles()
        {
            var keys = m_Details.Keys;
            string[] bundles = new string[keys.Count];
            keys.CopyTo(bundles, 0);
            Array.Sort(bundles);
            return bundles;
        }

        public Hash128 GetAssetBundleHash(string assetBundleName)
        {
            BundleDetails details;
            if (m_Details.TryGetValue(assetBundleName, out details))
                return details.hash;
            return new Hash128();
        }

        public uint GetAssetBundleCrc(string assetBundleName)
        {
            BundleDetails details;
            if (m_Details.TryGetValue(assetBundleName, out details))
                return details.crc;
            return 0;
        }

        public string[] GetAllDependencies(string assetBundleName)
        {
            BundleDetails details;
            if (m_Details.TryGetValue(assetBundleName, out details))
                return details.dependencies;
            return new string[0];
        }
    }
}
