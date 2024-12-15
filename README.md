# Edge Detection Outlines for URP

A high-quality edge detection render feature for Unity's Universal Render Pipeline (URP) that provides various edge detection algorithms for both depth and normal-based outlines.

## Features

- Multiple edge detection algorithms:
  - Sobel
  - Prewitt
  - Roberts Classic
  - Scharr
  - Custom Laplacian
  - Roberts Cross Gradient
  - Roberts Cross Extended
- Independent depth and normal edge detection
- View angle-based edge intensity
- Customizable edge color and opacity
- Adjustable thresholds for both depth and normal edges
- Optimized for URP

## Installation

1. Make sure you have Universal Render Pipeline installed in your Unity project
2. Clone this repository or download the files
3. Copy the contents into your Unity project's Assets folder
4. Add the Edge Detection Render Feature to your URP Renderer:
   - Select your URP Renderer Asset
   - Click "Add Renderer Feature"
   - Choose "Edge Detection Feature"

## Usage

### Basic Setup

1. Select your URP Renderer Asset in the Project window
2. Add the Edge Detection Feature if you haven't already
3. Configure the settings:
   - Edge Color: Set the color of the outlines
   - Injection Point: Choose when the effect should be applied in the render pipeline

### Edge Detection Settings

#### Depth Edges
- Enable/disable depth-based edge detection
- Choose the edge detection algorithm
- Adjust the depth threshold to control edge sensitivity

#### Normal Edges
- Enable/disable normal-based edge detection
- Choose the edge detection algorithm
- Adjust the normal threshold to control edge sensitivity

### Tips for Best Results

- For most scenes, using both depth and normal edges provides the best results
- Sobel and Scharr operators work well for general use
- Roberts Cross variants can provide sharper, more defined edges
- Adjust thresholds based on your scene's scale and content

## Requirements

- Unity 2021.3 or newer
- Universal Render Pipeline package
- Shader Model 4.5 or higher

## Performance Considerations

The edge detection is performed in a single pass and uses built-in depth and normal textures, making it relatively efficient. However, keep in mind:

- Using both depth and normal edges is more expensive than using just one
- More complex algorithms (like Scharr) are slightly more expensive than simpler ones (like Roberts)
- The effect scales well with resolution

## Acknowledgments

- Edge detection algorithms based on standard image processing techniques
- Optimized for Unity's Universal Render Pipeline
