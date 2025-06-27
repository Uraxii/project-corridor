class_name PlayerJumpState extends PlayerState

var direction   := Vector3.ZERO
var velocity    := Vector3.ZERO


func enter(entity: Player) -> void:
        super.enter(entity)

        entity.move.jump(
            entity.stats.jump_force.curr, entity.input.move, entity.stats.speed)


func frame_update(entity: Player) -> void:
        super.frame_update(entity)
        
        entity.move.move_with_input(
                entity.input.move,
                entity.stats.jump_force.curr * entity.stats.air_control.curr
        )

        if entity.move.jump_influence.y < 0:
                transition.emit(self, 'falling')
