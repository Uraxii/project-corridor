class_name PlayerJumpState extends PlayerState

var direction   := Vector3.ZERO
var velocity    := Vector3.ZERO


func enter(entity: Player) -> void:
        super.enter(entity)

        entity.move.jump(entity.get_jump_force(), entity.input.move, entity.get_speed())


func frame_update(entity: Player) -> void:
        super.frame_update(entity)
        
        entity.move.move_with_input(
                entity.input.move,
                entity.get_speed() * entity.get_air_control()
        )

        if entity.move.jump_influence.y < 0:
                transition.emit(self, 'falling')
