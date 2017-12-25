using System;
using UnityEngine;
using System.Collections.Generic;
using Object = UnityEngine.Object;

/// <summary>
/// The class in charge of batching dynamic objects. It will add objects to the same
/// mesh and use the tangent vertex information to sort out which vertex belongs to which
/// object (so it knows which transformation matrix to use in the shader).
/// </summary>
[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class DynamicShaderBatcher : MonoBehaviour
{
    public bool Visible { get; private set; }

    public void AddObject(Transform newObject)
    {
        // We limit the number of meshes added to a batch, so we accidentally don't
        // make a mistake by adding more meshes than supported
        if (_objectList.Count < MaxBatchedObject)
        {
            _objectList.Add(newObject);

            Renderer newObjectRenderer = newObject.GetComponent<Renderer>();
            if (newObjectRenderer != null) newObjectRenderer.enabled = false;

            MeshFilter filter = newObject.GetComponent<MeshFilter>();
            if (filter != null)
            {
                // If bounds available, then extract them
                _objectBounds.Add(filter.sharedMesh.bounds);
            }
            else _objectBounds.Add(new Bounds());

            UpdateShaderKeywords();
        }
        else Debug.LogError("Maximum number of batched objects is: " + MaxBatchedObject, this);
    }

    public void ChangeBounds(Transform tranformObject, Bounds bounds)
    {
        int index = _objectList.FindIndex(x => x == tranformObject);
        if (index != -1)
        {
            _objectBounds[index] = bounds;
        }
    }

    public void HideAddedObjects()
    {
        for (int i = 0; i < _objectList.Count; i++)
        {
            _objectList[i].GetComponent<Renderer>().enabled = false;
        }
    }

    /// <summary>
    /// Batch the added objects.  This will take all the added objects and make a single mesh
    /// out of them. It will use the tangent information in the vertex buffer as the transform selector,
    /// so the initial tangent data will be lost.
    /// </summary>
    public virtual void Batch()
    {
        if (_objectList.Count == 0) return;

        List<Mesh> meshList = new List<Mesh>();
        foreach (Transform currentObject in _objectList)
        {
            MeshFilter filter = currentObject.GetComponent<MeshFilter>();

            if (filter != null) meshList.Add(filter.sharedMesh);
            else meshList.Add(new Mesh());
        }

        Mesh mesh = _cachedMeshFilter.sharedMesh;
        if (mesh != null) Destroy(mesh);

        _cachedMeshFilter.sharedMesh = BatchList(meshList);

        _objectRenderer.sharedMaterial = new Material(_objectRenderer.sharedMaterial);
        UpdateShaderKeywords();
    }

    public void UpdateShaderKeywords()
    {
        if (_objectList.Count == 0) return;

        DisableAllKeywords(_objectRenderer.sharedMaterial);

        if (_objectList.Count > MaxBatchedObject)
        {
            Debug.LogError("Max batched object number exceeded. Update the shader to be able to batch more.", this);
            return;
        }

        _objectRenderer.sharedMaterial.EnableKeyword(ObjectNumberKeywords[_objectList.Count - 1]);
    }

    /// <summary>
    /// Static method for batching a list of meshes. Note that the selector information goes to tangent vertex
    /// information, so any data in the mesh tangents will be lost.
    /// </summary>
    /// <param name="meshList">The list of meshes to batch</param>
    public static Mesh BatchList(List<Mesh> meshList)
    {
        // We will use this to combine the meshes
        CombineInstance[] combineInstances = new CombineInstance[meshList.Count];
        List<Vector4> tangentSelectors = new List<Vector4>();

        for (int i = 0; i < combineInstances.Length; i++)
        {
            Mesh mesh = meshList[i];

            for (int j = 0; j < mesh.vertexCount; j++)
            {
                tangentSelectors.Add(new Vector4(i, 0, 0, 0));
            }

            combineInstances[i].mesh = mesh;

            // We don't want to transform the meshes, it will be done in the shader.
            combineInstances[i].transform = Matrix4x4.identity;
        }

        // Make our new mesh out of the combined instance
        Mesh resultMesh = new Mesh();
        resultMesh.CombineMeshes(combineInstances);
        // And set the selectors of the meshes
        resultMesh.tangents = tangentSelectors.ToArray();

        return resultMesh;
    }

    protected virtual void UpdateShaderParameters()
    {
        for (int i = 0; i < _objectList.Count; i++)
        {
            _objectRenderer.sharedMaterial.SetMatrix(ModelMatrixParameter[i], _objectList[i].transform.localToWorldMatrix);
        }
    }

    protected virtual void CalculateBoundingBox()
    {
        if (_cachedMeshFilter.sharedMesh == null)
        {
            return;
        }

        if (_objectBounds.Count == 0)
        {
            _cachedMeshFilter.sharedMesh.bounds = new Bounds();
            return;
        }

        Bounds newBounds = new Bounds();
        for (int i = 0; i < _objectBounds.Count; i++)
        {
            newBounds.Encapsulate(new Bounds(
                transform.InverseTransformPoint(_objectList[i].position), _objectBounds[i].size));
        }

        _cachedMeshFilter.sharedMesh.bounds = newBounds;
    }

    private void Awake()
    {
        Visible = false;

        _cachedMeshFilter = GetComponent<MeshFilter>();
        if (_cachedMeshFilter == null) _cachedMeshFilter = gameObject.AddComponent<MeshFilter>();

        _objectRenderer = GetComponent<MeshRenderer>();
        if (_objectRenderer == null) gameObject.AddComponent<MeshRenderer>();

        HideAddedObjects();

        if (_cachedMeshFilter.sharedMesh == null)
        {
            Batch();
            List<Transform> transforms = new List<Transform>(_objectList);
            _objectList.Clear();
            foreach (Transform currentTransform in transforms) AddObject(currentTransform);
        }
    }

    // These two functions take LODs into account as well! If the object's LOD changes, this will be called.
    private void OnBecameVisible()
    {
        Visible = true;
        UpdateShaderParameters();
    }

    private void OnBecameInvisible() { Visible = false; }

    private void LateUpdate()
    {
        if (!Visible) return;

        // The batched objects have probably moved, we don't want them to be frustum culled.
        // We have to calculate this before the culling occurs.
        CalculateBoundingBox();
    }

    private void OnWillRenderObject()
    {
        // All batched transforms have been moved during the update. Now we
        // update the shader parameters
        UpdateShaderParameters();
    }

    private void OnDestroy()
    {
        // We don't need the mesh anymore, so destroy it
        if (_cachedMeshFilter.sharedMesh != null)
        {
            Object.DestroyImmediate(_cachedMeshFilter.sharedMesh);
            _cachedMeshFilter = null;
        }
    }

    private static void DisableAllKeywords(Material material)
    {
        for (int i = material.shaderKeywords.Length - 1; i >= 0; i--) material.DisableKeyword(material.shaderKeywords[i]);
    }

    private void OnDrawGizmos()
    {
		if (_cachedMeshFilter != null && _cachedMeshFilter.sharedMesh != null)
        {
            Gizmos.DrawWireCube(_cachedMeshFilter.sharedMesh.bounds.center, _cachedMeshFilter.sharedMesh.bounds.size);
        }
    }

    [SerializeField]
    private List<Transform> _objectList = new List<Transform>();

    private List<Bounds> _objectBounds = new List<Bounds>();
    protected MeshFilter _cachedMeshFilter;
    private Renderer _objectRenderer = null;

    private const int MaxBatchedObject = 9;

    private static readonly string[] ModelMatrixParameter = new string[MaxBatchedObject]
    { 
        "ModelMatrix0",
        "ModelMatrix1",
        "ModelMatrix2",
        "ModelMatrix3",
        "ModelMatrix4",
        "ModelMatrix5",
        "ModelMatrix6",
        "ModelMatrix7",
        "ModelMatrix8"
        // Add more if needed, but don't forget to update the shaders :)
    };

    private static readonly string[] ObjectNumberKeywords = new string[MaxBatchedObject]
    {
        "BATCHING_OBJECT_NUMBER_1",
        "BATCHING_OBJECT_NUMBER_2",
        "BATCHING_OBJECT_NUMBER_3",
        "BATCHING_OBJECT_NUMBER_4",
        "BATCHING_OBJECT_NUMBER_5",
        "BATCHING_OBJECT_NUMBER_6",
        "BATCHING_OBJECT_NUMBER_7",
        "BATCHING_OBJECT_NUMBER_8",
        "BATCHING_OBJECT_NUMBER_9"
    };
}