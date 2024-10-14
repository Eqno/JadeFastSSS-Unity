using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraHelper : MonoBehaviour
{
    public float sensitivityX = 0.1f;
    public float sensitivityY = 0.1f;

    private Vector3 rotation = Vector3.zero;
    private Vector3 pressRotation = Vector3.zero;
    private Vector2 pressPosition = Vector2.zero;

    void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            pressRotation = transform.rotation.eulerAngles;
            pressPosition = Input.mousePosition;
        }
        if (Input.GetMouseButton(0))
        {
            Vector2 deltaPosition = Input.mousePosition;
            deltaPosition -= pressPosition;

            rotation.x = pressRotation.x - deltaPosition.y * sensitivityY;
            rotation.y = pressRotation.y + deltaPosition.x * sensitivityX;
            transform.rotation = Quaternion.Euler(rotation);
        }
    }
}
