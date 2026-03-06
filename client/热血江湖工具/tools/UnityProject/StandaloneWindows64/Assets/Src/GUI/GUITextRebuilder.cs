using System;
using System.Collections.Generic;
using UnityEngine;


[AddComponentMenu("UI/GUITextRebuilder")]
public class GUITextRebuilder : MonoBehaviour
{

    public static event Action<Dictionary<Font, bool>> textureRebuilt;

    private static bool m_dirty = false;
    private static Dictionary<Font, bool> m_dirtyFontMap = new();

    public GUITextRebuilder()
    {
        Font.textureRebuilt += RefreshTexture;
    }

    private static void RefreshTexture(Font font)
    {
        m_dirty = true;
        m_dirtyFontMap[font] = true;
    }

    private void LateUpdate()
    {
        if (m_dirty)
        {
            m_dirty = false;
            textureRebuilt?.Invoke(m_dirtyFontMap);
            m_dirtyFontMap.Clear();
        }
    }

}
