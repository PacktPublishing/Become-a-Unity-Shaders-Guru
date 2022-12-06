using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CH06.Billboarding
{

    public class BasicWASDMoveAndRotate : MonoBehaviour
    {
        private const float _ROTATION_SPEED = 50f;
        private const float _MOVE_SPEED = 10f;

        [SerializeField] private Rigidbody _rigidbody;

        void FixedUpdate()
        {
            float h = Input.GetAxis("Horizontal");
            float v = Input.GetAxis("Vertical");
            if (h > 0) _TurnRight();
            else if (h < 0) _TurnLeft();
            _Move(v);
        }

        private void _TurnRight()
        {
            transform.Rotate(Vector3.up * _ROTATION_SPEED * Time.deltaTime);
        }

        private void _TurnLeft()
        {
            transform.Rotate(-Vector3.up * _ROTATION_SPEED * Time.deltaTime);
        }

        private void _Move(float movement)
        {
            _rigidbody.AddForce(transform.forward * movement * _MOVE_SPEED);
        }
    }

}
