Shader "Custom/RaymarchedSkybox"
{
    Properties
    {
        _CloudTex ("Cloud Texture", 2D) = "white" {}
		_GradientTex("Cloud Lighting Gradient", 2D) = "white" {}

		_CloudHeight("Cloud Height", Float) = 1000
		_CloudThickness("Cloud Thickness", Float) = 700
		_TopSurfaceScale("Top Surface Scale", Float) = 2
		_BottomSurfaceScale("Bottom Surface Scale", Float) = 0.5
		_TurbulenceScale("Turbulence Scale", Float) = 0.1
		_CloudScale("Cloud Scale (xy = main, zw = turbulence)", Vector) = (18000, 18000, 2000, 2000)
		_CloudOpacity("Cloud Opacity", Float) = 0.005
		_CloudSoftness("Cloud Softness", Float) = 10
		_CloudSpeed("Cloud Speed (xy = main, zw = turbulence)", Vector) = (100, 0, 200, 0)

		_SkyColor("Sky Color", Color) = (0, 0, 0, 1)
		_GroundColor("Ground Color", Color) = (0, 0, 0, 1)

		_FogColor("Fog Color", Color) = (0, 0, 0, 1)
		_FogClouds("Fog Amount Clouds", Float) = 0.001
		_FogSky("Fog Amount Sky", Float) = 0.1
		_FogGround("Fog Amount Ground", Float) = 0.1
    }
    SubShader
    {
		Tags {
            "Queue" = "Background"
            "RenderType" = "Background"
            "PreviewType" = "Skybox"
        }
		Cull Off ZWrite Off

        HLSLINCLUDE
    	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // This can't be set as a property because the for loop needs to be unrolled
		#define SAMPLES 50

        TEXTURE2D(_CloudTex); SAMPLER(sampler_CloudTex);
		TEXTURE2D(_GradientTex); SAMPLER(sampler_GradientTex);

		float _CloudHeight;
		float _CloudThickness;
		float _TopSurfaceScale;
		float _BottomSurfaceScale;
		float _TurbulenceScale;
		float4 _CloudScale;
		float _CloudOpacity;
		float _CloudSoftness;
		float4 _CloudSpeed;

		float4 _SkyColor;
		float4 _GroundColor;

		float4 _FogColor;
		float _FogClouds;
		float _FogSky;
		float _FogGround;

        struct appdata
        {
            float4 vertex : POSITION;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
			float3 viewVector : TEXCOORD1;
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
                o.vertex = TransformObjectToHClip(v.vertex);
                o.viewVector = v.vertex.xyz;
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 viewVector = i.viewVector;

                if (viewVector.y > 0)
                {
                    // SKY
                    viewVector = viewVector / viewVector.y;
                    float3 viewerPosition = _WorldSpaceCameraPos;

                    // transpose view position to height _CloudHeight
                    float3 position = viewerPosition + viewVector * (_CloudHeight - viewerPosition.y);

                    // move amount between samples
                    float3 stepSize = viewVector * _CloudThickness / SAMPLES;
                    // make larger steps more opaque
                    float stepOpacity = 1 - (1 / (_CloudOpacity * length(stepSize) + 1));

                    // The fog in front of the clouds is added first
                    float cloudFog = 1 - (1 / (_FogClouds * length(viewVector) + 1));
                    float4 col = float4(_FogColor.rgb * cloudFog, cloudFog);

                    for (int i = 0; i < SAMPLES; i++)
                    {
                        position += stepSize;

                        float2 uv = (position.xz + _CloudSpeed.xy * _Time[1]) / _CloudScale.xy;
                        float h = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uv).r;

                        // Get two additional heights for the turbulence on the top and bottom of the clouds
                        float2 uvt1 = (position.xz + _CloudSpeed.zw * _Time[1]) / _CloudScale.zw;
                        float2 uvt2 = uvt1;
                        uvt2.y += 0.5;
                        float ht1 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uvt1).r;
                        float ht2 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uvt2).r;

                        float cloudTopHeight = 1 - (h * _TopSurfaceScale + ht1 * _TurbulenceScale);
                        float cloudBottomHeight = h * _BottomSurfaceScale + ht2 * _TurbulenceScale;

                        float f = (position.y - _CloudHeight) / _CloudThickness;
                        if (f > cloudBottomHeight && f < cloudTopHeight)
                        {
                            float cloudTopHeightSmooth = 1 - (h * _TopSurfaceScale);
                            float cloudDarkness = 1 - saturate(cloudTopHeightSmooth - f);
                            float4 cloudColor = SAMPLE_TEXTURE2D(_GradientTex, sampler_GradientTex, float2(cloudDarkness, 0));

                            float distanceToSurface = min(cloudTopHeight - f, f - cloudBottomHeight);
                            float localOpacity = saturate(distanceToSurface / _CloudSoftness);

                            col += (1 - col.a) * stepOpacity * localOpacity * cloudColor;
                            if (col.a > 0.99) // almost opaque: stop marching
                            {
                                col.rgb *= 1 / col.a;
                                col.a = 1;
                                break;
                            }
                        }
                    }

                    float skyFog = 1 - (1 / (_FogSky * length(viewVector) + 1));
                    float4 totalSkyColor = lerp(_SkyColor, _FogColor, skyFog);
                    col += (1 - col.a) * totalSkyColor;

                    return col;
                }
                else if (viewVector.y < 0)
                {
                    // GROUND
                    viewVector = viewVector / viewVector.y;
                    float groundFog = 1 - (1/ (_FogGround * length(viewVector) + 1));
                    return lerp(_GroundColor, _FogColor, groundFog);
                }
                else
                {
                    // HORIZON
                    return _FogColor;
                }
            }
            ENDHLSL
        }
    }
}