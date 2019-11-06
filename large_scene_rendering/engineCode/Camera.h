#pragma once

/* Camera.h
 *
 * Copyright (c) 2019, University of Minnesota
 *
 * Author: Bridger Herman (herma582@umn.edu)
 *
 */

#define GLM_FORCE_RADIANS
#define GLM_SWIZZLE
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

struct ViewFrustum {
    glm::vec3 nearTopLeft;
    glm::vec3 nearBottomLeft;
    glm::vec3 nearBottomRight;
    glm::vec3 nearTopRight;

    glm::vec3 farTopLeft;
    glm::vec3 farBottomLeft;
    glm::vec3 farBottomRight;
    glm::vec3 farTopRight;
};

struct ViewFrustumPlanes {
  glm::vec4 left;
  glm::vec4 right;
  glm::vec4 top;
  glm::vec4 bottom;
};

class UserCamera {
    public:
        UserCamera(
                glm::vec3 initPos,
                glm::vec3 initDir,
                glm::vec3 initUp,
                float fovDegrees,
                float screenWidth,
                float screenHeight,
                float nearPlane,
                float farPlane
        );

        // Update the camera view matrix from its current pos, dir, and up
        void updateViewMatrix();

        // Update the bounds of the view frustum
        void updateViewFrustum();

        // Update the pos, dir, up, and lookAt vectors
        void updateBasis(glm::vec3 pos, glm::vec3 dir, glm::vec3 up);

        glm::mat4 view;
        glm::mat4 proj;

        glm::vec3 pos;
        glm::vec3 dir;
        glm::vec3 up;
        glm::vec3 right;
        glm::vec3 lookAtPoint;

        ViewFrustum worldFrustum;
        ViewFrustumPlanes worldFrustumPlanes;

        float nearPlane;
        float farPlane;

    private:
        float fovHalfRadians;
        float aspectRatio;

        float halfWidthNear;
        float halfHeightNear;
        float halfWidthFar;
        float halfHeightFar;
};
