/*
Shader "Codeplay/Instancing" 
{ 
    Properties 
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }
    SubShader 
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderType"="Opaque"
            "Batching"="Dynamic"
        }
        LOD 200

        CGPROGRAM
        #pragma surface surf Lambert vertex:vert
        // Just put all the multi_compiles :D though if you know how many object you will have, you can remove the additional ones
        #pragma multi_compile BATCHING_OBJECT_NUMBER_1 BATCHING_OBJECT_NUMBER_2 BATCHING_OBJECT_NUMBER_3 BATCHING_OBJECT_NUMBER_4 BATCHING_OBJECT_NUMBER_5 BATCHING_OBJECT_NUMBER_6 BATCHING_OBJECT_NUMBER_7 BATCHING_OBJECT_NUMBER_8 BATCHING_OBJECT_NUMBER_9

        #include "Batching.cginc"

        sampler2D _MainTex;
        fixed4 _Color;

        struct Input 
        {
            float2 uv_MainTex;
        };

        void vert (inout appdata_tan v)
        {
            float4x4 modelMatrix = GetMatrix(length(v.tangent));
            // Now construct the MVP matrix, and transform the vertex position
            v.vertex = mul(mul(UNITY_MATRIX_VP, modelMatrix), v.vertex);
        }

        void surf (Input IN, inout SurfaceOutput o) 
        {
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }

    Fallback "Legacy Shaders/VertexLit"
}
*/

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

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            
            #include "Batching.cginc"
            #include "Lighting.cginc"
            
            /////////////// STRUCTS ///////////////////

            struct VertexInput
            {
                float4 position : POSITION;
                half2 texcoord0 : TEXCOORD0;
                // Lighting
                half3 normal : NORMAL;
                // This will be our selector
                float3 selector : TANGENT;
            };
            
            struct FragmentInput
            {
                float4 position : SV_POSITION;
                half2 texcoord0 : TEXCOORD0;
                half3 normal : TEXCOORD1;
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
                output.texcoord0 = input.texcoord0;
                // We use the normal in the world space, so do the transformation to the world space
                output.normal = mul(modelMatrix, input.normal);
                
                return output;
            }
            
            half4 FragmentProgram(FragmentInput input) : COLOR
            {
                half4 tex = tex2D(_MainTex, input.texcoord0) * _Color;
                return tex;
            }

            ENDCG
        }
    } 
    FallBack "Diffuse"
}
