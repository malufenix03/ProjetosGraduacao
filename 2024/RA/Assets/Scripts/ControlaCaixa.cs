using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ControlaCaixa : MonoBehaviour
{
    public float velocidade;

    private void FixedUpdate(){
        float desl = velocidade * Time.fixedDeltaTime,
            rotacaoHorizontal = Input.GetAxis("Horizontal") * desl,
            rotacaoVertical = Input.GetAxis("Vertical") * desl;
        transform.Rotate(rotacaoHorizontal,0,rotacaoVertical);
    }
}
