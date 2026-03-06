using UnityEngine.EventSystems;
using System.Collections.Generic;
using static UnityEngine.EventSystems.ExecuteEvents;
using UnityEngine;
using UnityEngine.Pool;

public static class GUIEvents
{

    private static readonly GUIEventData m_EventData = new();

    private static readonly Dictionary<int, bool> m_OverResultDict = new();

    private static readonly Dictionary<int, bool> m_RaycastResultDict = new();

    private static readonly Dictionary<int, List<GUIPointerEvents>> m_TouchDownDict = new();
    private static readonly Dictionary<int, List<GUIPointerEvents>> m_DragBeginDict = new();

    private static readonly Dictionary<int, List<GUIPointerEvents>> m_LastEnterDict = new();
    private static readonly Dictionary<int, Dictionary<int, bool>> m_LastEnterIdDict = new();



    public static GameObject CurrentSelect { get; private set; }

    public static void Init()
    {
        m_OverResultDict.Clear();
    }

    public static void Clear()
    {
        m_OverResultDict.Clear();
        m_RaycastResultDict.Clear();
        m_TouchDownDict.Clear();
        m_DragBeginDict.Clear();
        m_LastEnterDict.Clear();
        m_LastEnterIdDict.Clear();
    }

    /// <summary>
    /// 点击是否被UI拦截
    /// </summary>
    public static bool IsPointerOverUI(int pointerId)
    {
        if (m_OverResultDict.TryGetValue(pointerId, out var isOver)) return isOver;
        return false;
    }


