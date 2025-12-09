using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using Vuforia;

public class ControleRastreioMarcador : MonoBehaviour
{
    ObserverBehaviour multiTargetBehavior;
    GameObject bolinha;
    private void Awake(){
        multiTargetBehavior = GetComponent<ObserverBehaviour>();
    }
    // Start is called before the first frame update
    void Start()
    {
        bolinha = transform.Find("Bolinha").GameObject();
        Destroy(bolinha.GetComponent<Rigidbody>());
        if(multiTargetBehavior){
            multiTargetBehavior.OnTargetStatusChanged += OnTargetStatusChanged;
        }
        
    }

    private void OnTargetStatusChanged(ObserverBehaviour observerBehaviour,TargetStatus status){
        if(status.Status == Status.TRACKED || status.Status == Status.EXTENDED_TRACKED){
            if(bolinha.GetComponent<Rigidbody>() == null){
                bolinha.AddComponent<Rigidbody>();
                bolinha.GetComponent<Rigidbody>().velocity = new Vector3(0f,0f,0f);
            }
            
            
            
        }
        else{
            Destroy(bolinha.GetComponent<Rigidbody>());
            Debug.Log("O objeto foi perdido! Nome: " + observerBehaviour.TargetName);
        }
    }

}
