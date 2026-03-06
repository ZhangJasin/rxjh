using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

public class GUIInputModule : PointerInputModule
{

    //private GameObject m_CurrentFocusedGameObject;

    private PointerEventData m_InputPointerEvent;

    private List<GUIPointerEvents> m_PointerResultList = new();

    private readonly MouseState m_MouseState = new MouseState();

    protected override void OnDisable()
    {
        base.OnDisable();
        GUIEvents.Clear();
    }

    public override bool IsPointerOverGameObject(int pointerId)
    {
        return GUIEvents.IsPointerOverUI(pointerId);
    }

    public override void UpdateModule()
    {
        if (!eventSystem.isFocused && ShouldIgnoreEventsOnNoFocus())
        {
            if (m_InputPointerEvent != null && m_InputPointerEvent.pointerDrag != null && m_InputPointerEvent.dragging)
            {
                ReleaseMouse(m_InputPointerEvent, m_InputPointerEvent.pointerCurrentRaycast.gameObject);
            }

            m_InputPointerEvent = null;

            return;
        }
    }

    private bool ShouldIgnoreEventsOnNoFocus()
    {
#if UNITY_EDITOR
        return !UnityEditor.EditorApplication.isRemoteConnected;
#else
            return true;
#endif
    }

    private void ReleaseMouse(PointerEventData pointerEvent, GameObject currentOverGo)
    {
        GUIEvents.OnPointerUp(pointerEvent, m_PointerResultList);

        if (pointerEvent.pointerDrag != null && pointerEvent.dragging)
        {
            ExecuteEvents.ExecuteHierarchy(currentOverGo, pointerEvent, ExecuteEvents.dropHandler);
        }

        pointerEvent.eligibleForClick = false;
        pointerEvent.pointerPress = null;
        pointerEvent.rawPointerPress = null;
        pointerEvent.pointerClick = null;

        if (pointerEvent.pointerDrag != null && pointerEvent.dragging)
        {
            GUIEvents.OnEndDrag(pointerEvent);
        }

        pointerEvent.dragging = false;
        pointerEvent.pointerDrag = null;

        m_InputPointerEvent = pointerEvent;
    }


    /// <summary>
    /// See BaseInputModule.
    /// </summary>
    public override void ActivateModule()
    {
        if (!eventSystem.isFocused && ShouldIgnoreEventsOnNoFocus())
            return;

        base.ActivateModule();

        var toSelect = eventSystem.currentSelectedGameObject;
        if (toSelect == null)
            toSelect = eventSystem.firstSelectedGameObject;

        eventSystem.SetSelectedGameObject(toSelect, GetBaseEventData());
    }

    /// <summary>
    /// See BaseInputModule.
    /// </summary>
    public override void DeactivateModule()
    {
        base.DeactivateModule();
        ClearSelection();
    }

    public override void Process()
    {
        GUIEvents.Init();

        if (!eventSystem.isFocused && ShouldIgnoreEventsOnNoFocus())
            return;

        SendUpdateEventToSelectedObject();

        // case 1004066 - touch / mouse events should be processed before navigation events in case
        // they change the current selected gameobject and the submit button is a touch / mouse button.

        // touch needs to take precedence because of the mouse emulation layer
        if (!ProcessTouchEvents() && input.mousePresent)
            ProcessMouseEvent(0);
    }

    private bool ProcessTouchEvents()
    {
        for (int i = 0; i < input.touchCount; ++i)
        {
            Touch touch = input.GetTouch(i);

            if (touch.type == TouchType.Indirect)
                continue;
            bool released;
            bool pressed;
            var pointer = GetTouchPointerEventData(touch, out pressed, out released);

            ProcessTouchPress(pointer, pressed, released);

            ProcessMove(pointer);
            if (!released)
            {
                ProcessDrag(pointer);
            }
            else
                RemovePointerData(pointer);
            m_PointerResultList.Clear();
        }
        return input.touchCount > 0;
    }

