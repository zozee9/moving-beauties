using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraMovement : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        float speed = 10f;
        if (Input.GetKey("a"))
        {
            Vector3 position = this.transform.position;
            position.x += speed * Time.deltaTime;
            this.transform.position = position;
        }
        if (Input.GetKey("d"))
        {
            Vector3 position = this.transform.position;
            position.x -= speed * Time.deltaTime;
            this.transform.position = position;
        }
        if (Input.GetKey("w"))
        {
            Vector3 position = this.transform.position;
            position.z -= speed * Time.deltaTime;
            this.transform.position = position;
        }
        if (Input.GetKey("s"))
        {
            Vector3 position = this.transform.position;
            position.z += speed * Time.deltaTime;
            this.transform.position = position;
        }
    }
}
