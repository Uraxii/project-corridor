class_name Move
extends Node

var _direction: Vector3
var _velocity: Vector3

func cast(input: Vector2, body: CharacterBody3D, speed: float):
        _direction = body.transform.basis * Vector3(input.x, 0, input.y).normalized()
        _velocity = _direction * speed
        body.velocity += _velocity

        body.move_and_slide()

        body.velocity -= _velocity
