using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class GameManager : MonoBehaviour
{
    public enum Season {WINTER, SPRING, SUMMER, FALL, VOID};

    public static GameManager instance;

    public GameObject directionalLight;

    public GameObject firstPersonCamera;
    public GameObject thirdPersonCamera;
    private int cameraNum;

    public GameObject objectFolder;
    public GameObject ground;
    public TreeMaker treeMaker;
    public GameObject[] winterItems;
    public GameObject[] springItems;
    public GameObject[] summerItems;
    public GameObject[] fallItems;

    public Color winterLight; // winter summer spring fall
    public Color springLight; // winter summer spring fall
    public Color summerLight; // winter summer spring fall
    public Color fallLight; // winter summer spring fall

    public Color winterBackground; // winter summer spring fall
    public Color springBackground; // winter summer spring fall
    public Color summerBackground; // winter summer spring fall
    public Color fallBackground; // winter summer spring fall

    private Dictionary<Season, GameObject[]> seasonalItems;
    private Dictionary<Season, Color> lightColors;
    private Dictionary<Season, Color> backgroundColors;

    private Season season;

    void Awake()
    {
        instance = this;
    }

    // Start is called before the first frame update
    void Start()
    {
        treeMaker.MakeTrees();

        // seasonal items
        seasonalItems = new Dictionary<Season, GameObject[]>();
        seasonalItems.Add(Season.WINTER, winterItems);
        seasonalItems.Add(Season.SPRING, springItems);
        seasonalItems.Add(Season.SUMMER, summerItems);
        seasonalItems.Add(Season.FALL, fallItems);

        // light color per season
        lightColors = new Dictionary<Season, Color>();
        lightColors.Add(Season.WINTER, winterLight);
        lightColors.Add(Season.SPRING, springLight);
        lightColors.Add(Season.SUMMER, summerLight);
        lightColors.Add(Season.FALL, fallLight);

        // background color per season
        backgroundColors = new Dictionary<Season, Color>();
        backgroundColors.Add(Season.WINTER, winterBackground);
        backgroundColors.Add(Season.SPRING, springBackground);
        backgroundColors.Add(Season.SUMMER, summerBackground);
        backgroundColors.Add(Season.FALL, fallBackground);

        // set it to winter to begin with
        season = Season.VOID;

        // delete any shown items :)
        EndSeason(Season.WINTER);
        EndSeason(Season.SPRING);
        EndSeason(Season.SUMMER);
        EndSeason(Season.FALL);

        firstPersonCamera.SetActive(false);
        thirdPersonCamera.SetActive(true);
        cameraNum = 0;

        UpdateSeason(Season.SPRING);
    }

    public Season GetSeason()
    {
        return season;
    }

    void UpdateSeason(Season newSeason)
    {
        if (season != newSeason) // if actually updating season
        {
            EndSeason(season);
            StartSeason(newSeason);
            UpdateFolderSeasons(newSeason,objectFolder.transform);
        }
    }

    void UpdateFolderSeasons(Season newSeason, Transform t)
    {
        foreach (Transform child in t)
        {
            if (child.gameObject.activeSelf) // ignore hidden items
            {
                if (child.childCount == 0 && child.gameObject.GetComponent<Materials>() != null)
                {
                    child.gameObject.GetComponent<Materials>().ChangeSeason(newSeason);
                }
                else
                {
                    UpdateFolderSeasons(newSeason, child);
                }
            }
        }
    }

    void EndSeason(Season currentSeason)
    {
        if (currentSeason != Season.VOID) // if it's an actual season
        {
            foreach (GameObject obj in seasonalItems[currentSeason])
            {
                obj.SetActive(false);
            }
        }
    }

    void StartSeason(Season newSeason)
    {
        print(newSeason);
        season = newSeason;

        // add each of the seasonal items
        foreach (GameObject obj in seasonalItems[season])
        {
            obj.SetActive(true);
        }

        // move the ground
        if (newSeason == Season.WINTER) // ground moves up in winter
        {
            Vector3 currentPos = ground.transform.position;
            ground.transform.position = new Vector3(currentPos.x,3.6f,currentPos.z);
        }
        else
        {
            Vector3 currentPos = ground.transform.position;
            ground.transform.position = new Vector3(currentPos.x,3.5f,currentPos.z);
        }

        // change light color
        directionalLight.GetComponent<Light>().color = lightColors[season];
        firstPersonCamera.GetComponent<Camera>().backgroundColor = backgroundColors[season];
        thirdPersonCamera.GetComponent<Camera>().backgroundColor = backgroundColors[season];

    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.Alpha1))
        {
            UpdateSeason(Season.WINTER);
        }
        else if (Input.GetKey(KeyCode.Alpha2))
        {
            UpdateSeason(Season.SPRING);
        }
        else if (Input.GetKey(KeyCode.Alpha3))
        {
            UpdateSeason(Season.SUMMER);
        }
        else if (Input.GetKey(KeyCode.Alpha4))
        {
            UpdateSeason(Season.FALL);
        }

        if (Input.GetKey(KeyCode.Space))
        {
            cameraNum = (cameraNum + 1) % 2;
            if (cameraNum == 0)
            {
                firstPersonCamera.SetActive(false);
                thirdPersonCamera.SetActive(true);
            }
            else
            {
                firstPersonCamera.SetActive(true);
                thirdPersonCamera.SetActive(false);
            }
        }
    }
}
