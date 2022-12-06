using System.Collections.Generic;
using UnityEngine;


public class RandomColorGrid : MonoBehaviour
{
    public struct Cube
    {
        public Vector3 position;
        public Color color;
    }

    public Material cubeMaterial;
    public ComputeShader computeShader;
    public int gridSize = 50;
    public int nRandomizations = 1;

    private List<GameObject> _cubes;
    private List<MeshRenderer> _cubeRenderers;

    private Cube[] _data;

    private void Start()
    {
        _GenerateGrid();
    }

    private void OnGUI()
    {
        // quick UI to call our randomization process
        // (using the CPU)
        if (GUI.Button(new Rect(10, 10, 200, 40), "Randomize (CPU)"))
        {
            _Randomize(useGPU: false);
        }
        // (using the GPU, with a compute shader)
        if (GUI.Button(new Rect(220, 10, 200, 40), "Randomize (GPU)"))
        {
            _Randomize(useGPU: true);
        }
    }

    private void _GenerateGrid()
    {
        // create a gridSize * gridSize grid of cubes
        // with a given material
        // (+ store them, their MeshRenderer components
        //  and their cube data for later re-use)

        _cubes = new List<GameObject>();
        _cubeRenderers = new List<MeshRenderer>();

        _data = new Cube[gridSize * gridSize];

        GameObject g; MeshRenderer r;

        float cubeSize = 10 / (float)gridSize;
        Vector2 globalOffset = new Vector2(-5f, -5f);

        for (int x = 0; x < gridSize; x++)
        {
            for (int y = 0; y < gridSize; y++)
            {
                g = GameObject.CreatePrimitive(PrimitiveType.Cube);
                g.transform.SetParent(transform);
                g.transform.localScale = Vector3.one * cubeSize;
                g.transform.position = new Vector3(
                    x * cubeSize + globalOffset.x,
                    y * cubeSize + globalOffset.y,
                    Random.Range(-0.1f, 0.1f));

                Color color = Random.ColorHSV();
                r = g.GetComponent<MeshRenderer>();
                r.material = new Material(cubeMaterial);
                r.material.SetColor("_BaseColor", color);

                // populate lists
                _cubes.Add(g);
                _cubeRenderers.Add(r);
                // populate data for compute buffer
                _data[x * gridSize + y] = new Cube()
                {
                    position = g.transform.position,
                    color = color
                };
            }
        }
    }

    private void _Randomize(bool useGPU)
    {
        float timeStart = Time.realtimeSinceStartup;

        if (useGPU) _RandomizeGPU();
        else _RandomizeCPU();

        float timeEnd = Time.realtimeSinceStartup;
        Debug.Log($"Execution time: {(timeEnd - timeStart).ToString("f6")} sec");
    }

    private void _RandomizeCPU()
    {
        GameObject g;
        for (int r = 0; r < nRandomizations; r++)
        {
            for (int c = 0; c < _cubes.Count; c++)
            {
                g = _cubes[c];
                g.transform.position = new Vector3(
                    g.transform.position.x,
                    g.transform.position.y,
                    Random.Range(-0.1f, 0.1f));
                _cubeRenderers[c].material.SetColor("_BaseColor", Random.ColorHSV());
            }
        }
    }

    private void _RandomizeGPU()
    {
        // compute size of our Cube struct
        int vector3Size = sizeof(float) * 3;
        int colorSize = sizeof(float) * 4;
        int totalStructSize = vector3Size + colorSize;

        // prepare buffer with the right size + set data values
        ComputeBuffer cubesBuffer = new ComputeBuffer(_data.Length, totalStructSize);
        cubesBuffer.SetData(_data);

        // setup compute shader fields
        computeShader.SetBuffer(0, "cubes", cubesBuffer);
        computeShader.SetFloat("nCubes", _data.Length);
        computeShader.SetFloat("nRandomizations", nRandomizations);

        // invoke compute shader
        computeShader.Dispatch(0, _data.Length / 10, 1, 1);

        // read data back into buffer to get
        // results on the C# side
        cubesBuffer.GetData(_data);

        for (int i = 0; i < _cubes.Count; i++)
        {
            Cube c = _data[i];
            _cubes[i].transform.position = c.position;
            _cubeRenderers[i].material.SetColor("_BaseColor", c.color);
        }

        // clean up buffer
        cubesBuffer.Dispose();
    }
}
