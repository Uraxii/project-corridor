class_name EntityData extends Node

@export var file:               String
@export var display_name:       String
@export var team:               int

@export var skills:             Array

@export var health:             float
@export var energy:             float
@export var mana:               float
@export var rage:               float

@export var can_move:           bool
@export var speed:              float

@export var can_jump:           bool
@export var jump_force:         float

@export var can_air_jump:       bool
@export var air_jumps:          int
@export var air_control:        float

@export var gravity_scale:      float


func load(config_file: String = '') -> void:
        if config_file.is_empty():
                return

        file = config_file

        var config = ConfigFile.new()
        config.load("res://data/entities/data/%s.cfg" % file.to_lower())

        # Config file header, item, default value if item not found

        self.display_name       = config.get_value('info', 'display_name', 'NO_NAME_SET (%s)' % file)
        self.team               = config.get_value('info', 'team', Entity.TEAM_NEUTRAL)

        self.skills             = config.get_value('stats', 'skills', [])

        self.health             = config.get_value('stats', 'health', 0)
        self.energy             = config.get_value('stats', 'energy', 0)
        self.mana               = config.get_value('stats', 'mana', 0)
        self.rage               = config.get_value('stats', 'rage', 0)

        self.can_move           = config.get_value('stats', 'can_move', true)
        self.speed              = config.get_value('stats', 'speed', 0)

        self.can_jump           = config.get_value('stats', 'can_jump', true)
        self.jump_force         = config.get_value('stats', 'jump_force', 0)

        self.can_air_jump       = config.get_value('stats', 'jump_force', false)
        self.air_jumps          = config.get_value('stats', 'air_jumps', 0)
        self.air_control        = config.get_value('stats', 'air_control', 0.5)

        self.gravity_scale      = config.get_value('stats', 'gravity_scale', 1)