    protected void ProcessTouchPress(PointerEventData pointerEvent, bool pressed, bool released)
    {
        var currentOverGo = pointerEvent.pointerCurrentRaycast.gameObject;

        // PointerDown notification
        if (pressed)
        {
            pointerEvent.eligibleForClick = true;
            pointerEvent.delta = Vector2.zero;
            pointerEvent.dragging = false;
            pointerEvent.useDragThreshold = true;
            pointerEvent.pressPosition = pointerEvent.position;
            pointerEvent.pointerPressRaycast = pointerEvent.pointerCurrentRaycast;

            DeselectIfSelectionChanged(currentOverGo, pointerEvent);

            GUIEvents.OnPointerEnter(pointerEvent, m_PointerResultList);
            GUIEvents.OnPointerDown(pointerEvent, m_PointerResultList, out var newPressed);

            float time = Time.unscaledTime;

            if (newPressed == pointerEvent.lastPress)
            {
                var diffTime = time - pointerEvent.clickTime;
                if (diffTime < 0.3f)
                    ++pointerEvent.clickCount;
                else
                    pointerEvent.clickCount = 1;

                pointerEvent.clickTime = time;
            }
            else
            {
                pointerEvent.clickCount = 1;
            }

            pointerEvent.pointerPress = newPressed;
            pointerEvent.rawPointerPress = currentOverGo;
            //pointerEvent.pointerClick = newClick;

            pointerEvent.clickTime = time;

            // Save the drag handler as well
            pointerEvent.pointerDrag = currentOverGo;

            if (pointerEvent.pointerDrag != null)
                ExecuteEvents.Execute(pointerEvent.pointerDrag, pointerEvent, ExecuteEvents.initializePotentialDrag);
        }

        // PointerUp notification
        if (released)
        {
            GUIEvents.OnPointerUp(pointerEvent, m_PointerResultList);

            if (pointerEvent.pointerDrag != null && pointerEvent.dragging)
            {
                ExecuteEvents.ExecuteHierarchy(currentOverGo, pointerEvent, ExecuteEvents.dropHandler);
            }

            pointerEvent.eligibleForClick = false;
            pointerEvent.pointerPress = null;
            pointerEvent.rawPointerPress = null;
            pointerEvent.pointerClick = null;

            if (pointerEvent.pointerDrag != null && pointerEvent.dragging)
                GUIEvents.OnEndDrag(pointerEvent);

            pointerEvent.dragging = false;
            pointerEvent.pointerDrag = null;

            // send exit events as we need to simulate this on touch up on touch device
            GUIEvents.OnPointerExit(pointerEvent);
            pointerEvent.pointerEnter = null;
        }

        m_InputPointerEvent = pointerEvent;
    }


    protected override void ProcessMove(PointerEventData pointerEvent)
    {
        if (pointerEvent.IsPointerMoving())
        {
            GUIEvents.OnPointerMove(pointerEvent, m_PointerResultList);
        }
        else
        {
            GUIEvents.OnPointerStay(pointerEvent, m_PointerResultList);
        }
    }


    /// <summary>
    /// Process all mouse events.
    /// </summary>
    protected void ProcessMouseEvent(int id)
    {
        var mouseData = GetMousePointerEventData(id);
        var leftButtonData = mouseData.GetButtonState(PointerEventData.InputButton.Left).eventData;

        //m_CurrentFocusedGameObject = leftButtonData.buttonData.pointerCurrentRaycast.gameObject;

        // Process the first mouse button fully
        ProcessMousePress(leftButtonData);
        ProcessMove(leftButtonData.buttonData);
        ProcessDrag(leftButtonData.buttonData);

        // Now process right / middle clicks
        ProcessMousePress(mouseData.GetButtonState(PointerEventData.InputButton.Right).eventData);
        ProcessDrag(mouseData.GetButtonState(PointerEventData.InputButton.Right).eventData.buttonData);
        ProcessMousePress(mouseData.GetButtonState(PointerEventData.InputButton.Middle).eventData);
        ProcessDrag(mouseData.GetButtonState(PointerEventData.InputButton.Middle).eventData.buttonData);

        if (!Mathf.Approximately(leftButtonData.buttonData.scrollDelta.sqrMagnitude, 0.0f))
        {
            GUIEvents.OnScroll(leftButtonData.buttonData, m_PointerResultList);
        }
        m_PointerResultList.Clear();
    }

