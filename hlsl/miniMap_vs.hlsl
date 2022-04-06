// Mini Map Vertex Shader

//Matrices Buffer
cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

//Camera Buffer
cbuffer CameraBuffer : register(b1)
{
    float4 positionSS;
    float2 screen_space;
    float2 padding;
};

//Input
struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

//Output
struct OutputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float4 camera_position : POSITION;
    float2 screen_space : TEXCOORD1;
};

OutputType main(InputType input)
{
    OutputType output;

	// Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);

    
	//Calculate the camera position of the vertex against the world, view, and projection matrices.
    output.camera_position = mul(positionSS, worldMatrix);
    output.camera_position = mul(output.camera_position, viewMatrix);
    output.camera_position = mul(output.camera_position, projectionMatrix);

    output.screen_space = screen_space;
    
	// Store the texture coordinates for the pixel shader.
    output.tex = input.tex;

	// Calculate the normal vector against the world matrix only and normalise.
    output.normal = mul(input.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);

    return output;
}