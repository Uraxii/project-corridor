class_name Console extends Node


func _ready() -> void:
    Global.signal_bus.log_new_error.connect(_on_error)
    

func _on_error(error: String) -> void:
    printerr(error)
