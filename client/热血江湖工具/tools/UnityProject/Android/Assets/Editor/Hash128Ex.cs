using System.Text;
using UnityEngine;

namespace TCFramework
{
    public static class Hash128Ex
    {
        public static Hash128 Parse(string str, int start)
        {
            return new Hash128(
                ParseUIntBase16(str, start),
                ParseUIntBase16(str, start + 8),
                ParseUIntBase16(str, start + 16),
                ParseUIntBase16(str, start + 24));
        }

        public static Hash128 Parse(StringBuilder sb)
        {
            return new Hash128(
                ParseUIntBase16(sb, 0),
                ParseUIntBase16(sb, 8),
                ParseUIntBase16(sb, 16),
                ParseUIntBase16(sb, 24));
        }

        public static Hash128 Parse(char[] chars, int start)
        {
            return new Hash128(
                ParseUIntBase16(chars, start),
                ParseUIntBase16(chars, start + 8),
                ParseUIntBase16(chars, start + 16),
                ParseUIntBase16(chars, start + 24));
        }

        static uint ParseUIntBase16(string str, int start)
        {
            byte b0 = ParseByteBase16(str, start);
            byte b1 = ParseByteBase16(str, start + 2);
            byte b2 = ParseByteBase16(str, start + 4);
            byte b3 = ParseByteBase16(str, start + 6);
            return (uint)(b0 + (b1 << 8) + (b2 << 16) + (b3 << 24));
        }

        static uint ParseUIntBase16(StringBuilder sb, int start)
        {
            byte b0 = ParseByteBase16(sb, start);
            byte b1 = ParseByteBase16(sb, start + 2);
            byte b2 = ParseByteBase16(sb, start + 4);
            byte b3 = ParseByteBase16(sb, start + 6);
            return (uint)(b0 + (b1 << 8) + (b2 << 16) + (b3 << 24));
        }

        static uint ParseUIntBase16(char[] chars, int start)
        {
            byte b0 = ParseByteBase16(chars, start);
            byte b1 = ParseByteBase16(chars, start + 2);
            byte b2 = ParseByteBase16(chars, start + 4);
            byte b3 = ParseByteBase16(chars, start + 6);
            return (uint)(b0 + (b1 << 8) + (b2 << 16) + (b3 << 24));
        }

        static byte ParseByteBase16(string str, int start)
        {
            return (byte)(CharToIntBase16(str[start]) * 16 + CharToIntBase16(str[start + 1]));
        }

        static byte ParseByteBase16(StringBuilder sb, int start)
        {
            return (byte)(CharToIntBase16(sb[start]) * 16 + CharToIntBase16(sb[start + 1]));
        }

        static byte ParseByteBase16(char[] chars, int start)
        {
            return (byte)(CharToIntBase16(chars[start]) * 16 + CharToIntBase16(chars[start + 1]));
        }

        static int CharToIntBase16(char c)
        {
            return c >= 'a' ? 10 + c - 'a' : (c >= 'A' ? 10 + c - 'A' : c - '0');
        }
    }
}