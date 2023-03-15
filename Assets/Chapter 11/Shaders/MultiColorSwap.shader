Shader "Unlit/MultiColorSwap"
{
    Properties
    {
        [MainTexture][NoScaleOffset] _MainTex ("Main Texture", 2D) = "white" {}
        [NoScaleOffset] _SwapTex ("Swap Texture", 2D) = "white" {}
        [MainColor] _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        float4 _BaseColor;

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_SwapTex);
        SAMPLER(sampler_SwapTex);

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 mainColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                float4 swapColor = SAMPLE_TEXTURE2D(_SwapTex, sampler_SwapTex, float2(mainColor.r, 0));
                float4 c = lerp(mainColor, swapColor, swapColor.a);
                c.a = mainColor.a;
                return c * _BaseColor;
            }

            ENDHLSL
        }
    }
}
