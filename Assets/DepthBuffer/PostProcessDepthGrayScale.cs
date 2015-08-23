using UnityEngine;
using System.Collections;

public class PostProcessDepthGrayScale : MonoBehaviour 
{
	private void Awake()
	{
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
	}

	private void OnRenderImage(RenderTexture source, RenderTexture destination)
	{
		Graphics.Blit(source, destination, _material);
	}

	[SerializeField]
	private Material _material;
}
