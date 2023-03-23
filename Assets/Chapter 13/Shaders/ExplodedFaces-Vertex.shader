Shader "Custom/Exploded Faces (Vertex)"
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

        struct v2f
        {
            float4 vertex : SV_POSITION;
        };
        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex + v.normal * _Offset);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(_Color.xyz, 1);
            }
            ENDHLSL
        }
    }
}