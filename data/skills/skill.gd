class_name Skill extends Node

static var cast_result = CastResult.new()

### DATA VALUES ###
var file:               String
var id:                 String
var description:        String
var icon:               ImageTexture

var cost_mana:          float
var cost_rage:          float
var cost_energy:        float

var cooldown:           float

var charges:            int

var cast_range:         float
var cast_time:          float
var is_on_gcd:          bool

var can_target_self:    bool
var can_target_friend:  bool
var can_target_enemy:   bool

var impact_radius:      float

var damage_amount:      float

var heal_amount:        float

var slow:               float
var speed_boost:        float

var teleport_range:     float

### BUFF / DEBUFF / EFFECT OVER TIME ###
var status_effect_to_apply: String

var effect_type:                String
var effect_duration:            float
var effect_remaining_time:      float
var effect_timer:               Timer
var effect_caster:              Entity

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


func _init(config_file) -> void:
        self.file = config_file

        var config = ConfigFile.new()
        config.load("res://data/skills/data/%s.cfg" % file.to_lower())

        self.id                 = config.get_value('data', 'id', '')
        self.description        = config.get_value('data', 'description', '')

        var icon_file: String = config.get_value('data', 'icon_file', 'skill_default_icon')
        var icon_image = Image.load_from_file('res://art/icons/' + icon_file + '.png')
        self.icon = ImageTexture.create_from_image(icon_image)

        self.cost_mana          = config.get_value('data', 'cost_mana', 0.0)
        self.cost_rage          = config.get_value('data', 'cost_rage', 0.0)
        self.cost_energy        = config.get_value('data', 'cost_energy', 0.0)
        self.cast_range         = config.get_value('data', 'cast_range', 0.0)

        self.cooldown           = config.get_value('data', 'cooldown', 0.0)

        self.charges            = config.get_value('data', 'charges', 0)

        self.cast_time          = config.get_value('data', 'cast_time', 0.0)
        self.is_on_gcd          = config.get_value('data', 'is_on_gcd', true)

        self.can_target_self    = config.get_value('data', 'can_target_self', true)
        self.can_target_friend  = config.get_value('data', 'can_target_friend', false)
        self.can_target_enemy   = config.get_value('data', 'can_target_enemy', false)

        self.impact_radius      = config.get_value('data', 'impact_radius', 0.0)

        self.damage_amount      = config.get_value('data', 'damage_amount', 0.0)

        self.heal_amount        = config.get_value('data', 'heal_amount', 0.0)

        self.slow               = config.get_value('data', 'slow', 0.0)
        self.speed_boost        = config.get_value('data', 'speed_boost', 0.0)

        self.teleport_range     = config.get_value('data', 'teleport_range', 0.0)

        self.status_effect_to_apply     = config.get_value('data', 'apply_status_effect', '')
        self.effect_type                = config.get_value('data', 'effect_type', '')
        self.effect_duration            = config.get_value('data', 'effect_duration', 0.0)
        self.effect_remaining_time      = self.effect_duration

        self.trigger_free_cast  = config.get_value('data', 'trigger_free_cast', {})

        self.anim_charge        = config.get_value('anim', 'anim_charge', "")
        self.anim_cast          = config.get_value('anim', 'anim_cast', "")
        self.anim_cast_success  = config.get_value('anim', 'anim_cast_success', "")

        self.sfx_cast_start     = config.get_value('sfx', 'sfx_cast_start', "")
        self.sfx_cast           = config.get_value('sfx', 'sfx_cast', "")
        self.sfx_cast_success   = config.get_value('sfx', 'sfx_cast_success', "")

        self.effect_timer = Timer.new()


static func cast(skill: Skill, caster: Entity, target: Entity) -> CastResult:
        var result = CastResult.new()
        result.skill = skill.file

        if not skill:
                return result

        # If this is a normal cast (i.e. not a status effect) then check if the target is valid)
        if skill.effect_type.is_empty():
                if target == null:
                        target = caster

                result.caster = caster.name
                result.target = target.name

                if not is_target_valid(skill, caster, target):
                        result.success = CastResult.INVALID_TARGET
                        return result

        if skill.heal_amount != 0:
                result.heal = heal_health(target, skill.heal_amount)

        if skill.damage_amount != 0:
                result.damage = damage_health(target, skill.damage_amount)

        if not skill.status_effect_to_apply.is_empty():
                result.apply_status = apply_status_effect(caster, target, skill.status_effect_to_apply)

        if not skill.effect_type.is_empty():
                skill.effect_remaining_time -= Network.tick_interval
                result.status_remaining = skill.effect_remaining_time

                if skill.effect_remaining_time <= 0:
                        var status_effect_index = target.status_effects.find(skill)
                        target.status_effects.remove_at(status_effect_index)

        return result


static func damage_health(target: Entity, base_damage: float) -> float:
        var damage_to_apply = base_damage

        var remaining_damage = target.stats.health_extra - damage_to_apply
        target.stats.health_extra -= damage_to_apply

        # Any remaining damage will be negative beucase we are subtracting from the extra health pool above.
        if remaining_damage < 0:
                target.stats.health += remaining_damage

        return damage_to_apply


static func heal_health(target: Entity, amount: float) -> float:
        var healing_to_apply = amount
        target.stats.health += healing_to_apply
        return healing_to_apply


static func apply_status_effect(caster: Entity, target: Entity, status_effect_file: String) -> String:
        var status_effect = Skill.new(status_effect_file)
        status_effect.effect_caster = caster
        target.apply_status_effect(status_effect)
        return status_effect_file


static func is_target_valid(skill, caster: Entity, target: Entity) -> Entity:
        if caster == target:
                if skill.can_target_self:
                        return caster
                else:
                        return null

        if caster.team_id == target.team_id && not skill.can_target_friend:
                return null
        elif caster.team_id != target.team_id && not skill.can_target_enemy:
                return null

        return target
