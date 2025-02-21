using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionPass : ScriptableRenderPass
{
    private readonly Material material;
    private RTHandle sourceColorHandle;
    private RTHandle tempColorTarget;
    private EdgeDetectionFeature.EdgeDetectionSettings settings;
    private static readonly int ColorId = Shader.PropertyToID("_EdgeColor");
    private static readonly int UseDepthId = Shader.PropertyToID("_UseDepthEdges");
    private static readonly int DepthEdgeTypeId = Shader.PropertyToID("_DepthEdgeDetectionType");
    private static readonly int DepthSmoothMinId = Shader.PropertyToID("_DepthSmoothMin");
    private static readonly int UseNormalId = Shader.PropertyToID("_UseNormalEdges");
    private static readonly int NormalEdgeTypeId = Shader.PropertyToID("_NormalEdgeDetectionType");
    private static readonly int NormalSmoothMinId = Shader.PropertyToID("_NormalSmoothMin");
    private static readonly int UseDiffuseId = Shader.PropertyToID("_UseDiffuseEdges");
    private static readonly int DiffuseEdgeTypeId = Shader.PropertyToID("_DiffuseEdgeDetectionType");
    private static readonly int DiffuseSmoothMinId = Shader.PropertyToID("_DiffuseSmoothMin");
    private static readonly int UseDiffuseHueId = Shader.PropertyToID("_UseDiffuseHue");
    private static readonly int DiffuseIntensityId = Shader.PropertyToID("_DiffuseIntensity");

    public EdgeDetectionPass(Material material, EdgeDetectionFeature.EdgeDetectionSettings settings)
    {
        this.material = material;
        this.settings = settings;
        this.renderPassEvent = settings.injectionPoint;
        profilingSampler = new ProfilingSampler("Edge Detection");
    }

    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        var descriptor = renderingData.cameraData.cameraTargetDescriptor;
        descriptor.depthBufferBits = 0;
        sourceColorHandle = renderingData.cameraData.renderer.cameraColorTargetHandle;
        RenderingUtils.ReAllocateIfNeeded(ref tempColorTarget, descriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name: "_TempColorTarget");
        ConfigureInput(ScriptableRenderPassInput.Normal | ScriptableRenderPassInput.Depth | ScriptableRenderPassInput.Color);
    }

    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        if (!material || !sourceColorHandle.rt) return;
        
        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, profilingSampler))
        {
            UpdateMaterialProperties(cmd);
            Blitter.BlitCameraTexture(cmd, sourceColorHandle, tempColorTarget, material, 0);
            Blitter.BlitCameraTexture(cmd, tempColorTarget, sourceColorHandle);
        }
        
        context.ExecuteCommandBuffer(cmd);
        CommandBufferPool.Release(cmd);
    }

    private void UpdateMaterialProperties(CommandBuffer cmd)
    {
        material.SetColor(ColorId, settings.edgeColor);
        
        material.SetInt(UseDepthId, settings.useDepthEdges ? 1 : 0);
        material.SetInt(DepthEdgeTypeId, (int)settings.depthEdgeDetectionType);
        material.SetFloat(DepthSmoothMinId, settings.depthThreshold);
        
        material.SetInt(UseNormalId, settings.useNormalEdges ? 1 : 0);
        material.SetInt(NormalEdgeTypeId, (int)settings.normalEdgeDetectionType);
        material.SetFloat(NormalSmoothMinId, settings.normalThreshold);
        
        material.SetInt(UseDiffuseId, settings.useDiffuseEdges ? 1 : 0);
        material.SetInt(DiffuseEdgeTypeId, (int)settings.diffuseEdgeDetectionType);
        material.SetFloat(DiffuseSmoothMinId, settings.diffuseThreshold);
        material.SetInt(UseDiffuseHueId, settings.useDiffuseHue ? 1 : 0);
        material.SetFloat(DiffuseIntensityId, settings.diffuseIntensity);
    }

    public void Dispose()
    {
        tempColorTarget?.Release();
    }
}