class_name OriginSelect extends Control

const ORIGIN: Array[String] = [
        'Capsule',
        'Cylinder',
        'Box',
]

@export var previous:   Button
@export var label:      Label
@export var next:       Button

var curr_origin: int = 0

signal change_origin(origin: String)


func _ready() -> void:
        next.pressed.connect(NextOrigin)
        previous.pressed.connect(PreviousOrigin)

        update_origin()


func NextOrigin() -> void:
        curr_origin = curr_origin + 1 if curr_origin < ORIGIN.size() - 1 else 0

        update_origin()


func PreviousOrigin() -> void:
        curr_origin = curr_origin - 1 if curr_origin > 0 else ORIGIN.size() - 1

        update_origin()


func update_origin() -> void:
        label.text = ORIGIN[curr_origin]
        change_origin.emit(ORIGIN[curr_origin])
