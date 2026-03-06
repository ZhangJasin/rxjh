
using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

#if UNITY_EDITOR
using static UnityEditor.EditorApplication;
#endif

public static class GUIUtils
{
    private static Color defaultPHTextColor = new Color(0.321f, 0.321f, 0.321f, 0.623f);
    public static void RegisterClearFontMat(Material fontMat)
    {
#if UNITY_EDITOR
        Action<PlayModeStateChange> clearFontMat = null;
        clearFontMat = (PlayModeStateChange state) =>
        {
            if (fontMat) fontMat.mainTexture = null;
            playModeStateChanged -= clearFontMat;
        };
        playModeStateChanged += clearFontMat;
#endif
    }

    public static void InitNode(RectTransform rect, float x, float y, float pivotX, float pivotY, Transform parent = null)
    {
        rect.SetAnchoredPosition(x, y);
        //rect.SetLocalEulerAnglesZ(0);
        //rect.SetSizeDelta(0, 0);
        if (parent) rect.SetParent(parent, false);
    }

    public static void ResetNode(RectTransform rect, Transform parent = null)
    {
        if (!rect) return;
        var go = rect.gameObject;
        if (!go.activeSelf) go.SetActive(true);
        rect.anchorMin = Vector2.zero;
        rect.anchorMax = Vector2.zero;
        rect.SetAnchoredPosition(0, 0);
        if (parent) rect.SetParent(parent, false);
    }

    public static void InitLayout(RectTransform rect, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        rect.SetAnchoredPosition(x, y);
        //rect.SetLocalEulerAnglesZ(0);
        if (parent) rect.SetParent(parent, false);
    }

    public static void ResetLayout(GUIImage image, Transform parent = null)
    {
        if (!image) return;
        var rect = image.rectTransform;
        ResetNode(rect, parent);
        image.color = Color.white;
        image.drawColor = false;
        image.sprite = null;
        image.material = null;
        image.SetScale9Slice(0, 0, 0, 0);
        image.raycastTarget = true;
    }

    public static void ResetLayout(Graphic graphic, Transform parent = null)
    {
        if (!graphic) return;
        var rect = graphic.rectTransform;
        ResetNode(rect, parent);
        graphic.color = Color.white;
        graphic.material = null;
        graphic.raycastTarget = true;
    }

