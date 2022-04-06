//Shadow Vertex Shader

//Matrices Buffer
cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
    matrix lightView[3];
    matrix lightProjection[3];
};

//Camera Position Buffer
cbuffer CameraBuffer : register(b1)
{
    float3 cameraPosition;
    float padding;
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
    
    //For Lighting
    float3 worldPosition : TEXCOORD1;
    float3 viewVector : TEXCOORD2;
    float4 lightViewPos[3] : TEXCOORD3;
};


OutputType main(InputType input)
{
    OutputType output;

	// Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
	// Calculate the position of the vertice as viewed by the light source.
    output.worldPosition = mul(input.position, worldMatrix).xyz;
    output.viewVector = cameraPosition.xyz - output.worldPosition.xyz;
    output.viewVector = normalize(output.viewVector);
        
    // Calculate the position of the vertice as viewed by the light source.
    for (int i = 0; i < 3; i++)
    {
        output.lightViewPos[i] = mul(input.position, worldMatrix);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightView[i]);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjection[i]);
    }

    output.tex = input.tex;
    
    //Normals
    output.normal = mul(input.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);

    return output;
}