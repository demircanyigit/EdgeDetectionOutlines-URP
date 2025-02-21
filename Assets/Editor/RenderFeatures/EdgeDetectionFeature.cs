using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class EdgeDetectionFeature : ScriptableRendererFeature
{
    public enum EdgeDetectionType
    {
        Sobel = 0,
        Prewitt = 1,
        RobertsClassic = 2,
        Scharr = 3,
        CustomLaplacian = 4,
        RobertsCrossGradient = 5,
        RobertsCrossExtended = 6
    }

    [System.Serializable]
    public class EdgeDetectionSettings
    {
        public RenderPassEvent injectionPoint = RenderPassEvent.BeforeRenderingPostProcessing;
        public Color edgeColor = Color.black;
        
        public bool useDepthEdges = true;
        public EdgeDetectionType depthEdgeDetectionType = EdgeDetectionType.Sobel;
        [Range(0, 1f)] public float depthThreshold = 0.1f; // Changed from smoothMin/Max to single threshold
        
        public bool useNormalEdges = true;
        public EdgeDetectionType normalEdgeDetectionType = EdgeDetectionType.Sobel;
        [Range(0, 1f)] public float normalThreshold = 0.1f; // Changed from smoothMin/Max to single threshold
        
        public bool useDiffuseEdges = true;
        public EdgeDetectionType diffuseEdgeDetectionType = EdgeDetectionType.Sobel;
        [Range(0, 1f)] public float diffuseThreshold = 0.1f;
        
        public bool useDiffuseHue = false;
        [Range(0, 1f)] public float diffuseIntensity = 1.0f;
        public bool applyToReflections = true;
    }

    [SerializeField] public EdgeDetectionSettings settings = new EdgeDetectionSettings();
    [SerializeField] public Shader edgeDetectionShader;
    private Material edgeDetectionMaterial;
    private EdgeDetectionPass edgeDetectionPass;

    [SerializeField]
    private CameraType cameraType = CameraType.Game | CameraType.SceneView;

    public override void Create()
    {
        if (edgeDetectionShader == null) return;
        edgeDetectionMaterial = CoreUtils.CreateEngineMaterial(edgeDetectionShader);
        if (edgeDetectionMaterial != null)
            edgeDetectionPass = new EdgeDetectionPass(edgeDetectionMaterial, settings);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!RendererFeatureHelper.CameraTypeMatches(cameraType, renderingData.cameraData.cameraType))
            return;

        if (renderingData.cameraData.cameraType == CameraType.Preview || 
            (!settings.applyToReflections && renderingData.cameraData.cameraType == CameraType.Reflection))
            return;
        
        if (edgeDetectionMaterial == null) return;
        edgeDetectionPass.ConfigureInput(ScriptableRenderPassInput.Normal | ScriptableRenderPassInput.Depth);
        renderer.EnqueuePass(edgeDetectionPass);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(edgeDetectionMaterial);
        edgeDetectionPass?.Dispose();
    }
}