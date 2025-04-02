class_name PlayerJumpState

extends PlayerState


@export var air_control: float = 0.5

var direction := Vector3.ZERO
var velocity := Vector3.ZERO


func enter(entity: Player) -> void:
        super.enter(entity)

        entity.jump.cast(entity)


func frame_update(entity: Player) -> void:
        entity.move.cast(entity.input.move, entity.body, entity.stats.current_speed * air_control)

        if entity.body.velocity.y < 0:
                transition.emit(self, 'falling')
