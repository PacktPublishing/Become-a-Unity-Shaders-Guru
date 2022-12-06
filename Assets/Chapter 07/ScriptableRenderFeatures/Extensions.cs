// Adapted from Ryan Boyer's lovely code: http://ryanjboyer.com <3

using UnityEngine;

namespace CH07.ScriptableRenderFeatures
{

    public static class Extensions
    {
        public static Vector4 ToVector4(this Color color)
        {
            return new Vector4(color.r, color.g, color.b, color.a);
        }
    }

}
