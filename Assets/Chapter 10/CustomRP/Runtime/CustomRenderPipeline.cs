using UnityEngine;
using UnityEngine.Rendering;

public class CustomRenderPipeline : RenderPipeline
{
    static ShaderTagId shaderTagId = new ShaderTagId("SRPDefaultUnlit");

    protected override void Render(
		ScriptableRenderContext context,
		Camera[] cameras)
	{
        // 1. Clear the render target
		CommandBuffer cmd = new CommandBuffer();
		cmd.ClearRenderTarget(true, true, Color.black);
		context.ExecuteCommandBuffer(cmd);
		cmd.Release();

        //ShaderBindings.SetPerFrameShaderVariables(context);

        foreach (Camera camera in cameras)
        {
            //ShaderBindings.SetPerCameraShaderVariables(context, camera);

            // 2. Cull
            camera.TryGetCullingParameters(out var cullingParameters);
            CullingResults cullingResults = context.Cull(ref cullingParameters);

            // 3. Drawing
            // update built-in shader variables
            context.SetupCameraProperties(camera);

            var sortingSettings = new SortingSettings(camera);
            //{
            //    criteria = SortingCriteria.CommonOpaque
            //};
            DrawingSettings drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
            FilteringSettings filteringSettings = new FilteringSettings(RenderQueueRange.all);

            // draw skybox (if need be)
            if (camera.clearFlags == CameraClearFlags.Skybox && RenderSettings.skybox != null)
                context.DrawSkybox(camera);

            // draw geometry
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

            // perform all scheduled commands
            context.Submit();
        }
	}
}
