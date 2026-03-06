using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

[AddComponentMenu("UI/GUIButton")]
public class GUIButton : Selectable
{
    public enum ButtonState
    {
        Normal,
        Press,
        Disable,
    }

    public static Material GrayMat;
    public static float DefaultScale = 0.95f;

    public float scale = 0.95f;
    [SerializeField]
    private GUIImage m_ButtonImage;
    [SerializeField]
    private GUIText m_ButtonText;
    private Sprite m_PressedSprite;
    private Sprite m_DisabledSprite;

    private ButtonState m_State = ButtonState.Normal;

    private bool m_Scaled = false;
    private bool m_Disable = false;
    private bool m_Gray = false;
    private bool m_down = false;

    public GUIImage ButtonImage { get { return m_ButtonImage; } }
    public GUIText ButtonText { get { return m_ButtonText; } }
    public Sprite pressedSprite
    {
        get { return m_PressedSprite; }
        set
        {
            m_PressedSprite = value;
            if (m_State == ButtonState.Press)
            {
                SetState(ButtonState.Press, true);
                SetScale(value == null, true);
            }
        }
    }
    public Sprite disabledSprite
    {
        get { return m_DisabledSprite; }
        set
        {
            m_DisabledSprite = value;
            if (m_State == ButtonState.Disable)
            {
                SetState(ButtonState.Disable, true);
            }
        }
    }

    public bool disable { get { return m_Disable; } set { if (m_Disable == value) return; m_Disable = value; SetState(value ? ButtonState.Disable : ButtonState.Normal); } }
    public bool gray { get { return m_Gray; } set { if (m_Gray == value) return; m_Gray = value; SetState(m_State, true); } }

    protected override void Awake()
    {
        base.Awake();
        scale = DefaultScale;
        if (m_ButtonImage == null) m_ButtonImage = transform.GetChild(0).GetComponent<GUIImage>();
        //if (m_ButtonText == null) m_ButtonText = transform.GetChild(1).GetComponent<GUIText>();
    }

    private void SetState(ButtonState state, bool force = false)
    {
        if (state == m_State && !force) return;
        m_State = state;
        if (m_ButtonImage == null) return;
        switch (m_State)
        {
            default:
            case ButtonState.Normal:
                m_ButtonImage.overrideSprite = null;
                //m_ButtonImage.material = m_Gray ? GrayMat : null;
                break;
            case ButtonState.Press:
                m_ButtonImage.overrideSprite = m_PressedSprite;
                //m_ButtonImage.material = m_Gray ? GrayMat : null;
                break;
            case ButtonState.Disable:
                if (m_DisabledSprite != null)
                {
                    m_ButtonImage.overrideSprite = m_DisabledSprite;
                    //m_ButtonImage.material = m_Gray ? GrayMat : null;
                }
                else
                {
                    m_ButtonImage.overrideSprite = null;
                    //m_ButtonImage.material = GrayMat;
                }
                break;
        }
    }

    public ButtonState GetState()
    {
        return m_State;
    }

    private void SetScale(bool isScale, bool immediately)
    {
        if (scale == 1) return;
        if (isScale == m_Scaled) return;
        m_Scaled = isScale;
    }

    public void SetBrightStyle(int value)
    {
        SetScale(false, true);
        if (value == 0)
        {
            SetState(ButtonState.Normal);
        }
        else if (value == 1)
        {
            SetState(ButtonState.Press);
        }
    }

    public void Clear()
    {
        scale = DefaultScale;
        m_PressedSprite = null;
        m_DisabledSprite = null;
        m_Disable = false;
        m_Gray = false;
        m_down = false;
        SetState(ButtonState.Normal, true);
        SetScale(false, true);
    }

    public override void OnPointerDown(PointerEventData eventData)
    {
        m_down = true;
        if (m_ButtonImage != null && !m_Disable)
        {
            SetState(ButtonState.Press);
            if (m_PressedSprite == null)
            {
                SetScale(true, false);
            }
        }
    }

    public override void OnPointerUp(PointerEventData eventData)
    {
        if (!m_down) return;
        m_down = false;
        if (m_ButtonImage != null && !m_Disable)
        {
            SetState(ButtonState.Normal);
            SetScale(false, false);
        }
    }

    public override void OnPointerExit(PointerEventData eventData)
    {
        if (!m_down) return;
        m_down = false;
        if (m_ButtonImage != null && !m_Disable)
        {
            SetState(ButtonState.Normal);
            SetScale(false, false);
        }
    }

    public void SetRawSize()
    {
        if (!m_ButtonImage) return;
        var imgSprite = m_ButtonImage.sprite;
        if (!imgSprite) return;
        //仅处理宽高,不处理anchor,sizeDelta
        var pixelsPerUnit = m_ButtonImage.pixelsPerUnit;
        float w = imgSprite.rect.width / pixelsPerUnit;
        float h = imgSprite.rect.height / pixelsPerUnit;
        var rectTransform = transform as RectTransform;
        rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Horizontal, w);
        rectTransform.SetSizeWithCurrentAnchors(RectTransform.Axis.Vertical, h);
    }

    public void InitText(GUIText text)
    {
        var rect = text.rectTransform;
        var img = ButtonImage;
        rect.SetParent(img.transform, false);
        rect.SetAnchoredPosition(0, 0);
        text.material = img.material;
        text.raycastTarget = false;
        text.inUse = true;
    }

    public void ResetText(GUIText text)
    {
        var rect = text.rectTransform;
        text.material = null;
        text.raycastTarget = true;
        text.inUse = false;
    }
}