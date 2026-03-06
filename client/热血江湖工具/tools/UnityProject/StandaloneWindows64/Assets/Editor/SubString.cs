using System;
using System.Text;

namespace TCFramework
{
    public struct SubString : IEquatable<SubString>
    {
        public object obj;
        public int start;
        public int length;

        public SubString(string str)
        {
            obj = str;
            start = 0;
            length = str.Length;
        }

        public SubString(string str, int start)
        {
            obj = str;
            this.start = start;
            length = str.Length;
        }

        public SubString(string str, int start, int length)
        {
            obj = str;
            this.start = start;
            this.length = length;
        }

        public SubString(StringBuilder sb, int start, int length)
        {
            obj = sb;
            this.start = start;
            this.length = length;
        }

        public override int GetHashCode()
        {
            int hash = 0;
            if (obj is string str)
            {
                for (int i = 0; i < length; ++i)
                {
                    hash = hash * 37 + str[start + i];
                }
            }
            else
            {
                StringBuilder sb = (StringBuilder)obj;
                for (int i = 0; i < length; ++i)
                {
                    hash = hash * 37 + sb[start + i];
                }
            }
            return hash;
        }

        public bool Equals(SubString other)
        {
            if (length != other.length)
                return false;

            int start1 = start;
            int start2 = other.start;
            if (obj is string str1)
            {
                if (other.obj is string str2)
                {
                    for (int i = 0; i < length; ++i)
                    {
                        if (str1[start1 + i] != str2[start2 + i])
                            return false;
                    }
                }
                else
                {
                    StringBuilder sb2 = (StringBuilder)other.obj;
                    for (int i = 0; i < length; ++i)
                    {
                        if (str1[start1 + i] != sb2[start2 + i])
                            return false;
                    }
                }
            }
            else
            {
                StringBuilder sb1 = (StringBuilder)obj;
                if (other.obj is string str2)
                {
                    for (int i = 0; i < length; ++i)
                    {
                        if (sb1[start1 + i] != str2[start2 + i])
                            return false;
                    }
                }
                else
                {
                    StringBuilder sb2 = (StringBuilder)other.obj;
                    for (int i = 0; i < length; ++i)
                    {
                        if (sb1[start1 + i] != sb2[start2 + i])
                            return false;
                    }
                }
            }

            return true;
        }

        public override bool Equals(object obj)
        {
            if (obj is SubString other)
            {
                return Equals(other);
            }
            return false;
        }

        public override string ToString()
        {
            return obj is string str ?
                start == 0 && str.Length == length ? str : str.Substring(start, length) :
                ((StringBuilder)obj).ToString(start, length);
        }

        public static bool operator ==(SubString a, SubString b)
        {
            return a.Equals(b);
        }

        public static bool operator !=(SubString a, SubString b)
        {
            return !(a == b);
        }
    }
}
