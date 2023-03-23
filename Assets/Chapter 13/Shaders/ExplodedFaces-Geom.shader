Shader "Custom/Exploded Faces (Geometry)"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Offset ("Offset", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float4 _Color;
        float _Offset;
        CBUFFER_END
        
        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2g
        {
            float4 vertexOS : SV_POSITION;
            float3 normal : NORMAL;
            float3 vertexWS : TEXCOORD0;
        };

        struct g2f
        {
            float4 vertex : SV_POSITION;
        };
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            v2g vert (appdata v)
            {
                v2g o;
                o.vertexOS = v.vertex;
                o.vertexWS = TransformObjectToWorld(v.vertex);
                o.normal = v.normal;
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g i[3], inout TriangleStream<g2f> stream)
            {
                // recalculate normal
                float3 normal = normalize(cross(
                    i[1].vertexWS - i[0].vertexWS,
                    i[2].vertexWS - i[0].vertexWS)).xyz;

                g2f o;
                for (int idx = 0; idx < 3; idx++) {
                    o.vertex = TransformObjectToHClip(i[idx].vertexWS + normal * _Offset);
                    stream.Append(o);
                }

                stream.RestartStrip();
            }

            float4 frag(g2f i) : SV_Target
            {
                return float4(_Color.xyz, 1);
            }
            ENDHLSL
        }
    }
}