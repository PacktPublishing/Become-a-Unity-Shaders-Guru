using UnityEditor;
using UnityEngine;

public class CubemapRenderWizard : ScriptableWizard
{
    public Camera camera;

    private void OnWizardUpdate()
    {
        helpString = "Select the camera position to render the Cubemap from";
        isValid = (camera != null);
    }

    private void OnWizardCreate()
    {
        Cubemap cubemap = new Cubemap(512, TextureFormat.ARGB32, false);
        camera.RenderToCubemap(cubemap);
        AssetDatabase.CreateAsset(cubemap, $"Assets/Cubemaps/{camera.name}.cubemap");
    }

    [MenuItem("Tools/Cubemap Wizard")]
    static void RenderCubemap()
    {
        DisplayWizard<CubemapRenderWizard>("Render Cubemap", "Render");
    }
}