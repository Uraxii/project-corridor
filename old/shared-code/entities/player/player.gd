class_name Player extends Entity

@onready var input: PlayerInput
@onready var targeting: PlayerSelectTarget = %Targeting

@onready var player_plate: NamePlate = %PlayerPlate
@onready var target_plate: NamePlate = %TargetPlate

var skill_binds: Dictionary = {
        'bar_1_skill_1': 3,
}


func _ready() -> void:
        set_process(false)


func _process(delta: float) -> void:
    if not input.is_multiplayer_authority():
        return

    if input.target_next:
        targeting.target_next()
    elif input.target_self:
        targeting.set_target(self)
    elif input.target_cancel:
        targeting.set_target(null)


func enable_local_player() -> void:
    input.process_mode = Node.PROCESS_MODE_INHERIT

    $UI.process_mode = Node.PROCESS_MODE_INHERIT

    %SkillBar.initialize(self)

    targeting.initialize(self)
    targeting.process_mode = Node.PROCESS_MODE_INHERIT

    target_plate.initialize(self, 'changed_target') 
    player_plate.on_changed_target(self)

    add_child(preload("res://shared-code/player/player_camera.tscn").instantiate())

    set_process(true)


func set_target(new_target: Entity) -> void:
    if target:
        target.untargeted.emit()

    target = new_target
    if target:
        target.targeted.emit()

    changed_target.emit(target)
