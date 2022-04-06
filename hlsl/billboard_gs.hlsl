//Billboarding Geometry Shader

//Camera Position Buffer
cbuffer PlayerPosBuffer : register(b1)
{
    float3 playerPos;
    float padding;
}

//Buffer for new Vertex Positions
cbuffer PositionBuffer
{
    static float3 g_positions[8] =
    {
        float3(-1, 2, -1),
        float3(-1, -2, -1),
        float3(1, 2, 1),
        float3(1, -2, 1),
        float3(-1, 2, 1),
        float3(-1, -2, 1),
        float3(1, 2, -1),
        float3(1, -2, -1)
    };
};

//Matrices Buffer
cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

//Inputs
struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

//Outputs
struct OutputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    
    //For Lighting
    float3 worldPosition : TEXCOORD1;
};

//8 new Vertices
[maxvertexcount(8)]
void main(point InputType input[1], inout TriangleStream<OutputType> triStream)
{
    OutputType output;
	
    //Calculate Direction Vector
    float3 dir = normalize(input[0].position.xyz - playerPos);
    
    //Angle of Rotation
    float angleY = atan2(dir.x, dir.z);
    //Cos and Sin of angle
    float c = cos(angleY);
    float s = sin(angleY);
    
    //Rotational Matrix
    float4x4 rotYMatrix;
    rotYMatrix[0].xyzw = float4(c, 0, -s, 0);
    rotYMatrix[1].xyzw = float4(0, 1, 0, 0);
    rotYMatrix[2].xyzw = float4(s, 0, c, 0);
    rotYMatrix[3].xyzw = float4(0, 0, 0, 1);
    
    //For first quad
    for (int i = 0; i < 4; i++)
    {
       //Calculate new Vertex Position
        float4 vposition = float4(g_positions[i], 1.0f);
        vposition = mul(vposition, rotYMatrix);
        vposition.xyz += input[0].position.xyz;
        output.position = mul(vposition, worldMatrix);
        output.position = mul(output.position, viewMatrix);
        output.position = mul(output.position, projectionMatrix);
        
        //Calculate new Texture Coordinate
        output.tex = g_positions[i] / 2 + 0.5;
        output.tex.y = 1 - output.tex.y;
        
        //Calculate Normal
        input[0].normal = float3(1, 1, -1);
        input[0].normal = mul(float4(input[0].normal, 1), rotYMatrix);
        output.normal = mul(input[0].normal, (float3x3) worldMatrix);
        output.normal = normalize(output.normal);
        
        //Calculate World Position
        output.worldPosition = mul(vposition, worldMatrix).xyz;
        
        //Append new Vertex
        triStream.Append(output);
    }
  
    //Second quad  
    for (int j = 4; j < 8; j++)
    {
        //Calculate New Vertex Position
        float4 vposition = float4(g_positions[j], 1.0f);
        vposition = mul(vposition, rotYMatrix);
        vposition.xyz += input[0].position.xyz;
        output.position = mul(vposition, worldMatrix);
        output.position = mul(output.position, viewMatrix);
        output.position = mul(output.position, projectionMatrix);
        
        //Calculate new Texture Coord
        output.tex = g_positions[j] / 2 + 0.5;
        output.tex.y = 1 - output.tex.y;
        
        //Calculate Normal
        input[0].normal = float3(-1, 1, -1);
        input[0].normal = mul(float4(input[0].normal, 1), rotYMatrix);
        output.normal = mul(input[0].normal, (float3x3) worldMatrix);
        output.normal = normalize(output.normal);
        
        //Calculate World Position
        output.worldPosition = mul(vposition, worldMatrix).xyz;
        
        //Append new Vertex
        triStream.Append(output);
    }
    triStream.RestartStrip();
}