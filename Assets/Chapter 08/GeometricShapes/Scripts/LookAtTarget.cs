using UnityEngine;

namespace CH08
{
    [ExecuteInEditMode]
    public class LookAtTarget : MonoBehaviour
    {

        public Transform target;

        private void Update()
        {
            transform.LookAt(target);
        }

    }
}
