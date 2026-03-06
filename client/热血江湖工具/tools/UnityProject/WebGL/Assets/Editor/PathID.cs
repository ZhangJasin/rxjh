using System;
using System.Text;

namespace TCFramework
{
    public struct PathID : IEquatable<PathID>, IComparable<PathID>
    {
        public int dirID;
        public int nameID;
        public bool isEmpty => dirID == 0 && nameID == 0;

        public string dir
        {
            get => StringPool.Get(dirID);
            set => dirID = StringPool.Add(value);
        }

        public string name
        {
            get => StringPool.Get(nameID);
            set => nameID = StringPool.Add(value);
        }

        public string nameWithoutExtension => PathEx.RemoveExtension(name);

        public PathID(int dir, int name)
        {
            dirID = dir;
            nameID = name;
        }

        public PathID(string path)
        {
            if (string.IsNullOrEmpty(path))
            {
                dirID = nameID = 0;
                return;
            }

            int index = path.LastIndexOf('/');
            if (index == -1)
            {
                dirID = 0;
                nameID = StringPool.Add(path);
            }
            else
            {
                dirID = StringPool.Add(path, 0, index + 1);
                nameID = StringPool.Add(path, index + 1);
            }
        }

        public PathID(StringBuilder path)
        {
            if (path.Length == 0)
            {
                dirID = nameID = 0;
                return;
            }

            int index = -1;
            for (int i = path.Length - 1; i >= 0; i--)
            {
                if (path[i] == '/')
                {
                    index = i;
                    break;
                }
            }

            if (index == -1)
            {
                dirID = 0;
                nameID = StringPool.Add(path);
            }
            else
            {
                dirID = StringPool.Add(path, 0, index + 1);
                nameID = StringPool.Add(path, index + 1);
            }
        }

        public PathID(string str, int start, int length)
        {
            if (length == 0)
            {
                dirID = nameID = 0;
                return;
            }

            int index = str.LastIndexOf('/', start + length - 1);
            if (index < start)
            {
                dirID = 0;
                nameID = StringPool.Add(str, start, length);
            }
            else
            {
                dirID = StringPool.Add(str, start, index - start + 1);
                nameID = StringPool.Add(str, index + 1, start + length - index - 1);
            }
        }

        public override int GetHashCode()
        {
            return dirID * 37 + nameID;
        }

        public bool Equals(PathID other)
        {
            return dirID == other.dirID && nameID == other.nameID;
        }

        public override bool Equals(object obj)
        {
            if (isEmpty && obj == null) return true;

            if (obj is PathID other)
            {
                return Equals(other);
            }
            return false;
        }

        public override string ToString()
        {
            return dirID == 0 ? StringPool.Get(nameID) : StringPool.Get(dirID) + StringPool.Get(nameID);
        }

        public static bool operator ==(PathID a, PathID b)
        {
            return a.Equals(b);
        }

        public static bool operator !=(PathID a, PathID b)
        {
            return !(a == b);
        }

        public int CompareTo(PathID other)
        {
            int result = dir.CompareTo(other.dir);
            return result != 0 ? result : name.CompareTo(other.name);
        }
    }
}