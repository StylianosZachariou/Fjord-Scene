//Water Pixel Shader
//Textures and Samplers
Texture2D shaderTexture : register(t0);
Texture2D depthMapTexture[3] : register(t1);

SamplerState diffuseSampler : register(s0);
SamplerState shadowSampler : register(s1);

//Lighting Buffer
cbuffer LightBuffer : register(b0)
{
    float4 ambient[3];
    float4 diffuse[3];
    float4 position[3];
    float4 direction[3];
    float4 specular[3];
    float4 specularPower[3];
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
}

//Input
struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
    float3 viewVector : TEXCOORD2;
    float4 lightViewPos[3] : TEXCOORD3;
};

//Diffuse
float4 calculateLighting(float3 lightVector, float3 normal, float4 diffuse)
{
    //Calculate Intensity
    float intensity = saturate(dot(normal, lightVector));
    //Calculate Colour using intensity
    float4 colour = saturate(diffuse * intensity);
    return colour;
}

//Cut Off Angle
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

//Specular
float4 calculateSpecular(float3 lightDirection, float3 normal, float3 viewVector, float4 specularColour, float specularPower)
{
    //Calculate Specular
    float3 halfway = normalize(lightDirection + viewVector);
    float specularIntensity = pow(max(dot(normal, halfway), 0.0), specularPower);
    return saturate(specularColour * specularIntensity);
}

//Attenuation
float calculateAttenuation(float constantFactor, float linearFactor, float quadraticFactor, float3 dist)
{
    //Sum Up Factors
    float factors = constantFactor + (linearFactor * dist) + (quadraticFactor * pow(dist, 2));
    //Factors cant be less than 1
    if (factors < 1)
    {
        factors = 1;
    }
    float attenuation = 1 / factors;
    return attenuation;
}

//Check if there are depth data;
bool hasDepthData(float2 uv)
{
    if (uv.x < 0.f || uv.x > 1.f || uv.y < 0.f || uv.y > 1.f)
    {
        return false;
    }
    return true;
}

//Check if position is in shadow
bool isInShadow(Texture2D sMap, float2 uv, float4 lightViewPosition, float bias)
{
    // Sample the shadow map (get depth of geometry)
    float depthValue = sMap.Sample(shadowSampler, uv).x;

	// Calculate the depth from the light.
    float lightDepthValue = lightViewPosition.z/ lightViewPosition.w;
    lightDepthValue -= bias;

	// Compare the depth of the shadow map value and the depth of the light to determine whether to shadow or to light this pixel.
    if (depthValue > lightDepthValue)
    {
        return false;
    }
    else
    {
        return true;
    }
}

//Get Projective Coordinates
float2 getProjectiveCoords(float4 lightViewPosition)
{
    // Calculate the projected texture coordinates.
    float2 projTex = lightViewPosition.xy / lightViewPosition.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    return projTex;
}

float4 main(InputType input) : SV_TARGET
{
    //If Show Normlas
    if (showNormals)
    {
        //Map Normals xyz to colour rgb values
        return float4(input.normal.xyz, 1);
    }
    
    //Initialize light colour, bias, final colour
    float4 lightColour[3] = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } };
    float shadowMapBias = 0.005f;
    float4 finalColour = 0;
    
    //Get Texture Colour fro current position
    float4 textureColour = shaderTexture.Sample(diffuseSampler, input.tex*50);

    //For All three lights
    for (int i = 0; i < 3; i++)
    {
        //Calcualte Ambient Lighting
        float4 newAmbient = float4(ambient[i].xyz * ambient[i].w, ambient[i].w);

	    // Calculate the projected texture coordinates.
        float2 pTexCoord = getProjectiveCoords(input.lightViewPos[i]);
	
        // Shadow test. Is or isn't in shadow
        if (hasDepthData(pTexCoord))
        {
        // Has depth map data
            if (!isInShadow(depthMapTexture[i], pTexCoord, input.lightViewPos[i], shadowMapBias))
            {
                if (type[i].x == 0)//Light is off
                {
                    //Do nothing Light is off
                }
                else if (type[i].x == 1)//Directional Light
                {
                    //Calculate Lighting
                    lightColour[i] = calculateLighting(-direction[i].xyz, input.normal, diffuse[i]);
                    lightColour[i] += calculateSpecular(-direction[i].xyz, input.normal, input.viewVector, specular[i], specularPower[i].x);
                    lightColour[i] += newAmbient;
                }
                else if (type[i].x == 2)//Point Light
                {
                    //Calculate Light Vector
                    float3 dist = length(position[i].xyz - input.worldPosition);
                    float3 lightVector = normalize(position[i].xyz - input.worldPosition);

                    //Calculate Lighting
                    lightColour[i] = calculateLighting(lightVector, input.normal, diffuse[i]) * calculateAttenuation(constantFactor[i].x, linearFactor[i].x, quadraticFactor[i].x, dist);
                    lightColour[i] += calculateSpecular(lightVector, input.normal, input.viewVector, specular[i], specularPower[i].x);
                    lightColour[i] += newAmbient;
                }
                else if (type[i].x == 3)//SpotLight
                {
                    //Calculate Distance , Light Vector and Cut Off Angle
                    float3 dist = length(position[i].xyz - input.worldPosition);
                    float3 lightVector = normalize(position[i].xyz - input.worldPosition);
                    float angle = calculateCutOffAngle(lightVector, -direction[i].xyz);
        
                    if (abs(angle) <= cutOffAngle[i].x)
                    {
                        //Calculate Lighting
                        lightColour[i] = calculateLighting(lightVector, input.normal, diffuse[i]) * calculateAttenuation(constantFactor[i].x, linearFactor[i].x, quadraticFactor[i].x, dist);
                        lightColour[i] += calculateSpecular(lightVector, input.normal, input.viewVector, specular[i], specularPower[i].x);
                        lightColour[i] += newAmbient;
                    }
                }
            }
        }
    }
    
    //Sum up colours from all lights
    finalColour = lightColour[0] + lightColour[1] + lightColour[2];
    return saturate(textureColour* finalColour);
}