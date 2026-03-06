using UnityEngine.Events;

public class ListenerRectChange : UnityEngine.EventSystems.UIBehaviour
{
    public UnityAction onSizeChange;
    protected override void OnRectTransformDimensionsChange()
    {
        base.OnRectTransformDimensionsChange();
        onSizeChange?.Invoke();
    }
}
