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
    #region Constants

    public const int MaxBatchedObject = 9;

    /// <summary>
    /// The matrix parameter names in the shader
    /// </summary>
    public static readonly string[] ModelMatrixParameter = new string[MaxBatchedObject]
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

    public static readonly string[] ObjectNumberKeywords = new string[MaxBatchedObject]
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

    #endregion
    #region Private fields

    /// <summary>
    /// The mesh list added to be batched
    /// </summary>
    [SerializeField]
    private List<Transform> objectList = new List<Transform>();

    /// <summary>
    /// The list of the bounds the batch was constructed from. The size of the list should match
    /// 1-1 with the list of the objects.
    /// </summary>
    private List<Bounds> objectBounds = new List<Bounds>();

    /// <summary>
    /// Cached mesh filter, so we don't use GetComponenet every time
    /// we need the MeshFilter.
    /// </summary>
    protected MeshFilter cachedMeshFilter;

    /// <summary>
    /// The renderer added to this object to show the batch
    /// </summary>
    private Renderer objectRenderer = null;

    /// <summary>
    /// True if the batch is visible
    /// </summary>
    public bool Visible { get; private set; }

    #endregion
    #region Unity methods

    public void Awake()
    {
        // Default visibility
        Visible = false;

        // Get the mesh filter and mesh renderer, or add them if they are not added yet
        cachedMeshFilter = GetComponent<MeshFilter>();
        if (cachedMeshFilter == null) cachedMeshFilter = gameObject.AddComponent<MeshFilter>();

        objectRenderer = GetComponent<MeshRenderer>();
        if (objectRenderer == null) gameObject.AddComponent<MeshRenderer>();

        // Hide the already added objects, this will do nothing if the component is not serialized
        HideAddedObjects();

        // Batch the meshes if they have not yet been batched
        if (cachedMeshFilter.sharedMesh == null)
        {
            // Build & refresh bounds
            Batch();
            List<Transform> transforms = new List<Transform>(objectList);
            objectList.Clear();
            foreach (Transform currentTransform in transforms) AddObject(currentTransform);
        }
    }

    // These two functions take LODs into account as well! If the object's LOD changes, this will be called.
    public void OnBecameVisible()
    {
        Visible = true;
        UpdateShaderParameters();
    }
    public void OnBecameInvisible() { Visible = false; }

    public void LateUpdate()
    {
        if (!Visible) return;

        // The batched objects have probably moved, we don't want them to be frustum culled.
        // We have to calculate this before the culling occurs.
        CalculateBoundingBox();
    }

    public void OnWillRenderObject()
    {
        // All batched transforms have been moved during the update. Now we
        // update the shader parameters
        UpdateShaderParameters();
    }

    /// <summary>
    /// Called when the object is destroy
    /// </summary>
    public void OnDestroy()
    {
        // We don't need the mesh anymore, so destroy it
        if (cachedMeshFilter.sharedMesh != null)
        {
            Object.DestroyImmediate(cachedMeshFilter.sharedMesh);
            cachedMeshFilter = null;
        }
    }

    #endregion
    #region Public methods

    /// <summary>
    /// Adds an object to the list for batching. NOTE: there is a limited number of objects
    /// that can be added to the batcher (see MaxBatchedObject).
    /// </summary>
    /// <param name="newObject">The object to be added</param>
    public void AddObject(Transform newObject)
    {
        // We limit the number of meshes added to a batch, so we accidentally don't
        // make a mistake by adding more meshes than supported
        if (objectList.Count < MaxBatchedObject)
        {
            objectList.Add(newObject);

            Renderer newObjectRenderer = newObject.GetComponent<Renderer>();
            if (newObjectRenderer != null) newObjectRenderer.enabled = false;

            MeshFilter filter = newObject.GetComponent<MeshFilter>();
            if (filter != null)
            {
                // If bounds available, then extract them
                objectBounds.Add(filter.sharedMesh.bounds);
            }
            else objectBounds.Add(new Bounds());

            UpdateShaderKeywords();
        }
        else Debug.LogError("Maximum number of batched objects is: " + MaxBatchedObject, this);
    }

    /// <summary>
    /// Changes the bounds of an object.
    /// </summary>
    /// <param name="tranformObject">The object whose bounds to change</param>
    /// <param name="bounds">The new bounds</param>
    public void ChangeBounds(Transform tranformObject, Bounds bounds)
    {
        int index = objectList.FindIndex(x => x == tranformObject);
        if (index != -1)
        {
            objectBounds[index] = bounds;
        }
    }

    /// <summary>
    /// Hides the batched object renderers
    /// </summary>
    public void HideAddedObjects()
    {
        for (int i = 0; i < objectList.Count; i++)
        {
            objectList[i].GetComponent<Renderer>().enabled = false;
        }
    }

    /// <summary>
    /// Batch the added objects.  This will take all the added objects and make a single mesh
    /// out of them. It will use the tangent information in the vertex buffer as the transform selector,
    /// so the initial tangent data will be lost.
    /// </summary>
    public virtual void Batch()
    {
        // If there are no added mesh filters, nothing to do here.
        if (objectList.Count == 0) return;

        // Make a mesh list for batching
        List<Mesh> meshList = new List<Mesh>();
        foreach (Transform currentObject in objectList)
        {
            MeshFilter filter = currentObject.GetComponent<MeshFilter>();

            if (filter != null) meshList.Add(filter.sharedMesh);
            else meshList.Add(new Mesh());
        }

        Mesh mesh = cachedMeshFilter.sharedMesh;
        // If we had a previous batch, destroy it
        if (mesh != null) Destroy(mesh);

        // Get new the new batched mesh
        cachedMeshFilter.sharedMesh = BatchList(meshList);

        // Update material (instantiate a new material) same as objectRenderer.renderer
        objectRenderer.sharedMaterial = new Material(objectRenderer.sharedMaterial);
        UpdateShaderKeywords();
    }

    /// <summary>
    /// Updates the keywords on the material
    /// </summary>
    public void UpdateShaderKeywords()
    {
        if (objectList.Count == 0) return;

        // First disable all keywords
        DisableAllKeywords(objectRenderer.sharedMaterial);

        // Check if we can do something
        if (objectList.Count > MaxBatchedObject)
        {
            Debug.LogError("Max batched object number exceeded. Update the shader to be able to batch more.", this);
            return;
        }

        // Now set the necessary keywords
        objectRenderer.sharedMaterial.EnableKeyword(ObjectNumberKeywords[objectList.Count - 1]);
    }

    #region Static

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
                // Add selector data
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

    #endregion
    #endregion
    #region Protected methods

    /// <summary>
    /// Update the shader transform parameters of the batched object
    /// </summary>
    protected virtual void UpdateShaderParameters()
    {
        for (int i = 0; i < objectList.Count; i++)
        {
            objectRenderer.sharedMaterial.SetMatrix(ModelMatrixParameter[i], objectList[i].transform.localToWorldMatrix);
        }
    }

    /// <summary>
    /// Recalculates the bounding box of the batch
    /// </summary>
    protected virtual void CalculateBoundingBox()
    {
        if (cachedMeshFilter.sharedMesh == null)
        {
            return;
        }

        // Nothing to Calculate
        if (objectBounds.Count == 0)
        {
            cachedMeshFilter.sharedMesh.bounds = new Bounds();
            return;
        }

        // Take the first object for the starting point of the calculation
        Bounds newBounds = new Bounds();

        // Calculate all other objects
        for (int i = 0; i < objectBounds.Count; i++)
        {
            //newBounds.Encapsulate(new Bounds(transform.InverseTransformPoint(objectList[i].position), objectBounds[i].size));
            newBounds.Encapsulate(new Bounds(transform.InverseTransformPoint(objectList[i].position), objectBounds[i].size));
        }

        // Set the new bounding box to be used
        cachedMeshFilter.sharedMesh.bounds = newBounds;
    }

    #endregion

    /// <summary>
    /// Disables all keywords on the material.
    /// </summary>
    /// <param name="material">The material whose keywords to disable</param>
    public static void DisableAllKeywords(Material material)
    {
        for (int i = material.shaderKeywords.Length - 1; i >= 0; i--) material.DisableKeyword(material.shaderKeywords[i]);
    }

    private void OnDrawGizmos()
    {
        if (cachedMeshFilter != null)
        {
            Gizmos.DrawWireCube(cachedMeshFilter.sharedMesh.bounds.center, cachedMeshFilter.sharedMesh.bounds.size);
        }
    }
}