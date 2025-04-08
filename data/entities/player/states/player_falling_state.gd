class_name PlayerFallingState extends PlayerState

var direction := Vector3.ZERO
var velocity := Vector3.ZERO


func frame_update(entity: Player) -> void:
        if entity.body.is_on_floor():
                entity.reset_air_jumps()
                transition.emit(self, 'idle')
        elif entity.input.jump && entity.can_air_jump():
                entity.decrement_air_jumps()
                transition.emit(self, 'jump')


func physics_update(entity: Player) -> void:
                entity.move.move_with_input(entity.input.move,  entity.get_speed())
