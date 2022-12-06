// Adapted from Ryan Boyer's lovely code: http://ryanjboyer.com <3

using UnityEngine;
using UnityEngine.Rendering;

namespace CH07.ScriptableRenderFeatures
{

    public abstract class URPComputeAsset : ScriptableObject
    {
        public ComputeShader shader;

        public virtual void Setup() { }
        public abstract void Render(CommandBuffer commandBuffer, int kernelHandle);
        public virtual void Cleanup() { }
    }

}
