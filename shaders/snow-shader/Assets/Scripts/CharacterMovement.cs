using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterMovement : MonoBehaviour
{
    private float movementSpeed;
    private float turnSpeed;

    // Start is called before the first frame update
    void Start()
    {
        movementSpeed = 1.5f;

        turnSpeed = 90f;
    }

    // Update is called once per frame
    void Update()
    {
        // bool moving = false;


        if (Input.GetKey(KeyCode.LeftArrow))
        {
            this.transform.Rotate(0, Time.deltaTime * -turnSpeed, 0);
            // moving = true;
        }
        if (Input.GetKey(KeyCode.RightArrow))
        {
            this.transform.Rotate(0, Time.deltaTime * turnSpeed, 0);
            // moving = true;
        }
        if (Input.GetKey(KeyCode.UpArrow))
        {
            this.transform.position += this.transform.forward * movementSpeed * Time.deltaTime;
            // moving = true;
        }
        if (Input.GetKey(KeyCode.DownArrow))
        {
            this.transform.position -= this.transform.forward * movementSpeed * Time.deltaTime;
            // moving = true;
        }
    }
}
