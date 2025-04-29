# Skill.gd
# This script defines the "Skill" class for a Godot RPG, handling all properties and behavior for character skills.

class_name Skill extends Node

var area_scene: Resource = preload("res://data/skills/aoe.tscn")

#region Info
# --- General information about the skill ---
var file:               String          # Name/path of the config file for this skill
var id:                 String          # Unique skill identifier
var description:        String          # Description for UI or logs
var skill_type:         String          # The category/type of the skill (e.g. "targeted", "status", "area")
var is_on_gcd:          bool            # If true, using this skill triggers a global cooldown
var icon:               ImageTexture    # Skill icon to be shown in UI
#endregion

#region Targets
# --- Who/what the skill can target ---
var can_target_self:    bool            # Can the skill target the caster themselves?
var can_target_friend:  bool            # Can the skill target allies?
var can_target_enemy:   bool            # Can the skill target enemies?
#endregion

#region Cost
# --- Resource costs for casting the skill ---
var cost_mana:          float           # Mana required to cast
var cost_rage:          float           # Rage required to cast
var cost_energy:        float           # Energy required to cast
#endregion

#region Data
# --- Mechanical data for the skill ---
var cooldown:           float           # Time before the skill can be used again
var charges:            int             # Max number of uses before cooldown
var cast_range:         float           # Maximum casting distance
var cast_time:          float           # Time taken to cast (wind-up)
var damage:             float           # Damage dealt on hit
var heal:               float           # Healing done on use
var slow:               float           # Slow effect strength
var speed_boost:        float           # Speed boost strength
var teleport_range:     float           # Teleport distance if applicable

var apply_status:       String          # Name of status effect to apply (if any)
var create_area:        String          # Name of area effect to create (if any)
#endregion

#region Status Effect
# --- Data for skills that apply a status effect ---
var status_type:        String          # Type of status effect
var status_duration:    float           # Duration of the effect
var status_timer:       float           # Tracks remaining time for status effect
var status_tick_rate:   float           # How often status ticks (for DoT/HoT)
var status_tick_timer:  float           # Tracks ticks for periodic effects
#endregion

#region Area of Effect
# --- Data for skills that create an area effect ---
var area_exit_removes:  bool            # Should the appied skill be removed upon exiting the area?
var area_cast_delay:    float           # Amount of time to wait before casting after being placed
var area_size:          float           # Area radius/size
var area_duration:      float           # Duration of the area effect
var area_timer:         float           # Tracks remaining area duration
var area_tick_rate:     float           # Rate of area effect periodic application
var area_tick_timer:    float           # Tracks ticks for area periodic effects
#endregion

#region Animation
# --- Animation names for visual feedback ---
var anim_charge:        String          # Animation for charging the skill
var anim_cast:          String          # Animation for casting the skill
var anim_cast_success:  String          # Animation for successful cast
#endregion

#region SFX
# --- Sound effects for different phases of casting ---
var sfx_cast_start:     String          # SFX for cast start
var sfx_cast:           String          # SFX for casting
var sfx_cast_success:   String          # SFX for successful cast
#endregion

#region Casting Variables
# --- Runtime variables used during casting ---
var caster:             Entity          # The entity casting this skill
var target:             Entity          # The entity being targeted
var location:           Vector3         # Location where the skill is cast (for AOE, projectiles)
#endregion


# Called when a new skill instance is created; loads config data from file.
func _init(config_file) -> void:
    self.file = config_file

    var config = ConfigFile.new()
    var err = config.load("res://data/skills/data/%s.cfg" % file.to_lower())

    if err:
        Logger.error("Failed to load skill!", {"skill":config_file,"error":err})

    # --- Info section ---
    self.id                 = config.get_value("info", "id", "")
    self.description        = config.get_value("info", "description", "")
    self.skill_type         = config.get_value("info", "skill_type", "")
    self.is_on_gcd          = config.get_value("info", "is_on_gcd", true)

    # Load the icon image for this skill
    var icon_file: String = config.get_value("info", "icon_file", "skill_default_icon")
    var icon_image = Image.load_from_file("res://art/icons/" + icon_file + ".png")
    self.icon = ImageTexture.create_from_image(icon_image)

    # --- Targets section ---
    self.can_target_self    = config.get_value("targets", "can_target_self", false)
    self.can_target_friend  = config.get_value("targets", "can_target_friend", false)
    self.can_target_enemy   = config.get_value("targets", "can_target_enemy", false)

    # --- Cost section ---
    self.cost_mana          = config.get_value("cost", "cost_mana", 0.0)
    self.cost_rage          = config.get_value("cost", "cost_rage", 0.0)
    self.cost_energy        = config.get_value("cost", "cost_energy", 0.0)
    self.cast_range         = config.get_value("cost", "cast_range", 0.0)

    # --- Data section ---
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

    # --- Status section ---
    self.status_type        = config.get_value("status", "type", "")
    self.status_duration    = config.get_value("status", "duration", 0.0)
    self.status_timer       = self.status_duration
    self.status_tick_rate   = config.get_value("status", "tick_rate", 0.0)
    self.status_tick_timer  = 0.0

    # --- Area section ---
    self.area_exit_removes  = config.get_value("area", "exit_removes", false)
    self.area_cast_delay    = config.get_value("area", "cast_delay", 0.2)
    self.area_size          = config.get_value("area", "size", 0.0)
    self.area_duration      = config.get_value("area", "duration", 0.0)
    self.area_timer         = self.area_duration
    self.area_tick_rate     = config.get_value("area", "tick_rate", 0.0)
    self.area_tick_timer    = 0.0

    # --- Animation section ---
    self.anim_charge        = config.get_value("anim", "anim_charge", "")
    self.anim_cast          = config.get_value("anim", "anim_cast", "")
    self.anim_cast_success  = config.get_value("anim", "anim_cast_success", "")

    # --- SFX section ---
    self.sfx_cast_start     = config.get_value("sfx", "sfx_cast_start", "")
    self.sfx_cast           = config.get_value("sfx", "sfx_cast", "")
    self.sfx_cast_success   = config.get_value("sfx", "sfx_cast_success", "")


