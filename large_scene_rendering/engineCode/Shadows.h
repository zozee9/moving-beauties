#ifndef SHADOWS_H
#define SHADOWS_H

#include "Materials.h"
#include "Models.h"
#include "Camera.h"

//Shadow mapping functions
void initShadowMapping();
void initShadowBuffers();
void computeShadowDepthMap(glm::mat4 lightView, glm::mat4 lightProjection, std::vector<Model*> toDraw, UserCamera &mainCam);
void drawGeometryShadow(int shaderProgram, Model model, Material material, glm::mat4 transform, UserCamera &mainCam);

//Configuration values that can be set:
extern unsigned int shadowMapWidth, shadowMapHeight;

//Global values we write out:
extern unsigned int depthMapTex;

#endif //SHADOWS_H
