using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightHelper : MonoBehaviour
{
    public float speedX = 100f;
    public float speedY = 100f;

    void Update()
    {
        Vector3 euler = transform.rotation.eulerAngles;
        if (Input.GetKey(KeyCode.W))
        {
            euler.x += speedX * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.A))
        {
            euler.y -= speedY * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.S))
        {
            euler.x -= speedX * Time.deltaTime;
        }
        if (Input.GetKey(KeyCode.D))
        {
            euler.y += speedY * Time.deltaTime;
        }
        transform.rotation = Quaternion.Euler(euler);
    }
}
