using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Sprites;

[AddComponentMenu("UI/GUITextAtlas")]
public class GUITextAtlas : MaskableGraphic
{
    private readonly int START_NUM = 46;// 默认开头字符.的ASCII值

    [SerializeField] Sprite m_sprite;
    [SerializeField] private string m_FirstChar = "";
    [SerializeField] private float m_ItemWidth = 0;
    [SerializeField] private float m_ItemHeight = 0;
    [SerializeField] private string m_Text = "";
    [SerializeField] private float m_wordSpace = 0;
    private int m_Idx = 0;

    protected GUITextAtlas()
    {
        useLegacyMeshGeneration = false;
    }

    /// <summary>
    /// Returns the texture used to draw this Graphic.
    /// </summary>
    public override Texture mainTexture
    {
        get
        {
            if (sprite == null)
            {
                if (material != null && material.mainTexture != null)
                {
                    return material.mainTexture;
                }
                return null;
            }

            return sprite.texture;
        }
    }

    /**仅修改颜色*/
    public void SetColor(Color color)
    {
        var a = this.color.a;
        color.a = a;
        this.color = color;
    }

    public Sprite sprite
    {
        get
        {
            return m_sprite;
        }
        set
        {
            if (m_sprite == value)
                return;

            m_sprite = value;
            SetAllDirty();
        }
    }
    public string FirstChar
    {
        get { return m_FirstChar; }
        set
        {
            m_FirstChar = value;
            int idx = 0;
            if (!string.IsNullOrEmpty(value))
            {
                char c = value[0];
                idx = c - START_NUM;
            }
            if (idx != this.m_Idx)
            {
                m_Idx = idx;
                SetVerticesDirty();
            }
        }
    }
    public float ItemWidth
    {
        get { return m_ItemWidth; }
        set
        {
            if (m_ItemWidth != value)
            {
                m_ItemWidth = value;
                SetVerticesDirty();
            }
        }
    }
    public float ItemHeight
    {
        get { return m_ItemHeight; }
        set
        {
            if (m_ItemHeight != value)
            {
                m_ItemHeight = value;
                SetVerticesDirty();
            }
        }
    }
    public float WordSpace
    {
        get { return m_wordSpace; }
        set
        {
            if (m_wordSpace != value)
            {
                m_wordSpace = value;
                SetVerticesDirty();
            }
        }
    }
    public string Text
    {
        get { return m_Text; }
        set
        {
            if (m_Text != value)
            {
                m_Text = value;
                SetVerticesDirty();
            }
        }
    }

    public void SetProperty(string firstChat, float itemWidth, float itemHeight, string str)
    {
        FirstChar = firstChat;
        ItemWidth = itemWidth;
        ItemHeight = itemHeight;
        Text = str;
    }

    public override void SetNativeSize()
    {
        int w = Mathf.RoundToInt((m_ItemWidth + m_wordSpace) * m_Text.Length - m_wordSpace);
        int h = Mathf.RoundToInt(m_ItemHeight);
        //rectTransform.anchorMax = rectTransform.anchorMin;
        //rectTransform.sizeDelta = new Vector2(w, h);
        rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, w);
        rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, h);
    }

    protected override void OnPopulateMesh(VertexHelper vh)
    {
        vh.Clear();
        var sprite = m_sprite;
        if (sprite == null) return;
        var r = GetPixelAdjustedRect();
        var idx = 0;
        var len = m_Text.Length;
        if (len <= 0) return;
        var outer = DataUtility.GetOuterUV(sprite);
        var inner = DataUtility.GetInnerUV(sprite);
        var uvx1 = inner.x;
        var uvx2 = inner.z;
        var uvy1 = inner.y;
        var uvy2 = inner.w;
        var uvx2_1 = uvx2 - uvx1;
        var uvy2_1 = uvy2 - uvy1;
        var color32 = color;
        var spriteW = sprite.rect.width;
        var spriteH = sprite.rect.height;
        for (var i = 0; i < len; i++)
        {
            var c = m_Text[i];
            var cIdx = c - START_NUM;
            cIdx -= m_Idx;
            if (cIdx < 0) continue;
            var rectX = r.x + idx * (m_ItemWidth + m_wordSpace);
            var rectY = r.y;
            var rectZ = rectX + m_ItemWidth;
            var rectW = r.y + m_ItemHeight;
            float x1 = Mathf.Min(1, cIdx * m_ItemWidth * 1.0f / spriteW);
            float x2 = Mathf.Min(1, (cIdx + 1) * m_ItemWidth * 1.0f / spriteW);
            float y1 = 0;
            float y2 = 1;

            var xMin = uvx1 + uvx2_1 * x1;
            var xMinDis = outer.x - xMin;
            if (xMinDis > 0)
            {
                xMin = outer.x;
                rectX += spriteW * xMinDis / uvx2_1;
            }

            var xMax = uvx1 + uvx2_1 * x2;
            var xMaxDis = outer.z - xMax;
            if (xMaxDis < 0)
            {
                xMax = outer.z;
                rectZ += spriteW * xMaxDis / uvx2_1;
            }

            var yMin = uvy1 + uvy2_1 * y1;
            var yMinDis = outer.y - yMin;
            if (yMinDis > 0)
            {
                yMin = outer.y;
                rectY += spriteH * yMinDis / uvy2_1;
            }

            var yMax = uvy1 + uvy2_1 * y2;
            var yMaxDis = outer.w - yMax;
            if (yMaxDis < 0)
            {
                yMax = outer.w;
                rectW += spriteH * yMaxDis / uvy2_1;
            }

            vh.AddVert(new Vector3(rectX, rectY), color32, new Vector2(xMin, yMin));
            vh.AddVert(new Vector3(rectX, rectW), color32, new Vector2(xMin, yMax));
            vh.AddVert(new Vector3(rectZ, rectW), color32, new Vector2(xMax, yMax));
            vh.AddVert(new Vector3(rectZ, rectY), color32, new Vector2(xMax, yMin));

            vh.AddTriangle(4 * idx + 0, 4 * idx + 1, 4 * idx + 2);
            vh.AddTriangle(4 * idx + 2, 4 * idx + 3, 4 * idx + 0);
            idx++;
        }
    }

    public void Clear()
    {
        color = Color.white;
        sprite = null;
        FirstChar = string.Empty;
        ItemWidth = 0;
        ItemHeight = 0;
        Text = string.Empty;
        WordSpace = 0;
        material = null;
    }

}