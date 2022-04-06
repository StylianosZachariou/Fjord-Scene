//Water Hull Shader

//Tesselation Factor Buffer
cbuffer TessalationFactorBuffer : register(b0)
{
    float4 position;
    float2 minMaxLOD;
    float2 minMaxDist;
};

//Input
struct InputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

//Constant Output
struct ConstantOutputType
{
    float edges[4] : SV_TessFactor;
    float inside[2] : SV_InsideTessFactor;
};

//Output
struct OutputType
{
    float3 position : POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

//Calculate patch midpoint
float3 ComputePatchMid(float3 a, float3 b, float3 c, float3 d)
{
    return (a + b + c + d) / 4.0f;
}

//Scale Computation
float ComputeScaled(float3 f, float3 t)
{
    float d = distance(f.xz, t.xz);
    float maxD = minMaxDist.y;
    float minD = minMaxDist.x;
    return (d - minD) / (maxD - minD);
}

//Get LOD from distance
float DoLOD(float3 midP)
{
    float d = ComputeScaled(position.xyz, midP);
    return lerp(minMaxLOD.x, minMaxLOD.y, saturate(1 - d));
}


ConstantOutputType PatchConstantFunction(InputPatch<InputType, 12> ip, uint patchId : SV_PrimitiveID)
{
    ConstantOutputType output;

    float3 midPoints[5];
    //5 midpoints
    //For this Quad
    midPoints[0] = ComputePatchMid(ip[0].position, ip[1].position, ip[2].position, ip[3].position);
    //Right Quad
    midPoints[1] = ComputePatchMid(ip[2].position, ip[3].position, ip[4].position, ip[5].position);
    //Top Quad
    midPoints[2] = ComputePatchMid(ip[1].position, ip[3].position, ip[6].position, ip[7].position);
    //Left Quad
    midPoints[3] = ComputePatchMid(ip[0].position, ip[1].position, ip[8].position, ip[9].position);
    //Bottom Quad
    midPoints[4] = ComputePatchMid(ip[0].position, ip[2].position, ip[10].position, ip[11].position);
    
    //LOD of this quad
    float dist0 = DoLOD(midPoints[0]);
    
    //Compare this quad with other quads for eahc edge. Do the least LOD
    output.edges[0] = min(dist0, DoLOD(midPoints[3]));
    output.edges[1] = min(dist0, DoLOD(midPoints[4]));
    output.edges[2] = min(dist0, DoLOD(midPoints[1]));
    output.edges[3] = min(dist0, DoLOD(midPoints[2]));

    //iNSIDE LOD  is this quads LOD
    output.inside[0] = dist0;
    output.inside[1] = dist0;
    
    return output;
}


[domain("quad")]
[partitioning("fractional_odd")]
[outputtopology("triangle_ccw")]
[outputcontrolpoints(4)]
[patchconstantfunc("PatchConstantFunction")]
OutputType main(InputPatch<InputType, 12> patch, uint pointId : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    OutputType output;


    // Set the position for this control point as the output position.
    output.position = patch[pointId].position;

    //Set tex coord
    output.tex = patch[pointId].tex;
    
    // Set the input colour as the output colour.
    output.normal = patch[pointId].normal;

    return output;
}