#ifndef MODELS_H
#define MODELS_H

#include "Materials.h"
#include "CollisionSystem.h"

#include <vector>
#include <string>

enum LodLevel {always, low, high};

struct Model{
  std::string name = "**UNNAMED Model**";
  int ID = -1;
  bool modelShell = true; // each main model gets a shell parent, need a way to detect
  LodLevel lodLevel = always; // always draw by default
  glm::mat4 transform;
  glm::mat4 modelOffset; //Just for placing geometry, not passed down the scene graph
  float* modelData = 0;
  float lowLodDist = 0;
  int startVertex;
  int numVerts = 0;
  int numChildren = 0;
  int materialID = -1;
  Collider* collider = nullptr;
  glm::vec2 textureWrap = glm::vec2(1,1);
  glm::vec3 modelColor = glm::vec3(1,1,1); //TODO: Perhaps we can replace this simple approach with a more general material blending system?
  std::vector<Model*> childModel;

  float radius = 0; // radius as set by math transformations on original
  float originalRadius = 0; // radius as set by obj
};

void resetModels();
void loadModel(string fileName);

void loadAllModelsTo1VBO(unsigned int vbo);
int addModel(string modelName);
void addChild(string childName, int curModelID);
float findMaxRadiusInChildren(Model m);

//Global Model List
extern Model models[4000];
extern int numModels;

#endif //MODELS_H
