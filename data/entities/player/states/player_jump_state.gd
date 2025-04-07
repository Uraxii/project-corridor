class_name PlayerJumpState extends PlayerState

@export var air_control: float = 0.5

var direction := Vector3.ZERO
var velocity := Vector3.ZERO


func enter(entity: Player) -> void:
        super.enter(entity)

        entity.movement.jump(entity.stats.current_jump_force, entity.input.move, entity.stats.current_speed)


func frame_update(entity: Player) -> void:
        entity.movement.move_with_input(entity.input.move, entity.stats.current_speed * air_control)

        if entity.movement.jump_influence.y < 0:
                transition.emit(self, 'falling')
