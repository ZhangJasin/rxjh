using UnityEngine;
using UnityEngine.EventSystems;

[AddComponentMenu("UI/GUICanvasListener")]
public class GUICanvasListener : UIBehaviour
{

    protected override void OnEnable()
    {
        var canvas = this.GetComponent<Canvas>();
        if (canvas)
        {
            canvas.overrideSorting = true;
            //if (!canvas.overrideSorting) 
            //    return;//异常,还是未能勾上
        }
        DestroyImmediate(this);
    }

}