using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GiraObstaculo : MonoBehaviour
{
    public float velocidadeHorizontal = 0f;
    public float velocidadeVertical = 5f;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        transform.Rotate(velocidadeVertical * Time.deltaTime ,velocidadeHorizontal * Time.deltaTime,0f);
    }
}