    public static void OnPointerDown(PointerEventData eventData, List<GUIPointerEvents> raycastResults, out GameObject pressGo)
    {
        pressGo = null;
        //var currentOverGo = eventData.pointerCurrentRaycast.gameObject;
        var pointerId = eventData.pointerId;
        var succ = m_TouchDownDict.TryGetValue(pointerId, out var touchDownList);
        if (!succ || touchDownList == null)
        {
            touchDownList = ListPool<GUIPointerEvents>.Get();
            m_TouchDownDict[pointerId] = touchDownList;
        }
        touchDownList.Clear();

        var count = raycastResults.Count;
        if (count <= 0) return;
        var isBreak = false;
        for (var i = 0; i < count; i++)
        {
            var pointer = raycastResults[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;

            var go = pointer.gameObject;
            if (!go) continue;

            if (!pressGo) pressGo = go;
            if (!isBreak)
            {
                pointer.touchDown = true;
                Execute(go, eventData, pointerDownHandler);
                pointer.onPointerDown?.Invoke(eventData);
                touchDownList.Add(pointer);
            }
            else if (pointer.enableScroll)
            {
                //记录scroll用于drag
                touchDownList.Add(pointer);
            }

            if (pointer.swallowTouch) isBreak = true;
        }
        // MouseDown, ScrollRect stop
        var gEventData = m_EventData;
        gEventData.Init();
        for (var i = 0; i < count; i++)
        {
            var pointer = raycastResults[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;

            var go = pointer.gameObject;
            if (!go) continue;

            pointer.onMouseDown?.Invoke(eventData, gEventData);
            if (pointer.enableDrag)
            {
                Execute(go, eventData, initializePotentialDrag);
            }
            if (gEventData.Stop) break;
        }
    }

    public static void OnPointerUp(PointerEventData eventData, List<GUIPointerEvents> raycastResults)
    {
        var pointerId = eventData.pointerId;
        var rstCount = raycastResults.Count;

        var succ = m_TouchDownDict.TryGetValue(pointerId, out var touchDownList);
        if (succ && touchDownList != null)
        {
            var raycastResultDict = m_RaycastResultDict;
            var count = touchDownList.Count;
            if (count > 0)
            {
                for (var i = 0; i < rstCount; i++)
                {
                    var pointer = raycastResults[i];
                    if (!pointer) continue;
                    if (pointer.IsDestroyed()) continue;
                    raycastResultDict[pointer.GetInstanceID()] = true;
                }
            }
            for (var i = 0; i < count; i++)
            {
                var pointer = touchDownList[i];
                if (!pointer) continue;
                if (pointer.IsDestroyed()) continue;
                if (!pointer.touchDown) continue;
                if (!pointer.enabled) continue;
                var go = pointer.gameObject;
                if (!go) continue;

                Execute(go, eventData, pointerUpHandler);
                if (eventData.eligibleForClick && raycastResultDict.ContainsKey(pointer.GetInstanceID()))
                {
                    //滚动容器中拖拽情况不触发
                    //在点击区域节点,触发up,click
                    pointer.onPointerUp?.Invoke(eventData);

                    Execute(go, eventData, pointerClickHandler);
                    pointer.onPointerClick?.Invoke(eventData);
                    //Execute(go, eventData, selectHandler);
                }
                else
                {
                    pointer.onPointerCancel?.Invoke(eventData);
                }
                pointer.touchDown = false;
                if (pointer.swallowTouch) break;//吞噬,终止后续节点响应
            }
            m_TouchDownDict.Remove(pointerId);
            ListPool<GUIPointerEvents>.Release(touchDownList);
            raycastResultDict.Clear();
        }
        // MouseUp
        var gEventData = m_EventData;
        gEventData.Init();
        for (var i = 0; i < rstCount; i++)
        {
            var pointer = raycastResults[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;

            pointer.onMouseUp?.Invoke(eventData, gEventData);

            if (gEventData.Stop) break;
        }
    }

    

    public static void OnBeginDrag(PointerEventData eventData, List<GUIPointerEvents> raycastResults)
    {
        var pointerId = eventData.pointerId;

        var succ = m_DragBeginDict.TryGetValue(pointerId, out var dragList);
        if (!succ || dragList == null)
        {
            dragList = ListPool<GUIPointerEvents>.Get();
            m_DragBeginDict[pointerId] = dragList;
        }

        succ = m_TouchDownDict.TryGetValue(pointerId, out var touchDownList);
        if (!succ || touchDownList == null) return;
        var list = touchDownList;

        var count = list.Count;
        if (count <= 0) return;

        var isBreak = false;
        GUIPointerEvents trigPointer = null;
        for (var i = 0; i < count; i++)
        {
            var pointer = list[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;

            var go = pointer.gameObject;
            if (!go) continue;

            if (isBreak)
            {
                if (pointer.enableScroll)
                {
                    if (trigPointer && trigPointer.transform.IsChildOf(pointer.transform))
                    {
                        //响应父级scroll
                        if (pointer.enableDrag || pointer.onDrag != null)
                        {
                            pointer.dragBegin = true;
                            dragList.Add(pointer);
                            Execute(go, eventData, beginDragHandler);
                        }
                        break;
                    }
                }
            }
            else
            {
                if (!pointer.touchDown) continue;
                trigPointer = pointer;
                if (pointer.enableDrag || pointer.onDrag != null)
                {
                    pointer.dragBegin = true;
                    dragList.Add(pointer);
                    Execute(go, eventData, beginDragHandler);
                }
            }

            if (pointer.swallowTouch) isBreak = true;
        }
    }

    public static void OnEndDrag(PointerEventData eventData)
    {
        var pointerId = eventData.pointerId;

        var succ = m_DragBeginDict.TryGetValue(pointerId, out var dragList);
        if (succ && dragList != null)
        {
            var count = dragList.Count;
            if (count > 0)
            {
                for (var i = 0; i < count; i++)
                {
                    var pointer = dragList[i];
                    if (pointer.IsDestroyed()) continue;
                    if (!pointer.dragBegin) continue;
                    var go = pointer.gameObject;
                    if (!go) continue;

                    pointer.dragBegin = false;
                    Execute(go, eventData, endDragHandler);
                }
            }
            m_DragBeginDict.Remove(pointerId);
            ListPool<GUIPointerEvents>.Release(dragList);
        }
    }

    public static void OnDrag(PointerEventData eventData)
    {
        var pointerId = eventData.pointerId;

        var succ = m_DragBeginDict.TryGetValue(pointerId, out var dragList);
        if (succ && dragList != null)
        {
            var count = dragList.Count;
            for (var i = 0; i < count; i++)
            {
                var pointer = dragList[i];
                if (!pointer) continue;
                if (pointer.IsDestroyed()) continue;
                //if (!pointer.enabled) continue;
                if (!pointer.dragBegin) continue;
                var go = pointer.gameObject;
                if (!go) continue;

                //触发滚动容器后不响应点击
                if (pointer.enableScroll) eventData.eligibleForClick = false;
                Execute(go, eventData, dragHandler);
                pointer.onDrag?.Invoke(eventData);
            }
        }
    }

    public static void OnScroll(PointerEventData eventData, List<GUIPointerEvents> raycastResults)
    {
        var count = raycastResults.Count;
        if (count <= 0) return;
        //获取第一个点击到的scroll
        GUIPointerEvents scrollPointer = null;
        for (var i = 0; i < count; i++)
        {
            var pointer = raycastResults[i];
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;
            if (!pointer.enableScroll) continue;
            scrollPointer = pointer;
            break;
        }
        for (var i = 0; i < count; i++)
        {
            var pointer = raycastResults[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;

            var go = pointer.gameObject;
            if (!go) continue;

            if (pointer.enableScroll)
            {
                Execute(go, eventData, scrollHandler);
            }
            if (pointer.swallowTouch)
            {
                if (scrollPointer && pointer.transform.IsChildOf(scrollPointer.transform))
                {
                    if (scrollPointer.gameObject)
                    {
                        Execute(scrollPointer.gameObject, eventData, scrollHandler);
                    }
                }
                break;
            }
        }
    }

    public static void OnPointerStay(PointerEventData eventData, List<GUIPointerEvents> raycastResults)
    {
        var pointerId = eventData.pointerId;
        for (var i = 0; i < raycastResults.Count; i++)
        {
            var pointer = raycastResults[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;
            if (pointer.swallowTouch)
            {
                m_OverResultDict[pointerId] = true;
                return;
            }
        }
    }

    public static void OnPointerMove(PointerEventData eventData, List<GUIPointerEvents> raycastResults, bool isEnter = false)
    {
        var pointerId = eventData.pointerId;

        var succ1 = m_LastEnterDict.TryGetValue(pointerId, out var lastEnterList);
        if (!succ1 || lastEnterList == null)
        {
            lastEnterList = ListPool<GUIPointerEvents>.Get();
            m_LastEnterDict[pointerId] = lastEnterList;
        }
        var succ2 = m_LastEnterIdDict.TryGetValue(pointerId, out var lastEnterIdDict);
        if (!succ2 || lastEnterIdDict == null)
        {
            lastEnterIdDict = DictionaryPool<int, bool>.Get();
            m_LastEnterIdDict[pointerId] = lastEnterIdDict;
        }
        var currEnterList = ListPool<GUIPointerEvents>.Get();
        var currEnterIdDict = DictionaryPool<int, bool>.Get();
        var isOver = false;
        for (var i = 0; i < raycastResults.Count; i++)
        {
            var pointer = raycastResults[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;
            currEnterList.Add(pointer);
            currEnterIdDict[pointer.GetInstanceID()] = true;
            if (pointer.swallowTouch)
            {
                isOver = true;
                break;
            }
        }
        m_OverResultDict[pointerId] = isOver;
        //Exit
        var lastCount = lastEnterList.Count;
        for (var i = 0; i < lastCount; i++)
        {
            var pointer = lastEnterList[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;
            if (!currEnterIdDict.ContainsKey(pointer.GetInstanceID()))
            {
                pointer.onPointerExit?.Invoke(eventData);
                Execute(pointer.gameObject, eventData, pointerExitHandler);
            }
        }
        //Enter, Move
        var currCount = currEnterList.Count;
        for (var i = 0; i < currCount; i++)
        {
            var pointer = currEnterList[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;
            if (!lastEnterIdDict.ContainsKey(pointer.GetInstanceID()))
            {
                pointer.onPointerEnter?.Invoke(eventData);
                Execute(pointer.gameObject, eventData, pointerEnterHandler);
            }
            else //if(!isEnter)
            {
                pointer.onPointerMove?.Invoke(eventData);
            }
        }
        ListPool<GUIPointerEvents>.Release(lastEnterList);
        DictionaryPool<int, bool>.Release(lastEnterIdDict);
        m_LastEnterDict[pointerId] = currEnterList;
        m_LastEnterIdDict[pointerId] = currEnterIdDict;
    }

    public static void OnPointerEnter(PointerEventData eventData, List<GUIPointerEvents> raycastResults)
    {
        OnPointerMove(eventData, raycastResults, true);
    }

    public static void OnPointerExit(PointerEventData eventData)
    {
        var pointerId = eventData.pointerId;

        var succ1 = m_LastEnterDict.TryGetValue(pointerId, out var lastEnterList);
        if (!succ1 || lastEnterList == null) return;
        m_LastEnterIdDict.TryGetValue(pointerId, out var lastEnterIdDict);

        var lastCount = lastEnterList.Count;
        for (var i = 0; i < lastCount; i++)
        {
            var pointer = lastEnterList[i];
            if (!pointer) continue;
            if (pointer.IsDestroyed()) continue;
            if (!pointer.enabled) continue;

            pointer.onPointerExit?.Invoke(eventData);
        }
        ListPool<GUIPointerEvents>.Release(lastEnterList);
        if (lastEnterIdDict != null)
        {
            DictionaryPool<int, bool>.Release(lastEnterIdDict);
        }
        m_LastEnterDict[pointerId] = null;
        m_LastEnterIdDict[pointerId] = null;
    }


}

public class GUIEventData
{
    public bool Stop { get; private set; }

    public void Init()
    {
        Stop = false;
    }
    public void StopPropagation()
    {
        Stop = true;
    }
}

