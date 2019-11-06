using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterAttackSelector : MonoBehaviour
{
    public GameObject attackLocationPrefab;
    public GameObject attackHighlightPrefab;

    private List<Vector2Int> attackLocations;
    private List<GameObject> attackLocationHighlights;
    private GameObject attackHighlight;

    private bool attacking;
    private bool dying;
    private Vector2Int dyingPoint;
    private float startTime;

    GameObject movingPiece;

    // Start is called before the first frame update
    void Start()
    {
        this.enabled = false;

        Vector2Int gridPoint = Geometry.GridPoint(0, 0);
        Vector3 point = Geometry.PointFromGrid(gridPoint);
        attackHighlight = Instantiate(attackHighlightPrefab, point, Quaternion.identity, gameObject.transform);
        attackHighlight.SetActive(false);
    }

    // setup for this activation
    public void EnterState(GameObject piece)
    {
        movingPiece = piece;
        this.enabled = true;
        dying = false;

        attackLocations = GameManager.instance.AttacksForPiece(movingPiece);

        attackLocationHighlights = new List<GameObject>();

        foreach (Vector2Int loc in attackLocations)
        {
            GameObject highlight;

            highlight = Instantiate(attackLocationPrefab,
                Geometry.PointFromGrid(loc), Quaternion.identity,
                gameObject.transform);

            attackLocationHighlights.Add(highlight);
        }

        if (attackLocations.Count == 0) // and we oop out
        {
            ExitState();
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (!dying && !attacking)
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

            RaycastHit hit;
            if (Physics.Raycast(ray, out hit))
            {
                Vector3 point = hit.point;
                Vector2Int gPoint = Geometry.GridFromPoint(point);

                // show path if it's a valid move
                if (attackLocations.Contains(gPoint))
                {
                    attackHighlight.SetActive(true);
                    attackHighlight.transform.position =
                        Geometry.PointFromGrid(gPoint) + new Vector3(0,.01f,0);
                }
                else // if move is not valid, get out!
                {
                    attackHighlight.SetActive(false);
                    return;
                }

                if (Input.GetMouseButtonDown(0))
                {
                    attacking = true;
                    Piece piece = movingPiece.GetComponent<Piece>();
                    piece.Attack();

                    dyingPoint = gPoint;

                    startTime = Time.time;
                }
            }
            else
            {
                attackHighlight.SetActive(false);
            }
        }
        else  // dying/attacking animation is playing
        {
            if (attacking && Time.time - startTime > 1)
            {
                GameObject dyingPiece = GameManager.instance.PieceAtGrid(dyingPoint);
                Piece dPiece = dyingPiece.GetComponent<Piece>();
                dPiece.Die();
                attacking = false;
                dying = true;
            }
            else if (dying && Time.time - startTime > 2)
            {
                GameManager.instance.KillPieceAt(dyingPoint);
                ExitState();
            }
        }
    }

    // cleans up current state
    private void ExitState()
    {
        this.enabled = false;
        attackHighlight.SetActive(false);
        foreach (GameObject highlight in attackLocationHighlights)
        {
            Destroy(highlight);
        }

        TileSelector selector = GetComponent<TileSelector>();

        // switch turns, then go back to selecting
        GameManager.instance.NextPlayer();
        selector.EnterState();
    }
}
