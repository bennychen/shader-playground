Shader "Spine/Skeleton Outline"
{
	Properties
	{
 		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}

		[KeywordEnum(Simple, SimpleWithDiagonals, Smooth)]
		_OutlineQuality("Outline Quality", Float) = 0

		_OutlineColor("Outline Color", Color) = (1,1,1,1)
		_OutlineSize("Outline Size", Float) = 1
		_OutlineMultiplier("Outline Power", Range(0, 20)) = 1
		_Cutout ("Main Alpha Cutout", Range(0,1)) = 0.5
		[PowerSlider(3.0)]_OutlineCutout("Outline Alpha Cutout", Range(0, 10)) = 1
	}

	SubShader
	{
        CGINCLUDE

		struct appdata_t
		{
			float4 vertex   : POSITION;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex   : SV_POSITION;
			float2 texcoord  : TEXCOORD0;
			float2 depth : TEXCOORD1;
		};

		v2f vert(appdata_t IN)
		{
			v2f OUT;
			OUT.vertex = UnityObjectToClipPos(IN.vertex);
			OUT.texcoord = IN.texcoord;
			return OUT;
		}

		ENDCG

        Tags
        {
            "Queue"="Transparent+1"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass {
			ZTest LEqual
			ColorMaterial AmbientAndDiffuse
			SetTexture [_MainTex] {
				Combine texture * primary
			}
		}

		Pass {
            Stencil {
                Ref 128
                Comp always
                Pass replace
            }

			ZTest Greater
			ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
			fixed _Cutout;
            fixed4 _OutlineColor;

			v2f vertDepth(appdata_t IN) {
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				return OUT;
			}

            half4 frag(v2f IN) : SV_Target {
                fixed4 c = tex2D (_MainTex, IN.texcoord);
				clip(c.a - _Cutout);
				return fixed4(c);
            }

            ENDCG
        }

		// OUTLINE PASS
		Pass
		{
			Stencil {
                Ref 128
                Comp NotEqual
            }

			ZTest Greater

		CGPROGRAM
			#pragma vertex vert
		    #pragma fragment frag

			#pragma shader_feature _OUTLINEQUALITY_SIMPLE _OUTLINEQUALITY_SIMPLEWITHDIAGONALS _OUTLINEQUALITY_SMOOTH

			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			float4 _OutlineColor;
			fixed _OutlineSize;
			fixed _OutlineMultiplier;
			fixed _OutlineCutout;

			fixed4 SampleSpriteTex(float2 uv)
			{
				if (uv.x < 0) return fixed4(0, 0, 0, 0);
				if (uv.x > 1) return fixed4(0, 0, 0, 0);
				if (uv.y < 0) return fixed4(0, 0, 0, 0);
				if (uv.y > 1) return fixed4(0, 0, 0, 0);

				fixed4 color = tex2D(_MainTex, uv);
				return color;
			}

			fixed4 HQBlur(float2 uv, float4 texelSize, float size)
			{
				fixed4 color = fixed4(0, 0, 0, 0);

				// blur LEFT RIGHT
				color += SampleSpriteTex(float2(uv.x - texelSize.x * 3.0 * size, uv.y)) * 0.045;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * 2.0 * size, uv.y)) * 0.06;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * size, uv.y)) * 0.075;
				color += SampleSpriteTex(float2(uv.x, uv.y)) * 0.09;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * size, uv.y)) * 0.075;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * 2.0 * size, uv.y)) * 0.06;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * 3.0 * size, uv.y)) * 0.045;

				// // blur TOP BOT
				color += SampleSpriteTex(float2(uv.x, uv.y - texelSize.y * 3.0 * size)) * 0.045;
				color += SampleSpriteTex(float2(uv.x, uv.y - texelSize.y * 2.0 * size)) * 0.06;
				color += SampleSpriteTex(float2(uv.x, uv.y - texelSize.y * size)) * 0.075;
				color += SampleSpriteTex(float2(uv.x, uv.y)) * 0.09;
				color += SampleSpriteTex(float2(uv.x, uv.y + texelSize.y * size)) * 0.075;
				color += SampleSpriteTex(float2(uv.x, uv.y + texelSize.y * 2.0 * size)) * 0.06;
				color += SampleSpriteTex(float2(uv.x, uv.y + texelSize.y * 3.0 * size)) * 0.045;

				// Simplified diagonals
				color += SampleSpriteTex(float2(uv.x + texelSize.x * 2 * size, uv.y + texelSize.x * 2 * size)) * 0.1;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * 2 * size, uv.y - texelSize.x * 2 * size)) * 0.1;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * 2 * size, uv.y + texelSize.x * 2 * size)) * 0.1;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * 2 * size, uv.y - texelSize.x * 2 * size)) * 0.1;

				color += SampleSpriteTex(float2(uv.x + texelSize.x * 3 * size, uv.y + texelSize.x * 3 * size)) * 0.025;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * 3 * size, uv.y - texelSize.x * 3 * size)) * 0.025;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * 3 * size, uv.y + texelSize.x * 3 * size)) * 0.025;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * 3 * size, uv.y - texelSize.x * 3 * size)) * 0.025;

				return color / 1.4;
			}

			fixed4 LQBlur(float2 uv, float4 texelSize, float size)
			{
				fixed4 color = fixed4(0, 0, 0, 0);

				// blur LEFT RIGHT
				color += SampleSpriteTex(float2(uv.x - texelSize.x * size, uv.y));
				color += SampleSpriteTex(float2(uv.x + texelSize.x * size, uv.y));

				// // blur TOP BOT
				color += SampleSpriteTex(float2(uv.x, uv.y - texelSize.y * size));
				color += SampleSpriteTex(float2(uv.x, uv.y + texelSize.y * size));

				return color * 0.25;
			}

			fixed4 LQWithDiagBlur(float2 uv, float4 texelSize, float size)
			{
				fixed4 color = fixed4(0, 0, 0, 0);

				// blur LEFT RIGHT
				color += SampleSpriteTex(float2(uv.x - texelSize.x * size, uv.y)) * 0.125;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * size, uv.y)) * 0.125;

				// // blur TOP BOT
				color += SampleSpriteTex(float2(uv.x, uv.y - texelSize.y * size)) * 0.125;
				color += SampleSpriteTex(float2(uv.x, uv.y + texelSize.y * size)) * 0.125;

				// Simplified diagonals
				color += SampleSpriteTex(float2(uv.x + texelSize.x * size, uv.y + texelSize.x * size)) * 0.125;
				color += SampleSpriteTex(float2(uv.x + texelSize.x * size, uv.y - texelSize.x * size)) * 0.125;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * size, uv.y + texelSize.x * size)) * 0.125;
				color += SampleSpriteTex(float2(uv.x - texelSize.x * size, uv.y - texelSize.x * size)) * 0.125;

				return color;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed2 texCoords = IN.texcoord;

				fixed4 spriteCol = SampleSpriteTex(float2(texCoords.x, texCoords.y));

				fixed4 cBlur;

				#ifdef _OUTLINEQUALITY_SIMPLE
				cBlur = LQBlur(texCoords, _MainTex_TexelSize, _OutlineSize);
				#elif _OUTLINEQUALITY_SIMPLEWITHDIAGONALS
				cBlur = LQWithDiagBlur(texCoords, _MainTex_TexelSize, _OutlineSize);
				#else
				cBlur = HQBlur(texCoords, _MainTex_TexelSize, _OutlineSize);
				#endif	

				cBlur.a *= saturate(1 - spriteCol.a * _OutlineCutout);

				cBlur.rgb = _OutlineColor.rgb * _OutlineMultiplier;
				cBlur.a *= _OutlineColor.a;
				cBlur.rgb *= cBlur.a;

				return cBlur;
			}

		ENDCG
		}

		// DRAW SPRITE PASS - Would break batching, therefore it's better to draw the sprite as a separate gameObject!
	}
}
