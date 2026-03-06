using System;
using UnityEngine;
using UnityEngine.UI;

namespace TCFramework
{
    public class SpriteAnimation : MonoBehaviour
    {
        public Sprite[] sprites;
        [Min(1)]
        public int frameRate = 30;
        public int loop = 0;
        [Min(0)]
        public float interval = 1;
        public bool nativeSize = false;

        public Action callback;
        Image m_Image;
        SpriteRenderer m_SpriteRenderer;
        float m_StartTime;
        float m_LoopTime;

        int m_CurrentIndex;

        private void OnEnable()
        {
            m_Image = GetComponent<Image>();
            m_SpriteRenderer = GetComponent<SpriteRenderer>();

            if (!m_Image && !m_SpriteRenderer || sprites == null || sprites.Length == 0)
            {
                enabled = false;
                return;
            }

            if (frameRate <= 0)
            {
                frameRate = 1;
            }

            if (interval < 0)
            {
                interval = 0;
            }

            m_StartTime = Time.time;
            m_LoopTime = (float)sprites.Length / frameRate + interval;
            m_CurrentIndex = -1;
        }

        private void Update()
        {
            double dt = Time.time - m_StartTime;
            int l = (int)(dt / m_LoopTime);

            int index = 0;
            if (loop > 0 && l >= loop)
            {
                index = sprites.Length - 1;
                enabled = false;
                if (callback != null)
                {
                    callback();
                    enabled = true;
                    callback = null;
                    loop = 0;
                }
            }
            else
            {
                index = Mathf.Clamp((int)((dt - l * m_LoopTime) * frameRate), 0, sprites.Length - 1);
            }

            if (m_CurrentIndex != index)
            {
                m_CurrentIndex = index;

                var sprite = sprites[index];
                if (m_Image)
                {
                    m_Image.sprite = sprite;
                    if (nativeSize)
                    {
                        m_Image.rectTransform.pivot = new Vector2(sprite.pivot.x / sprite.rect.width, sprite.pivot.y / sprite.rect.height);
                        m_Image.SetNativeSize();
                    }
                }
                if (m_SpriteRenderer)
                    m_SpriteRenderer.sprite = sprite;
            }
        }
    }
}