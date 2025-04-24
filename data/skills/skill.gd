class_name Skill extends Node

#region Info
var file:               String
var id:                 String
var description:        String
var cast_type:          String
var is_on_gcd:          bool
var icon:               ImageTexture
#endregion

#region Targets
var can_target_self:    bool
var can_target_friend:  bool
var can_target_enemy:   bool
#endregion

#region Cost
var cost_mana:          float
var cost_rage:          float
var cost_energy:        float
#endregion

#region Data
var cooldown:           float
var charges:            int
var cast_range:         float
var cast_time:          float
var damage:             float
var heal:               float
var slow:               float
var speed_boost:        float
var teleport_range:     float

var apply_status:       String
var create_area:        String
#endregion

#region Status Effect
var status_type:        String
var status_duration:    float
var status_timer:       float
var status_tick_rate:   float
var status_tick_timer:  float
#endregion

#region Area of Effect
var is_area:            bool
var area_size:          float
var area_duration:      float
var area_timer:         float
var area_tick_rate:     float
var area_tick_timer:    float
#endregion

#region Animation
var anim_charge:        String
var anim_cast:          String
var anim_cast_success:  String
#endregion

#region SFX
var sfx_cast_start:     String
var sfx_cast:           String
var sfx_cast_success:   String
#endregion

#region Casting Variables
var caster:             Entity
var target:             Entity
var location:           Vector3
#endregion


func _init(config_file) -> void:
        self.file = config_file

        var config = ConfigFile.new()
        config.load("res://data/skills/data/%s.cfg" % file.to_lower())

        self.id                 = config.get_value("info", "id", "")
        self.description        = config.get_value("info", "description", "")
        self.cast_type          = config.get_value("info", "cast_type", "")
        self.is_on_gcd          = config.get_value("info", "is_on_gcd", true)

        var icon_file: String = config.get_value("info", "icon_file", "skill_default_icon")
        var icon_image = Image.load_from_file("res://art/icons/" + icon_file + ".png")
        self.icon = ImageTexture.create_from_image(icon_image)

        self.can_target_self    = config.get_value("targets", "can_target_self", false)
        self.can_target_friend  = config.get_value("targets", "can_target_friend", false)
        self.can_target_enemy   = config.get_value("targets", "can_target_enemy", false)

        self.cost_mana          = config.get_value("cost", "cost_mana", 0.0)
        self.cost_rage          = config.get_value("cost", "cost_rage", 0.0)
        self.cost_energy        = config.get_value("cost", "cost_energy", 0.0)
        self.cast_range         = config.get_value("cost", "cast_range", 0.0)

        self.cooldown           = config.get_value("data", "cooldown", 0.0)
        self.charges            = config.get_value("data", "charges", 0)
        self.cast_time          = config.get_value("data", "cast_time", 0.0)
        self.damage             = config.get_value("data", "damage", 0.0)
        self.heal               = config.get_value("data", "heal", 0.0)
        self.slow               = config.get_value("data", "slow", 0.0)
        self.speed_boost        = config.get_value("data", "speed_boost", 0.0)
        self.teleport_range     = config.get_value("data", "teleport_range", 0.0)
        self.apply_status       = config.get_value("data", "apply_status", "")
        self.create_area        = config.get_value("data", "create_area", "")

        self.status_type        = config.get_value("status", "type", "")
        self.status_duration    = config.get_value("status", "duration", 0.0)
        self.status_timer       = self.status_duration
        self.status_tick_rate   = config.get_value("status", "tick_rate", 0.0)
        self.status_tick_timer  = 0.0

        self.area_size          = config.get_value("area", "size", 0.0)
        self.area_duration      = config.get_value("area", "duration", 0.0)
        self.area_timer         = self.area_duration
        self.area_tick_rate     = config.get_value("area", "tick_rate", 0.0)
        self.area_tick_timer    = 0.0

        self.anim_charge        = config.get_value("anim", "anim_charge", "")
        self.anim_cast          = config.get_value("anim", "anim_cast", "")
        self.anim_cast_success  = config.get_value("anim", "anim_cast_success", "")

        self.sfx_cast_start     = config.get_value("sfx", "sfx_cast_start", "")
        self.sfx_cast           = config.get_value("sfx", "sfx_cast", "")
        self.sfx_cast_success   = config.get_value("sfx", "sfx_cast_success", "")


func cast() -> MessageCastResult:
        var result = MessageCastResult.new()

        if file.is_empty():
                return result

        result.skill = file

        if cast_type == "targeted":
                if target == null:
                        target = caster

                result.caster = caster.name
                result.target = target.name

                if not is_target_valid(self, caster, target):
                        result.success = MessageCastResult.INVALID_TARGET

                        return result

        elif cast_type == "status":
                # Logger.debug("status", {"skill":file})

                if status_timer <= 0:
                        if target.status_effects.get(file) == self:
                            target.status_effects.erase(file)

                        return result

                else:
                        status_timer -= Network.poll_timer.wait_time
                        result.status_remaining = status_timer

                        if status_tick_timer > 0:
                                status_tick_timer -= Network.poll_timer.wait_time
                                return result
                        else:
                                status_tick_timer = status_tick_rate

        elif cast_type == "area":
                Logger.debug("Casted area skill. Returning", {"skill":file})
                return result

        result.heal = heal_health(target, heal)
        result.damage = damage_health(target, damage)

        if apply_status:
                result.apply_status = apply_status_effect(caster, target, apply_status)

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


static func apply_status_effect(status_caster: Entity, status_target: Entity, skill_file: String) -> String:
        var status_effect = Skill.new(skill_file)
        status_effect.caster = status_caster
        status_effect.target = status_target
        status_target.apply_status_effect(status_effect)
        return skill_file


static func create_area_of_effect(caster: Entity):
        pass


static func is_target_valid(skill: Skill, caster: Entity, target: Entity) -> Entity:
        if target == null:
                        target = caster

        if not skill or not caster or not target:
                return null

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
