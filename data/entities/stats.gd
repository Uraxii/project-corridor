class_name EntityData extends MultiplayerSynchronizer

signal death

@export var file:               String
@export var display_name:       String
@export var team:               int

@export var skills:             Array

@export var health_base:        float
@export var health:             float:
        set(value):
                health = clamp(value, 0, health_base)
                if health == 0:
                        death.emit()


@export var health_extra:       float:
        set(value):
                health_extra = clamp(value, 0, 9999)


@export var armour_base:        float
@export var armour:             float:
        set(value):
                armour = clamp(value, 0, armour_base)


@export var armour_extra:       float:
        set(value):
                armour_extra = clamp(value, 0, 9999)


@export var energy_base:        float
@export var energy:             float:
        set(value):
                energy = clamp(value, 0, energy_base)


@export var energy_extra:       float:
        set(value):
                energy_extra = clamp(value, 0, 9999)


@export var mana_base:          float
@export var mana:               float:
        set(value):
                mana = clamp(value, 0, mana_base)

@export var mana_extra:         float:
        set(value):
                mana_extra = clamp(value, 0, 9999)


@export var rage_base:          float
@export var rage:               float:
        set(value):
                clamp(value, 0, rage_base)


@export var rage_extra:         float:
        set(value):
                clamp(value, 0, 9999)


@export var can_move:           bool

@export var speed_base:         float
@export var speed:              float

@export var can_jump:           bool

@export var jump_force_base:    float
@export var jump_force:         float

@export var can_air_jump_base:  bool
@export var can_air_jump:       bool
@export var air_jumps_base:     int
@export var air_jumps:          int
@export var air_control_base:   float
@export var air_control:        float

@export var gravity_scale_base: float
@export var gravity_scale:      float


func _enter_tree() -> void:
        replication_interval = Network.tick_interval
        delta_interval = Network.tick_interval



var is_dead: bool:
        get():
                return health == 0


func load(config_file: String = '') -> void:
        if config_file.is_empty():
                return

        file = config_file

        var config = ConfigFile.new()
        config.load("res://data/entities/data/%s.cfg" % file.to_lower())

        # TODO: Assign default values for remaining _extra variables.

        # Config file header, item, default value if item not found

        self.display_name       = config.get_value('info', 'display_name', 'NO_NAME_SET (%s)' % file)
        self.team               = config.get_value('info', 'team', Entity.TEAM_NEUTRAL)

        self.skills             = config.get_value('stats', 'skills', [])

        self.health_base        = config.get_value('stats', 'health', 0)
        self.health             = self.health_base
        self.health_extra       = 0

        self.armour_base        = config.get_value('stats', 'armour', 0)
        self.armour             = self.armour_base
        self.armour_extra       = 0

        self.energy_base        = config.get_value('stats', 'energy', 0)
        self.energy             = self.energy_base
        self.energy_extra       = 0

        self.mana_base          = config.get_value('stats', 'mana', 0)
        self.mana               = self.mana_base
        self.mana_extra         = 0

        self.rage_base          = config.get_value('stats', 'rage', 0)
        self.rage               = self.rage_base
        self.rage_extra         = 0

        self.can_move           = config.get_value('stats', 'can_move', true)
        self.speed_base         = config.get_value('stats', 'speed', 0)
        self.speed              = self.speed_base

        self.can_jump           = config.get_value('stats', 'can_jump', true)
        self.jump_force_base    = config.get_value('stats', 'jump_force', 0)
        self.jump_force         = jump_force_base

        self.can_air_jump_base  = config.get_value('stats', 'jump_force', false)
        self.can_air_jump       = self.can_air_jump_base
        self.air_jumps_base     = config.get_value('stats', 'air_jumps', 0)
        self.air_jumps          = self.air_jumps_base
        self.air_control_base   = config.get_value('stats', 'air_control', 0.5)
        self.air_control        = self.air_control_base

        self.gravity_scale_base = config.get_value('stats', 'gravity_scale', 1)
        self.gravity_scale      = self.gravity_scale_base
