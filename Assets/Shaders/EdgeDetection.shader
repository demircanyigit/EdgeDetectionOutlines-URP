Shader "Hidden/Custom/EdgeDetection"
{
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
    #include "EdgeDetectionTypes.hlsl"
    
    float4 _EdgeColor;
    float4 _BlitTexture_TexelSize;
    int _UseDepthEdges;
    int _DepthEdgeDetectionType;
    float _DepthSmoothMin;
    float _DepthSmoothMax;
    int _UseNormalEdges;
    int _NormalEdgeDetectionType;
    float _NormalSmoothMin;
    float _NormalSmoothMax;
    float _EdgePower;
    int _EdgeControlType;
    float _ExponentialFactor;
    TEXTURE2D(_EdgeControlCurve);
    SAMPLER(sampler_EdgeControlCurve);

    float3 GetWorldSpaceNormal(float2 uv)
    {
        float3 viewNormal = SampleSceneNormals(uv);
        // Use the existing unity_MatrixV to transform from view to world space
        float3 worldNormal = mul(transpose((float3x3)unity_MatrixV), viewNormal);
        return normalize(worldNormal);
    }

    float3 GetViewDirection(float2 uv, float depth)
    {
        // Convert screen position to world position
        float2 screenUV = uv * 2.0 - 1.0;
        float4 clipPos = float4(screenUV, depth, 1.0);
        float4 viewPos = mul(unity_CameraInvProjection, clipPos);
        viewPos = viewPos / viewPos.w;
        return normalize(-viewPos.xyz);
    }

    float ProcessEdge(float edge, float minValue, float maxValue)
    {
        // Smooth step for more consistent edge thickness
        return smoothstep(minValue * 0.5, minValue * 1.5, edge);
    }

    float GetDepthEdge(float2 uv)
    {
        if (!_UseDepthEdges) return 0;
        float2 texelSize = _BlitTexture_TexelSize.xy;
        float d = SampleSceneDepth(uv);
        if (d >= 0.99999f) return 0;
        
        float linearDepth = LinearEyeDepth(d, _ZBufferParams);
        
        // Get view direction and normal for edge masking
        float3 viewDir = GetViewDirection(uv, d);
        float3 normal = GetWorldSpaceNormal(uv);
        float ndotv = abs(dot(normal, viewDir));
        
        // Sample neighboring depths and convert to linear space
        float d1 = LinearEyeDepth(SampleSceneDepth(uv + float2(-texelSize.x, -texelSize.y)), _ZBufferParams);
        float d2 = LinearEyeDepth(SampleSceneDepth(uv + float2(-texelSize.x, 0)), _ZBufferParams);
        float d3 = LinearEyeDepth(SampleSceneDepth(uv + float2(-texelSize.x, texelSize.y)), _ZBufferParams);
        float d4 = LinearEyeDepth(SampleSceneDepth(uv + float2(0, -texelSize.y)), _ZBufferParams);
        float d5 = LinearEyeDepth(SampleSceneDepth(uv + float2(0, texelSize.y)), _ZBufferParams);
        float d6 = LinearEyeDepth(SampleSceneDepth(uv + float2(texelSize.x, -texelSize.y)), _ZBufferParams);
        float d7 = LinearEyeDepth(SampleSceneDepth(uv + float2(texelSize.x, 0)), _ZBufferParams);
        float d8 = LinearEyeDepth(SampleSceneDepth(uv + float2(texelSize.x, texelSize.y)), _ZBufferParams);
        
        // Normalize depths relative to center depth and scale down the differences
        float scale = 0.5 * ndotv; // Scale based on view angle
        d1 = abs(d1 - linearDepth) * scale;
        d2 = abs(d2 - linearDepth) * scale;
        d3 = abs(d3 - linearDepth) * scale;
        d4 = abs(d4 - linearDepth) * scale;
        d5 = abs(d5 - linearDepth) * scale;
        d6 = abs(d6 - linearDepth) * scale;
        d7 = abs(d7 - linearDepth) * scale;
        d8 = abs(d8 - linearDepth) * scale;
        
        float2 grad;
        GetGradient(d1, d4, d6, d2, 0, d7, d3, d5, d8, _DepthEdgeDetectionType, false, grad);
        float depthEdge = length(grad);
        
        // Adjust depth scale for Roberts Cross methods
        float depthScale = 1.0;
        if (_DepthEdgeDetectionType >= 2 && _DepthEdgeDetectionType <= 6)
        {
            depthScale = 1.0 / (linearDepth * 0.05 + 1.0);
        }
        else
        {
            depthScale = 1.0 / (linearDepth * 0.1 + 1.0);
        }
        depthEdge *= depthScale;
        
        return ProcessEdge(depthEdge, _DepthSmoothMin, _DepthSmoothMax);
    }

    float GetNormalEdge(float2 uv)
    {
        if (!_UseNormalEdges) return 0;
        float depth = SampleSceneDepth(uv);
        if (depth >= 0.99999f) return 0;
        
        float2 texelSize = _BlitTexture_TexelSize.xy;
        float3 c = GetWorldSpaceNormal(uv);
        float3 n1 = GetWorldSpaceNormal(uv + float2(-texelSize.x, -texelSize.y));
        float3 n2 = GetWorldSpaceNormal(uv + float2(-texelSize.x, 0));
        float3 n3 = GetWorldSpaceNormal(uv + float2(-texelSize.x, texelSize.y));
        float3 n4 = GetWorldSpaceNormal(uv + float2(0, -texelSize.y));
        float3 n5 = GetWorldSpaceNormal(uv + float2(0, texelSize.y));
        float3 n6 = GetWorldSpaceNormal(uv + float2(texelSize.x, -texelSize.y));
        float3 n7 = GetWorldSpaceNormal(uv + float2(texelSize.x, 0));
        float3 n8 = GetWorldSpaceNormal(uv + float2(texelSize.x, texelSize.y));
        
        float sensitivity = 2.0;
        float v1 = (1 - abs(dot(normalize(c), normalize(n1)))) * sensitivity;
        float v2 = (1 - abs(dot(normalize(c), normalize(n2)))) * sensitivity;
        float v3 = (1 - abs(dot(normalize(c), normalize(n3)))) * sensitivity;
        float v4 = (1 - abs(dot(normalize(c), normalize(n4)))) * sensitivity;
        float v5 = (1 - abs(dot(normalize(c), normalize(n5)))) * sensitivity;
        float v6 = (1 - abs(dot(normalize(c), normalize(n6)))) * sensitivity;
        float v7 = (1 - abs(dot(normalize(c), normalize(n7)))) * sensitivity;
        float v8 = (1 - abs(dot(normalize(c), normalize(n8)))) * sensitivity;
        
        float2 grad;
        float vc = 0;
        GetGradient(v1, v4, v6, v2, vc, v7, v3, v5, v8, _NormalEdgeDetectionType, true, grad);
        float normalEdge = length(grad);
        float linearDepth = LinearEyeDepth(depth, _ZBufferParams);
        float depthScale = 1.0 / (linearDepth * 0.1 + 1.0);
        normalEdge *= depthScale;
        
        return ProcessEdge(normalEdge, _NormalSmoothMin, _NormalSmoothMax);
    }
    
    float4 EdgeDetection(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
        float2 uv = input.texcoord;
        float4 baseColor = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv);
        float rawDepth = SampleSceneDepth(uv);
        if (rawDepth >= 0.99999f) return baseColor;
        
        float depthEdge = GetDepthEdge(uv);
        float normalEdge = GetNormalEdge(uv);
        
        float edge = max(depthEdge, normalEdge);
        return float4(lerp(baseColor.rgb, _EdgeColor.rgb, edge * _EdgeColor.a), baseColor.a);
    }
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always
        ZWrite Off 
        Cull Off
        Pass
        {
            Name "Edge Detection"
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment EdgeDetection
            ENDHLSL
        }
    }
}