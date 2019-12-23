using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    public GameObject player;

    private float turnSpeed;
    private Vector3 offset;

    // Start is called before the first frame update
    void Start()
    {
        turnSpeed = 10f;
        offset = player.transform.position - this.transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey("a"))
        {
            this.transform.Rotate(0, Time.deltaTime * -turnSpeed, 0);
        }
        if (Input.GetKey("d"))
        {
            this.transform.Rotate(0, Time.deltaTime * turnSpeed, 0);
        }
        // if (Input.GetKey("w"))
        // {
        //     Vector3 position = this.transform.position;
        //     position.z -= speed * Time.deltaTime;
        //     this.transform.position = position;
        // }
        // if (Input.GetKey("s"))
        // {
        //     Vector3 position = this.transform.position;
        //     position.z += speed * Time.deltaTime;
        //     this.transform.position = position;
        // }
    }

    void LateUpdate()
    {
        float desiredAngle = player.transform.eulerAngles.y;
        Quaternion rotation = Quaternion.Euler(0, desiredAngle, 0);
        Vector3 lookOffset = new Vector3(0,1,0);
        transform.position = (player.transform.position) - (rotation * offset);

        transform.LookAt(player.transform);
    }
}
