Shader "FX/Glass/Blurry" {
	SubShader {

		// We must be transparent, so other objects are drawn before this one.

		Tags { "Queue"="Transparent" "RenderType"="Opaque" }

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _GrabBlurTexture;

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : POSITION;
				float4 uvgrab : TEXCOORD0;
				float2 uv : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uvgrab = ComputeGrabScreenPos(o.vertex);
				o.uv = v.uv;
				return o;
			}

			half4 frag (v2f i) : SV_Target
			{
				if (i.uv.x > 0.975) return half4(0, 0, 0, 1);
				if (i.uv.x < 0.025) return half4(0, 0, 0, 1);
				if (i.uv.y > 0.975) return half4(0, 0, 0, 1);
				if (i.uv.y < 0.025) return half4(0, 0, 0, 1);
				return tex2Dproj (_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));
			}
			ENDCG
		}
	}
}
