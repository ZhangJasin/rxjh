using UnityEngine;

namespace TCFramework
{
    public class SkinnedMeshRendererData : MonoBehaviour
    {
        public string rootBoneName;
        public string[] boneNames;

        public void Save(SkinnedMeshRenderer smr)
        {
            rootBoneName = GetBoneName(smr.rootBone);
            boneNames = GetBoneNames(smr);
        }

        public void Load(SkinnedMeshRenderer smr, Transform parent)
        {
            smr.rootBone = GetBone(parent, rootBoneName);
            if (boneNames == null)
            {
                smr.bones = new Transform[0];
            }
            else
            {
                Transform[] bones = new Transform[boneNames.Length];
                for (int i = 0; i < bones.Length; ++i)
                {
                    bones[i] = GetBone(parent, boneNames[i]);
                }
                smr.bones = bones;
            }
        }

        public static string[] GetBoneNames(SkinnedMeshRenderer smr)
        {
            var bones = smr.bones;
            if (bones == null) return new string[0];

            var boneNames = new string[bones.Length];
            for (int i = 0; i < bones.Length; ++i)
            {
                boneNames[i] = GetBoneName(bones[i]);
            }
            return boneNames;
        }

        public static string GetBoneName(Transform bone)
        {
            return bone?.name;
        }

        public static Transform GetBone(Transform parent, string name)
        {
            if (string.IsNullOrEmpty(name))
                return null;

            return parent.FindByName(name);
        }
    }
}