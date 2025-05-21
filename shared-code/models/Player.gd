class_name PlayerNewer extends Node

@onready var input: PlayerInput = %Input
@onready var targeting: PlayerSelectTarget = %Targeting

var authorities: Array[int] = []


func _ready() -> void:
        set_process(false)


func _process(delta: float) -> void:
        if not input.is_multiplayer_authority():
                return


func enable_local_player() -> void:
        input.process_mode = Node.PROCESS_MODE_INHERIT
        $UI.process_mode = Node.PROCESS_MODE_INHERIT

        %SkillBar.initialize(self)

        add_child(preload("res://shared-code/entities/player/camera.tscn").instantiate())
        set_process(true)
