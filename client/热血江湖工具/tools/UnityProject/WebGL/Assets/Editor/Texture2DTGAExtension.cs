using UnityEngine;

// References:
//    Quick and Dirty Writeable Bitmap as TGA image: http://nokola.com/blog/post/2010/01/21/Quick-and-Dirty-Output-of-WriteableBitmap-as-TGA-Image.aspx
//    TGLoader: https://gist.github.com/mikezila/10557162
//    Truevision TGA Specification on Wikipedia: https://en.wikipedia.org/wiki/Truevision_TGA#Technical_details
public static class Texture2DTGAExtension
{
    public enum Channel { R, G, B, A, White, Black, Gray }

    /// <summary> Default TGA Footer. </summary>
    private static readonly byte[] TGA_FOOTER = new byte[]
    {
        0, 0, 0, 0, // extension offset
        0, 0, 0, 0, // developer area offset
        (byte)'T',
        (byte)'R',
        (byte)'U',
        (byte)'E',
        (byte)'V',
        (byte)'I',
        (byte)'S',
        (byte)'I',
        (byte)'O',
        (byte)'N',
        (byte)'-',
        (byte)'X',
        (byte)'F',
        (byte)'I',
        (byte)'L',
        (byte)'E',
        (byte)'.',
        0 // required null
    };

    /// <summary>Encode this Texture2D into TGA format. Defaults to RGBA</summary>
    /// <param name="channels">Specify the order of channels to be written. Must be 3 or 4 in lenght. Defaults to RGBA if null</param>
    public static byte[] EncodeToTGA(this Texture2D texture, Channel[] channels = null)
    {
        // Default Channels
        if (channels == null)
        {
            // How you expect to view the channels in Photoshop, etc.
            channels = new[]
            {
                Channel.R,
                Channel.G,
                Channel.B,
                Channel.A
            };

        }

        int channelNum = channels.Length;
        if (channelNum != 3 && channelNum != 4)
            throw new UnityException("Can only save TGA with 3 or 4 channels");


        byte[] headerBytes = CreateTGAHeader(texture.width, texture.height, channelNum == 4);

        Color32[] pixels = texture.GetPixels32();
        byte[] tgaBytes = new byte[headerBytes.Length + TGA_FOOTER.Length + pixels.Length * channelNum];

        int curByte = headerBytes.Length;
        foreach (Color32 pixel in pixels)
        {
            // TGA flips RGB internally. ex: RGBA textures are stored as BGRA internally
            tgaBytes[curByte + 0] = GetChannel(pixel, channels[2]);         // Default: B
            tgaBytes[curByte + 1] = GetChannel(pixel, channels[1]);         // Default: G
            tgaBytes[curByte + 2] = GetChannel(pixel, channels[0]);         // Default: R
            if (channelNum == 4)
            {
                tgaBytes[curByte + 3] = GetChannel(pixel, channels[3]);     // Default: A
            }
            curByte += channelNum;
        }

        System.Array.ConstrainedCopy(headerBytes, 0, tgaBytes, 0, headerBytes.Length);
        System.Array.ConstrainedCopy(TGA_FOOTER, 0, tgaBytes, curByte, TGA_FOOTER.Length);

        return tgaBytes;
    }


    private static byte GetChannel(Color32 color, Channel channel)
    {
        switch (channel)
        {
            case Channel.R: return color.r;
            case Channel.G: return color.g;
            case Channel.B: return color.b;
            case Channel.A: return color.a;
            case Channel.Black: return 0;
            case Channel.Gray: return 127;
            default:
            case Channel.White: return 255;
        }
    }

    private static byte[] CreateTGAHeader(int width, int height, bool haveFourthChannel = true)
    {
        return new byte[]
        {
            0, // ID length
            0, // no color map
            2, // uncompressed, true color
            0, 0, 0, 0,
            0,
            0, 0, 0, 0, // x and y origin
            (byte)(width & 0x00FF),
            (byte)((width & 0xFF00) >> 8),
            (byte)(height & 0x00FF),
            (byte)((height & 0xFF00) >> 8),
            (byte)(haveFourthChannel ? 32 : 24), // 32 or 24 bit bitmap
            0
        };
    }
}