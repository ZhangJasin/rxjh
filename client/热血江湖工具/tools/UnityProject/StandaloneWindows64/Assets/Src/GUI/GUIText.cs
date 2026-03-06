using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;


[AddComponentMenu("UI/GUIText")]
public class GUIText : Text
{
    /// <summary>
    /// 下划线向上偏移一定距离
    /// </summary>
    public int ulineYOff = 2;

    /// <summary>
    /// 下划线信息列表
    /// </summary>
    private readonly List<UnderlineInfo> m_UnderlineInfos = new List<UnderlineInfo>();


    [SerializeField] private bool m_underLine = false;
    [SerializeField] private Color? m_underLineColor = null;

    /// <summary>
    /// 标记是否在实际使用
    /// </summary>
    private bool m_inUse = false;

    public bool underLine
    {
        get { return m_underLine; }
        set
        {
            if (m_underLine != value)
            {
                m_underLine = value;
                SetVerticesDirty();
            }
        }
    }

    public Color? underLineColor
    {
        get { return m_underLineColor.HasValue ? m_underLineColor.Value : this.color; }
        set
        {
            if (m_underLineColor != value)
            {
                m_underLineColor = value;
                SetVerticesDirty();
            }
        }
    }

    public bool inUse
    {
        get { return m_inUse; }
        set
        {
            if (m_inUse == value) return;
            m_inUse = value;
            if (value)
            {
                if (IsActive())
                {
                    GUITextRebuilder.textureRebuilt += RefreshTexture;
                }
            }
            else
            {
                if (IsActive())
                {
                    GUITextRebuilder.textureRebuilt -= RefreshTexture;
                }
            }
        }
    }

    public ContentSizeFitter contentSizeFitter { get; protected set; }

    /**仅修改颜色*/
    public void SetColor(Color color)
    {
        var a = this.color.a;
        color.a = a;
        this.color = color;
    }

    public override void SetVerticesDirty()
    {
        base.SetVerticesDirty();
        UpdateUnderlineInfo(text);

    }

    protected override void Awake()
    {
        base.Awake();
        contentSizeFitter = GetComponent<ContentSizeFitter>();
    }

    protected override void OnEnable()
    {
        base.OnEnable();
        if (m_inUse)
        {
            GUITextRebuilder.textureRebuilt += RefreshTexture;
        }
    }

    protected override void OnDisable()
    {
        base.OnDisable();
        if (m_inUse)
        {
            GUITextRebuilder.textureRebuilt -= RefreshTexture;
        }
    }

    protected override void OnDestroy()
    {
        base.OnDestroy();
        GUITextRebuilder.textureRebuilt -= RefreshTexture;
    }

    protected void RefreshTexture(Dictionary<Font, bool> dirtyFontMap)
    {
        if (!font) return;
        if (dirtyFontMap == null) return;
        if (dirtyFontMap.ContainsKey(font))
        {
            FontTextureChanged();
        }
    }

    protected override void OnPopulateMesh(VertexHelper toFill)
    {
        base.OnPopulateMesh(toFill);

        UIVertex vert = new UIVertex();

        if (m_UnderlineInfos.Count > 0)
        {
            // 处理下划线包围框
            foreach (var underlineInfo in m_UnderlineInfos)
            {
                underlineInfo.boxes.Clear();
#if UNITY_2019_1_OR_NEWER
                int startIndex = underlineInfo.newStartIndex;
                int endIndex = underlineInfo.newEndIndex;
#if UNITY_2019_4_3
                    //目前发现此版本单行没有优化顶点多行优化了顶点
                    if (preferredWidth > rect.sizeDelta.x)
                    {
                        startIndex = underlineInfo.startIndex;
                        endIndex = underlineInfo.endIndex;
                    }
#endif
#else
                    int startIndex = underlineInfo.startIndex;
                    int endIndex = underlineInfo.endIndex;
#endif
                if (startIndex >= toFill.currentVertCount)
                {
                    continue;
                }

                // 将下划线里面的文本顶点索引坐标加入到包围框
                toFill.PopulateUIVertex(ref vert, startIndex + 3);
                var pos = vert.position;
                var bounds = new Bounds(pos, Vector3.zero);
                for (int i = startIndex + 3, m = endIndex; i <= m; i += 4)
                {
                    if (i >= toFill.currentVertCount)
                    {
                        break;
                    }

                    toFill.PopulateUIVertex(ref vert, i);
                    pos = vert.position;
                    if (pos.x < bounds.min.x || (bounds.min.y - pos.y) >= fontSize / 2f) // 换行重新添加包围框
                    {
                        underlineInfo.boxes.Add(new Rect(bounds.min, bounds.size));
                        bounds = new Bounds(pos, Vector3.zero);
                    }
                    //else
                    //{
                    bounds.Encapsulate(pos); // 扩展包围框
                    toFill.PopulateUIVertex(ref vert, i - 2);
                    bounds.Encapsulate(vert.position);
                    //}
                }
                underlineInfo.boxes.Add(new Rect(bounds.min, bounds.size));
            }

            TextGenerator _UnderlineText = new TextGenerator();
            _UnderlineText.Populate("_", this.GetGenerationSettings(this.rectTransform.rect.size));
            IList<UIVertex> _TUT = _UnderlineText.verts;
            //增加这层判断是因为 控件的rect可能会被设置为0或很小的值导致无法放下一个字也就无法生成顶点了
            if (_TUT.Count > 0)
            {
                foreach (var underlineInfo in m_UnderlineInfos)
                {
#if UNITY_2019_1_OR_NEWER
                    int startIndex = underlineInfo.newStartIndex;
                    int endIndex = underlineInfo.newEndIndex;
#if UNITY_2019_4_3
                        //目前发现此版本单行没有优化顶点多行优化了顶点
                        if (preferredWidth > rect.sizeDelta.x)
                        {
                            startIndex = underlineInfo.startIndex;
                            endIndex = underlineInfo.endIndex;
                        }
#endif
#else
                        int startIndex = underlineInfo.startIndex;
                        int endIndex = underlineInfo.endIndex;
#endif
                    if (startIndex >= toFill.currentVertCount)
                    {
                        continue;
                    }
                    for (int i = 0; i < underlineInfo.boxes.Count; i++)
                    {
                        Vector3 _StartBoxPos = new Vector3(underlineInfo.boxes[i].x, underlineInfo.boxes[i].y + ulineYOff, 0.0f);
                        Vector3 _EndBoxPos = _StartBoxPos + new Vector3(underlineInfo.boxes[i].width, underlineInfo.boxes[i].height, 0.0f);
                        AddUnderlineQuad(toFill, _TUT, _StartBoxPos, _EndBoxPos, underLineColor);
                    }
                }
            }
        }

    }

