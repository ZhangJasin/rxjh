using System;
using System.Collections.Generic;
using UnityEngine;

public class GUILuaBehaviour : MonoBehaviour
{
    public string luaFilePath = "";

    public static bool bAwake = false;
    public static bool bStart = false;
    public static bool bUpdate = false;
    public static bool bFixedUpdate = false;
    public static bool bLateUpdate = false;
    public static bool bOnDestroy = false;
    public static bool bOnDisable = false;
    public static bool bOnEnable = false;

    [SerializeField]
    public LuaBehaviourData[] components;
    public int componentChild = 0;


    [Serializable]
    public class LuaBehaviourData
    {
        public string name;
        public int type;
        public Component target;
        public Transform text = null;
        public GameObject gameObject;
        public Transform transform;
        public int parent = -1;
        public int index;
        public bool visible = true;
        public bool touchEnabled = false;
    }
}
