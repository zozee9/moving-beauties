using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterShaderToggle : MonoBehaviour
{
    Shader shader1;
    Shader shader2;
    Renderer rend;

    void Start()
    {
        rend = GetComponent<Renderer> ();
        shader1 = Shader.Find("Standard");
        shader2 = Shader.Find("ToonWater");
    }

    void Update()
    {
        if (Input.GetKeyDown("space"))
        {
            if (rend.material.shader == shader1)
            {
                rend.material.shader = shader2;
            }
            else
            {
                rend.material.shader = shader1;
            }
        }
    }
}
