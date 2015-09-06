using UnityEngine;
using System.Collections;

public class AutoSpin : MonoBehaviour
{
    private void Update()
    {
        transform.rotation *= Quaternion.Euler(100 * Time.deltaTime, 0, 0);
    }
}
