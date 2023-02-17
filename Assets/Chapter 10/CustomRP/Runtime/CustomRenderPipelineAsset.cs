using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Custom RP/Custom Render Pipeline")]
public class CustomRenderPipelineAsset : RenderPipelineAsset
{

	protected override RenderPipeline CreatePipeline()
	{
		return new CustomRenderPipeline();
	}

}
