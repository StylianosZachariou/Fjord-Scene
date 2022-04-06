//Horizontal Blur Vertex Shader

//Matrices Buffer
cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

//Input
struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
};

//Output
struct OutputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
};


OutputType main(InputType input)
{
    OutputType output;

    //Calculate position against matrices
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);

    output.tex = input.tex;

    return output;
}