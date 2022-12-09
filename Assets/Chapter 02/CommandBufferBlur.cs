using UnityEngine;
using UnityEngine.Rendering;
using System.Collections.Generic;

// See _ReadMe.txt for an overview
[ExecuteInEditMode]
public class CommandBufferBlur : MonoBehaviour
{
	public Shader _blurShader;
	private Material _material;

	// We'll want to add a command buffer on any camera that renders us,
	// so have a dictionary of them.
	private Dictionary<Camera,CommandBuffer> _cameras = new Dictionary<Camera,CommandBuffer>();

	// Remove command buffers from all cameras we added into
	private void Cleanup()
	{
		foreach (var cam in _cameras)
		{
			if (cam.Key)
			{
				cam.Key.RemoveCommandBuffer (CameraEvent.AfterSkybox, cam.Value);
			}
		}
		_cameras.Clear();
		Object.DestroyImmediate (_material);
	}

	public void OnEnable()
	{
		Cleanup();
	}

	public void OnDisable()
	{
		Cleanup();
	}

	// Whenever any camera will render us, add a command buffer to do the work on it
	public void OnWillRenderObject()
	{
		var act = gameObject.activeInHierarchy && enabled;
		if (!act)
		{
			Cleanup();
			return;
		}
		
		var cam = Camera.current;
		if (!cam)
			return;

		CommandBuffer buf = null;
		// Did we already add the command buffer on this camera? Nothing to do then.
		if (_cameras.ContainsKey(cam))
			return;

		if (!_material)
		{
			_material = new Material(_blurShader);
			_material.hideFlags = HideFlags.HideAndDontSave;
		}

		buf = new CommandBuffer();
		_cameras[cam] = buf;

		// copy screen into temporary RT
		int screenCopyID = Shader.PropertyToID("_ScreenCopyTexture");
		buf.GetTemporaryRT (screenCopyID, -1, -1, 0, FilterMode.Bilinear);
		buf.Blit (BuiltinRenderTextureType.CurrentActive, screenCopyID);
		
		// get two smaller RTs
		int blurredID = Shader.PropertyToID("_Temp1");
		int blurredID2 = Shader.PropertyToID("_Temp2");
		buf.GetTemporaryRT (blurredID, -2, -2, 0, FilterMode.Bilinear);
		buf.GetTemporaryRT (blurredID2, -2, -2, 0, FilterMode.Bilinear);
		
		// downsample screen copy into smaller RT, release screen RT
		buf.Blit (screenCopyID, blurredID);
		buf.ReleaseTemporaryRT (screenCopyID); 
		
		// horizontal blur
		buf.SetGlobalVector("offsets", new Vector4(4.0f/Screen.width,0,0,0));
		buf.Blit (blurredID, blurredID2, _material);
		// vertical blur
		buf.SetGlobalVector("offsets", new Vector4(0,4.0f/Screen.height,0,0));
		buf.Blit (blurredID2, blurredID, _material);
		// horizontal blur
		buf.SetGlobalVector("offsets", new Vector4(8.0f/Screen.width,0,0,0));
		buf.Blit (blurredID, blurredID2, _material);
		// vertical blur
		buf.SetGlobalVector("offsets", new Vector4(0,8.0f/Screen.height,0,0));
		buf.Blit (blurredID2, blurredID, _material);

		buf.SetGlobalTexture("_GrabBlurTexture", blurredID);

		cam.AddCommandBuffer (CameraEvent.AfterSkybox, buf);
	}	
}
