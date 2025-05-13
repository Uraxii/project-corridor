class_name ControllerManager extends Node

var active: Array[Controller] = [
    LoginController.new()
]


func _ready() -> void:
    for controller in active:
        add_child(controller)
