using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SeguirTarget : MonoBehaviour
{
    public GameObject target;
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        transform.localPosition = target.transform.localPosition + new Vector3(0f,15f,0f);
    }
}
