Shader "Codeplay/InstancingShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        // We use Forward base light model for this example
        Tags
        {
            "Queue"="Geometry"
            "RenderType"="Opaque"
            "LightMode"="ForwardBase"
            "Batching"="Dynamic"
        }
        
        LOD 200
        
        Pass
        {
            CGPROGRAM
            
            ///////////////// PRAGMAS /////////////////
            
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            // Just put all the multi_compiles :D though if you know how many object you will have, you can remove the additional ones
            #pragma multi_compile BATCHING_OBJECT_NUMBER_1 BATCHING_OBJECT_NUMBER_2 BATCHING_OBJECT_NUMBER_3 BATCHING_OBJECT_NUMBER_4 BATCHING_OBJECT_NUMBER_5 BATCHING_OBJECT_NUMBER_6 BATCHING_OBJECT_NUMBER_7 BATCHING_OBJECT_NUMBER_8 BATCHING_OBJECT_NUMBER_9

            #include "Batching.cginc"
            #include "Lighting.cginc"
            
            /////////////// STRUCTS ///////////////////

            struct VertexInput
            {
                float4 position  : POSITION;
                half2  texcoord0 : TEXCOORD0;
                half3  normal    : NORMAL;
                float3 selector  : TANGENT; // This will be our selector
            };
            
            struct FragmentInput
            {
                float4 position  : SV_POSITION;
                half2  texcoord0 : TEXCOORD0;
                half4  lighting  : COLOR;
            };
            
            /////////////////// UNIFORMS ///////////////////
            
            uniform sampler2D _MainTex;
            uniform half4 _Color;
            
            ////////////////// PROGRAMS ////////////////////
            
            FragmentInput VertexProgram(VertexInput input)
            {
                FragmentInput output = (FragmentInput)0;
                
                // Get the matrix from this function
                float4x4 modelMatrix = GetMatrix(length(input.selector));
                // Now construct the MVP matrix, and transform the vertex position
                output.position = mul(mul(UNITY_MATRIX_VP, modelMatrix), input.position);

                // We use the normal in the world space, so do the transformation to the world space
                float3 normal = mul(modelMatrix, input.normal);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 diffuseReflection = _LightColor0.rgb * _Color.rgb
                   * max(0.0, dot(normal, lightDirection));
                output.lighting = float4(diffuseReflection, 1.0);

                output.texcoord0 = input.texcoord0;
                
                return output;
            }
            
            half4 FragmentProgram(FragmentInput input) : COLOR
            {
                half4 tex = tex2D(_MainTex, input.texcoord0) * _Color * UNITY_LIGHTMODEL_AMBIENT + input.lighting;
                return tex;
            }

            ENDCG
        }
    } 
    FallBack "Diffuse"
}