using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Reinicia : MonoBehaviour
{
    private Vector3 posInicial;
    // Start is called before the first frame update
    void Start()
    {
        posInicial=transform.localPosition;
    }

    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown("r")){
            GetComponent<Rigidbody>().velocity = new Vector3(0f,0f,0f);
            GameObject.Find("Caixa").transform.localRotation = new Quaternion(0f,0f,0f,0f);
            transform.localPosition=posInicial;
        }
    }
}
