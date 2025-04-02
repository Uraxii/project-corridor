class_name player_falling_state

extends PlayerState

@export var air_control: float = 0.5

var direction := Vector3.ZERO
var velocity := Vector3.ZERO


func frame_update(entity: Player) -> void:
        if entity.body.is_on_floor():
                entity.stats.current_jump_amount = entity.stats.base_jump_amount
                transition.emit(self, 'idle')
        elif entity.input.jump && entity.stats.current_jump_amount > 0:
                transition.emit(self, 'jump')


func physics_update(entity: Player) -> void:
        entity.move.cast(entity.input.move, entity.body, entity.stats.current_speed)
