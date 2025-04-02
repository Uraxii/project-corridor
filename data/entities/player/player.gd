class_name Player extends Entity

@export var stats: Stats

@export var player_plate: NamePlate
@export var target_plate: NamePlate

@onready var health: Health = $Components/Health

var skill_binds: Dictionary = {
        'bar_1_skill_1': 'attack',
        'bar_1_skill_2': 'heal',
        'bar_1_skill_3': 'apply_bleed',
        'bar_1_skill_4': 'apply_regenerate',
}

var targeting   := load_ability('player_select_target')
var input       := load_ability('player_input')
var move        := load_ability('move')
var jump        := load_ability('jump')


func _process(delta: float) -> void:
        super._process(delta)

        if input.target_next:
                targeting.target_next()
        if input.target_self:
                targeting.target_entity(self)
        if input.cancel:
                set_target(null)


func _ready() -> void:
        super._ready()

        targeting.initialize(self)
        target_plate.initialize(self, 'changed_target')
        player_plate.on_changed_target(self)
