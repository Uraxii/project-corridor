class_name TransformState

var position: Vector3
var rotation: Vector3
var timestamp: float
var velocity: Vector3
var on_floor: bool


func _init(pos: Vector3, rot: Vector3, time: float, vel: Vector3, floor_state: bool):
    position = pos
    rotation = rot
    timestamp = time
    velocity = vel
    on_floor = floor_state
