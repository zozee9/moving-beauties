using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterUpdate : MonoBehaviour
{
    private float snowCoverSpeed;
    private float snowVanishSpeed;

    // Start is called before the first frame update
    void Start()
    {
        snowCoverSpeed = .25f;
        snowVanishSpeed = 2.5f;
        gameObject.GetComponent<Renderer>().sharedMaterial.SetFloat("_SnowAmount", 1f);
    }

    // Update is called once per frame
    void Update()
    {
        bool moving = false;
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            moving = true;
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            moving = true;
        }
        if (Input.GetKey(KeyCode.UpArrow))
        {
            moving = true;
        }
        if (Input.GetKey(KeyCode.DownArrow))
        {
            moving = true;
        }
        
        if (GameManager.instance.GetSeason() == GameManager.Season.WINTER)
        {
            Snow(moving);
        }
    }

    void Snow(bool moving)
    {
        float currentSnowAmount = gameObject.GetComponent<Renderer>().sharedMaterial.GetFloat("_SnowAmount");
        if (!moving) {
            gameObject.GetComponent<Renderer>().sharedMaterial.SetFloat("_SnowAmount", Mathf.Max(-.3f, currentSnowAmount - snowCoverSpeed * Time.deltaTime));
        }
        else
        {
            gameObject.GetComponent<Renderer>().sharedMaterial.SetFloat("_SnowAmount", Mathf.Min(1f, currentSnowAmount + snowVanishSpeed * Time.deltaTime));
        }
    }
}
