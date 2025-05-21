class_name Death extends Node

@export var entity: Entity
@export var health: Health

var is_dead: bool = false

signal death


func _on_health_zero():
        death.emit()
        entity.hide()


func _ready() -> void:
        if health != null:
                health.health_is_zero.connect(_on_health_zero)
