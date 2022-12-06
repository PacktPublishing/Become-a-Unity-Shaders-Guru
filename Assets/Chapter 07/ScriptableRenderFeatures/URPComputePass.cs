// Adapted from Ryan Boyer's lovely code: http://ryanjboyer.com <3

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CH07.ScriptableRenderFeatures
{

    public class URPComputePass : ScriptableRenderPass
    {
        private string profilerTag;

        private URPComputeAsset computeAsset;

        private readonly int TargetBufferID = Shader.PropertyToID("targetBuffer");
        private readonly int ConvergedBufferID = Shader.PropertyToID("convergedBuffer");

        private Material addMaterial;
        private int currentSample;

        public URPComputePass(string profilerTag, URPComputeFeature.URPComputeSettings settings)
        {
            this.profilerTag = profilerTag;
            computeAsset = settings.computeAsset;
            renderPassEvent = settings.passEvent;

            currentSample = 0;

            computeAsset.Setup();
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            base.OnCameraSetup(cmd, ref renderingData);
            RenderTextureDescriptor textureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            textureDescriptor.enableRandomWrite = true;

            cmd.GetTemporaryRT(TargetBufferID, textureDescriptor);
            ConfigureTarget(TargetBufferID);

            cmd.GetTemporaryRT(ConvergedBufferID, textureDescriptor);
            ConfigureTarget(ConvergedBufferID);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (computeAsset == null || computeAsset.shader == null) { return; }
            if (addMaterial == null)
            {
                addMaterial = new Material(Shader.Find("Unlit/Texture"));
            }

            CommandBuffer cmd = CommandBufferPool.Get();
            ScriptableRenderer renderer = renderingData.cameraData.renderer;

            int kernelHandle = computeAsset.shader.FindKernel("CSMain");
            computeAsset.shader.GetKernelThreadGroupSizes(kernelHandle,
                out uint threadsGroupSizeX,
                out uint threadsGroupSizeY,
                out _);

            using (new ProfilingScope(cmd, new ProfilingSampler("Compute Pass")))
            {
                computeAsset.Render(cmd, kernelHandle);

                cmd.SetComputeTextureParam(computeAsset.shader, kernelHandle, "Result", TargetBufferID);
                cmd.DispatchCompute(computeAsset.shader, kernelHandle,
                    Mathf.CeilToInt(Screen.width / (float)threadsGroupSizeX),
                    Mathf.CeilToInt(Screen.height / (float)threadsGroupSizeY),
                    1);

                addMaterial.SetFloat("_Sample", currentSample);
                Blit(cmd, TargetBufferID, ConvergedBufferID, addMaterial);
                Blit(cmd, ConvergedBufferID, renderer.cameraColorTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(TargetBufferID);
            cmd.ReleaseTemporaryRT(ConvergedBufferID);
        }

        public void Dispose() => Material.Destroy(addMaterial);
    }

}
