/*
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public static GameManager instance;

    public Board board;

    public GameObject whiteQueen;
    public GameObject blackQueen;

    private GameObject[,] pieces;

    private Player white;
    private Player black;
    public Player currentPlayer;
    public Player otherPlayer;

    void Awake()
    {
        instance = this;
    }

    void Start ()
    {
        pieces = new GameObject[8, 8];

        white = new Player("Robots", true);
        black = new Player("Bees", false);

        currentPlayer = white;
        otherPlayer = black;

        InitialSetup();
    }

    void Update()
    {
        currentPlayer.Dance();
        otherPlayer.Dance();
    }

    private void InitialSetup()
    {
        AddPiece(whiteQueen, white, 2, 6);
        AddPiece(whiteQueen, white, 3, 3);
        AddPiece(whiteQueen, white, 7, 2);
        AddPiece(whiteQueen, white, 0, 0);
        AddPiece(blackQueen, black, 4, 2);
        AddPiece(blackQueen, black, 6, 1);
        AddPiece(blackQueen, black, 3, 4);
        AddPiece(blackQueen, black, 7, 7);
        AddPiece(blackQueen, black, 1, 2);
    }

    public void AddPiece(GameObject prefab, Player player, int col, int row)
    {
        GameObject pieceObject = board.AddPiece(prefab, col, row);
        player.pieces.Add(pieceObject);
        pieces[col, row] = pieceObject;
    }

    // public void SelectPieceAtGrid(Vector2Int gridPoint)
    // {
    //     GameObject selectedPiece = pieces[gridPoint.x, gridPoint.y];
    // }

    public GameObject PieceAtGrid(Vector2Int gridPoint)
    {
        if (gridPoint.x > 7 || gridPoint.y > 7 || gridPoint.x < 0 || gridPoint.y < 0)
        {
            return null;
        }
        return pieces[gridPoint.x, gridPoint.y];
    }

    public Vector2Int GridForPiece(GameObject piece)
    {
        for (int i = 0; i < 8; i++)
        {
            for (int j = 0; j < 8; j++)
            {
                if (pieces[i, j] == piece)
                {
                    return new Vector2Int(i, j);
                }
            }
        }

        return new Vector2Int(-1, -1);
    }

    public bool FriendlyPieceAt(Vector2Int gridPoint)
    {
        GameObject piece = PieceAtGrid(gridPoint);

        if (piece == null) {
            return false;
        }

        if (otherPlayer.pieces.Contains(piece))
        {
            return false;
        }

        return true;
    }

    public bool DoesPieceBelongToCurrentPlayer(GameObject piece)
    {
        return currentPlayer.pieces.Contains(piece);
    }

    public float GetRelativeGridAngle(Vector3 gridPos, Vector3 goalPos)
    {
        Vector2Int gridPoint = Geometry.GridFromPoint(gridPos);
        Vector2Int goalPoint = Geometry.GridFromPoint(goalPos);
        if (gridPoint + Vector2Int.up == goalPoint)
        {
            return 0;
        }
        else if (gridPoint + Vector2Int.right == goalPoint)
        {
            return 90;
        }
        else if (gridPoint + Vector2Int.down == goalPoint)
        {
            return 180;
        }
        else if (gridPoint + Vector2Int.left == goalPoint)
        {
            return 270;
        }
        else
        {
            Debug.Log("goal point is not next to grid point, can't calculate angle");
            return 0; // ERROR
        }
    }

    // game manager moves piece in memory, character movement moves piece
    // in space
    public void Move(GameObject piece, Vector2Int gridPoint)
    {
        Vector2Int startGridPoint = GridForPiece(piece);
        pieces[startGridPoint.x, startGridPoint.y] = null;
        pieces[gridPoint.x, gridPoint.y] = piece;
    }

    public Dictionary<Vector2Int, List<Vector2Int>> MovesForPiece(GameObject pieceObject)
    {
        Piece piece = pieceObject.GetComponent<Piece>();
        Vector2Int gridPoint = GridForPiece(pieceObject);
        var locations = piece.MoveLocations(gridPoint);

        // rules that are true for any piece!

        // get rid if off board
        locations.RemoveAll(tile => tile.x < 0 || tile.x > 7
            || tile.y < 0 || tile.y > 7);

        // filter out locations with a piece
        locations.RemoveAll(tile => PieceAtGrid(tile));

        // copy original locations to use to find unreachable moves
        List<Vector2Int> locationsCopy = new List<Vector2Int>(locations);

        Dictionary<Vector2Int, List<Vector2Int>> allPaths = ReachableMoves(gridPoint, locationsCopy, piece.dist);

        return allPaths;
    }

    private List<Vector2Int> getPath(Dictionary<Vector2Int, Vector2Int> paths, Vector2Int current)
    {
        if (!paths.ContainsKey(current)) // == Mathf.Infinity)
        {
            return null; // no way of getting back :(
        }

        List<Vector2Int> finalPath = new List<Vector2Int>();
        finalPath.Add(current);

        while (paths.ContainsKey(current))
        {
            current = paths[current];
            finalPath.Insert(0, current);
        }

        // remove where we started, get rid of first thing
        finalPath.RemoveAt(0);
        return finalPath;
    }

    // Dijkstra's
    // I realized that I only have to run dijkstra's once to get all paths -- not A* anymore
    // https://en.wikipedia.org/wiki/A*_search_algorithm and https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm#Algorithm wiki is my friend
    // retuns a dictionary of each valid move and how to get to it
    private Dictionary<Vector2Int, List<Vector2Int>> ReachableMoves(Vector2Int gridPoint, List<Vector2Int> locations, int maxDist)
    {
        List<Vector2Int> frontier = new List<Vector2Int>(); // object list
        frontier.Add(gridPoint);

        Dictionary<Vector2Int, Vector2Int> paths = new Dictionary<Vector2Int, Vector2Int>();

        // if key doesn't exist, treat as inf
        Dictionary<Vector2Int, float> cost = new Dictionary<Vector2Int, float>();
        for (int i = 0; i < locations.Count; i++)
        {
            cost.Add(locations[i], Mathf.Infinity);
        }
        cost[gridPoint] = 0;

        while (frontier.Count != 0)
        {
            // brute force search
            int minIdx = 0;
            float minScore = Mathf.Infinity;
            for (int i = 0; i < frontier.Count; i++)
            {
                if (cost[frontier[i]] < minScore)
                {
                    minIdx = i;
                    minScore = cost[frontier[i]];
                }
            }
            Vector2Int current = frontier[minIdx];

            frontier.RemoveAt(minIdx);

            Vector2Int[] neighbors = new Vector2Int[4];
            neighbors[0] = Vector2Int.left;
            neighbors[1] = Vector2Int.up;
            neighbors[2] = Vector2Int.right;
            neighbors[3] = Vector2Int.down;

            foreach (Vector2Int dir in neighbors)
            {
                Vector2Int check = current + dir;
                if (locations.Contains(check)) // only check rest if it's a valid location
                {
                    float costGuess = cost[current] + 1;
                    if (costGuess < cost[check])
                    {
                        // best path here so far, save it!
                        if (paths.ContainsKey(check))
                        {
                            paths[check] = current;
                        }
                        else
                        {
                            paths.Add(check,current);
                        }

                        cost[check] = costGuess;
                        //hCost[check] = costGuess + h(check,goalGridPoint);

                        if (!frontier.Contains(check))
                        {
                            frontier.Add(check);
                        }
                    }

                }
            }
        }

        Dictionary<Vector2Int, List<Vector2Int>> pathMap = new Dictionary<Vector2Int, List<Vector2Int>>();
        for (int i = 0; i < locations.Count; i++)
        {
            List<Vector2Int> path = getPath(paths,locations[i]);
            if (path != null && path.Count <= maxDist) // if there is a path and it's within reach
            {
                pathMap.Add(locations[i],path);
            }
        }
        return pathMap;
    }

    public List<Vector2Int> AttacksForPiece(GameObject pieceObject)
    {
        Piece piece = pieceObject.GetComponent<Piece>();
        Vector2Int gridPoint = GridForPiece(pieceObject);
        var locations = piece.AttackLocations(gridPoint);

        // rules that are true for any piece!

        // get rid if off board
        locations.RemoveAll(tile => tile.x < 0 || tile.x > 7
            || tile.y < 0 || tile.y > 7);

        // filter out locations without a piece
        locations.RemoveAll(tile => !PieceAtGrid(tile));
        locations.RemoveAll(tile => FriendlyPieceAt(tile));

        return locations;
    }

    public void NextPlayer()
    {
        Player tempPlayer = currentPlayer;
        currentPlayer = otherPlayer;
        otherPlayer = tempPlayer;
    }

    // never getting called right now :( :( :(
    public void KillPieceAt(Vector2Int gridPoint)
    {
        GameObject toDie = PieceAtGrid(gridPoint);

        currentPlayer.capturedPieces.Add(toDie);
        otherPlayer.pieces.Remove(toDie);

        pieces[gridPoint.x,gridPoint.y] = null;

        Destroy(toDie);

        if (otherPlayer.pieces.Count == 0)
        {
            Debug.Log(currentPlayer.name + " win!");

            currentPlayer.Win();

            Destroy(board.GetComponent<TileSelector>());
            Destroy(board.GetComponent<MoveSelector>());
            Destroy(board.GetComponent<CharacterMovement>());
            Destroy(board.GetComponent<CharacterAttackSelector>());
        }
    }
}
