using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;

[AddComponentMenu("UI/GUIPageView")]
public class GUIPageView : ScrollRect
{
    //private GridLayoutGroup gridLayoutGroup;
    public override void OnBeginDrag(PointerEventData eventData)
    {
        base.OnBeginDrag(eventData);
    }

    public override void OnDrag(PointerEventData eventData)
    {
        base.OnDrag(eventData);
    }

    public override void OnEndDrag(PointerEventData eventData)
    {
        base.OnEndDrag(eventData);
        this.StopMovement();
        //Îü¸½¾ÓÖÐ
        var childCount = this.content.childCount;
        if (childCount <= 0) return;
        var curX = this.content.anchoredPosition.x;
        var width = this.content.sizeDelta.x;
        var aveWidth = width / childCount;
        var idx = -Mathf.Round(curX / aveWidth);

        var targetX = -idx * aveWidth;
        var time = Mathf.Abs(targetX - curX) / aveWidth;
    }
}
