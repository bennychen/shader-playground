using UnityEngine;
using System.Collections;

public class PostProcessDepthRingPass : MonoBehaviour 
{
	private void Start () 
	{
	    GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
	}

	private void OnGUI()
	{
	   if (GUILayout.Button("Start Ring Anim"))
	   {
	      _material.SetFloat("_StartingTime", Time.time);
	      _material.SetFloat("_RunRingPass", 1);
	   }
	   if (GUILayout.Button("Stop Ring Anim"))
	   {
	      _material.SetFloat("_StartingTime", 0);
	      _material.SetFloat("_RunRingPass", 0);
	   }
	}

	private void OnRenderImage (RenderTexture source, RenderTexture destination)
	{
	   Graphics.Blit(source, destination, _material);
	}

	[SerializeField]
	private Material _material;
}
