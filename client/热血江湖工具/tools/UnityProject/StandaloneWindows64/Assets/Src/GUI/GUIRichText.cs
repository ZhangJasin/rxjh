using UnityEngine;
using UnityEngine.UI;

public class GUIRichText : MaskableGraphic
{

    private float[] m_drawInfos;
    private Color m_BgColor;



    public void DrawBgColor(Color bgColor, params float[] drawInfos)
    {
        m_BgColor = bgColor;
        m_drawInfos = drawInfos;
        this.SetVerticesDirty();
    }

    protected override void OnPopulateMesh(VertexHelper vh)
    {
        vh.Clear();
        if (m_BgColor == null) return;
        if (m_drawInfos == null) return;

        var r = GetPixelAdjustedRect();
        Color32 color32 = m_BgColor;
        for (var i = 0; i < m_drawInfos.Length; i += 4)
        {
            var x = r.x + (float)m_drawInfos.GetValue(i);
            var y = r.y + (float)m_drawInfos.GetValue(i + 1);
            var w = x + (float)m_drawInfos.GetValue(i + 2);
            var h = y + (float)m_drawInfos.GetValue(i + 3);

            var v = new Vector4(x, y, w, h);

            vh.AddVert(new Vector3(v.x, v.y), color32, new Vector2(0f, 0f));
            vh.AddVert(new Vector3(v.x, v.w), color32, new Vector2(0f, 1f));
            vh.AddVert(new Vector3(v.z, v.w), color32, new Vector2(1f, 1f));
            vh.AddVert(new Vector3(v.z, v.y), color32, new Vector2(1f, 0f));

            vh.AddTriangle(0 + i, 1 + i, 2 + i);
            vh.AddTriangle(2 + i, 3 + i, 0 + i);
        }
    }

}


