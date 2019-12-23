using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TreeMaker : MonoBehaviour
{
    public GameObject[] treePrefabs;
    public Transform treeFolder;
    // Start is called before the first frame update
    public void MakeTrees()
    {
        float z = -40f;
        while (z < 0)
        {
            float x = Random.Range(-20f,-18f);
            while (x < 20f) {
                float tempZ = z + Random.Range(1f, 2f);
                MakeTree(x,tempZ);
                x += Random.Range(1f, 3f);
            }
            z += Random.Range(1f, 3f);
        }

        z = 20f;
        while (z < 30)
        {
            float x = Random.Range(-20f,-18f);
            while (x < 20f) {
                float tempZ = z + Random.Range(1f, 2f);
                MakeTree(x,tempZ);
                x += Random.Range(1f, 3f);
            }
            z += Random.Range(1f, 3f);
        }

        z = -9.5f;
        while (z < 25)
        {
            float x = Random.Range(-20f,-18f);
            while (x < 5f) {
                float tempZ = z + Random.Range(1f, 3f);
                MakeTree(x,tempZ);
                x += Random.Range(1f, 2f);
            }
            z += Random.Range(1f, 3f);
        }

        z = -9.5f;
        while (z < 25)
        {
            float x = Random.Range(20f,21f);
            while (x < 30f) {
                float tempZ = z + Random.Range(1f, 2f);
                MakeTree(x,tempZ);
                x += Random.Range(1f, 3f);
            }
            z += Random.Range(1f, 3f);
        }
    }

    private void MakeTree(float x, float z)
    {
        GameObject tree = Instantiate(treePrefabs[Random.Range(0,treePrefabs.Length)], new Vector3(x, 3.45f, z), Quaternion.Euler(0, Random.Range(0f, 360f), 0));
        float scaleFactor = Random.Range(.1f,.3f);
        tree.transform.localScale += new Vector3(scaleFactor,scaleFactor,scaleFactor);
        tree.transform.SetParent(treeFolder);
    }
}
