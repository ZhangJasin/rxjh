using UnityEngine;

namespace TCFramework
{
    public class SkinnedMeshBoneData : MonoBehaviour
    {
        public string[] boneNames;
        public Transform[] boneTfs;

        public void Init()
        {
            Transform[] allBones = transform.GetComponentsInChildren<Transform>(true);
            boneNames = new string[allBones.Length];
            boneTfs = new Transform[allBones.Length];
            for (int i = 0; i < allBones.Length; ++i)
            {
                var tf = allBones[i];
                boneNames[i] = tf.name;
                boneTfs[i] = tf;
            }
        }
        
    }
}