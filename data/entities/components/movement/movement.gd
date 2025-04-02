class_name Movement extends Node

const FORCE_GRAVITY: float = 0.8

@export var stats: Stats
@export var body: CharacterBody3D

var _move_velocity := Vector3.ZERO
var _move_velocity_cache := Vector3.ZERO


func set_force_movement(velocity: Vector3) -> void:
        _move_velocity = velocity


func move_towards(position: Vector3, speed: float) -> void:
    var direction = position - body.global_transform.origin
    direction = direction.normalized()
    _move_velocity = direction * speed


func _get_force_movement() -> Vector3:
        var velocity: Vector3 = _move_velocity
        _move_velocity = Vector3.ZERO

        return velocity


func _get_force_gravity() -> float:
        if body.is_on_floor():
                return 0

        if stats.current_gravity_scale == 1:
                return FORCE_GRAVITY

        if stats.current_gravity_scale == 0:
                return 0

        return FORCE_GRAVITY * stats.current_gravity_scale


func _physics_process(delta: float) -> void:
        _move_velocity_cache = _get_force_movement()
        body.velocity += _move_velocity_cache
        body.velocity.y -= _get_force_gravity()

        body.move_and_slide()

        if _move_velocity_cache != Vector3.ZERO:
                body.velocity -= _move_velocity_cache
