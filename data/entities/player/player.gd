class_name Player extends Entity

const SHADER_HIGHLIGHT: Resource = preload("res://data/materials/highlight.tres")

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

var targeting = null
var input = null

var local_enabled: bool = false


func _ready() -> void:
        super._ready()
        $UI.visible = false


func frame_update(delta: float) -> void:
        if not is_multiplayer_authority():
                return
                
        if not local_enabled:
                enable_local_control()
                
                
        super.frame_update(delta)

        targeting.position = body.position
        targeting.rotation = body.rotation

        if input.target_next:
                targeting.target_next()
        if input.target_self:
                targeting.set_target(self)
        if input.cancel:
                set_target(null)


func enable_local_control() -> void:
        if not is_multiplayer_authority() or local_enabled:
                return

        local_enabled = true

        $UI.visible = true

        %SkillBar.initialize(self)
        targeting   = load_ability('player_select_target')
        input       = load_ability('player_input')

        targeting.initialize(self)
        target_plate.initialize(self, 'changed_target') 
        player_plate.on_changed_target(self)

        add_child(preload("res://data/entities/player/camera.tscn").instantiate())


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
