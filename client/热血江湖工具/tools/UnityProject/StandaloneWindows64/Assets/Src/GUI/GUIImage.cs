using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Sprites;

[AddComponentMenu("UI/GUIImage")]
public class GUIImage : Image
{
    [SerializeField]
    private bool m_Sliced9Enable = false;   //GUI九宫格
    [SerializeField]
    private float m_SliceClip_l = 0;
    [SerializeField]
    private float m_SliceClip_r = 0;
    [SerializeField]
    private float m_SliceClip_t = 0;
    [SerializeField]
    private float m_SliceClip_b = 0;

    public bool drawTou { get; set; }       //绘制透明
    public bool drawColor = false;          //绘制单色

    /**仅修改颜色*/
    public void SetColor(Color color)
    {
        var a = this.color.a;
        color.a = a;
        this.color = color;
    }

    public void SetScale9Slice(float l, float r, float t, float b)
    {
        m_SliceClip_l = Mathf.Max(0, l);
        m_SliceClip_r = Mathf.Max(0, r);
        m_SliceClip_t = Mathf.Max(0, t);
        m_SliceClip_b = Mathf.Max(0, b);
        m_Sliced9Enable = m_SliceClip_l != 0 || m_SliceClip_r != 0 || m_SliceClip_t != 0 || m_SliceClip_b != 0;
        SetVerticesDirty();
    }

    public void GetScale9Slice(out float l, out float r, out float t, out float b)
    {
        l = m_SliceClip_l;
        r = m_SliceClip_r;
        t = m_SliceClip_t;
        b = m_SliceClip_b;
    }

    protected override void OnPopulateMesh(VertexHelper vh)
    {
        var activeSprite = overrideSprite ?? sprite;
        if (activeSprite || drawColor)
        {
            if (m_Sliced9Enable)
            {
                GenerateSlicedSprite(vh);
            }
            else
            {
                base.OnPopulateMesh(vh);
            }
        }
        else if (drawTou)
        {
            vh.Clear();
            Rect rect = GetPixelAdjustedRect();
            AddQuad(vh,
                    new Vector2(rect.x, rect.y),
                    new Vector2(rect.x + rect.width, rect.y + rect.height),
                    Color.clear, Vector2.zero, Vector2.one);
        }
        else
        {
            vh.Clear();
            return;
        }
    }

    static readonly Vector2[] s_VertScratch = new Vector2[4];
    static readonly Vector2[] s_UVScratch = new Vector2[4];

