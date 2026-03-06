using System;
using UnityEngine;
using UnityEngine.Pool;
using UnityEngine.UI;

[AddComponentMenu("UI/GUIHorizontalLayoutGroup")]
public class GUIHorizontalLayoutGroup : HorizontalLayoutGroup
{
    public Action onEnable;

    protected override void OnEnable()
    {
        base.OnEnable();
        onEnable?.Invoke();
    }

    public override void CalculateLayoutInputHorizontal()
    {
        var rectChildren = this.rectChildren;
        rectChildren.Clear();
        var toIgnoreList = ListPool<Component>.Get();
        for (int i = 0; i < rectTransform.childCount; i++)
        {
            var rect = rectTransform.GetChild(i) as RectTransform;
            if (rect == null)
                continue;

            rect.GetComponents(typeof(ILayoutIgnorer), toIgnoreList);

            if (toIgnoreList.Count == 0)
            {
                rectChildren.Add(rect);
                continue;
            }

            for (int j = 0; j < toIgnoreList.Count; j++)
            {
                var ignorer = (ILayoutIgnorer)toIgnoreList[j];
                if (!ignorer.ignoreLayout)
                {
                    rectChildren.Add(rect);
                    break;
                }
            }
        }
        ListPool<Component>.Release(toIgnoreList);
        m_Tracker.Clear();

        CalcAlongAxis(0, false);
    }
}