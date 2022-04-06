//Billboard Pixel Shader

//Texture and Sampler
Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);

//Buffer for Lighting
cbuffer LightBuffer : register(b0)
{
    float4 ambient[3];
    float4 diffuse[3];
    float4 position[3];
    float4 direction[3];
    int4 type[3];
    float4 cutOffAngle[3];
    float4 constantFactor[3];
    float4 linearFactor[3];
    float4 quadraticFactor[3];
};

//Show Normals Buffer
cbuffer NormalBuffer : register(b1)
{
    bool showNormals;
    bool p1;
    bool p2;
    bool p3;
    float3 padding;
};

//INput
struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
};

//Attenuation
float calculateAttenuation(float constantFactor, float linearFactor, float quadraticFactor, float3 dist)
{
    //Sum up factors
    float factors = constantFactor + (linearFactor * dist) + (quadraticFactor * pow(dist, 2));
  
    //Factors can't be less than 1
    if (factors < 1)
    {
        factors = 1;
    }
    float attenuation = 1 / factors;
    return attenuation;
}

//Lighting
float4 calculateLighting(float3 lightVector, float3 normal, float4 diffuse)
{
    //Calculate Intensity
    float intensity = saturate(dot(normal, lightVector));
    //Calculate Colours
    float4 colour = saturate(diffuse * intensity);
    return colour;
}

//Cut Off Angle for Spotlight
float calculateCutOffAngle(float3 lightVector, float3 lightDirection)
{
    //Calculate angle between Light Vector and Direction Vector
    float angle = acos((lightVector.x * lightDirection.x + lightVector.y * lightDirection.y + lightVector.z * lightDirection.z) /
	(sqrt(pow(lightVector.x, 2) + pow(lightVector.y, 2) + pow(lightVector.z, 2)) *
    sqrt(pow(lightDirection.x, 2) + pow(lightDirection.y, 2) + pow(lightDirection.z, 2))));
    
    //Convert the angle to radians
    angle *= 0.01745329252;
    return angle;
}

float4 main(InputType input) : SV_TARGET
{
    //If Show normals
    if (showNormals)
    {
        //Return normals mapped to color;
        return float4(input.normal.xyz, 1);
    }
    
	// Sample the pixel color from the texture using the sampler at this texture coordinate location.
    float4 textureColour = texture0.Sample(Sampler0, input.tex);
    //Initialize light Colour (1 for each light)
    float4 lightColour[3] = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } };
    //Initialize final Colour
    float4 finalColour = 0;
    
    //For all 3 lights
    for (int i = 0; i < 3; i++)
    {
        //Multiply Ambient xyz with w
        float4 newAmbient = float4(ambient[i].xyz * ambient[i].w, ambient[i].w);

	   if (type[i].x == 0)//Light is off
       {
           //Do nothing Light is off
       }
       else if (type[i].x == 1)//Directional Light
       {
            //Calculate diffuse lighting and Ambient
            lightColour[i] = calculateLighting(-direction[i].xyz, input.normal, diffuse[i]);
            lightColour[i] += newAmbient;
       }
       else if (type[i].x == 2)//Point Light
       {
        
            //Calculate Light Vector
            float3 dist = length(position[i].xyz - input.worldPosition);
            float3 lightVector = normalize(position[i].xyz - input.worldPosition);

            //Calculate diffuse lighting and Ambient
            lightColour[i] = calculateLighting(lightVector, input.normal, diffuse[i]) * calculateAttenuation(constantFactor[i].x, linearFactor[i].x, quadraticFactor[i].x, dist);
            lightColour[i] += newAmbient;
       }
       else if (type[i].x == 3)//SpotLight
       {
            //Calculate Light Vector and cut off angle
            float3 lightVector = normalize(position[i].xyz - input.worldPosition);
            float angle = calculateCutOffAngle(lightVector, -direction[i].xyz);
        
            if (abs(angle) <= cutOffAngle[i].x)
            {
                 float3 dist = length(position[i].xyz - input.worldPosition);
                
                 //Calculate diffuse lighting and Ambient
                 lightColour[i] = calculateLighting(lightVector, input.normal, diffuse[i]) * calculateAttenuation(constantFactor[i].x, linearFactor[i].x, quadraticFactor[i].x, dist);
                 lightColour[i] += newAmbient;
            }
       }
    }

    //Final Colouyr is all light Colours Summed Up
    finalColour = lightColour[0] + lightColour[1] + lightColour[2];
    
    return float4((textureColour * finalColour).xyz, textureColour.w);
}