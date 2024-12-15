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



    float ProcessEdge(float edge, float minValue, float maxValue)
    {
        // Use a simple threshold instead of smooth transitions
        return edge > minValue ? 1.0 : 0.0;
    }

    float GetDepthEdge(float2 uv)
    {
        if (!_UseDepthEdges) return 0;
        float2 texelSize = _BlitTexture_TexelSize.xy;
        float d = SampleSceneDepth(uv);
        if (d >= 0.99999f) return 0;
        
        float d1 = SampleSceneDepth(uv + float2(-texelSize.x, -texelSize.y));
        float d2 = SampleSceneDepth(uv + float2(-texelSize.x, 0));
        float d3 = SampleSceneDepth(uv + float2(-texelSize.x, texelSize.y));
        float d4 = SampleSceneDepth(uv + float2(0, -texelSize.y));
        float d5 = SampleSceneDepth(uv + float2(0, texelSize.y));
        float d6 = SampleSceneDepth(uv + float2(texelSize.x, -texelSize.y));
        float d7 = SampleSceneDepth(uv + float2(texelSize.x, 0));
        float d8 = SampleSceneDepth(uv + float2(texelSize.x, texelSize.y));
        
        float2 grad;
        GetGradient(d1, d4, d6, d2, d, d7, d3, d5, d8, _DepthEdgeDetectionType, false, grad);
        float depthEdge = length(grad);
        return ProcessEdge(depthEdge, _DepthSmoothMin, _DepthSmoothMax);
    }

    float GetNormalEdge(float2 uv)
    {
        if (!_UseNormalEdges) return 0;
        float depth = SampleSceneDepth(uv);
        if (depth >= 0.99999f) return 0;
        
        float2 texelSize = _BlitTexture_TexelSize.xy * 0.5;
        float3 c = GetWorldSpaceNormal(uv);
        float3 n1 = GetWorldSpaceNormal(uv + float2(-texelSize.x, -texelSize.y));
        float3 n2 = GetWorldSpaceNormal(uv + float2(-texelSize.x, 0));
        float3 n3 = GetWorldSpaceNormal(uv + float2(-texelSize.x, texelSize.y));
        float3 n4 = GetWorldSpaceNormal(uv + float2(0, -texelSize.y));
        float3 n5 = GetWorldSpaceNormal(uv + float2(0, texelSize.y));
        float3 n6 = GetWorldSpaceNormal(uv + float2(texelSize.x, -texelSize.y));
        float3 n7 = GetWorldSpaceNormal(uv + float2(texelSize.x, 0));
        float3 n8 = GetWorldSpaceNormal(uv + float2(texelSize.x, texelSize.y));
        
        float v1 = 1 - abs(dot(normalize(c), normalize(n1)));
        float v2 = 1 - abs(dot(normalize(c), normalize(n2)));
        float v3 = 1 - abs(dot(normalize(c), normalize(n3)));
        float v4 = 1 - abs(dot(normalize(c), normalize(n4)));
        float v5 = 1 - abs(dot(normalize(c), normalize(n5)));
        float v6 = 1 - abs(dot(normalize(c), normalize(n6)));
        float v7 = 1 - abs(dot(normalize(c), normalize(n7)));
        float v8 = 1 - abs(dot(normalize(c), normalize(n8)));
        
        float2 grad;
        float vc = 0;
        GetGradient(v1, v4, v6, v2, vc, v7, v3, v5, v8, _NormalEdgeDetectionType, true, grad);
        float normalEdge = length(grad);
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