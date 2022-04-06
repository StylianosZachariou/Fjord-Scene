//Bright Detection Pixel Shader

//Texture and Sampler
Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);

//Brightnes Settings Buffer
cbuffer BrightnessSettings : register(b0)
{
    float strength;
    float threshold;
    float2 padding;
};

//Input
struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};


float4 main(InputType input) : SV_TARGET
{
	// Sample the pixel color from the texture using the sampler at this texture coordinate location.
    float4 textureColour = texture0.Sample(Sampler0, input.tex);
    
    //Turn colour to greyscale to see brightness
    float brightness = (textureColour.x + textureColour.y + textureColour.z) / 3;
    
    //If Brightness is more than threshold
    if (brightness > threshold)
    {
        //Then is bright
        return float4((strength * textureColour).xyz, 1);
    }
    else
    {
        //Is not bright
        return float4(0, 0, 0, 1);
    }
}