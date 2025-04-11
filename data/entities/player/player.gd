class_name Player extends Entity

const SHADER_HIGHLIGHT: Resource = preload("res://data/materials/highlight.tres")

@export var id: int = Network.SERVER_ID:
        set(new_id):
                Logger.debug('Changed authority id on %s' % name, {'old':id, 'new':new_id})
                id = new_id
                %Input.set_multiplayer_authority(id)
                if id == multiplayer.get_unique_id():
                        enable_local_player()


@onready var input: PlayerInput = %Input
@onready var targeting: PlayerSelectTarget = %Targeting

@onready var player_plate: NamePlate = %PlayerPlate
@onready var target_plate: NamePlate = %TargetPlate

var player_info: PlayerInfo

var target_original_material: Material

var skill_binds: Dictionary = {
        'bar_1_skill_1': 'attack',
        'bar_1_skill_2': 'heal',
        'bar_1_skill_3': 'apply_bleed',
        'bar_1_skill_4': 'apply_regenerate',
}


func _ready() -> void:
        super._ready()

        set_process(false)


func _process(delta: float) -> void:
        super._process(delta)

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

        add_child(preload("res://data/entities/player/camera.tscn").instantiate())

        set_process(true)


func send_state_data() -> void:
        # Server.update_player_info.rpc(body.position, body.rotation)
        pass


func set_target(new_target: Entity) -> void:
        var target_visuals

        if target != null:
                target_visuals = target.body.get_children()

                for element in target_visuals:
                        if element is MeshInstance3D:
                                element.set_surface_override_material(0, target_original_material)


        if new_target != null:
                target_visuals = new_target.body.get_children()

                for element in target_visuals:
                        if element is MeshInstance3D:
                                target_original_material = element.get_surface_override_material(0)
                                element.set_surface_override_material(0, SHADER_HIGHLIGHT)

        target = new_target
        changed_target.emit(target)