    public static void InitText(GUIText text, ContentSizeFitter csf, float x, float y, float pivotX, float pivotY, int fontSize, Color color, string str, Transform parent = null)
    {
        var rect = text.rectTransform;

        text.inUse = true;
        text.fontSize = fontSize;
        text.horizontalOverflow = HorizontalWrapMode.Wrap;
        text.verticalOverflow = VerticalWrapMode.Truncate;
        text.alignment = TextAnchor.UpperLeft;
        text.SetColor(color);
        text.text = str;
        if (csf)
        {
            csf.enabled = false;
            //csf.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            //csf.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        }
        LayoutRebuilder.ForceRebuildLayoutImmediate(rect);
        InitNode(rect, x, y, pivotX, pivotY, parent);
    }

    public static void InitText(GUIText text, ContentSizeFitter csf, float x, float y, float pivotX, float pivotY, int fontSize, Color color, float str, Transform parent = null)
    {
        InitText(text, csf, x, y, pivotX, pivotY, fontSize, color, str.ToString(), parent);
    }

    //RichText中的Text子节点
    public static void InitRichText(GUIText text, ContentSizeFitter csf, float x, float y, float pivotX, float pivotY, int fontSize, Color color, string str, Transform parent = null)
    {
        var rect = text.rectTransform;

        text.inUse = true;
        text.fontSize = fontSize;
        text.horizontalOverflow = HorizontalWrapMode.Overflow;
        text.verticalOverflow = VerticalWrapMode.Overflow;
        text.alignment = TextAnchor.MiddleLeft;
        text.SetColor(color);
        text.text = str;
        //text.raycastTarget = false;
        if (csf)
        {
            csf.enabled = false;
            //csf.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            //csf.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
        }
        InitNode(rect, x, y, pivotX, pivotY, parent);
    }

    public static void ResetText(GUIText text, Outline outline, Transform parent = null)
    {
        if (!text) return;
        var rect = text.rectTransform;
        ResetNode(rect, parent);
        text.inUse = false;
        text.text = string.Empty;
        text.color = Color.white;
        text.fontSize = 14;
        text.lineSpacing = 1;
        text.raycastTarget = true;
        //text.material = null;
        text.underLine = false;
        text.underLineColor = null;
        text.horizontalOverflow = HorizontalWrapMode.Wrap;
        text.verticalOverflow = VerticalWrapMode.Truncate;
        text.alignment = TextAnchor.UpperLeft;
        //self: SetFontName(GUI.PATH_FONT)
        if (outline)
        {
            outline.enabled = false;
        }
    }

    public static void InitScrollText(RectTransform rect, GUIText text, float x, float y, float pivotX, float pivotY, float w, int fontSize, Color color, string str, Transform parent = null)
    {
        var textRect = text.rectTransform;

        text.inUse = true;
        text.fontSize = fontSize;
        text.SetColor(color);
        text.text = str;
        LayoutRebuilder.ForceRebuildLayoutImmediate(textRect);

        InitNode(rect, x, y, pivotX, pivotY, parent);
    }

    public static void ResetScrollText(GUIImage image, GUIText text, Outline outline, Transform parent = null)
    {
        if (!image) return;
        var rect = image.rectTransform;
        ResetNode(rect, parent);
        image.sprite = null;
        image.raycastTarget = true;
        image.material = null;
        if (text)
        {
            text.inUse = false;
            text.text = string.Empty;
            //text.color = Color.white;
            //text.fontSize = 14;
            text.lineSpacing = 1;
            //text.raycastTarget = true;
            text.material = null;
            //text.underLine = false;
            //text.underLineColor = null;
            //text.horizontalOverflow = HorizontalWrapMode.Wrap;
            //text.verticalOverflow = VerticalWrapMode.Truncate;
            text.alignment = TextAnchor.UpperLeft;
        }
        if (outline)
        {
            outline.enabled = false;
        }
    }

    public static void InitTextInput(InputField input, float x, float y, float pivotX, float pivotY, float w, float h, int fontSize, Transform parent = null)
    {
        RectTransform rect = input.transform as RectTransform;

        var text = input.textComponent as GUIText;
        text.inUse = true;
        text.fontSize = fontSize;
        var placeholder = input.placeholder as GUIText;
        placeholder.inUse = true;
        placeholder.fontSize = fontSize;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void ResetTextInput(GUIImage image, InputField input, Transform parent = null)
    {
        if (!image) return;
        var rect = image.rectTransform;
        ResetNode(rect, parent);

        image.sprite = null;
        image.raycastTarget = true;
        image.material = null;
        if (!input) return;
        input.onEndEdit.RemoveAllListeners();
        input.onValueChanged.RemoveAllListeners();
        input.text = string.Empty;
        input.characterLimit = 0;
        input.inputType = InputField.InputType.Standard;
        input.lineType = InputField.LineType.MultiLineNewline;
        input.keyboardType = TouchScreenKeyboardType.Default;
        input.characterValidation = InputField.CharacterValidation.None;

        var text = input.textComponent as GUIText;
        if (text)
        {
            text.inUse = false;
            text.text = string.Empty;
            text.color = Color.white;
            //text.fontSize = 24;
            text.alignment = TextAnchor.UpperLeft;
        }
        var phText = input.placeholder as GUIText;
        if (phText)
        {
            phText.inUse = false;
            phText.text = string.Empty;
            phText.color = defaultPHTextColor;
            phText.fontSize = 24;
            phText.alignment = TextAnchor.UpperLeft;
        }
    }

    public static void InitImage(GUIImage image, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        RectTransform rect = image.rectTransform;

        image.type = Image.Type.Simple;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void InitLoadingBar(GUIImage image, float x, float y, float pivotX, float pivotY, float w, float h, int dir, Transform parent = null)
    {
        RectTransform rect = image.rectTransform;

        image.type = Image.Type.Filled;
        image.fillMethod = Image.FillMethod.Horizontal;
        image.fillAmount = 0;
        image.fillOrigin = dir;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void InitProgressTimer(GUIImage image, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        RectTransform rect = image.rectTransform;

        image.type = Image.Type.Filled;
        image.fillMethod = Image.FillMethod.Radial360;
        image.fillAmount = 0;
        image.fillOrigin = 2;
        image.fillClockwise = true;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void ResetImage(GUIImage image, Transform parent = null)
    {
        if (!image) return;
        var rect = image.rectTransform;
        ResetNode(rect, parent);
        image.type = Image.Type.Simple;
        image.color = Color.white;
        image.drawColor = false;
        image.sprite = null;
        image.material = null;
        image.SetScale9Slice(0, 0, 0, 0);
        image.raycastTarget = true;
    }

    public static void InitButton(GUIButton button, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        RectTransform rect = button.transform as RectTransform;

        var image = button.ButtonImage;


        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void ResetButton(GUIButton button, Graphic graphic, Outline outline, ContentSizeFitter csf, Transform parent = null)
    {
        if (!button) return;
        var rect = button.transform as RectTransform;
        ResetNode(rect, parent);
        graphic.raycastTarget = true;
        var image = button.ButtonImage;
        image.color = Color.white;
        image.drawColor = false;
        image.sprite = null;
        image.material = null;
        image.SetScale9Slice(0, 0, 0, 0);
        //image.raycastTarget = true;
        //text.alignment = TextAnchor.UpperCenter;
        if (outline)
        {
            outline.enabled = false;
        }
        if (csf)
        {
            csf.enabled = false;
            //csf.horizontalFit = ContentSizeFitter.FitMode.PreferredSize;
            //csf.verticalFit = ContentSizeFitter.FitMode.PreferredSize;
        }
        button.Clear();
    }

    public static void InitTextAtlas(GUITextAtlas textAtlas, float x, float y, float pivotX, float pivotY, string firstChat, float itemWidth, float itemHeight, string str, Transform parent = null)
    {
        RectTransform rect = textAtlas.rectTransform;

        textAtlas.SetProperty(firstChat, itemWidth, itemHeight, str);
        textAtlas.SetNativeSize();

        InitNode(rect, x, y, pivotX, pivotY, parent);
    }

    public static void ResetTextAtlas(GUITextAtlas textAtlas, Transform parent = null)
    {
        if (!textAtlas) return;
        var rect = textAtlas.rectTransform;
        ResetNode(rect, parent);
        textAtlas.Clear();
        textAtlas.raycastTarget = true;
    }

    public static void InitCheckBox(Toggle toggle, float x, float y, float pivotX, float pivotY, float w, float h, float checkW, float checkH, Transform parent = null)
    {
        RectTransform rect = toggle.transform as RectTransform;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void ResetCheckBox(Toggle toggle, Transform parent = null)
    {
        if (!toggle) return;
        var rect = toggle.transform as RectTransform;
        ResetNode(rect, parent);
        toggle.onValueChanged.RemoveAllListeners();
        toggle.SetIsOnWithoutNotify(false);
        toggle.group = null;

        var box = toggle.targetGraphic as GUIImage;
        box.color = Color.white;
        box.sprite = null;
        box.material = null;
        box.SetScale9Slice(0, 0, 0, 0);
        box.raycastTarget = true;

        var check = toggle.graphic as GUIImage;
        check.color = Color.white;
        check.sprite = null;
        check.material = null;
    }

    public static void InitSlider(Slider slider, float x, float y, float pivotX, float pivotY, float w, float h, float handlerW, float handlerH, Transform parent = null)
    {
        RectTransform rect = slider.transform as RectTransform;

        slider.minValue = 0;
        slider.maxValue = 100;
        slider.value = 0;

        var handler = slider.handleRect;
        slider.handleRect = null;
        slider.handleRect = handler;

        var top = (h - handlerH) * 0.5f;
        handler.offsetMin = new Vector2(0, top);
        handler.offsetMax = new Vector2(0, -top);

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void ResetSlider(Slider slider, GUIImage image, GUIImage fill, GUIImage handle, Transform parent = null)
    {
        if (!slider) return;
        var rect = slider.transform as RectTransform;
        ResetNode(rect, parent);
        slider.onValueChanged.RemoveAllListeners();
        slider.wholeNumbers = true;
        //slider.minValue = 0;
        //slider.maxValue = 100;
        //slider.value = 0;
        if (image)
        {
            image.raycastTarget = true;
        }
        if (fill)
        {
            fill.color = Color.white;
            //fill.drawColor = false;
            fill.sprite = null;
            fill.SetScale9Slice(0, 0, 0, 0);
            fill.material = null;
            //fill.raycastTarget = false;
        }
        if (handle)
        {
            handle.color = Color.white;
            //handle.drawColor = false;
            handle.sprite = null;
            handle.material = null;
            //handle.SetScale9Slice(0, 0, 0, 0);
            //handle.raycastTarget = false;
        }
    }

    public static void InitListView(ScrollRect scroll, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        RectTransform rect = scroll.transform as RectTransform;

        InitLayout(rect, x, y, pivotX, pivotY, w, h - 0.15f, parent);
    }

    public static void InitScrollView(ScrollRect scroll, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        RectTransform rect = scroll.transform as RectTransform;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void InitTableView(ScrollRect scroll, float x, float y, float pivotX, float pivotY, float w, float h, Transform parent = null)
    {
        RectTransform rect = scroll.transform as RectTransform;

        scroll.movementType = ScrollRect.MovementType.Elastic;

        InitLayout(rect, x, y, pivotX, pivotY, w, h, parent);
    }

    public static void ResetScroll(GUIImage image, ScrollRect scroll, RectMask2D mask, LayoutGroup group, ContentSizeFitter csf, Transform parent = null)
    {
        if (!scroll) return;
        ResetLayout(image, parent);
        scroll.onValueChanged.RemoveAllListeners();
        scroll.movementType = ScrollRect.MovementType.Clamped;
        scroll.StopMovement();

        var contentRect = scroll.content;
        contentRect.SetAnchoredPosition(0, 0);

        if (mask)
        {
            mask.enabled = true;
            mask.padding = Vector4.zero;
            mask.softness = Vector2Int.zero;
        }
        if (group)
        {
            group.childAlignment = TextAnchor.UpperLeft;
            var pad = group.padding;
            pad.left = 0;
            pad.right = 0;
            pad.top = 0;
            pad.bottom = 0;
            if (group is GridLayoutGroup)
            {
                (group as GridLayoutGroup).spacing = Vector2.zero;

            }
            else if (group is HorizontalOrVerticalLayoutGroup)
            {
                (group as HorizontalOrVerticalLayoutGroup).spacing = 0;
            }
        }
        if (csf)
        {
            csf.horizontalFit = ContentSizeFitter.FitMode.Unconstrained;
            csf.verticalFit = ContentSizeFitter.FitMode.Unconstrained;
        }
    }


    public static void ResetCanvasGroup(CanvasGroup canvasGroup)
    {
        if (!canvasGroup) return;
        canvasGroup.alpha = 1;
        canvasGroup.interactable = true;
        canvasGroup.blocksRaycasts = true;
    }

    public static void SyncNode(RectTransform rect, RectTransform tempRect)
    {
        var go = rect.gameObject;
        var tempGO = tempRect.gameObject;
        go.name = tempGO.name;
        go.SetActive(tempGO.activeSelf);
    }

    public static void SyncNode(Graphic graphic, Graphic tempGraphic)
    {
        graphic.color = tempGraphic.color;
        graphic.raycastTarget = tempGraphic.raycastTarget;
        SyncNode(graphic.rectTransform, tempGraphic.rectTransform);
    }

    public static void SyncImage(GUIImage image, GUIImage tempImg)
    {
        SyncNode(image.rectTransform, tempImg.rectTransform);
        tempImg.GetScale9Slice(out float l, out float r, out float t, out float b);
        image.SetScale9Slice(l, r, t, b);
        image.fillCenter = tempImg.fillCenter;
        image.drawColor = tempImg.drawColor;
        image.color = tempImg.color;
        image.sprite = tempImg.sprite;
        if (tempImg.type == Image.Type.Filled)
        {
            image.type = Image.Type.Filled;
            image.fillMethod = tempImg.fillMethod;
            image.fillOrigin = tempImg.fillOrigin;
            image.fillAmount = tempImg.fillAmount;
            image.fillClockwise = tempImg.fillClockwise;
        }
    }

    public static void SyncText(GUIText text, GUIText tempText, Outline outline = null, Outline tempOutline = null, ContentSizeFitter csf = null, ContentSizeFitter tempCsf = null)
    {
        if (csf && tempCsf)
        {
            csf.enabled = tempCsf.enabled;
            csf.verticalFit = tempCsf.verticalFit;
            csf.horizontalFit = tempCsf.horizontalFit;
        }
        SyncNode(text.rectTransform, tempText.rectTransform);
        text.text = tempText.text;
        text.color = tempText.color;
        text.fontStyle = tempText.fontStyle;
        text.fontSize = tempText.fontSize;
        text.alignment = tempText.alignment;
        text.lineSpacing = tempText.lineSpacing;
        text.verticalOverflow = tempText.verticalOverflow;
        text.horizontalOverflow = tempText.horizontalOverflow;
        text.underLine = tempText.underLine;
        text.underLineColor = tempText.underLineColor;
        text.inUse = tempText.inUse;

        if (outline && tempOutline){
            outline.enabled = tempOutline.enabled;
            outline.effectColor = tempOutline.effectColor;
            outline.effectDistance = tempOutline.effectDistance;
        }
    }

    public static void SyncButton(GUIButton button, GUIButton tempBtn)
    {
        SyncNode((RectTransform)button.transform, (RectTransform)tempBtn.transform);
        //Image
        tempBtn.ButtonImage.GetScale9Slice(out float l, out float r, out float t, out float b);
        button.ButtonImage.SetScale9Slice(l, r, t, b);
        //Text

        button.scale = tempBtn.scale;
        button.disable = tempBtn.disable;
        button.SetBrightStyle((int)tempBtn.GetState());
    }





    public static void SetAnchoredPosition(this RectTransform rect,float x, float y)
    {
        rect.anchoredPosition = new Vector2(x,y);
    }
}

