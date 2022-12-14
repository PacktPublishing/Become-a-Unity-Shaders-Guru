using UnityEngine;
using UnityEngine.Rendering;

using CH07.ScriptableRenderFeatures;

namespace CH08
{

    [CreateAssetMenu(menuName = "Compute Assets/CH08/Raymarching Sphere")]
    public class ComputeRaymarchingSphere : URPComputeAsset
    {
        public Color surfaceColor = Color.white;

        public Vector3 lightRotation = new Vector3(30, 25, 0);
        [Range(0, 4)] public float lightIntensity = 1;

        public override void Render(CommandBuffer commandBuffer, int kernelHandle)
        {
            Camera camera = Camera.main;

            commandBuffer.SetComputeMatrixParam(shader, "CameraToWorld", camera.cameraToWorldMatrix);
            commandBuffer.SetComputeMatrixParam(shader, "CameraInverseProjection", camera.projectionMatrix.inverse);

            commandBuffer.SetComputeVectorParam(shader, "SurfaceColor", new Vector3(
                surfaceColor.r, surfaceColor.g, surfaceColor.b));

            Vector3 lightDirection = Quaternion.Euler(lightRotation) * Vector3.forward;
            commandBuffer.SetComputeVectorParam(shader, "DirectionalLight", new Vector4(
                lightDirection.x, lightDirection.y, lightDirection.z, lightIntensity));
        }
    }

}