# Main cast method - performs skill logic and returns result
func cast() -> MessageCastResult:
    var result = MessageCastResult.new()

    if file.is_empty():
        return result

    result.skill = file

    if skill_type == "targeted":
        _handle_targeted(result)
    elif skill_type == "status":
        _handle_status(result)
    elif skill_type == "area":
        _handle_area(result)
    else:
        Logger.warn(
            "Invalid cast type! Returning",
            {"skill type": self.skill_type, "skill": file})

        return result

    # Apply heal and damage
    result.heal = heal_hp(target, heal)
    result.damage = damage_hp(target, damage)

    # Apply status if specified
    if apply_status:
        result.apply_status = apply_status_effect(
            caster,
            target,
            apply_status
        )

    return result


func set_area_location(pos: Vector3) -> void:
    self.location = pos


func _handle_targeted(result: MessageCastResult) -> MessageCastResult:
        if target == null:
            target = caster

        result.caster = caster.name
        result.target = target.name

        # Check if the target is valid for this skill
        if not is_target_valid(self, caster, target):
            result.success = MessageCastResult.INVALID_TARGET

        return result


func _handle_status(result: MessageCastResult) -> MessageCastResult:
        # If the effect's duration is over, remove the status
        if status_timer <= 0:
            if target.status_effects.get(file) == self:
                target.status_effects.erase(file)
            return result
        else:
            status_timer -= Network.poll_timer.wait_time
            result.status_remaining = status_timer
            # Handle status ticking (periodic effect application)
            if status_tick_timer > 0:
                status_tick_timer -= Network.poll_timer.wait_time
                return result
            else:
                status_tick_timer = status_tick_rate

        return result


func _handle_area(result: MessageCastResult) -> MessageCastResult:
        Logger.debug("Casted area skill.", {"skill":file})
        var area_node = area_scene.instantiate()
        area_node.position = self.location
        caster.get_tree().root.add_child(area_node)

        return result


# Static utility: Applies damage, using the target's hp_extra as a shield
static func damage_hp(target: Entity, base_damage: float) -> float:
    var damage_to_apply = base_damage

    var remaining_damage = target.stats.hp_extra - damage_to_apply
    target.stats.hp_extra -= damage_to_apply

    # If hp_extra is depleted, reduce main hp by the remainder
    if remaining_damage < 0:
        target.stats.hp += remaining_damage

    return damage_to_apply


# Static utility: Heals the target by a given amount
static func heal_hp(target: Entity, amount: float) -> float:
    var healing_to_apply = amount
    target.stats.hp += healing_to_apply
    return healing_to_apply


# Static utility: Applies a status effect by creating a new Skill instance and assigning it to the target
static func apply_status_effect(
    status_caster: Entity,
    status_target: Entity,
    skill_file: String
) -> String:
    var status_effect = Skill.new(skill_file)
    status_effect.caster = status_caster
    status_effect.target = status_target
    status_target.apply_status_effect(status_effect)
    return skill_file


# Static utility: Creates area of effect (placeholder - to be implemented)
static func create_area_of_effect(caster: Entity):
    pass


# Static utility: Checks if a target is valid for a given skill/caster
static func is_target_valid(
    skill: Skill,
    caster: Entity,
    target: Entity
) -> Entity:
    if target == null:
        target = caster

    if not skill or not caster or not target:
        return null

    # Self targeting
    if caster == target:
        if skill.can_target_self:
            return caster
        else:
            return null

    # Ally and enemy checks
    if caster.team_id == target.team_id && not skill.can_target_friend:
        return null
    elif caster.team_id != target.team_id && not skill.can_target_enemy:
        if caster.team_id == target.team_id && not skill.can_target_friend:
            return null
        elif caster.team_id != target.team_id && not skill.can_target_enemy:
            return null

    return target