    private void GenerateSlicedSprite(VertexHelper toFill)
    {
        var activeSprite = overrideSprite ?? sprite;

        Vector4 outer, inner, padding, border;

        float sliceL = m_SliceClip_l;
        float sliceR = m_SliceClip_r;
        float sliceB = m_SliceClip_b;
        float sliceT = m_SliceClip_t;
        if (activeSprite != null)
        {
            outer = DataUtility.GetOuterUV(activeSprite);
            float uvw = outer.z - outer.x;
            float uvh = outer.w - outer.y;
            float rectW = activeSprite.rect.width;
            float rectH = activeSprite.rect.height;
            float texW = activeSprite.textureRect.width;
            float texH = activeSprite.textureRect.height;
            var rectOffset = activeSprite.textureRectOffset;
            if (rectW != texW)
            {
                float offL = rectOffset.x;
                float offR = rectW - texW - offL;
                sliceL = sliceL - offL;
                sliceR = sliceR - offR;
            }
            if (rectH != texH)
            {
                float offB = rectOffset.y;
                float offT = rectH - texH - offB;
                sliceB = sliceB - offB;
                sliceT = sliceT - offT;
            }
            float innerX = outer.x + uvw * sliceL / texW;
            float innerZ = outer.z - uvw * sliceR / texW;
            float innerY = outer.y + uvh * sliceB / texH;
            float innerW = outer.w - uvh * sliceT / texH;
            inner = new Vector4(innerX, innerY, innerZ, innerW);
            padding = DataUtility.GetPadding(activeSprite);
            border = new Vector4(m_SliceClip_l, m_SliceClip_b, m_SliceClip_r, m_SliceClip_t);
        }
        else
        {
            if (fillCenter)
            {
                outer = Vector4.zero;
                inner = Vector4.zero;
                padding = Vector4.zero;
                border = Vector4.zero;
            }
            else
            {
                outer = Vector4.one;
                var transRect = (this.transform as RectTransform).rect;
                float innerX = outer.x + 1 * sliceL / transRect.width;
                float innerZ = outer.z - 1 * sliceR / transRect.width;
                float innerY = outer.y + 1 * sliceB / transRect.height;
                float innerW = outer.w - 1 * sliceT / transRect.height;
                inner = new Vector4(innerX, innerY, innerZ, innerW);
                padding = Vector4.zero;
                border = new Vector4(m_SliceClip_l, m_SliceClip_b, m_SliceClip_r, m_SliceClip_t);
            }
        }

        Rect rect = GetPixelAdjustedRect();

        Vector4 adjustedBorders = GetAdjustedBorders(border / multipliedPixelsPerUnit, rect);
        padding = padding / multipliedPixelsPerUnit;

        s_VertScratch[0] = new Vector2(padding.x, padding.y);
        s_VertScratch[3] = new Vector2(rect.width - padding.z, rect.height - padding.w);

        s_VertScratch[1].x = adjustedBorders.x;
        s_VertScratch[1].y = adjustedBorders.y;

        s_VertScratch[2].x = rect.width - adjustedBorders.z;
        s_VertScratch[2].y = rect.height - adjustedBorders.w;

        for (int i = 0; i < 4; ++i)
        {
            s_VertScratch[i].x += rect.x;
            s_VertScratch[i].y += rect.y;
        }

        s_UVScratch[0] = new Vector2(outer.x, outer.y);
        s_UVScratch[1] = new Vector2(inner.x, inner.y);
        s_UVScratch[2] = new Vector2(inner.z, inner.w);
        s_UVScratch[3] = new Vector2(outer.z, outer.w);

        toFill.Clear();

        for (int x = 0; x < 3; ++x)
        {
            int x2 = x + 1;

            for (int y = 0; y < 3; ++y)
            {
                if (!fillCenter && x == 1 && y == 1)
                    continue;

                int y2 = y + 1;


                AddQuad(toFill,
                    new Vector2(s_VertScratch[x].x, s_VertScratch[y].y),
                    new Vector2(s_VertScratch[x2].x, s_VertScratch[y2].y),
                    color,
                    new Vector2(s_UVScratch[x].x, s_UVScratch[y].y),
                    new Vector2(s_UVScratch[x2].x, s_UVScratch[y2].y));
            }
        }
    }

    static void AddQuad(VertexHelper vertexHelper, Vector2 posMin, Vector2 posMax, Color32 color, Vector2 uvMin, Vector2 uvMax)
    {
        int startIndex = vertexHelper.currentVertCount;

        vertexHelper.AddVert(new Vector3(posMin.x, posMin.y, 0), color, new Vector2(uvMin.x, uvMin.y));
        vertexHelper.AddVert(new Vector3(posMin.x, posMax.y, 0), color, new Vector2(uvMin.x, uvMax.y));
        vertexHelper.AddVert(new Vector3(posMax.x, posMax.y, 0), color, new Vector2(uvMax.x, uvMax.y));
        vertexHelper.AddVert(new Vector3(posMax.x, posMin.y, 0), color, new Vector2(uvMax.x, uvMin.y));

        vertexHelper.AddTriangle(startIndex, startIndex + 1, startIndex + 2);
        vertexHelper.AddTriangle(startIndex + 2, startIndex + 3, startIndex);
    }

    private Vector4 GetAdjustedBorders(Vector4 border, Rect adjustedRect)
    {
        Rect originalRect = rectTransform.rect;
        for (int axis = 0; axis <= 1; axis++)
        {
            float borderScaleRatio;
            if (originalRect.size[axis] != 0)
            {
                borderScaleRatio = adjustedRect.size[axis] / originalRect.size[axis];
                border[axis] *= borderScaleRatio;
                border[axis + 2] *= borderScaleRatio;
            }
            float combinedBorders = border[axis] + border[axis + 2];
            if (adjustedRect.size[axis] < combinedBorders && combinedBorders != 0)
            {
                borderScaleRatio = adjustedRect.size[axis] / combinedBorders;
                border[axis] *= borderScaleRatio;
                border[axis + 2] *= borderScaleRatio;
            }
        }
        return border;
    }


    public void SetRawSize()
    {
        if (sprite != null)
        {
            //仅处理宽高,不处理anchor,sizeDelta
            float w = sprite.rect.width / pixelsPerUnit;
            float h = sprite.rect.height / pixelsPerUnit;
            rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, w);
            rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, h);
            SetAllDirty();
        }
    }

}
