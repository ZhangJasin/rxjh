using UnityEngine;
using UnityEngine.EventSystems;

[AddComponentMenu("UI/GUISliderHandle")]
public class GUISliderHandle : GUIImage, IDragHandler, IInitializePotentialDragHandler
{
    public GameObject slider;

    protected override void Awake()
    {
        base.Awake();
        if (!slider)
        {
            slider = this.transform.parent.gameObject;
        }
    }

    public void OnDrag(PointerEventData eventData)
    {
        if (!slider) return;
        ExecuteEvents.Execute(slider, eventData, ExecuteEvents.dragHandler);
    }

    public void OnInitializePotentialDrag(PointerEventData eventData)
    {
        if (!slider) return;
        ExecuteEvents.Execute(slider, eventData, ExecuteEvents.initializePotentialDrag);
    }
}
