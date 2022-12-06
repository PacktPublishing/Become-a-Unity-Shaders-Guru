Shader "Custom/BlinnPhong"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        [Toggle] _UseAmbient ("Use Ambient", Float) = 1
        _Gloss ("Gloss", Range(0, 1)) = 1
        [HideInInspector] _Metalness ("Metalness", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            // (required if the project is based on a
            // SRP render pipeline, to enforce a
            // Forward rendering-like behavior)
            Tags { "LightMode" = "ForwardBase" }

            //Blend SrcAlpha OneMinusSrcAlpha
            //ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            float4 _Color;
            float _UseAmbient;
            float _Gloss;
            float _Metalness;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = v.normal;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // get normalized normal for fragment
                float3 N = normalize(i.normal);
                // get (outgoing) light vector
                float3 L = _WorldSpaceLightPos0.xyz;
                // get view direction
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

                // diffuse lighting (Lambertian)
                float lambert = saturate(dot(N, L));
                float3 diffuseLight = lambert * _LightColor0.xyz;
                float3 diffuseColor = diffuseLight * _Color;

                // ambient lighting (direct from Unity settings)
                float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.xyz * (_UseAmbient > 0);

                // specular lighting (Blinn-Phong)
                float3 H = normalize(L + V);
                float3 specularLight = saturate(dot(N, H)) * (lambert > 0);
                float specularExponent = exp2(_Gloss * 8) + 2;
                specularLight = pow(specularLight, specularExponent) * _LightColor0.xyz;

                return float4(diffuseColor + ambientLight + specularLight, 1);
            }
            ENDCG
        }

        /*Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            Lighting On
            Blend One One
            ZWrite On
            ZTest LEqual

            CGPROGRAM
            #pragma vertex vertAdd
            #pragma fragment fragAdd

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #pragma multi_compile_fwdadd
            #pragma multi_compile_fwdadd_fullshadows

            float4 _Color;
            float _Gloss;
            float _Metalness;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };

            v2f vertAdd(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_LIGHTING(o, 0.0);
                return o;
            }

            float4 fragAdd(v2f i) : SV_Target
            {
                float3 N = normalize(i.normal);

                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                float3 L = normalize(lightDir);
                float atten = LIGHT_ATTENUATION(i);

                // diffuse lighting
                float3 lambert = saturate(dot(N, L));
                float3 diffuseLight = lambert * atten * _LightColor0.xyz;

                // specular lighting
                float3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 H = normalize(L + V);
                float specularLight = saturate(dot(H, N)) * (lambert > 0);
                float specularExponent = exp2(_Gloss * 8) + 2; // to remap from [0,1]
                specularLight = pow(specularLight, specularExponent);
                specularLight *= _Gloss; // to approximate energy conservation as in PBR

                specularLight *= _LightColor0.xyz;

                // combine lights
                float3 fullLight = diffuseLight * _Color;
                fullLight += specularLight * lerp(float3(1, 1, 1), _Color, _Metalness);
                return float4(fullLight, 1);
            }
            ENDCG

        }*/
    }
}
