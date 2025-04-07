class_name EntityData

var id:                 int
var display_name:       String
var team:               int

var health:     float
var energy:     float
var mana:       float
var rage:       float

var move_speed: float
var jump_force: float

var gravity_scale: float


func _init(data_file: String) -> void:
        var config = ConfigFile.new()
        config.load("res://data/entities/data/%s.cfg" % data_file.to_lower())

        # Config file header, item, default value if item not found

        self.id                 = config.get_value('info', 'id', Entity.INVALID_ID)
        self.display_name       = config.get_value('info', 'display_name', 'NO_NAME_SET (%d)' % self.id)
        self.team               = config.get_value('info', 'team', Entity.TEAM_NEUTRAL)

        self.health             = config.get_value('stats', 'health', 0)
        self.energy             = config.get_value('stats', 'energy', 0)
        self.mana               = config.get_value('stats', 'mana', 0)
        self.rage               = config.get_value('stats', 'rage', 0)

        self.move_speed         = config.get_value('stats', 'speed', 0)
        self.jump_force         = config.get_value('stats', 'jump_force', 0)

        self.gravity_scale      = config.get_value('stats', 'gravity_scale', 1)