    protected bool SendUpdateEventToSelectedObject()
    {
        if (eventSystem.currentSelectedGameObject == null)
            return false;

        var data = GetBaseEventData();
        ExecuteEvents.Execute(eventSystem.currentSelectedGameObject, data, ExecuteEvents.updateSelectedHandler);
        return data.used;
    }

    /// <summary>
    /// Calculate and process any mouse button state changes.
    /// </summary>
    protected void ProcessMousePress(MouseButtonEventData data)
    {
        var pointerEvent = data.buttonData;
        var currentOverGo = pointerEvent.pointerCurrentRaycast.gameObject;

        // PointerDown notification
        if (data.PressedThisFrame())
        {
            pointerEvent.eligibleForClick = true;
            pointerEvent.delta = Vector2.zero;
            pointerEvent.dragging = false;
            pointerEvent.useDragThreshold = true;
            pointerEvent.pressPosition = pointerEvent.position;
            pointerEvent.pointerPressRaycast = pointerEvent.pointerCurrentRaycast;

            DeselectIfSelectionChanged(currentOverGo, pointerEvent);

            GUIEvents.OnPointerEnter(pointerEvent, m_PointerResultList);
            GUIEvents.OnPointerDown(pointerEvent, m_PointerResultList, out var newPressed);

            float time = Time.unscaledTime;

            if (newPressed == pointerEvent.lastPress)
            {
                var diffTime = time - pointerEvent.clickTime;
                if (diffTime < 0.3f)
                    ++pointerEvent.clickCount;
                else
                    pointerEvent.clickCount = 1;

                pointerEvent.clickTime = time;
            }
            else
            {
                pointerEvent.clickCount = 1;
            }

            pointerEvent.pointerPress = newPressed;
            pointerEvent.rawPointerPress = currentOverGo;

            pointerEvent.clickTime = time;

            pointerEvent.pointerDrag = currentOverGo;

            if (pointerEvent.pointerDrag != null)
                ExecuteEvents.Execute(pointerEvent.pointerDrag, pointerEvent, ExecuteEvents.initializePotentialDrag);

            m_InputPointerEvent = pointerEvent;
        }


        // PointerUp notification
        if (data.ReleasedThisFrame())
        {
            ReleaseMouse(pointerEvent, currentOverGo);
        }
    }

    //protected GameObject GetCurrentFocusedGameObject()
    //{
    //    return m_CurrentFocusedGameObject;
    //}


    private static bool ShouldStartDrag(Vector2 pressPos, Vector2 currentPos, float threshold, bool useDragThreshold)
    {
        if (!useDragThreshold)
            return true;

        return (pressPos - currentPos).sqrMagnitude >= threshold * threshold;
    }

    protected override void ProcessDrag(PointerEventData pointerEvent)
    {
        if (!pointerEvent.IsPointerMoving() ||
            Cursor.lockState == CursorLockMode.Locked ||
            pointerEvent.pointerDrag == null)
            return;

        if (!pointerEvent.dragging
            && ShouldStartDrag(pointerEvent.pressPosition, pointerEvent.position, eventSystem.pixelDragThreshold, pointerEvent.useDragThreshold))
        {
            pointerEvent.dragging = true;
            GUIEvents.OnBeginDrag(pointerEvent, m_PointerResultList);
        }

        // Drag notification
        if (pointerEvent.dragging)
        {
            GUIEvents.OnDrag(pointerEvent);
        }
    }

