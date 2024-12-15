#ifndef EDGE_DETECTION_TYPES_INCLUDED
#define EDGE_DETECTION_TYPES_INCLUDED

void Sobel(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, out float2 grad)
{
    grad.x = (-tl - 2.0 * l - bl + tr + 2.0 * r + br) * scale;
    grad.y = (-tl - 2.0 * t - tr + bl + 2.0 * b + br) * scale;
}

void Prewitt(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, out float2 grad)
{
    grad.x = (-tl - l - bl + tr + r + br) * scale;
    grad.y = (-tl - t - tr + bl + b + br) * scale;
}

void RobertsClassic(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, out float2 grad)
{
    grad.x = (br - tl) * scale;
    grad.y = (tr - bl) * scale;
}

void Scharr(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, out float2 grad)
{
    grad.x = (-3.0 * tl - 10.0 * l - 3.0 * bl + 3.0 * tr + 10.0 * r + 3.0 * br) * scale;
    grad.y = (-3.0 * tl - 10.0 * t - 3.0 * tr + 3.0 * bl + 10.0 * b + 3.0 * br) * scale;
}

void CustomLaplacian(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, bool isNormal, out float2 grad)
{
    if (isNormal)
    {
        float weight = 0.4;
        float diagonalWeight = 0.2;
        float sum = 0;
        sum += (tl - c) * diagonalWeight;
        sum += (t - c) * weight;
        sum += (tr - c) * diagonalWeight;
        sum += (l - c) * weight;
        sum += (r - c) * weight;
        sum += (bl - c) * diagonalWeight;
        sum += (b - c) * weight;
        sum += (br - c) * diagonalWeight;
        grad = float2(sum, sum) * 2.0 * scale;
    }
    else
    {
        float laplacian = (tl + 2.0 * t + tr + 2.0 * l - 12.0 * c + 2.0 * r + bl + 2.0 * b + br) * scale;
        grad = float2(laplacian, laplacian);
    }
}

void RobertsCrossGradient(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, out float2 grad)
{
    grad.x = (c - bl) * scale;
    grad.y = (l - b) * scale;
}

void RobertsCrossExtended(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, float scale, out float2 grad)
{
    grad.x = (abs(c - bl) + abs(tr - l)) * 0.5 * scale;
    grad.y = (abs(l - b) + abs(t - br)) * 0.5 * scale;
}

void GetGradient(float tl, float t, float tr, float l, float c, float r, float bl, float b, float br, int type, bool isNormal, out float2 grad)
{
    float scale = 1.0;
    
    switch(type)
    {
        case 0:
            Sobel(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
        case 1:
            Prewitt(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
        case 2:
            RobertsClassic(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
        case 3:
            Scharr(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
        case 4:
            CustomLaplacian(tl, t, tr, l, c, r, bl, b, br, scale, isNormal, grad);
            break;
        case 5:
            RobertsCrossGradient(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
        case 6:
            RobertsCrossExtended(tl, t, tr, l, c, r, bl, b, br, scale, grad);
            break;
        default:
            grad = float2(0, 0);
            break;
    }
}

#endif // EDGE_DETECTION_TYPES_INCLUDED