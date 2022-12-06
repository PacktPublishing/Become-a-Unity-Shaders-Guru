using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CH06.Billboarding
{

    public class FollowTarget : MonoBehaviour
    {
        [SerializeField] private Transform _target;

        private Vector3 _offset;

        void Start()
        {
            _offset = transform.position - _target.position;
        }

        void Update()
        {
            transform.position = _target.position + _offset;
        }
    }

}
