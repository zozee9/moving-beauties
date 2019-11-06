--Simple Example
print("Starting Lua for InClassExample")

--Todo:
-- Lua modules (for better organization, and maybe reloading?)

CameraPosX = -3.0
CameraPosY = 2.0
CameraPosZ = 0.0

CameraDirX = 1.0
CameraDirY = -0.0
CameraDirZ = -0.0

CameraUpX = 0.0
CameraUpY = 1.0
CameraUpZ = 0.0

animatedModels = {}
velModel = {}
rotYVelModel = {}

linVel = 2.0
angVel = 1.0

-- REQUIRED
function frameUpdate(dt)
  frameDt = dt -- EVERYTHING IS GLOBAL BY DEFAULT
  for modelID,v in pairs(animatedModels) do
    --print("ID",modelID)
    local vel = velModel[modelID]
    if vel then 
      translateModel(modelID,dt*vel[1],dt*vel[2],dt*vel[3])
    end

    local rotYvel = rotYVelModel[modelID]
    if rotYvel then 
      rotateModel(modelID,rotYvel*dt, 0, 1, 0)
    end

  end
end

-- REQUIRED
theta = 0
function keyHandler(keys)
  if keys.left then
    theta = theta + angVel * frameDt
  end
  if keys.right then
    theta = theta - angVel * frameDt
  end
  if keys.up then
    CameraPosX = CameraPosX + CameraDirX * linVel * frameDt
    CameraPosZ = CameraPosZ + CameraDirZ * linVel * frameDt
  end
  if keys.down then
    CameraPosX = CameraPosX - CameraDirX * linVel * frameDt
    CameraPosZ = CameraPosZ - CameraDirZ * linVel * frameDt
  end
  CameraDirX = math.cos(theta)
  CameraDirZ = -math.sin(theta)
end

id = addModel("Teapot",0,0,0)
setModelMaterial(id,"Shiny Red Plastic")
--setModelMaterial(id,"Steel")
animatedModels[id] = true
rotYVelModel[id] = 1
id = addModel("FloorPart",0,0,0)
placeModel(id,0,-.02,0)
scaleModel(id,13,1,13)
setModelMaterial(id,"Gold")
-- piller = addModel("Dino",0,0,-.15)  --VeryFancyCube
--placeModel(piller,-1.5,1.5,0.5)
--scaleModel(piller,.5,0.5,1.5)
--animatedModels[piller] = true
--rotZVelModel[piller] = 1

-- donut = addModel("Torus",0,2,0)
-- setModelMaterial(donut, "Clay")
-- dinoHat = addModel("DinoHat", 0, 0, 0)

dinoHats = {}
idx = 1
num = 3
for i = -num, num do
  for j = -num, num + 1 do
    dinoHats[idx] = addModel("DinoHat", i * 2, 0.0, j * 2)
    -- setModelMaterial(dinoHats[idx], "Shiny Red Plastic")
    idx = idx + 1
  end
end

