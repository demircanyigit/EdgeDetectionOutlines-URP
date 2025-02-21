#ifndef EDGE_DETECTION_TYPES_INCLUDED
#define EDGE_DETECTION_TYPES_INCLUDED

// ------------------------------------------------------------------------------------------------
// Edge Detection Kernels
// Each function implements a different edge detection algorithm
// Input: 3x3 kernel values (tl = top left, c = center, br = bottom right, etc.)
// Output: gradient vector (x, y)
// ------------------------------------------------------------------------------------------------

void Sobel(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Modified Sobel to detect center-aligned edges
    float gx = (tr + 2.0 * r + br - tl - 2.0 * l - bl) * 0.25;
    float gy = (bl + 2.0 * b + br - tl - 2.0 * t - tr) * 0.25;
    grad = float2(gx, gy) * scale;
}

void Prewitt(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Modified Prewitt for single-pixel edges
    float gx = (tr + r + br - tl - l - bl) * 0.33333;
    float gy = (bl + b + br - tl - t - tr) * 0.33333;
    grad = float2(gx, gy) * scale;
}

void RobertsClassic(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Modified Roberts Cross for single-pixel edges
    grad.x = (c - bl) * 0.7071 * scale;
    grad.y = (l - b) * 0.7071 * scale;
}

void Scharr(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Modified Scharr with better center alignment
    float gx = (3.0 * tr + 10.0 * r + 3.0 * br - 3.0 * tl - 10.0 * l - 3.0 * bl) * 0.0625;
    float gy = (3.0 * bl + 10.0 * b + 3.0 * br - 3.0 * tl - 10.0 * t - 3.0 * tr) * 0.0625;
    grad = float2(gx, gy) * scale;
}

void CustomLaplacian(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    bool isNormal,
    out float2 grad
) {
    if (isNormal)
    {
        // Adjusted weights for single-pixel normal edges
        float weight = 0.25;
        float diagWeight = 0.125;
        
        float sum = 0;
        sum += (tl - c) * diagWeight;
        sum += (t  - c) * weight;
        sum += (tr - c) * diagWeight;
        sum += (l  - c) * weight;
        sum += (r  - c) * weight;
        sum += (bl - c) * diagWeight;
        sum += (b  - c) * weight;
        sum += (br - c) * diagWeight;
        
        grad = float2(sum, sum) * scale;
    }
    else
    {
        // Modified Laplacian for single-pixel edges
        float laplacian = (tl + t + tr + l - 8.0 * c + r + bl + b + br) * 0.125 * scale;
        grad = float2(laplacian, laplacian);
    }
}

void RobertsCrossGradient(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Modified Roberts Cross using center pixel
    grad.x = (c - bl) * scale;
    grad.y = (l - b) * scale;
}

void RobertsCrossExtended(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Modified Extended Roberts Cross for single-pixel edges
    grad.x = (abs(c - bl) + abs(tr - l)) * 0.35355 * scale;
    grad.y = (abs(l - b) + abs(t - r)) * 0.35355 * scale;
}

float3 RGBtoHSV(float3 rgb)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(rgb.bg, K.wz), float4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    float4 q = lerp(float4(p.xyw, rgb.r), float4(rgb.r, p.yzx), step(p.x, rgb.r));
    
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float HueDifference(float3 color1, float3 color2)
{
    float3 hsv1 = RGBtoHSV(color1);
    float3 hsv2 = RGBtoHSV(color2);
    
    // Handle hue wrap-around
    float hueDiff = abs(hsv1.x - hsv2.x);
    hueDiff = min(hueDiff, 1.0 - hueDiff);
    
    // Weight the difference by saturation and value to reduce noise
    float saturationWeight = (hsv1.y + hsv2.y) * 0.5;
    float valueWeight = (hsv1.z + hsv2.z) * 0.5;
    return hueDiff * saturationWeight * valueWeight;
}

void DiffuseGradient(
    float3 tl, float3 t,  float3 tr,
    float3 l,  float3 c,  float3 r,
    float3 bl, float3 b,  float3 br,
    float scale,
    bool useHue,  // New parameter to switch between luminance and hue
    out float2 grad
) {
    if (useHue)
    {
        // Calculate hue differences from center
        float htl = HueDifference(c, tl);
        float ht = HueDifference(c, t);
        float htr = HueDifference(c, tr);
        float hl = HueDifference(c, l);
        float hr = HueDifference(c, r);
        float hbl = HueDifference(c, bl);
        float hb = HueDifference(c, b);
        float hbr = HueDifference(c, br);
        
        // Use Sobel operator on hue differences
        grad.x = (-htl - 2.0 * hl - hbl + htr + 2.0 * hr + hbr) * scale * 2.0;
        grad.y = (-htl - 2.0 * ht - htr + hbl + 2.0 * hb + hbr) * scale * 2.0;
    }
    else
    {
        // Original luminance-based edge detection
        float ltl = dot(tl, float3(0.299, 0.587, 0.114));
        float lt = dot(t, float3(0.299, 0.587, 0.114));
        float ltr = dot(tr, float3(0.299, 0.587, 0.114));
        float ll = dot(l, float3(0.299, 0.587, 0.114));
        float lc = dot(c, float3(0.299, 0.587, 0.114));
        float lr = dot(r, float3(0.299, 0.587, 0.114));
        float lbl = dot(bl, float3(0.299, 0.587, 0.114));
        float lb = dot(b, float3(0.299, 0.587, 0.114));
        float lbr = dot(br, float3(0.299, 0.587, 0.114));

        grad.x = (-ltl - 2.0 * ll - lbl + ltr + 2.0 * lr + lbr) * scale;
        grad.y = (-ltl - 2.0 * lt - ltr + lbl + 2.0 * lb + lbr) * scale;
    }
}

// ------------------------------------------------------------------------------------------------
// Main gradient calculation function
// Selects and applies the appropriate edge detection algorithm based on type parameter
// ------------------------------------------------------------------------------------------------

void GetGradient(
    float tl, float t,  float tr,   // Top row values
    float l,  float c,  float r,    // Middle row values
    float bl, float b,  float br,   // Bottom row values
    int type,                       // Edge detection algorithm type
    bool isNormal,                  // Whether we're processing normal edges
    out float2 grad                 // Output gradient
) {
    float scale = 1.0;
    
    switch(type)
    {
        case 0: // Sobel
            Sobel(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
            
        case 1: // Prewitt
            Prewitt(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
            
        case 2: // Roberts Classic
            RobertsClassic(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
            
        case 3: // Scharr
            Scharr(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
            
        case 4: // Custom Laplacian
            CustomLaplacian(tl, t, tr, l, c, r, bl, b, br, scale, isNormal, grad);
            break;
            
        case 5: // Roberts Cross Gradient
            RobertsCrossGradient(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
            
        case 6: // Roberts Cross Extended
            RobertsCrossExtended(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
            
        case 7: // Diffuse
            DiffuseGradient(tl, t, tr, l, c, r, bl, b, br, scale, isNormal, grad);
            break;
            
        default:
            grad = float2(0, 0);
            break;
    }
}

#endif // EDGE_DETECTION_TYPES_INCLUDED