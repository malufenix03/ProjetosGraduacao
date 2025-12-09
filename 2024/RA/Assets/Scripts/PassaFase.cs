using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.SceneManagement;

public class PassaFase : MonoBehaviour
{
    private bool fim;
    public string proximaFase;
    void Start()
    {
        fim=false;
    }

    // Update is called once per frame
    void Update()
    {
        if(fim ){
            SceneManager.LoadScene(proximaFase);
        }
    }
    void OnTriggerEnter(Collider other){
        if(other.gameObject.name == "Bolinha"){
            fim=true;
            GameObject bolinha = other.gameObject;
            Destroy(bolinha.GetComponent<Rigidbody>());
        }
    }
}
