# Fjord Scene

### Background

The goal of the project was to create shaders along with a scene showcasing them. The scene created was heavily inspired by the Norwegian fjord, Geiranger and included multiple shaders and techniques.

### The Scene

The scene was created using the programmable pipeline in C++ and DirectX11 (HLSL). It includes mountains, a river, trees and objects. The techniques used to create the Fjord scene are:

- Vertex Manipulation:

      - Using a height map

      - Using algorithmic manipulation
- Post Processing:

      - Customizable Bloom effect

      - A mini map
- Lighting and Shadows:

      - 5 lights that cast shadows
      
      - Lights can change type (Directional, Point, Spotlight)
      
      - Each can have ambient and specular 
- Tessellation:

      - Dynamic Tessellation based on distance from camera
      
      - Distance and Tessellation factor can be changed
      
- Geometry Shader:

      - Billboarded Trees

Most of the above features are extensively customizable from the GUI. More details on the implementation and controls can be found [here](https://github.com/StylianosZachariou/Fjord-Scene/files/8457274/Documentation.pdf)

### The Application
The application can be downloaded from the Release page or [here](https://github.com/StylianosZachariou/Fjord-Scene/releases/download/1.0/executable.zip). 

<img src = "https://media.giphy.com/media/xuqZSOmLoyeZRyzhST/giphy.gif" width ="400">
