using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Materials : MonoBehaviour
{
    public Material winter;
    public Material spring;
    public Material summer;
    public Material fall;

    public void ChangeSeason(GameManager.Season season)
    {
        Renderer renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            switch (season)
            {
                case GameManager.Season.WINTER:
                    renderer.material = winter;
                    break;

                case GameManager.Season.SPRING:
                    renderer.material = spring;
                    break;

                case GameManager.Season.SUMMER:
                    renderer.material = summer;
                    break;

                case GameManager.Season.FALL:
                    renderer.material = fall;
                    break;

                default:
                    break;
            }
        }
    }
}
