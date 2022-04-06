//Tesselation Pixel Shader

//Texture and Sampler
Texture2D depthMapTexture[3] : register(t0);
SamplerState shadowSampler : register(s0);

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
    //Calculate intensity
    float intensity = saturate(dot(normal, lightVector));
    //Calculate colour using intensity
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
float4 calculateSpecular(float3 lightVector, float3 normal, float3 viewVector,float4 specularColour, float specularPower)
{
    //Calculate Specular
    float3 halfway = normalize(lightVector + viewVector);
    float specularIntensity = pow(max(dot(normal, halfway), 0.0), specularPower);
    return saturate(specularColour * specularIntensity);
}

//Attneuation
float calculateAttenuation(float constantFactor,float linearFactor, float quadraticFactor,float3 dist)
{
    //Sum up factors
    float factors = constantFactor + (linearFactor * dist) + (quadraticFactor * pow(dist, 2));
   
    //Factors cant be less than 1
    if(factors<1)
    {
        factors = 1;
    }
    float attenuation = 1 / factors;
    return attenuation;
}

//Check if there are depth data
bool hasDepthData(float2 uv)
{
    if (uv.x < 0.f || uv.x > 1.f || uv.y < 0.f || uv.y > 1.f)
    {
        return false;
    }
    return true;
}

//Check if texture coord is in shadow
bool isInShadow(Texture2D sMap, float2 uv, float4 lightViewPosition, float bias)
{
    // Sample the shadow map (get depth of geometry)
    float depthValue = sMap.Sample(shadowSampler, uv).x;

	// Calculate the depth from the light.
    float lightDepthValue = lightViewPosition.z / lightViewPosition.w;
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

//Get Projective coordinates
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
    //If show Normals
    if(showNormals)
    {
        //Map normals to colour values
        return float4(input.normal.xyz, 1);
    }
    
    //Initialize Variables
    float4 textureColour = float4(1, 1, 1, 1);
    float4 lightColour[3] = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } };
    float4 finalColour=0;
    
    //Bias
    float shadowMapBias = 0.005f;

    //For Each Light
    for (int i = 0; i < 3;i++)
    {
        //Calculate ambient Lighting
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

                    //Calculate Lighing
                    lightColour[i] = calculateLighting(lightVector, input.normal, diffuse[i]) * calculateAttenuation(constantFactor[i].x, linearFactor[i].x, quadraticFactor[i].x, dist);
                    lightColour[i] += calculateSpecular(lightVector, input.normal, input.viewVector, specular[i], specularPower[i].x);
                    lightColour[i] += newAmbient;
                }
                else if (type[i].x == 3)//SpotLight
                {
                    //Calculate light vector, distance and angle
                    float3 dist = length(position[i].xyz - input.worldPosition);
                    float3 lightVector = normalize(position[i].xyz - input.worldPosition);
                    float angle = calculateCutOffAngle(lightVector, -direction[i].xyz);
        
                    if (abs(angle) <= cutOffAngle[i].x)
                    {
                        //Calculate Lighing
                        lightColour[i] = calculateLighting(lightVector, input.normal, diffuse[i]) * calculateAttenuation(constantFactor[i].x, linearFactor[i].x, quadraticFactor[i].x, dist);
                        lightColour[i] += calculateSpecular(lightVector, input.normal, input.viewVector, specular[i], specularPower[i].x);
                        lightColour[i] += newAmbient;
                    }
                }
            }
        }
    }
    
    //Create Texture
    //Dirt Colour
    float4 dirt = float4(0.314, 0.165, 0.02, 1);
    //Stone Colour
    float4 stone = float4(0.322, 0.322, 0.322, 1);
    //Snow Colour
    float4 snow = float4(1, 1, 1, 1);
    
    float4 color1;
    float4 color2;
    float percent;
  
   //If y position is less than 11
   if (input.worldPosition.y < 11)
   {
       //Dirt and Stone Grading
       percent = input.worldPosition.y / 10;
       color1 = dirt;
       color2 = stone;
   }
   else
   {
        //Stone and Snow Grading
       percent = ((input.worldPosition.y - 11) / 5);
       color1 = stone;
       color2 = snow;
   }
   
    //Calculate texture RGB
    float resultRed = color1.x + (percent * (color2.x - color1.x));
    float resultGreen = color1.y + (percent * (color2.y - color1.y));
    float resultBlue = color1.z + (percent * (color2.z - color1.z));
    
    textureColour = float4(resultRed, resultGreen, resultBlue, 1);
   
    //Add up lighting Variables
    finalColour = lightColour[0] + lightColour[1] + lightColour[2];
    
    return saturate(textureColour * finalColour);
}