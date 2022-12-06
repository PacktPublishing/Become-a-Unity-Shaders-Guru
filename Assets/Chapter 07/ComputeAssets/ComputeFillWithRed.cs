using UnityEngine;
using UnityEngine.Rendering;

namespace CH07
{

    using ScriptableRenderFeatures;

    [CreateAssetMenu(menuName = "Compute Assets/CH07/Fill With Red")]
    public class ComputeFillWithRed : URPComputeAsset
    {
        public override void Render(CommandBuffer commandBuffer, int kernelHandle) {}
    }

}
