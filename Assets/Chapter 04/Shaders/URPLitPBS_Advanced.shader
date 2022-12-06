// Example Shader for Universal RP
// Written by @Cyanilux
// https://www.cyanilux.com/tutorials/urp-shader-code

Shader "Custom/URP Lit PBS (Advanced)" {
	Properties {
		// Sorry the inspector is a little messy, but I'd rather not rely on a Custom ShaderGUI
		// or the one used by the Lit/Shader, as then adding new properties won't show
		// Tried to organise it somewhat, with spacing to help separate related parts.

		[MainTexture] _BaseMap("Base Map (RGB) Smoothness / Alpha (A)", 2D) = "white" {}
		[MainColor]   _BaseColor("Base Color", Color) = (1, 1, 1, 1)

		[Space(20)]
		[Toggle(_ALPHATEST_ON)] _AlphaClipToggle ("Alpha Clipping", Float) = 0
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5

		[Space(20)]
		[Toggle(_SPECULAR_SETUP)] _MetallicSpecToggle ("Workflow, Specular (if on), Metallic (if off)", Float) = 0
		[Toggle(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)] _SmoothnessSource ("Smoothness Source, Albedo Alpha (if on) vs Metallic (if off)", Float) = 0
		_Metallic("Metallic", Range(0.0, 1.0)) = 0
		_Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
		[Toggle(_METALLICSPECGLOSSMAP)] _MetallicSpecGlossMapToggle ("Use Metallic/Specular Gloss Map", Float) = 0
		_MetallicSpecGlossMap("Specular or Metallic Map", 2D) = "black" {}
		// Usually this is split into _SpecGlossMap and _MetallicGlossMap, but I find
		// that a bit annoying as I'm not using a custom ShaderGUI to show/hide them.

		[Space(20)]
		[Toggle(_NORMALMAP)] _NormalMapToggle ("Use Normal Map", Float) = 0
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1

		// Not including Height (parallax) map in this example/template

		[Space(20)]
		[Toggle(_OCCLUSIONMAP)] _OcclusionToggle ("Use Occlusion Map", Float) = 0
		[NoScaleOffset] _OcclusionMap("Occlusion Map", 2D) = "bump" {}
		_OcclusionStrength("Occlusion Strength", Range(0.0, 1.0)) = 1.0

		[Space(20)]
		[Toggle(_EMISSION)] _Emission ("Emission", Float) = 0
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap("Emission Map", 2D) = "black" {}

		[Space(20)]
		[Toggle(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("Turn Specular Highlights Off", Float) = 0
		[Toggle(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentalReflections("Turn Environmental Reflections Off", Float) = 0
		// These are inverted fom what the URP/Lit shader does which is a bit annoying.
		// They would usually be handled by the Lit ShaderGUI but I'm using Toggle instead,
		// which assumes the keyword is more of an "on" state.

		// Not including Detail maps in this template
	}
	SubShader {
		Tags {
			"RenderPipeline"="UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry"
		}

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		float4 _BaseColor;
		float4 _BaseMap_ST;
		float4 _EmissionColor;
		float4 _SpecColor;
		float _Metallic;
		float _Smoothness;
		float _OcclusionStrength;
		float _Cutoff;
		float _BumpScale;
		ENDHLSL

		Pass {
			Name "ForwardLit"
			Tags { "LightMode"="UniversalForward" }

			HLSLPROGRAM
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			// ---------------------------------------------------------------------------
			// Keywords
			// ---------------------------------------------------------------------------

			// Material Keywords
			#pragma shader_feature_local _NORMALMAP
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local_fragment _EMISSION
			#pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			#pragma shader_feature_local_fragment _OCCLUSIONMAP

			#pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
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
			// InputData
			// ---------------------------------------------------------------------------
			
			#if SHADER_LIBRARY_VERSION_MAJOR < 9
			// These functions were added in URP v9.x versions, if we want to support URP versions before, we need to handle it
			// If you're in v10, should be safe to remove this if you don't care about supporting prior versions.
			// (Note, also using GetWorldSpaceViewDir in Vertex Shader)

			// Computes the world space view direction (pointing towards the viewer).
			float3 GetWorldSpaceViewDir(float3 positionWS) {
				if (unity_OrthoParams.w == 0) {
					// Perspective
					return _WorldSpaceCameraPos - positionWS;
				} else {
					// Orthographic
					float4x4 viewMat = GetWorldToViewMatrix();
					return viewMat[2].xyz;
				}
			}

			half3 GetWorldSpaceNormalizeViewDir(float3 positionWS) {
				float3 viewDir = GetWorldSpaceViewDir(positionWS);
				if (unity_OrthoParams.w == 0) {
					// Perspective
					return half3(normalize(viewDir));
				} else {
					// Orthographic
					return half3(viewDir);
				}
			}
			#endif

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
			// SurfaceData
			// ---------------------------------------------------------------------------
			// (note, BaseMap, BumpMap and EmissionMap is being defined by the SurfaceInput.hlsl include)
			TEXTURE2D(_MetallicSpecGlossMap); 	SAMPLER(sampler_MetallicSpecGlossMap);
			TEXTURE2D(_OcclusionMap); 			SAMPLER(sampler_OcclusionMap);

			half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha) {
				half4 specGloss;
				#ifdef _METALLICSPECGLOSSMAP
					specGloss = SAMPLE_TEXTURE2D(_MetallicSpecGlossMap, sampler_MetallicSpecGlossMap, uv);
					#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
						specGloss.a = albedoAlpha * _Smoothness;
					#else
						specGloss.a *= _Smoothness;
					#endif
				#else
					#if _SPECULAR_SETUP
						specGloss.rgb = _SpecColor.rgb;
					#else
						specGloss.rgb = _Metallic.rrr;
					#endif

					#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
						specGloss.a = albedoAlpha * _Smoothness;
					#else
						specGloss.a = _Smoothness;
					#endif
				#endif
				return specGloss;
			}

			half SampleOcclusion(float2 uv) {
				#ifdef _OCCLUSIONMAP
				#if defined(SHADER_API_GLES)
					return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
				#else
					half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
					return LerpWhiteTo(occ, _OcclusionStrength);
				#endif
				#else
					return 1.0;
				#endif
			}

			void InitializeSurfaceData(Varyings IN, out SurfaceData surfaceData){
				surfaceData = (SurfaceData)0; // avoids "not completely initalized" errors

				half4 albedoAlpha = SampleAlbedoAlpha(IN.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
				surfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);
				surfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

				surfaceData.normalTS = SampleNormal(IN.uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
				surfaceData.emission = SampleEmission(IN.uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
				surfaceData.occlusion = SampleOcclusion(IN.uv);
	
				half4 specGloss = SampleMetallicSpecGloss(IN.uv, albedoAlpha.a);
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
			// Vertex Shader
			// ---------------------------------------------------------------------------

			Varyings LitPassVertex(Attributes IN) {
				Varyings OUT;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
				#ifdef _NORMALMAP
					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz, IN.tangentOS);
				#else
					VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normalOS.xyz);
				#endif

				OUT.positionCS = positionInputs.positionCS;
				OUT.positionWS = positionInputs.positionWS;

				half3 viewDirWS = GetWorldSpaceViewDir(positionInputs.positionWS);
				half3 vertexLight = VertexLighting(positionInputs.positionWS, normalInputs.normalWS);
				
				#ifdef _NORMALMAP
					OUT.normalWS = half4(normalInputs.normalWS, viewDirWS.x);
					OUT.tangentWS = half4(normalInputs.tangentWS, viewDirWS.y);
					OUT.bitangentWS = half4(normalInputs.bitangentWS, viewDirWS.z);
				#else
					OUT.normalWS = NormalizeNormalPerVertex(normalInputs.normalWS);
				#endif

				OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapUV);
				OUTPUT_SH(OUT.normalWS.xyz, OUT.vertexSH);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					OUT.shadowCoord = GetShadowCoord(positionInputs);
				#endif

				OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
				return OUT;
			}

			// ---------------------------------------------------------------------------
			// Fragment Shader
			// ---------------------------------------------------------------------------
			
			half4 LitPassFragment(Varyings IN) : SV_Target {
				// Setup SurfaceData
				SurfaceData surfaceData;
				InitializeSurfaceData(IN, surfaceData);

				// Setup InputData
				InputData inputData;
				InitializeInputData(IN, surfaceData.normalTS, inputData);

				// Simple Lighting (Lambert & BlinnPhong)
				half4 color = UniversalFragmentPBR(inputData, surfaceData);
				return color;
			}
			ENDHLSL
		}

		// ShadowCaster, for casting shadows
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual

			HLSLPROGRAM
			#pragma vertex ShadowPassVertex
			#pragma fragment ShadowPassFragment

			// Material Keywords
			#pragma shader_feature_local_fragment _ALPHATEST_ON
			#pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			// Universal Pipeline Keywords
			// (v11+) This is used during shadow map generation to differentiate between directional and punctual (point/spot) light shadows, as they use different formulas to apply Normal Bias
			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"

			ENDHLSL
		}
	}
}
