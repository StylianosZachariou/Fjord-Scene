// Mini Map Pixel Shader

//Texture and Sampler
Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

//Input
struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float4 camera_pos : POSITION;
    float2 screen_space : TEXCOORD1;
};

float4 main(InputType input) : SV_TARGET
{
    float4 textureColour;
    float4 lightColour;

	// Sample the texture. Calculate light intensity and colour, return light*texture for final pixel colour.
    textureColour = texture0.Sample(sampler0, input.tex);
	
    //Calculate Camera's position to screen space
    input.camera_pos.xyz /= input.camera_pos.w;

    input.camera_pos.x *= 0.5;
    input.camera_pos.y *= -0.5;
	
    input.camera_pos.x += 0.5;
    input.camera_pos.y += 0.5;

    input.camera_pos.x *= input.screen_space.x;
    input.camera_pos.y *= input.screen_space.y;
    
    //make a red circle with radius 5 around player's position
    if (abs(sqrt(pow((input.position.x - input.camera_pos.x), 2) + pow((input.position.y - input.camera_pos.y), 2))) <= 5)
    {
       textureColour = float4(1, 0, 0, 1);
    }
       
    return textureColour;
}