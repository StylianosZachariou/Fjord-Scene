//Blend Pixel Shader

//2 Textures to blend and Sampler
Texture2D texture0 : register(t0);
Texture2D texture1 : register(t1);
SamplerState Sampler0 : register(s0);

//Input
struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};


float4 main(InputType input) : SV_TARGET
{
	// Sample the pixel color from both textures using the sampler at this texture coordinate location.
    float4 textureColour1 = texture0.Sample(Sampler0, input.tex);
    float4 textureColour2 = texture1.Sample(Sampler0, input.tex);
    
    //Add them together and return
    return (textureColour1 + textureColour2);

}