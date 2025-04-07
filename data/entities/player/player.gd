class_name Player extends Entity

const SHADER_HIGHLIGHT: Resource = preload("res://data/materials/highlight.tres")

@export var stats: Stats

@export var player_plate: NamePlate
@export var target_plate: NamePlate

@onready var health: Health = $Components/Health
@onready var movement: Movement = %Movement

var player_info: PlayerInfo

var target_original_material: Material

var skill_binds: Dictionary = {
        'bar_1_skill_1': 'attack',
        'bar_1_skill_2': 'heal',
        'bar_1_skill_3': 'apply_bleed',
        'bar_1_skill_4': 'apply_regenerate',
}

var targeting   := load_ability('player_select_target')
var input       := load_ability('player_input')
# var move        := load_ability('move')
var jump        := load_ability('jump')


func _ready() -> void:
        super._ready()

        targeting.initialize(self)
        target_plate.initialize(self, 'changed_target')
        player_plate.on_changed_target(self)


func _process(delta: float) -> void:
        super._process(delta)

        targeting.position = body.position
        targeting.rotation = body.rotation

        if input.target_next:
                targeting.target_next()
        if input.target_self:
                targeting.set_target(self)
        if input.cancel:
                set_target(null)


func _physics_process(delta: float) -> void:
        super._process(delta)

        Server.update_player_info.rpc(body.position, body.rotation)

        # player_info = Server.connections[multiplayer.get_unique_id()]


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
