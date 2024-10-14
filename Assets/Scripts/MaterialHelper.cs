using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaterialHelper : MonoBehaviour
{
    public Transform _camera = null;
    public Transform _light = null;

    void Update()
    {
        foreach(Renderer renderer in GetComponentsInChildren<Renderer>())
        {
            renderer.material.SetVector("_CameraPosition", _camera.position);
            renderer.material.SetVector("_LightPosition", _light.position);
        }
    }
}
