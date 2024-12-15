#ifndef EDGE_DETECTION_TYPES_INCLUDED
#define EDGE_DETECTION_TYPES_INCLUDED

// ------------------------------------------------------------------------------------------------
// Edge Detection Kernels
// Each function implements a different edge detection algorithm
// Input: 3x3 kernel values (tl = top left, c = center, br = bottom right, etc.)
// Output: gradient vector (x, y)
// ------------------------------------------------------------------------------------------------

void Sobel(
    float tl, float t,  float tr,  // Top row
    float l,  float c,  float r,   // Middle row
    float bl, float b,  float br,  // Bottom row
    float scale,                   // Intensity scale
    out float2 grad                // Output gradient
) {
    // Horizontal and vertical gradients using Sobel operator
    grad.x = (-tl - 2.0 * l - bl + tr + 2.0 * r + br) * scale;
    grad.y = (-tl - 2.0 * t - tr + bl + 2.0 * b + br) * scale;
}

void Prewitt(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Similar to Sobel but with uniform weights
    grad.x = (-tl - l - bl + tr + r + br) * scale;
    grad.y = (-tl - t - tr + bl + b + br) * scale;
}

void RobertsClassic(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Classic Roberts Cross operator - diagonal differences
    grad.x = (br - tl) * scale;
    grad.y = (tr - bl) * scale;
}

void Scharr(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    out float2 grad
) {
    // Scharr operator - better rotational symmetry than Sobel
    grad.x = (-3.0 * tl - 10.0 * l - 3.0 * bl + 3.0 * tr + 10.0 * r + 3.0 * br) * scale;
    grad.y = (-3.0 * tl - 10.0 * t - 3.0 * tr + 3.0 * bl + 10.0 * b + 3.0 * br) * scale;
}

void CustomLaplacian(
    float tl, float t,  float tr,
    float l,  float c,  float r,
    float bl, float b,  float br,
    float scale,
    bool isNormal,  // Special handling for normal edges
    out float2 grad
) {
    if (isNormal)
    {
        // For normal edges, use weighted differences from center
        float weight = 0.4;        // Direct neighbor weight
        float diagWeight = 0.2;    // Diagonal neighbor weight
        
        float sum = 0;
        sum += (tl - c) * diagWeight;  // Top-left
        sum += (t  - c) * weight;      // Top
        sum += (tr - c) * diagWeight;  // Top-right
        sum += (l  - c) * weight;      // Left
        sum += (r  - c) * weight;      // Right
        sum += (bl - c) * diagWeight;  // Bottom-left
        sum += (b  - c) * weight;      // Bottom
        sum += (br - c) * diagWeight;  // Bottom-right
        
        grad = float2(sum, sum) * 2.0 * scale;
    }
    else
    {
        // For depth edges, use standard Laplacian
        float laplacian = (tl + 2.0 * t + tr + 
                          2.0 * l - 12.0 * c + 2.0 * r + 
                          bl + 2.0 * b + br) * scale;
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
    // Extended Roberts Cross using two diagonal pairs
    grad.x = (abs(c - bl) + abs(tr - l)) * 0.5 * scale;
    grad.y = (abs(l - b) + abs(t - br)) * 0.5 * scale;
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
            
        default:
            grad = float2(0, 0);
            break;
    }
}

#endif // EDGE_DETECTION_TYPES_INCLUDED