//Tesselation Domain Shader
//Texture and Sampler
Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

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

//Ouptut
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

//Calculate Height at position
float getHeight(float2 uv)
{
    //Get height map colour at position
    float4 textureColour = texture0.SampleLevel(sampler0, uv, 0);
	
    float height;
    height = (textureColour.x + textureColour.y + textureColour.z);
    height *= 7;
    
    //Lower the lowest parts for water
    if(height == 0)
    {
        height = -5;
    }
    return height;
}


[domain("quad")]
OutputType main(ConstantOutputType input, float2 uv : SV_DomainLocation, const OutputPatch<InputType, 4> patch)
{
    OutputType output;
   
    //New Position, Normal and TexCoord
    float3 vertexPosition,vertexNormal;
    float2 texCoord;
       
    //Calculate Tex Coord
    float2 t1 = lerp(patch[0].tex, patch[1].tex, uv.y);
    float2 t2 = lerp(patch[2].tex, patch[3].tex, uv.y);
    texCoord = lerp(t1, t2, uv.x);
    
    //Calculate Vertex Position - XZ
    float3 v1 = lerp(patch[0].position, patch[1].position, uv.y);
    float3 v2 = lerp(patch[2].position, patch[3].position, uv.y);
    vertexPosition = lerp(v1, v2, uv.x);
    
    //Calculate Vertex Position - Y
    vertexPosition.y = getHeight(texCoord);

    //Difference in texture coords between each vertex
    float diffy = ((abs(patch[0].tex - patch[1].tex) + abs(patch[2].tex - patch[3].tex))/2)/input.edges[0];
    float diffx = ((abs(patch[1].tex - patch[2].tex) + abs(patch[3].tex - patch[0].tex))/2)/input.edges[1];
    
    //Adjacent vertices Y Values
    float adjacent[4];
    adjacent[0] = getHeight(texCoord + float2(0, diffy));
    adjacent[1] = getHeight(texCoord + float2(diffx, 0));
    adjacent[2] = getHeight(texCoord + float2(0, -diffy));
    adjacent[3] = getHeight(texCoord + float2(-diffx, 0));
	
    
    //Get Vectors between positions
    float3 vector1 = float3(vertexPosition.x, adjacent[0], vertexPosition.z + diffy) - vertexPosition;
    float3 vector2 = float3(vertexPosition.x + diffx, adjacent[1], vertexPosition.z) - vertexPosition;
    float3 vector3 = float3(vertexPosition.x, adjacent[2], vertexPosition.z - diffy) - vertexPosition;
    float3 vector4 = float3(vertexPosition.x - diffx, adjacent[3], vertexPosition.z) - vertexPosition;
    
	//Cross  1 & 2
    float3 cp1 = float3(((vector1.y * vector2.z) - (vector1.z * vector2.y)), ((vector1.z * vector2.x) - (vector1.x * vector2.z)), ((vector1.x * vector2.y) - (vector1.y * vector2.x)));
	//Cross  2 & 3
    float3 cp2 = float3(((vector2.y * vector3.z) - (vector2.z * vector3.y)), ((vector2.z * vector3.x) - (vector2.x * vector3.z)), ((vector2.x * vector3.y) - (vector2.y * vector3.x)));
	//Cross  3 & 4
    float3 cp3 = float3(((vector3.y * vector4.z) - (vector3.z * vector4.y)), ((vector3.z * vector4.x) - (vector3.x * vector4.z)), ((vector3.x * vector4.y) - (vector3.y * vector4.x)));
	//Cross  4 & 1
    float3 cp4 = float3(((vector4.y * vector1.z) - (vector4.z * vector1.y)), ((vector4.z * vector1.x) - (vector4.x * vector1.z)), ((vector4.x * vector1.y) - (vector4.y * vector1.x)));
	
	
    //Find average of Cross products
    vertexNormal = (cp1 + cp2 + cp3 + cp4)/4;
    
    
    output.normal = vertexNormal;
    output.normal = mul(output.normal, (float3x3) worldMatrix);
    output.normal = normalize(output.normal);
    
    // Calculate the position of the new vertex against the world, view, and projection matrices.
    output.position = mul(float4(vertexPosition, 1.0f), worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
    output.tex = texCoord;
    
    //For Lighting
    output.worldPosition = mul(float4(vertexPosition,1.0), worldMatrix).xyz;
    output.viewVector = cameraPosition.xyz - output.worldPosition.xyz;
    output.viewVector = normalize(output.viewVector);
        
    // Calculate the position of the vertice as viewed by the light source.
    for (int i = 0; i < 3;i++)
    {
        output.lightViewPos[i] = mul(float4(vertexPosition, 1.0), worldMatrix);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightView[i]);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjection[i]);
    }
    
    return output;
   
}