    /// <summary>
    /// Given a touch populate the PointerEventData and return if we are pressed or released.
    /// </summary>
    /// <param name="input">Touch being processed</param>
    /// <param name="pressed">Are we pressed this frame</param>
    /// <param name="released">Are we released this frame</param>
    /// <returns></returns>
    protected new PointerEventData GetTouchPointerEventData(Touch input, out bool pressed, out bool released)
    {
        PointerEventData pointerData;
        var created = GetPointerData(input.fingerId, out pointerData, true);

        pointerData.Reset();

        pressed = created || (input.phase == TouchPhase.Began);
        released = (input.phase == TouchPhase.Canceled) || (input.phase == TouchPhase.Ended);

        if (created)
            pointerData.position = input.position;

        if (pressed)
            pointerData.delta = Vector2.zero;
        else
            pointerData.delta = input.position - pointerData.position;

        pointerData.position = input.position;

        pointerData.button = PointerEventData.InputButton.Left;

        if (input.phase == TouchPhase.Canceled)
        {
            pointerData.pointerCurrentRaycast = new RaycastResult();
        }
        else
        {
            eventSystem.RaycastAll(pointerData, m_RaycastResultCache);
            FindPointerResults(m_RaycastResultCache);

            var raycast = FindFirstRaycast(m_RaycastResultCache);
            pointerData.pointerCurrentRaycast = raycast;
            m_RaycastResultCache.Clear();
        }

        pointerData.pressure = input.pressure;
        pointerData.altitudeAngle = input.altitudeAngle;
        pointerData.azimuthAngle = input.azimuthAngle;
        pointerData.radius = Vector2.one * input.radius;
        pointerData.radiusVariance = Vector2.one * input.radiusVariance;

        return pointerData;
    }

    /// <summary>
    /// Return the current MouseState.
    /// </summary>
    protected override MouseState GetMousePointerEventData(int id)
    {
        // Populate the left button...
        PointerEventData leftData;
        var created = GetPointerData(kMouseLeftId, out leftData, true);

        leftData.Reset();

        if (created)
            leftData.position = input.mousePosition;

        Vector2 pos = input.mousePosition;
        if (Cursor.lockState == CursorLockMode.Locked)
        {
            // We don't want to do ANY cursor-based interaction when the mouse is locked
            leftData.position = new Vector2(-1.0f, -1.0f);
            leftData.delta = Vector2.zero;
        }
        else
        {
            leftData.delta = pos - leftData.position;
            leftData.position = pos;
        }
        leftData.scrollDelta = input.mouseScrollDelta;
        leftData.button = PointerEventData.InputButton.Left;

        eventSystem.RaycastAll(leftData, m_RaycastResultCache);
        FindPointerResults(m_RaycastResultCache);

        var raycast = FindFirstRaycast(m_RaycastResultCache);
        leftData.pointerCurrentRaycast = raycast;
        m_RaycastResultCache.Clear();

        // copy the apropriate data into right and middle slots
        PointerEventData rightData;
        GetPointerData(kMouseRightId, out rightData, true);
        rightData.Reset();

        CopyFromTo(leftData, rightData);
        rightData.button = PointerEventData.InputButton.Right;

        PointerEventData middleData;
        GetPointerData(kMouseMiddleId, out middleData, true);
        middleData.Reset();

        CopyFromTo(leftData, middleData);
        middleData.button = PointerEventData.InputButton.Middle;

        m_MouseState.SetButtonState(PointerEventData.InputButton.Left, StateForMouseButton(0), leftData);
        m_MouseState.SetButtonState(PointerEventData.InputButton.Right, StateForMouseButton(1), rightData);
        m_MouseState.SetButtonState(PointerEventData.InputButton.Middle, StateForMouseButton(2), middleData);

        return m_MouseState;
    }

    protected void FindPointerResults(List<RaycastResult> candidates)
    {
        var length = candidates.Count;
        for (int i = 0; i < length; i++)
        {
            var result = candidates[i];
            var go = result.gameObject;
            if (!go) continue;
            var pointer = go.GetComponent<GUIPointerEvents>();
            if (!pointer) continue;
            m_PointerResultList.Add(pointer);
        }
    }


}