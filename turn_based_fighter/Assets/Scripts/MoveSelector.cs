using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MoveSelector : MonoBehaviour
{
    public GameObject moveLocationPrefab;
    public GameObject pathHighlightPrefab;

    private List<GameObject> pathHighlights;
    private GameObject movingPiece;

    Dictionary<Vector2Int, List<Vector2Int>> movePaths;
    private List<GameObject> locationHighlights;

    // Start is called before the first frame update
    void Start()
    {
        this.enabled = false;
    }

    // setup for this activation
    public void EnterState(GameObject piece)
    {
        movingPiece = piece;
        this.enabled = true;

        movePaths = GameManager.instance.MovesForPiece(movingPiece);
        locationHighlights = new List<GameObject>();
        pathHighlights = new List<GameObject>();

        foreach (Vector2Int loc in movePaths.Keys)
        {
            GameObject highlight;

            highlight = Instantiate(moveLocationPrefab,
                Geometry.PointFromGrid(loc), Quaternion.identity,
                gameObject.transform);

            locationHighlights.Add(highlight);
        }
    }

    // Update is called once per frame
    void Update()
    {
        // get rid of all the highlights
        foreach (GameObject highlight in pathHighlights)
        {
            Destroy(highlight);
        }
        pathHighlights.Clear();

        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
        {
            Vector3 point = hit.point;
            Vector2Int gPoint = Geometry.GridFromPoint(point);

            // show path if it's a valid move
            if (movePaths.ContainsKey(gPoint))
            {
                foreach (Vector2Int loc in movePaths[gPoint])
                {
                    GameObject highlight;

                    highlight = Instantiate(pathHighlightPrefab,
                        Geometry.PointFromGrid(loc) + new Vector3(0,.01f,0), Quaternion.identity,
                        gameObject.transform);
                    // }
                    pathHighlights.Add(highlight);
                }
            }
            else // if move is not valid, get out!
            {
                return;
            }

            if (Input.GetMouseButtonDown(0))
            {
                // if there's not already a piece there, move! :D
                GameManager.instance.Move(movingPiece, gPoint);
                ExitState(movePaths[gPoint]);
            }
        }

    }

    // cleans up current state
    private void ExitState(List<Vector2Int> goalPath)
    {
        this.enabled = false;
        // tileHighlight.SetActive(false);
        foreach (GameObject highlight in pathHighlights)
        {
            Destroy(highlight);
        }

        // get rid of all the highlights
        foreach (GameObject highlight in locationHighlights)
        {
            Destroy(highlight);
        }

        CharacterMovement movement = GetComponent<CharacterMovement>();
        movement.EnterState(movingPiece, goalPath);
        movingPiece = null;
    }
}
