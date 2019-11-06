using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TileSelector : MonoBehaviour
{
    public GameObject tileHighlightPrefab;

    private GameObject tileHighlight;

    // Start is called before the first frame update
    void Start()
    {
        Vector2Int gPoint = Geometry.GridPoint(0, 0);
        Vector3 point = Geometry.PointFromGrid(gPoint);
        tileHighlight = Instantiate(tileHighlightPrefab, point,
            Quaternion.identity, gameObject.transform);
        tileHighlight.SetActive(false);
    }

    // setup for this activation
    public void EnterState()
    {
        enabled = true;
    }

    // Update is called once per frame
    void Update()
    {
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

        RaycastHit hit;
        if (Physics.Raycast(ray, out hit))
        {
            Vector3 point = hit.point;
            Vector2Int gPoint = Geometry.GridFromPoint(point);

            tileHighlight.SetActive(true);
            tileHighlight.transform.position =
                Geometry.PointFromGrid(gPoint);

            if (Input.GetMouseButtonDown(0))
            {
                GameObject selectedPiece =
                    GameManager.instance.PieceAtGrid(gPoint);
                if (GameManager.instance.DoesPieceBelongToCurrentPlayer(selectedPiece))
                {
                    ExitState(selectedPiece);
                }
            }
        }
        else
        {
            tileHighlight.SetActive(false);
        }
    }

    // cleans up current state
    private void ExitState(GameObject movingPiece)
    {
        this.enabled = false;
        tileHighlight.SetActive(false);
        MoveSelector move = GetComponent<MoveSelector>();

        move.EnterState(movingPiece);
    }
}
