using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

using CH07.ScriptableRenderFeatures;

namespace CH08
{

    [CreateAssetMenu(menuName = "Compute Assets/CH08/Raymarching Shapes")]
    public class ComputeRaymarchingShapes : URPComputeAsset
    {
        public enum ShapeType
        {
            Sphere = 0,
            Cube,
            Torus,
            Prism,
            N_SHAPE_TYPES,
        };

        public struct Shape
        {
            public int type;
            public Color color;
            public Vector3 position;
            public Vector3 size;
        }

        public int randomSeed;
        [Range(4, 10)] public int nShapes = 4;

        public Vector3 lightRotation = new Vector3(30, 25, 0);
        [Range(0, 4)] public float lightIntensity = 1;

        private List<Shape> _shapes;
        private ComputeBuffer _shapesBuffer;
        private int _sizeofShape;

        public override void Setup()
        {
            _sizeofShape = sizeof(int) + sizeof(float) * (4 + 3 + 3);

            _shapes = new List<Shape>();

            Random.InitState(randomSeed);

            // ground plane
            _shapes.Add(new Shape()
            {
                type = (int) ShapeType.Cube,
                color = Color.white,
                position = Vector3.zero,
                size = new Vector3(10f, 0.1f, 10f),
            });

            int t; Color c; Vector3 p, s;
            for (int i = 0; i < nShapes; i++)
            {
                t = Mathf.FloorToInt(Random.value * (int)ShapeType.N_SHAPE_TYPES);
                c = Random.ColorHSV();
                p = new Vector3(
                    (Random.value < 0.5f ? 1 : -1) * Random.value * 4f,
                    (Random.value < 0.5f ? 1 : -1) * Random.value * 2f,
                    (Random.value < 0.5f ? 1 : -1) * Random.value * 5f);
                s = Random.value * 3f * Vector3.one;

                _shapes.Add(new Shape()
                {
                    type = t,
                    color = c,
                    position = p,
                    size = s,
                });
            }
        }

        public override void Render(CommandBuffer commandBuffer, int kernelHandle)
        {
            Cleanup();

            if (nShapes == 0 || _shapes.Count == 0) return;

            Camera camera = Camera.main;

            _shapesBuffer = new ComputeBuffer(_shapes.Count, _sizeofShape);
            _shapesBuffer.SetData(_shapes);
            commandBuffer.SetComputeBufferParam(shader, 0, "Shapes", _shapesBuffer);
            commandBuffer.SetComputeIntParam(shader, "NShapes", _shapes.Count);

            commandBuffer.SetComputeMatrixParam(shader, "CameraToWorld", camera.cameraToWorldMatrix);
            commandBuffer.SetComputeMatrixParam(shader, "CameraInverseProjection", camera.projectionMatrix.inverse);

            Vector3 lightDirection = Quaternion.Euler(lightRotation) * Vector3.forward;
            commandBuffer.SetComputeVectorParam(shader, "DirectionalLight", new Vector4(lightDirection.x, lightDirection.y, lightDirection.z, lightIntensity));
        }

        public override void Cleanup()
        {
            _shapesBuffer?.Dispose();
        }
    }

}
