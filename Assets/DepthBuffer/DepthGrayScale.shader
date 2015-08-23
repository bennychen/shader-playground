Shader "Codeplay/DepthGrayscale" 
{
SubShader {
Tags { "RenderType"="Opaque" }

Pass{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"

sampler2D _CameraDepthTexture;

struct v2f {
   float4 pos : SV_POSITION;
   float4 scrPos:TEXCOORD1;
};

v2f vert (appdata_base v)
{
   v2f o;
   o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
   o.scrPos = ComputeScreenPos(o.pos);
   return o;
}

half4 frag (v2f i) : COLOR
{
   half4 depth;
   depth.rgb = Linear01Depth (tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)).r);
   depth.a = 1;
   return depth;
}
ENDCG
}
}
FallBack "Diffuse"
}