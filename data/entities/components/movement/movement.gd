class_name Movement extends Node

const FORCE_GRAVITY: float = 0.8
const FORCE_JUMP_GRAVIY: float = 0.4

@export var stats: Stats
@export var body: CharacterBody3D

var current_gravity: float = 0.0

var move_velocity := Vector3.ZERO

var is_jumping: bool = false
var jump_influence := Vector3.ZERO


func set_force_movement(velocity: Vector3) -> void:
        move_velocity = velocity


func move_towards(position: Vector3, speed: float) -> void:
        var direction = position - body.global_transform.origin
        direction = direction.normalized()
        move_velocity = direction * speed


func jump(jump_force: float, input: Vector2, speed: float) -> void:
        jump_influence = body.transform.basis * Vector3(input.x, 0, input.y).normalized()
        jump_influence = jump_influence * speed
        jump_influence.y = jump_force


func move_with_input(input: Vector2, speed: float):
        var direction = body.transform.basis * Vector3(input.x, 0, input.y).normalized()
        move_velocity = direction * speed


func _apply_gravity(current_velocity: Vector3) -> Vector3:
        if body.is_on_floor():
                current_gravity = 0
                current_velocity.y = 0
                return current_velocity

        var gravity_to_apply: float

        if is_jumping and jump_influence.y > 0:
                gravity_to_apply = FORCE_JUMP_GRAVIY
        else:
                gravity_to_apply = FORCE_GRAVITY

        current_gravity -= gravity_to_apply * stats.current_gravity_scale
        current_velocity.y += current_gravity

        return current_velocity


func _apply_jump_influence(current_velocity: Vector3) -> Vector3:
        if is_jumping and body.is_on_floor() or jump_influence == Vector3.ZERO:
                is_jumping = false
                jump_influence = Vector3.ZERO
                return current_velocity

        is_jumping = true

        # print('Current jump influence y %3f' % jump_influence.y)

        current_velocity += jump_influence

        if jump_influence.y > 0:
                jump_influence.y -= FORCE_JUMP_GRAVIY

        return current_velocity


func _apply_movement(current_velocity: Vector3) -> Vector3:
        current_velocity += move_velocity

        move_velocity = Vector3.ZERO

        return current_velocity


func _physics_process(delta: float) -> void:
        body.velocity = _apply_gravity(body.velocity)
        body.velocity = _apply_jump_influence(body.velocity)
        body.velocity = _apply_movement(body.velocity)

        body.move_and_slide()

        body.velocity = Vector3.ZERO
