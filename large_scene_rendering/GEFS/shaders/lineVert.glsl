#version 330 core

in vec3 inPos;

uniform mat4 VP;

void main() {
    // final postion on screen
    gl_Position = VP * vec4(inPos, 1);
}
