using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class TransformExt
{
    public static Transform FindByName(this Transform parent, string name)
    {
        if (string.IsNullOrEmpty(name))
            return null;

        // 如果当前节点就能够找到的话，直接返回
        Transform ret = parent.Find(name);
        if (ret != null) return ret;

        // 否则遍历每个子节点
        int count = parent.childCount;
        for (int i = 0; i < count; ++i)
        {
            var child = parent.GetChild(i);
            ret = FindByName(child, name);
            if (ret != null) return ret;
        }
        return null;
    }
}
