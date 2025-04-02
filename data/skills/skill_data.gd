class_name SkillData

### DATA VALUES ###
var name:               String

var cost_mana:          float
var cost_rage:          float
var cost_energy:        float

var charges:            int

var cast_range:         float
var cast_time:          float
var is_on_gcd:          bool

var can_target_self:    bool
var can_target_friend:  bool
var can_target_enemy:   bool

var marker_shape:       String
var impact_radius:      float

var heal:               float
var damage:             float

var slow:               float
var speed_boost:        float

var teleport_range:     float

# Skill name, percentage to trigger the skill
var trigger_free_cast:  Dictionary

### ANIMATION FILES ###
var anim_charge:        String
var anim_cast:          String
var anim_cast_success:  String

### SOUND FX FILES ###
var sfx_cast_start:     String
var sfx_cast:           String
var sfx_cast_success:   String


func init(skill_name: String) -> void:
        var config = ConfigFile.new()
        config.load("res://skills/%s.cfg" % skill_name.to_lower())

        self.name               = config.get_value('data', 'name', "")

        self.cost_mana          = config.get_value('data', 'cost_mana', 0.0)
        self.cost_rage          = config.get_value('data', 'cost_rage', 0.0)
        self.cost_energy        = config.get_value('data', 'cost_energy', 0.0)
        self.cast_range         = config.get_value('data', 'cast_range', 0.0)

        self.charges            = config.get_value('data', 'charges', 0)

        self.cast_time          = config.get_value('data', 'cast_time', 0.0)
        self.is_on_gcd          = config.get_value('data', 'is_on_gcd', true)

        self.can_target_self    = config.get_value('data', 'can_target_self', false)
        self.can_target_friend  = config.get_value('data', 'can_target_friend', false)
        self.can_target_enemy   = config.get_value('data', 'can_target_enemy', false)

        self.marker_shape       = config.get_value('data', 'marker_shape', "")
        self.impact_radius      = config.get_value('data', 'impact_radius', 0.0)

        self.heal               = config.get_value('data', 'heal', 0.0)
        self.damage             = config.get_value('data', 'damage', 0.0)

        self.slow               = config.get_value('data', 'slow', 0.0)
        self.speed_boost        = config.get_value('data', 'speed_boost', 0.0)

        self.teleport_range     = config.get_value('data', 'teleport_range', 0.0)

        self.trigger_free_cast  = config.get_value('data', 'trigger_free_cast', {})

        self.anim_charge        = config.get_value('anim', 'anim_charge', "")
        self.anim_cast          = config.get_value('anim', 'anim_cast', "")
        self.anim_cast_success  = config.get_value('anim', 'anim_cast_success', "")

        self.sfx_cast_start     = config.get_value('sfx', 'sfx_cast_start', "")
        self.sfx_cast           = config.get_value('sfx', 'sfx_cast', "")
        self.sfx_cast_success   = config.get_value('sfx', 'sfx_cast_success', "")
