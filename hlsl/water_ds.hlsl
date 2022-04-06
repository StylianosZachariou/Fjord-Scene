//Water Domain Shader

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

//Wave Settings Buffer
cbuffer WaveBuffer : register(b2)
{
    float time;
    float amplitude;
    float speed;
    float frequency;
}

//Constant Output
struct ConstantOutputType
{
    float edges[4] : SV_TessFactor;
    float inside[2] : SV_InsideTessFactor;
};

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
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    
    //For Lighting
    float3 worldPosition : TEXCOORD1;
    float3 viewVector : TEXCOORD2;
    float4 lightViewPos[3] : TEXCOORD3;
};

[domain("quad")]
OutputType main(ConstantOutputType input, float2 uv : SV_DomainLocation, const OutputPatch<InputType, 4> patch)
{
    OutputType output;
    
    //New Vertex Position, Vertex Normal and Texture Coordinate
    float3 vertexPosition, vertexNormal=0;
    float2 texCoord;
    
    //Calculate Tex Coord
    float2 t1 = lerp(patch[0].tex, patch[1].tex, uv.y);
    float2 t2 = lerp(patch[2].tex, patch[3].tex, uv.y);
    texCoord = lerp(t1, t2, uv.x);    
    
    //Calculate control point y values
    float3 patches[4];
    patches[0] = patch[0].position;
    patches[0].y = patch[0].position.y + sin(patch[0].position.x * frequency + -time * speed) * amplitude;
    patches[0].x = patch[0].position.x + cos(patch[0].position.z * frequency + -time * speed) * amplitude;
    patches[1] = patch[1].position;
    patches[1].y = patch[1].position.y + sin(patch[1].position.x * frequency + -time * speed) * amplitude;
    patches[1].x = patch[1].position.x + cos(patch[1].position.z * frequency + -time * speed) * amplitude;
    patches[2] = patch[2].position;
    patches[2].y = patch[2].position.y + sin(patch[2].position.x * frequency + -time * speed) * amplitude;
    patches[2].x = patch[2].position.x + cos(patch[2].position.z * frequency + -time * speed) * amplitude;
    patches[3] = patch[3].position;
    patches[3].y = patch[3].position.y + sin(patch[3].position.x * frequency + -time * speed) * amplitude;
    patches[3].x = patch[3].position.x + cos(patch[3].position.z * frequency + -time * speed) * amplitude;
    
    //Calculate Vertex Position by interpolation
    float3 v1 = lerp(patches[0], patches[1], uv.y);
    float3 v2 = lerp(patches[2], patches[3], uv.y);
    vertexPosition = lerp(v1, v2, uv.x);
    
    //Calcuate Normals
    float3 normals[4];
    
    normals[0].x = -(cos(patch[0].position.x * frequency + (-time * speed))) * amplitude;
    normals[1].x = -(cos(patch[1].position.x * frequency + (-time * speed))) * amplitude;
    normals[2].x = -(cos(patch[2].position.x * frequency + (-time * speed))) * amplitude;
    normals[3].x = -(cos(patch[3].position.x * frequency + (-time * speed))) * amplitude;
   
    normals[0].z = sin(patch[0].position.z * frequency + (-time * speed)) * amplitude;
    normals[1].z = sin(patch[1].position.z * frequency + (-time * speed)) * amplitude;
    normals[2].z = sin(patch[2].position.z * frequency + (-time * speed)) * amplitude;
    normals[3].z = sin(patch[3].position.z * frequency + (-time * speed)) * amplitude;
    
    float3 n1 = lerp(normals[0], normals[1], uv.y);
    float3 n2 = lerp(normals[2], normals[3], uv.y);
    vertexNormal = lerp(n1, n2, uv.x);
    
    vertexNormal.y = 1;
    
    output.normal = vertexNormal;
    output.normal = mul(output.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);
    
    // Calculate the position of the new vertex against the world, view, and projection matrices.
    output.position = mul(float4(vertexPosition, 1.0f), worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    output.tex = texCoord;
    
    //For Lighting
    output.worldPosition = mul(float4(vertexPosition, 1.0), worldMatrix).xyz;
    output.viewVector = cameraPosition.xyz - output.worldPosition.xyz;
    output.viewVector = normalize(output.viewVector);
    
    for (int i = 0; i < 3; i++)
    {
        output.lightViewPos[i] = mul(float4(vertexPosition, 1.0), worldMatrix);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightView[i]);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjection[i]);
    }
    
    return output;
}