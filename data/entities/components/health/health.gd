class_name Health extends Node

@export var max:        float = 100
@export var current:    float = 100

var is_health_zero = false

signal health_is_zero


func damage(amount: float) -> void:
        _modify(amount * -1)


func heal(amount: float) -> void:
        _modify(amount)


func _modify(amount: float) -> void:
        var new_health = current + amount

        if new_health > max:
                current = max
        elif new_health <= 0:
                current = 0
                health_is_zero.emit()
        else:
                current = new_health

        is_health_zero = current == 0
