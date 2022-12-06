// Adapted from an example by @Cyanilux:
// https://www.cyanilux.com/tutorials/urp-shader-code

Shader "Custom/URP Lit PBS" {
	Properties {
		[MainTexture] _BaseMap("Base Map (RGB) Smoothness / Alpha (A)", 2D) = "white" {}
		[MainColor]   _BaseColor("Base Color", Color) = (1, 1, 1, 1)

		[Space(20)]
		[Toggle(_ALPHATEST_ON)] _AlphaClipToggle ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5

		[Space(20)]
		[Toggle(_SPECULAR_SETUP)] _MetallicSpecToggle ("Workflow: Specular (if on) or Metallic (if off)", Float) = 0
		_SpecGloss("Specular Gloss", Range(0, 1)) = 0.5
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
		_Metallic("Metallic", Range(0, 1)) = 0
		[Toggle(_METALLICSPECGLOSSMAP)] _MetallicSpecMapToggle ("Use Metallic/Specular Map", Float) = 0
		_MetallicSpecMap("Metallic/Specular Map", 2D) = "black" {}

		[Space(20)]
		[Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Float) = 0
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		[Space(20)]
		[Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
		[NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "bump" {}
		_OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		TEXTURE2D(_MetallicSpecMap); SAMPLER(sampler_MetallicSpecMap);
		TEXTURE2D(_OcclusionMap);    SAMPLER(sampler_OcclusionMap);

		float4 _BaseColor;
		float4 _BaseMap_ST;
		float _Cutoff;
		float _SpecGloss;
		float4 _SpecColor;
		float _Metallic;
		float _BumpScale;
		float _OcclusionStrength;
		ENDHLSL

		Pass {
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			// ---------------------------------------------------------------------------
			// Keywords
			// ---------------------------------------------------------------------------

			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _OCCLUSIONMAP
			#pragma shader_feature_local_fragment _SPECULAR_SETUP
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF

			// URP Keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile_fragment _ _SHADOWS_SOFT
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION // (SSAO support)
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK

			// Unity Keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED

			// ---------------------------------------------------------------------------
			// Structs
			// ---------------------------------------------------------------------------

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

			struct Attributes {
				float4 positionOS	: POSITION;
				#ifdef _NORMALMAP
					float4 tangentOS 	: TANGENT;
				#endif
				float4 normalOS		: NORMAL;
				float2 uv		    : TEXCOORD0;
				float2 lightmapUV	: TEXCOORD1;
			};

			struct Varyings {
				float4 positionCS 					: SV_POSITION; // CS: clip space
				float3 positionWS					: TEXCOORD0;   // WS: world space
				float2 uv		    				: TEXCOORD1;

				#ifdef _NORMALMAP
					half4 normalWS					: TEXCOORD2;
					half4 tangentWS					: TEXCOORD3;
					half4 bitangentWS				: TEXCOORD4;
				#else
					half3 normalWS					: TEXCOORD2;
				#endif

				DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 5);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					float4 shadowCoord 				: TEXCOORD6;
				#endif
			};

			// ---------------------------------------------------------------------------
			// SurfaceData
			// ---------------------------------------------------------------------------
			half SampleOcclusion(float2 uv) {
				#ifdef _OCCLUSIONMAP
					half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
					return LerpWhiteTo(occ, _OcclusionStrength);
				#else
					return 1.0;
				#endif
			}

			half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha) {
				half4 specGloss;
				#ifdef _METALLICSPECGLOSSMAP
					specGloss = SAMPLE_TEXTURE2D(_MetallicSpecMap, sampler_MetallicSpecMap, uv);
					specGloss.a *= _SpecGloss;
				#else
					#if _SPECULAR_SETUP
						specGloss.rgb = _SpecColor.rgb;
					#else
						specGloss.rgb = _Metallic.rrr;
					#endif

					specGloss.a = _SpecGloss;
				#endif
				return specGloss;
			}

			void InitializeSurfaceData(Varyings i, out SurfaceData surfaceData){
				surfaceData = (SurfaceData)0; // avoids "not completely initalized" errors

				half4 albedoAlpha = SampleAlbedoAlpha(i.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
				surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
				surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

				surfaceData.normalTS = SampleNormal(i.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);

				surfaceData.occlusion = SampleOcclusion(i.uv);
	
				half4 specGloss = SampleMetallicSpecGloss(i.uv, albedoAlpha.a);
				#if _SPECULAR_SETUP
					surfaceData.metallic = 1.0h;
					surfaceData.specular = specGloss.rgb;
				#else
					surfaceData.metallic = specGloss.r;
					surfaceData.specular = half3(0.0h, 0.0h, 0.0h);
				#endif
				surfaceData.smoothness = specGloss.a;
			}

			// ---------------------------------------------------------------------------
			// InputData
			// ---------------------------------------------------------------------------
			void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData) {
				inputData = (InputData)0; // avoids "not completely initalized" errors

				inputData.positionWS = input.positionWS;

				#ifdef _NORMALMAP
					half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
					inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
				#else
					half3 viewDirWS = GetWorldSpaceNormalizeViewDir(inputData.positionWS);
					inputData.normalWS = input.normalWS;
				#endif

				inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);

				viewDirWS = SafeNormalize(viewDirWS);
				inputData.viewDirectionWS = viewDirWS;

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					inputData.shadowCoord = input.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
				#else
					inputData.shadowCoord = float4(0, 0, 0, 0);
				#endif

				inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
				inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
			}

			// ---------------------------------------------------------------------------
			// Vertex Shader
			// ---------------------------------------------------------------------------

			Varyings vert(Attributes i) {
				Varyings v;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(i.positionOS.xyz);
				#ifdef _NORMALMAP
					VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
				#else
					VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz);
				#endif

				v.positionCS = positionInputs.positionCS;
				v.positionWS = positionInputs.positionWS;

				half3 viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
				half3 vertexLight = VertexLighting(positionInputs.positionWS, normalInputs.normalWS);
				
				#ifdef _NORMALMAP
					v.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
					v.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
					v.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);
				#else
					v.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
				#endif

				OUTPUT_LIGHTMAP_UV(i.lightmapUV, unity_LightmapST, v.lightmapUV);
				OUTPUT_SH(v.normalWS.xyz, v.vertexSH);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					v.shadowCoord = GetShadowCoord(positionInputs);
				#endif

				v.uv = TRANSFORM_TEX(i.uv, _BaseMap);
				return v;
			}

			// ---------------------------------------------------------------------------
			// Fragment Shader
			// ---------------------------------------------------------------------------
			
			half4 frag(Varyings i) : SV_Target {
				SurfaceData surfaceData;
				InitializeSurfaceData(i, surfaceData);

				InputData inputData;
				InitializeInputData(i, surfaceData.normalTS, inputData);

				half4 color = UniversalFragmentPBR(inputData, surfaceData);
				return color;
			}
			ENDHLSL
		}
	}
}
