using System.Collections;
using System.Collections.Generic;
using System.Security.Cryptography.X509Certificates;
using UnityEngine;

public class MoveObstaculo : MonoBehaviour
{
    public float velocidadeLado = 0f;
    public float velocidadeFrente = 50f;
    public float distancia = 10;
    private Vector3 posInicial;
    private bool voltando = false;

    // Start is called before the first frame update
    void Start()
    {
        posInicial = transform.localPosition;
    }

    // Update is called once per frame
    void FixedUpdate()
    {
        if(voltando){
            transform.localPosition -=new Vector3(velocidadeLado*Time.deltaTime,0,velocidadeFrente*Time.deltaTime);
        }
        else{
            transform.localPosition +=new Vector3(velocidadeLado*Time.deltaTime,0,velocidadeFrente*Time.deltaTime);
        }
        if(transform.localPosition.x < posInicial[0] || transform.localPosition.z < posInicial[2]){
            transform.localPosition = posInicial;
            voltando = false;
        }
        
        if(transform.localPosition.x > posInicial[0]+distancia || transform.localPosition.z > posInicial[2]+distancia){
            transform.localPosition = posInicial + new Vector3(velocidadeLado!=0?distancia:0f,0f,velocidadeFrente!=0?distancia:0f);
            voltando = true;
        }
        
        
    }
}
