Shader "Custom/URP Wireframe (Transparent)"
{
    Properties
    {
        _BaseAlpha ("Base Alpha", Range(0, 1)) = 0.25
        _WireframeColor ("Wireframe Color", Color) = (0, 0, 0, 1)
        _WireframeThickness ("Wireframe Thickness", Range(0, 5)) = 10
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Back

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float _BaseAlpha;
        float4 _WireframeColor;
        float _WireframeThickness;
        CBUFFER_END
        
        struct appdata
        {
            float4 vertex : POSITION;
        };

        struct v2g
        {
            float4 vertex : SV_POSITION;
        };

        struct g2f
        {
            float4 vertex : SV_POSITION;
            float3 barycentric : TEXCOORD0;
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
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g i[3], inout TriangleStream<g2f> stream)
            {
                g2f o;
                o.vertex = i[0].vertex;
                o.barycentric = float3(1, 0, 0);
                stream.Append(o);

                o.vertex = i[1].vertex;
                o.barycentric = float3(0, 1, 0);
                stream.Append(o);

                o.vertex = i[2].vertex;
                o.barycentric = float3(0, 0, 1);
                stream.Append(o);
            }

            float4 frag(g2f i) : SV_Target
            {
                float3 unitWidth = fwidth(i.barycentric);
                float3 wire = smoothstep(float3(0, 0, 0), unitWidth * _WireframeThickness, i.barycentric);
                float dist = min(wire.x, min(wire.y, wire.z));
                return float4(_WireframeColor.xyz, (1 - _BaseAlpha) * (1 - dist) + _BaseAlpha);
            }
            ENDHLSL
        }
    }
}