//Horizontal Blur Pixel Shader

//Texture and Sampler
Texture2D shaderTexture : register(t0);
SamplerState SampleType : register(s0);

//Blur Settings Buffer
cbuffer ScreenSizeBuffer : register(b0)
{
    float screenWidth;
    int neighbours;
    float weighting;
    float padding;
};

//Input
struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
};

float4 main(InputType input) : SV_TARGET
{
    //Weights
    float weight[10];
    // Initialize the colour to black.
    float4 colour = (0.0f, 0.0f, 0.0f, 0.0f);

	// Create the weights that each neighbor pixel will contribute to the blur.
    for (int i = 0; i < neighbours; i++)
    {
        float p = -(pow(i, 2)) / (2 * pow(weighting, 2));
        weight[i] = (1 / (sqrt(2 * 3.14159265359 * pow(weighting, 2)))) * pow(2.71828, p);

    }
    
    //Depending on the neighbours add neighbour colour to colour
    float texelSize = 1.0f / screenWidth;
    colour += shaderTexture.Sample(SampleType, input.tex) * weight[0];
    for (int j = 1; j < neighbours; j++)
    {
        if (input.tex.x + texelSize * -j >= 0)
        {
            colour += shaderTexture.Sample(SampleType, input.tex + float2(texelSize * -j,0.0f)) * weight[j];
        }
        
        if (input.tex.x + texelSize * j <= 1)
        {
            colour += shaderTexture.Sample(SampleType, input.tex + float2(texelSize * j, 0.0f)) * weight[j];
        }
    }
 
    // Set the alpha channel to one.
    colour.a = 1.0f;

    return colour;
}