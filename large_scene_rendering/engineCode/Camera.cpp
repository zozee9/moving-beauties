/* Camera.cpp
 *
 * Copyright (c) 2019, University of Minnesota
 *
 * Author: Bridger Herman (herma582@umn.edu)
 *
 */

#include "Camera.h"

UserCamera::UserCamera(
        glm::vec3 initPos,
        glm::vec3 initDir,
        glm::vec3 initUp,
        float fovDegrees,
        float screenWidth,
        float screenHeight,
        float initNearPlane,
        float initFarPlane
) {
    pos = initPos;
    dir = initDir;
    up = initUp;
    lookAtPoint = pos + dir;
    right = glm::cross(dir, up);

    proj = glm::perspective(
            fovDegrees * 3.14f / 180,
            screenWidth / (float) screenHeight,
            initNearPlane, initFarPlane
    );
    updateViewMatrix();

    fovHalfRadians = fovDegrees * 3.14f / 360;
    aspectRatio = screenWidth / (float) screenHeight;
    nearPlane = initNearPlane;
    farPlane = initFarPlane;
    halfWidthNear = nearPlane * tan(fovHalfRadians) * aspectRatio;
    halfHeightNear = nearPlane * tan(fovHalfRadians);
    halfWidthFar = farPlane * tan(fovHalfRadians) * aspectRatio;
    halfHeightFar = farPlane * tan(fovHalfRadians);

    updateViewFrustum();
}

void UserCamera::updateViewMatrix() {
    view = glm::lookAt(
            pos,
            lookAtPoint,
            up
    );
}

void UserCamera::updateViewFrustum() {
    worldFrustum = {
        // Near top left
        pos + (nearPlane * dir) - (halfWidthNear * right) + (halfHeightNear * up),
        // Near bottom left
        pos + (nearPlane * dir) - (halfWidthNear * right) - (halfHeightNear * up),
        // Near bottom right
        pos + (nearPlane * dir) + (halfWidthNear * right) - (halfHeightNear * up),
        // Near top right
        pos + (nearPlane * dir) + (halfWidthNear * right) + (halfHeightNear * up),

        // Far top left
        pos + (farPlane * dir) - (halfWidthFar * right) + (halfHeightFar * up),
        // Far bottom left
        pos + (farPlane * dir) - (halfWidthFar * right) - (halfHeightFar * up),
        // Far bottom right
        pos + (farPlane * dir) + (halfWidthFar * right) - (halfHeightFar * up),
        // Far top right
        pos + (farPlane * dir) + (halfWidthFar * right) + (halfHeightFar * up),
    };

    // Store planes ax + by + cz + d = 0 -> vec4(a, b, c, d)
    // Left
    glm::vec3 leftNormal = glm::normalize(glm::cross(
        worldFrustum.nearBottomLeft - worldFrustum.nearTopLeft,
        worldFrustum.farTopLeft - worldFrustum.nearTopLeft
    ));
    // Right
    glm::vec3 rightNormal = glm::normalize(glm::cross(
        worldFrustum.farTopRight - worldFrustum.nearTopRight,
        worldFrustum.nearBottomRight - worldFrustum.nearTopRight
    ));
    // Top
    glm::vec3 topNormal = glm::normalize(glm::cross(
        worldFrustum.nearTopLeft - worldFrustum.nearTopRight,
        worldFrustum.farTopRight - worldFrustum.nearTopRight
    ));
    // Bottom
    glm::vec3 bottomNormal = glm::normalize(glm::cross(
        worldFrustum.nearBottomRight - worldFrustum.nearBottomLeft,
        worldFrustum.farBottomRight - worldFrustum.nearBottomRight
    ));

    worldFrustumPlanes = {
      // Left
      glm::vec4(leftNormal.x, leftNormal.y, leftNormal.z,
          -glm::dot(leftNormal, worldFrustum.nearTopLeft)),
      // Right
      glm::vec4(rightNormal.x, rightNormal.y, rightNormal.z,
          -glm::dot(rightNormal, worldFrustum.nearTopRight)),
      // Top
      glm::vec4(topNormal.x, topNormal.y, topNormal.z,
          -glm::dot(topNormal, worldFrustum.nearTopRight)),
      // Bottom
      glm::vec4(bottomNormal.x, bottomNormal.y, bottomNormal.z,
          -glm::dot(bottomNormal, worldFrustum.nearBottomRight)),
    };
}

void UserCamera::updateBasis(glm::vec3 newPos, glm::vec3 newDir, glm::vec3 newUp) {
    pos = newPos;
    dir = newDir;
    up = newUp;
    right = glm::cross(dir, up);
    lookAtPoint = pos + dir;
}
