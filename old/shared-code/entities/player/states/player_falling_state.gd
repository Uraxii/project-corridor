class_name PlayerFallingState extends PlayerState

var direction := Vector3.ZERO
var velocity := Vector3.ZERO


func frame_update(entity: Player) -> void:
        if entity.body.is_on_floor():
                entity.stats.air_jumps = entity.stats.air_jumps_base
                transition.emit(self, 'idle')
        elif entity.input.jump && entity.stats.can_air_jump:
                entity.stats.air_jumps.reduce(1)
                transition.emit(self, 'jump')


func physics_update(entity: Player) -> void:
                entity.move.move_with_input(entity.input.move,  entity.stats.speed)
