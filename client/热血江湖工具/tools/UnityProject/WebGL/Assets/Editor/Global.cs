using System.Text;

namespace TCFramework
{
    public static class Global
    {
        static StringBuilder m_StringBuilder = new StringBuilder(1024);
        public static StringBuilder stringBuilder
        {
            get { return m_StringBuilder.Clear(); }
        }
    }
}