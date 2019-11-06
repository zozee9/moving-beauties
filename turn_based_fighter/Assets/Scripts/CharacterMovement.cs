using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterMovement : MonoBehaviour
{
    private GameObject movingPiece; // will move one direction, then the other...
    private List<Vector3> goalPath;
    private int currentPos;

    private float maxRunSpeed;
    private float maxWalkSpeed;
    private float minWalkSpeed;
    private float currentSpeed;

    //private float goalAng;
    //private int turnDir;

    private bool willRun;
    private bool turning;
    //private bool rotateFirst;

    // Start is called before the first frame update
    void Start()
    {
        this.enabled = false; // start off

        maxRunSpeed = 3f;
        maxWalkSpeed = 1.5f;
        minWalkSpeed = .75f;
        currentSpeed = 0f;
    }

    public void EnterState(GameObject piece, List<Vector2Int> gPath)
    {
        movingPiece = piece;
        currentPos = 0;

        willRun = gPath.Count > 2;

        goalPath = new List<Vector3>();

        for (int i = 0; i < gPath.Count; i++)
        {
            goalPath.Add(Geometry.PointFromGrid(gPath[i]));
        }

        currentSpeed = minWalkSpeed;

        // start with turning
        // goalAng = GameManager.instance.GetRelativeGridPosition(movingPiece.transform.position, goalPath[currentPos]);
        //
        // turnDir = FindTurnDir(movingPiece);

        turning = true;

        this.enabled = true;
    }

    // Update is called once per frame
    void Update()
    {
        Piece piece;
        // Time.deltaTime for smooth animation
        float timePassed = Time.deltaTime;

        // if the piece should turn before moving, do that first
        turning = true;
        if (turning) { // current turn
            // first turn bases it on what is coming up
            float goalAng;

            if (Geometry.GridFromPoint(goalPath[currentPos]) != Geometry.GridFromPoint(movingPiece.transform.position))
            {
                goalAng = GameManager.instance.GetRelativeGridAngle(movingPiece.transform.position, goalPath[currentPos]);
            } // looking at the tile we're going to next
            else if (currentPos != goalPath.Count - 1)
            {
                goalAng = GameManager.instance.GetRelativeGridAngle(movingPiece.transform.position, goalPath[currentPos+1]); // start planning ahead
            } // just chillin
            else
            {
                goalAng = movingPiece.transform.eulerAngles.y; // current angle
            }

            if (goalAng != movingPiece.transform.eulerAngles.y)
            {
                int turnDir = FindTurnDir(movingPiece, goalAng);

                piece = movingPiece.GetComponent<Piece>();
                piece.SetSpeed(currentSpeed); // start walk animation :)

                // rotate in relation to self! :)
                float origAng = movingPiece.transform.eulerAngles.y;
                // turn speed
                // figure out which direction to turn!

                float newAng = origAng + 120*timePassed*turnDir;

                // deal with going over 0 when going right
                float shiftedGoalAng = goalAng;
                if (turnDir == 1 && goalAng == 0) {
                    shiftedGoalAng = 360;
                }

                if (Mathf.Abs(newAng - origAng) > Mathf.Abs(shiftedGoalAng - origAng))
                {
                    newAng = goalAng;
                }

                Vector3 currentEulerAngles = new Vector3(0,newAng,0);
                Quaternion currentRotation = new Quaternion();
                currentRotation.eulerAngles = currentEulerAngles;
                movingPiece.transform.rotation = currentRotation;

                if (movingPiece.transform.eulerAngles.y == goalAng)
                {
                    turning = false;
                }

                // don't move if we're on the first rotation!
                if (currentPos == 0 && Geometry.GridFromPoint(goalPath[0]) != Geometry.GridFromPoint(movingPiece.transform.position))
                {
                    return;
                }
            }

        }
        Vector3 pos = movingPiece.transform.position;

        Vector3 dir = goalPath[currentPos] - pos;
        Vector3 dirNorm = dir.normalized;

        piece = movingPiece.GetComponent<Piece>();

        // BELOW CODE DEALS WITH THE MOVEMENT ANIMATION WORKING SMOOTHLY (YAY)
        if (willRun && (goalPath.Count - currentPos) > 2)
        {
            currentSpeed = Mathf.Min(currentSpeed+(currentSpeed * 1.5f * timePassed), maxRunSpeed);
        }
        else if ((goalPath.Count - currentPos) > 2)
        {
            currentSpeed = Mathf.Min(currentSpeed+(currentSpeed * 1.5f * timePassed), maxWalkSpeed);
         }
         else
        {
            currentSpeed = Mathf.Max(currentSpeed-(currentSpeed * 1.5f * timePassed), minWalkSpeed);
        }

        piece.SetSpeed(currentSpeed);

        // NOW TURN!
        Vector3 vel = dirNorm * currentSpeed * timePassed;

        // if going where we want to go will put us past our goal,
        // just go to our goal :)

        // where we are: pos
        // where we want to be: goalPath[curentPos]
        // where we will end up:
        Vector3 goalPos = pos + vel;
        Vector3 newPos;

        // if the new position is further from the current position than the
        // goal is from the current position, then set the goal as the new
        // position
        float overshoot = Mathf.Abs(Vector3.Distance(goalPos, pos)) - Mathf.Abs(Vector3.Distance(goalPath[currentPos], pos));
        if (overshoot >= 0f)
        {
            newPos = goalPath[currentPos];

            movingPiece.transform.position = newPos; // move this far

            // deal with overshoot!
            currentPos++; // move to next state, this is a lil janky but i'm calling it good unless it looks bad

            if (currentPos != goalPath.Count)
            {
                // time left is how much extra we went / how far we could have gone * amount of time we have total
                float timeLeft = (overshoot/Vector3.Distance(goalPos, pos)) * timePassed;
                dir = goalPath[currentPos] - newPos;
                dirNorm = dir.normalized;
                vel = dirNorm * currentSpeed * timeLeft;

                newPos += vel; // go new direction
            }
        }
        else
        {
            newPos = goalPos;
        }

        movingPiece.transform.position = newPos;

        // if we have moved to the end, exit! :)
        if (currentPos == goalPath.Count) { //
            ExitState();
        }

    }

    private int FindTurnDir(GameObject movingPiece, float goalAng)
    {
        float origAng = movingPiece.transform.eulerAngles.y;

        int tempTurnDir = 0;
        if (movingPiece.transform.eulerAngles.y != goalAng)
        {
            tempTurnDir = 1;
            // normal scenario
            if (goalAng < origAng)
            {
                tempTurnDir = -1;
            }

            // deal with 0 :( bad zero
            if (origAng == 0 && goalAng > 180)
            {
                tempTurnDir = -1;
            }
            else if (origAng > 180 && goalAng == 0)
            {
                tempTurnDir = 1;
            }
        }
        return tempTurnDir;
    }

    private void ExitState()
    {
        // make sure we are facing the right way
        if (goalPath.Count > 1)
        {
            float newAng = GameManager.instance.GetRelativeGridAngle(goalPath[currentPos-2], goalPath[currentPos-1]);

            Vector3 currentEulerAngles = new Vector3(0,newAng,0);
            Quaternion currentRotation = new Quaternion();
            currentRotation.eulerAngles = currentEulerAngles;
            movingPiece.transform.rotation = currentRotation;
        }

        this.enabled = false;

        // all done animating! set speed back to 0
        Piece piece = movingPiece.GetComponent<Piece>();
        piece.SetSpeed(0f);

        CharacterAttackSelector attacker = GetComponent<CharacterAttackSelector>();
        attacker.EnterState(movingPiece);

        //GameManager.instance.DeselectPiece(movingPiece);
        movingPiece = null;


    }
}
