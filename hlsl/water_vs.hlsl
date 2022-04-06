//Water Pixel Shader

//Input
struct InputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

//Output
struct OutputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

OutputType main(InputType input)
{
    OutputType output;

	 // Pass the vertex position into the hull shader.
    output.position = input.position;
    
    //Pass tex coord
    output.tex = input.tex;
    
    // Pass the input color into the hull shader.
    output.normal = input.normal;
    
    return output;
}