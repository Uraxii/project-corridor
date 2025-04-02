class_name AbilityBase

extends Node
var reset_timer := Timer.new()
var is_on_cooldown: bool = false


func reset_cooldown():
        is_on_cooldown = false


func _ability_logic():
        pass


func  _ready() -> void:
        add_child(reset_timer)
        reset_timer.timeout.connect(reset_cooldown)