    void AddUnderlineQuad(VertexHelper _VToFill, IList<UIVertex> _VTUT, Vector3 _VStartPos, Vector3 _VEndPos, Color32? color)
    {
        float yOffset = _VStartPos.y - _VTUT[0].position.y;
        float len = _VTUT[1].position.x - _VTUT[0].position.x;
        bool uvX = true;//true表示横着的使用uv中的X计算 false表示竖着的用uv中的Y计算
        float uvLen = _VTUT[1].uv0.x - _VTUT[0].uv0.x;
        if (uvLen == 0)
        {
            uvX = false;
            uvLen = _VTUT[1].uv0.y - _VTUT[0].uv0.y;
        }

        float step = 0;
        //此处增加判断是因为顶点有可能只有4个（因为控件的宽度不够只能放下1个字时只有4个顶点）
        if (_VTUT.Count > 4)
        {
            step = _VTUT[4].position.x - _VTUT[0].position.x;
        }
        int lineCount = (int)(step > 0 ? (_VEndPos.x - _VStartPos.x) / step : 1);
        lineCount = lineCount > 0 ? lineCount : 1;
        UIVertex[] m_TempVerts = new UIVertex[4];
        for (int i = 0; i < lineCount; i++)
        {
            float startX = _VStartPos.x + i * step;
            for (int j = 0; j < 4; j++)
            {
                Vector2 pos = Vector2.zero;
                Vector2 uv0 = _VTUT[j].uv0;
                if (j == 0 || j == 3)
                {
                    pos.x = startX;
                    if (uvX)
                    {
                        uv0.x += 0.2f * uvLen;
                    }
                    else
                    {
                        uv0.y += 0.2f * uvLen;
                    }
                }
                if (j == 1 || j == 2)
                {
                    if (i < lineCount - 1)
                    {
                        pos.x = startX + len;
                    }
                    else
                    {
                        pos.x = _VEndPos.x;
                        if (uvX)
                        {
                            uv0.x -= 0.2f * uvLen;
                        }
                        else
                        {
                            uv0.y -= 0.2f * uvLen;
                        }
                    }
                }
                m_TempVerts[j] = _VTUT[j];
                pos.y = _VTUT[j].position.y + yOffset;
                m_TempVerts[j].position = pos;
                m_TempVerts[j].uv0 = uv0;
                if (color != null)
                {
                    m_TempVerts[j].color = color.Value;
                }
            }
            _VToFill.AddUIVertexQuad(m_TempVerts);
        }
    }


    protected void UpdateUnderlineInfo(string outputText)
    {
        m_UnderlineInfos.Clear();
        if (!m_underLine) return;
        var underlineInfo = new UnderlineInfo
        {
            startIndex = 0, // 下划线的文本起始顶点索引
            endIndex = outputText.Length * 4 + 3,
            newStartIndex = 0,
            newEndIndex = outputText.Length * 4
        };

        m_UnderlineInfos.Add(underlineInfo);
    }
   


    /// <summary>
    /// 超链接信息类
    /// </summary>
    private class HrefInfo
    {
        public int startIndex;
        public int newStartIndex;

        public int endIndex;
        public int newEndIndex;

        public string name;

        public readonly List<Rect> boxes = new List<Rect>();
    }

    private class UnderlineInfo
    {
        //public Color32? color;

        public int startIndex;
        public int newStartIndex;

        public int endIndex;
        public int newEndIndex;

        public readonly List<Rect> boxes = new List<Rect>();
    }
}
