using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CapturaMoeda : MonoBehaviour
{
    public AudioClip somMoeda;

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(0,0,Time.deltaTime *100);
    }

    private void OnTriggerEnter(Collider other){
        if(other.gameObject.name == "Bolinha"){
            AudioSource.PlayClipAtPoint(somMoeda,GameObject.Find("ARCamera").transform.position);
            GameObject saida = GameObject.Find("ParedeSaida").gameObject;
            saida.transform.localPosition -= new Vector3(0f,0f,1.33600004f);
            Destroy(gameObject);
        }
    }
}
