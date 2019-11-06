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


-- Debug camera
DebugCameraPosX = -10.0
DebugCameraPosY = 2.0
DebugCameraPosZ = 0.0

DebugCameraDirX = 1.0
DebugCameraDirY = -0.0
DebugCameraDirZ = -0.0

DebugCameraUpX = 0.0
DebugCameraUpY = 1.0
DebugCameraUpZ = 0.0

animatedModels = {}
velModel = {}
rotYVelModel = {}

cameraLinVel = 10.0
cameraAngVel = 1

-- Normal or debug camera mode
UseDebugCamera = 0
TimeSinceDebugPress = 0 -- In seconds

-- REQUIRED
function frameUpdate(dt)
    TimeSinceDebugPress = TimeSinceDebugPress + dt
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
debugTheta = 0
function keyHandler(keys)
    if keys.left then
        theta = theta + cameraAngVel * frameDt
    end
    if keys.right then
        theta = theta - cameraAngVel * frameDt
    end

    if keys.a then
        debugTheta = debugTheta + cameraAngVel * frameDt
    end
    if keys.d then
        debugTheta = debugTheta - cameraAngVel * frameDt
    end

    if keys.up then
        CameraPosX = CameraPosX + CameraDirX * cameraLinVel * frameDt
        CameraPosZ = CameraPosZ + CameraDirZ * cameraLinVel * frameDt
    end
    if keys.down then
        CameraPosX = CameraPosX - CameraDirX * cameraLinVel * frameDt
        CameraPosZ = CameraPosZ - CameraDirZ * cameraLinVel * frameDt
    end

    if keys.w then
        if keys.shift then
            DebugCameraPosY = DebugCameraPosY + DebugCameraUpY * cameraLinVel * frameDt
        else
            DebugCameraPosX = DebugCameraPosX + DebugCameraDirX * cameraLinVel * frameDt
            DebugCameraPosZ = DebugCameraPosZ + DebugCameraDirZ * cameraLinVel * frameDt
        end
    end
    if keys.s then
        if keys.shift then
            DebugCameraPosY = DebugCameraPosY - DebugCameraUpY * cameraLinVel * frameDt
        else
            DebugCameraPosX = DebugCameraPosX - DebugCameraDirX * cameraLinVel * frameDt
            DebugCameraPosZ = DebugCameraPosZ - DebugCameraDirZ * cameraLinVel * frameDt
        end
    end

    CameraDirX = math.cos(theta)
    CameraDirZ = -math.sin(theta)
    DebugCameraDirX = math.cos(debugTheta)
    DebugCameraDirZ = -math.sin(debugTheta)

    if keys.z and TimeSinceDebugPress > 0.5 then
        TimeSinceDebugPress = 0.0
        if UseDebugCamera == 1 then
            UseDebugCamera = 0
        else
            UseDebugCamera = 1
        end
    end
end

dinoHats = {}

idx = 1
num = 15
sep = 3
for i = -num, num do
    for j = -num, num do
        dinoHats[idx] = addModel("DinoHat", i * sep, 0.0, j * sep)
        animatedModels[dinoHats[idx]] = true
        rotYVelModel[dinoHats[idx]] = 0.5
    end
end
