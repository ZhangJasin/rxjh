using ICSharpCode.SharpZipLib.GZip;
using System;
using System.IO;

namespace TCFramework
{
    public static class GZip
    {
        public static byte[] CompressWithSize(byte[] input)
        {
            using (var outStream = new MemoryStream())
            {
                outStream.Write(BitConverter.GetBytes(input.Length), 0, 4);
                using (var zipStream = new GZipOutputStream(outStream))
                {
                    zipStream.Write(input, 0, input.Length);
                }
                return outStream.ToArray();
            }
        }

        public static byte[] DecompressWithSize(byte[] input)
        {
            int size = BitConverter.ToInt32(input, 0);
            using (var inStream = new MemoryStream(input, 4, input.Length - 4))
            {
                using (var zipStream = new GZipInputStream(inStream))
                {
                    byte[] output = new byte[size];
                    int readSize = 0;
                    while (readSize < size)
                    {
                        readSize += zipStream.Read(output, readSize, size - readSize);
                    }
                    return output;
                }
            }
        }
    }
}