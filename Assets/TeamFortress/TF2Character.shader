Shader "Codeplay/TF2Character" 
{
    Properties 
    {
        _MainTex ("Diffuse Color(RGB), Specular&Reflection(A)", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _MainColor ("Diffuse Color(RGB), Specular&Reflection(A)", Color) = (0.5,0.5,0.5,1.0)
        _DiffuseWarper ("Diffuse Warp Texutre", 2D) = "black" {}    
        _SpecularK ("Specular K", Float) = 1.0
        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
        _Shininess ("Shininess", Float) = 0.078125
        _FresnelLookupS ("Fresnel Lookup Specular", 2D) = "black" {} 
        _AmbientColor ("Ambient Color", Color) = (1.0,1.0,1.0,1.0)
        _AmbientCube("Ambient Cube", Cube)  = "whte" 
        _RimLightK ("Rim Light K", Float) = 1.0
        _FresnelLookupR ("Fresnel Lookup Rim Light", 2D) = "black" {}     
        _MaskTex ("Rim(R), Specular K(G), Shiness(B), Ambient(A)", 2D) = "white" {}
    }

    SubShader 
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }

        CGPROGRAM
        #pragma target 2.0
        #pragma surface surf Fresnel noshadow nodirlightmap novertexlights nofog interpolateview
        #pragma debug

        struct Input 
        {
            fixed2 uv_MainTex;
            float2 uv_BumpMap;
            fixed3 viewDir;
            fixed3 worldNormal;
        };
        
        struct SurfaceOutputCustom
        {
            fixed3 Albedo;
            fixed3 Normal;
            half Specular;
            fixed Gloss;
            fixed3 Emission;
            fixed Alpha;
            
            float2 UV;            
        };

        sampler2D _MainTex;
        sampler2D _BumpMap;
        fixed4 _MainColor;
        sampler2D _DiffuseWarper;

        fixed _SpecularK;     
        sampler2D _SpecularPowerMap;
        fixed _Shininess;
        sampler2D _FresnelLookupS;

        fixed4 _AmbientColor;
        samplerCUBE _AmbientCube;

        fixed _RimLightK;
        sampler2D _FresnelLookupR;
        
        sampler2D _MaskTex;

        void surf (Input IN, inout SurfaceOutputCustom o) 
        {
            fixed4 albedo = tex2D (_MainTex, IN.uv_MainTex) * _MainColor;
            o.Specular = _Shininess;
            o.Gloss = albedo.w * _SpecularK;
            o.Albedo = albedo;
            o.UV = IN.uv_MainTex;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
        }

        inline fixed4 LightingFresnel (SurfaceOutputCustom s, fixed3 lightDir, fixed3 viewDir, fixed atten)
        {
            float4 controlMap = tex2D(_MaskTex, s.UV);
            
            fixed3 h = normalize (lightDir + viewDir);

            // Diffuse + Ambient
            // s.Normal = normalize(s.Normal);
            float diff = dot (s.Normal, lightDir);  
            //return float4(1,1,1, 1);
            //return float4(diff.xxx, 1);
            
            // UNDONE:
            diff = tex2D(_DiffuseWarper, fixed2(diff * 0.5f + 0.5f, 0)); // half lambert
            fixed3 ambient = texCUBE(_AmbientCube, s.Normal).xyz * _AmbientColor.xyz * controlMap.a;
            

            // Specular
            fixed nh = max (0, dot (s.Normal, h));
            fixed spec = pow (nh, s.Specular*128.0 * controlMap.b) * s.Gloss * controlMap.g;
            fixed viewDotN = dot(viewDir, s.Normal);
            fixed fresnelS = tex2D(_FresnelLookupS, fixed2(viewDotN, 0)).x;

            // Rim Light
            fixed fresnelR = tex2D(_FresnelLookupR, fixed2(viewDotN, 0)).x;
            fixed upDotN = saturate(dot(s.Normal, fixed3(0,1,0)));
            fixed3 rim = texCUBE(_AmbientCube, -viewDir) * fresnelR * upDotN * _RimLightK * controlMap.r;

            // Combine
            fixed3 light = _LightColor0.rgb * atten;
            fixed3 finalColor = ((light * diff.xxx) + ambient) * s.Albedo   // Diffuse
                + light * _SpecColor.rgb * spec * fresnelS                  // Specular
                + rim;                                                      // Rim Light

            //return fixed4(diff.xxx, 1);
            //return fixed4(((light * diff.xxx) + ambient) * s.Albedo, 1);
            //return fixed4(light * _SpecColor.rgb * spec * fresnelS, 1);
            //return fixed4(rim, 1);
            //return fixed4(s.Normal, 1);
            return fixed4(finalColor, 1);
        }

        ENDCG
    } 

    Fallback "Mobile/Diffuse"
}
