using System.Collections.Generic;
using System.Text;

namespace TCFramework
{
    public static class StringPool
    {
        static List<string> m_Pool = new List<string>();
        static Dictionary<SubString, int> m_String2ID = new Dictionary<SubString, int>();

        public static int count => m_Pool.Count;
        public static int memory { get; private set; }

        public static int Add(string str)
        {
            return Add(str, 0, str.Length);
        }

        public static int Add(string str, int index)
        {
            return Add(str, index, str.Length - index);
        }

        public static int Add(string str, int index, int count)
        {
            if (count == 0) return 0;

            SubString key = new SubString(str, index, count);
            if (!m_String2ID.TryGetValue(key, out int id))
            {
                string sub = key.ToString();
                m_Pool.Add(sub);
                id = m_Pool.Count;
                m_String2ID.Add(new SubString(sub), id);
                memory += sub.Length * 2;
            }
            return id;
        }

        public static int Add(StringBuilder sb)
        {
            return Add(sb, 0, sb.Length);
        }

        public static int Add(StringBuilder sb, int index)
        {
            return Add(sb, index, sb.Length - index);
        }

        public static int Add(StringBuilder sb, int index, int count)
        {
            if (count == 0) return 0;

            SubString key = new SubString(sb, index, count);
            if (!m_String2ID.TryGetValue(key, out int id))
            {
                string sub = key.ToString();
                m_Pool.Add(sub);
                id = m_Pool.Count;
                m_String2ID.Add(new SubString(sub), id);
                memory += sub.Length * 2;
            }
            return id;
        }

        public static string Get(int id)
        {
            if (id <= 0) return "";
            return m_Pool[id - 1];
        }
    }
}