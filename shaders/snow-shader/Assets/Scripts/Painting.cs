using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Painting : MonoBehaviour
{
    public GameObject collideObject; // what to collide with
    Collider collider;
    RenderTexture renderTexture;
    public int resolution = 512;
    Texture2D whiteMap;
    public float brushSize;
    public Texture2D brushTexture;
    Vector2 stored;
    void Start()
    {
        CreateClearTexture();// clear white texture to draw on

        // set up collision for one game object (only need to check one!)
        collider = collideObject.GetComponent<Collider>();

        Renderer rend = collideObject.transform.GetComponent<Renderer>();
        renderTexture = getWhiteRT();
        rend.material.SetTexture("_PaintMap", renderTexture);
    }

    void Update()
    {
        RaycastHit hit;
        if (Physics.Raycast(transform.position, Vector3.down, out hit))
        {
            Collider coll = hit.collider;
            if (coll != null && coll == collider)
            {
                // if (!paintTextures.ContainsKey(coll)) // if there is already paint on the material, add to that
                // {
                //     print("more than one collision now");
                // }

                if (stored != hit.lightmapCoord) // stop drawing on the same point
                {
                    stored = hit.lightmapCoord;
                    Vector2 pixelUV = hit.lightmapCoord;
                    pixelUV.y *= resolution;
                    pixelUV.x *= resolution;
                    DrawTexture(renderTexture, pixelUV.x, pixelUV.y);
                }
            }
        }
    }

    void DrawTexture(RenderTexture rt, float posX, float posY)
    {
        RenderTexture.active = rt; // activate rendertexture for drawtexture;
        GL.PushMatrix(); // save matrixes
        GL.LoadPixelMatrix(0, resolution, resolution, 0); // setup matrix for correct size

        // draw brushtexture
        Graphics.DrawTexture(new Rect(posX - brushTexture.width / brushSize, (rt.height - posY) - brushTexture.height / brushSize, brushTexture.width / (brushSize * 0.5f), brushTexture.height / (brushSize * 0.5f)), brushTexture);
        GL.PopMatrix();
        RenderTexture.active = null;// turn off rendertexture
    }

    RenderTexture getWhiteRT()
    {
        RenderTexture rt = new RenderTexture(resolution, resolution, 32);
        Graphics.Blit(whiteMap, rt);
        return rt;
    }

    void CreateClearTexture()
    {
        whiteMap = new Texture2D(1, 1);
        whiteMap.SetPixel(0, 0, Color.black);
        whiteMap.Apply();
    }
}
