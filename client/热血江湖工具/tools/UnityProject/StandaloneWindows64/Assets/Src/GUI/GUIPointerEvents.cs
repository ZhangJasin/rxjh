using System;
using UnityEngine;
using UnityEngine.EventSystems;

[AddComponentMenu("UI/GUIPointerEvents")]
public class GUIPointerEvents : UIBehaviour
{
    public bool enableDrag = false;
    public bool enableScroll = false;

    public bool touchDown = false;
    public bool dragBegin = false;


    public bool swallowTouch = true;    //吞噬触摸
    public Action<PointerEventData> onPointerDown;
    public Action<PointerEventData> onPointerUp;
    public Action<PointerEventData> onPointerClick;
    public Action<PointerEventData> onPointerCancel;
    public Action<PointerEventData> onPointerEnter;
    public Action<PointerEventData> onPointerExit;
    public Action<PointerEventData> onPointerMove;

    public Action<PointerEventData> onDrag;

    public Action<PointerEventData, GUIEventData> onMouseDown;
    public Action<PointerEventData, GUIEventData> onMouseUp;


    public void Init()
    {
        swallowTouch = true;
    }

    public void Clear()
    {
        enabled = true;

        touchDown = false;
        //swallowTouch = true;

        onPointerClick = null;
        onPointerDown = null;
        onPointerEnter = null;
        onPointerExit = null;
        onPointerUp = null;
        onMouseUp = null;
    }

    protected override void OnDestroy()
    {
        base.OnDestroy();
        onPointerDown = null;
        onPointerUp = null;
        onPointerClick = null;
        onPointerCancel = null;
        onPointerEnter = null;
        onPointerExit = null;
    }

}