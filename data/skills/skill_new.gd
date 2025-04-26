class_name SkillNew

const INVALID_ID:       int     = -1
const INVALID_NAME:     String  = ""
const CONFIG_PATH:      String  = "res://data/skills/configs"
const CONDITION_PATH:   String  = "res://data/skills/conditions"

static var skill_pool:  Dictionary[int, SkillNew] = {}
static var con_pool:    Dictionary[int, ConditionBase] = {}
static var aoe_scene:   Resource = preload("res://data/skills/aoe.tscn")

#region Skill Info
var id:     int
var name:   String
var desc:   String
var kind:   String
var icon:   ImageTexture

var conditions: Array[ConditionBase] = []
#endregion

#region Cost
var cost_hp:        float
var cost_mana:      float
var cost_rage:      float
var cost_energy:    float
var cost_money:     float
#endregion

var cooldown:       float
var max_range:      float

var impact_enemy:   bool
var impact_friend:  bool
var impact_caster:  bool

#region AOE Skill
var aoe_exit_removes:  bool     # Should the appied skill be removed upon exiting the area?
var aoe_cast_delay:    float    # Amount of time to wait before casting after being placed
var aoe_size:          float    # Area radius/size
var aoe_duration:      float    # Duration of the area effect
var aoe_timer:         float    # Tracks remaining area duration
var aoe_tick_rate:     float    # Rate of area effect periodic application
var aoe_tick_timer:    float    # Tracks ticks for area periodic effects

var aoe_targets:    Array[Entity] = []
var aoe_location:   Vector3
#endregion

#region Status Effect Skill
var status_type:        String  # Type of status effect
var status_duration:    float   # Duration of the effect
var status_timer:       float   # Tracks remaining time for status effect
var status_tick_rate:   float   # How often status ticks (for DoT/HoT)
var status_tick_timer:  float   # Tracks ticks for periodic effects

var status_target:      Entity
#endregion

#region Targeted Skill
var can_target_self:    bool    # Can the skill target the caster themselves?
var can_target_friend:  bool    # Can the skill target allies?
var can_target_enemy:   bool    # Can the skill target enemies?

var targeted_target:    Entity
#endregion

var steps: Array[Effect] = []

var caster: Entity


static func initialize() -> void:
    var dir = DirAccess.open(CONFIG_PATH)

    if not dir:
        Logger.error("Unable to open skill data directory!",
            {"dir":CONFIG_PATH})

        return

    dir.list_dir_begin()

    for file:String in dir.get_files():
        SkillNew.load(file)


static func load(file:String) -> SkillNew:
    var id_str := file.replace("skill-", "").replace(".cfg", "")
    var id_int := int(id_str)

    if id_int == 0:
        Logger.error("Skill ID is 0. This is invalid.",
            {"file": file})


    var existing_skill = SkillNew.skill_pool.get(id_int)

    # If there is a copy of the skill in the pool, no need to load it from disk.
    if existing_skill:
        return existing_skill.duplicate()

    var cfg := ConfigFile.new()
    var df = "%s/%s" % [CONFIG_PATH, file]
    var err = cfg.load(df)

    if err:
        Logger.error("Could not parse skill file!",
            {"path":df,"error":error_string(err)})

        return

    if not cfg.has_section("skill"):
        Logger.error("Invalid skill configuration file!",
            {"skill":file, "issue":"No 'skill' section."})

        return

    var skill := SkillNew.new()

    skill.id    = id_int
    skill.name  = cfg.get_value("skill", "name", INVALID_NAME)

    if skill.name == INVALID_NAME:
        skill.name = str(skill.id)
        Logger.warn("Skill does not define name!",
            {"id":skill.id})

    skill.desc   = cfg.get_value("skill", "desc", "")

    var icon_file: String = cfg.get_value("skill", "icon", "skill_default_icon")

    if icon_file == "skill_default_icon":
        Logger.warn("Skill does not define icon!",
            {"id":skill.id,"name":skill.name})

    var icon_image: Image = Image.load_from_file(
        "res://art/icons/%s.png" % icon_file)

    if icon_image:
        skill.icon = ImageTexture.create_from_image(icon_image)
    else:
        Logger.error("Failed to load skill icon!",
            {"skill":skill.id,"icon":icon_file})

    # Expecting an Array[String], but we cannot strictly enforce that here
    var con_files: Array = cfg.get_value("skill", "conditions", [])

    for script in con_files:
        # If the value is not a string, print a warning and skip it.
        if script is not String:
            Logger.warn("Bad condition file type!",
                {"skill":file,
                    "expected type":TYPE_STRING_NAME,
                    "got type": type_string(typeof(script))})

        var con: ConditionBase = _load_condition(script)

        if con:
            skill.conditions.append(con)

    skill.kind = cfg.get_value("cast_type", "kind", "")

    if skill.kind.is_empty():
        Logger.warn(
            "Skill does not define kind!",
            {"id":skill.id,"name":skill.name})

    skill.can_target_enemy  = cfg.get_value("cast_type", "can_target_enemy", false)
    skill.can_target_friend = cfg.get_value("cast_type", "can_target_friend", false)
    skill.can_target_self   = cfg.get_value("cast_type", "can_target_self", false)

    skill.cooldown  = cfg.get_value("skill", "cooldown", 1)
    skill.max_range = cfg.get_value("skill", "max_range", 10)

    # --- Status section ---
    skill.status_type        = cfg.get_value("status", "type", "")
    skill.status_duration    = cfg.get_value("status", "duration", 0.0)
    skill.status_timer       = skill.status_duration
    skill.status_tick_rate   = cfg.get_value("status", "tick_rate", 0.0)
    skill.status_tick_timer  = 0.0

    # --- Area section ---
    skill.aoe_exit_removes  = cfg.get_value("aoe", "exit_removes", false)
    skill.aoe_cast_delay    = cfg.get_value("aoe", "cast_delay", 0.2)
    skill.aoe_size          = cfg.get_value("aoe", "size", 0.0)
    skill.aoe_duration      = cfg.get_value("aoe", "duration", 0.0)
    skill.aoe_timer         = skill.aoe_duration
    skill.aoe_tick_rate     = cfg.get_value("aoe", "tick_rate", 0.0)
    skill.aoe_tick_timer    = 0.0


    var i := 1
    var step_base = "step-"
    var curr_step= step_base + str(i)

    while cfg.has_section(curr_step):
        skill.steps.append( Effect.new(skill, cfg, curr_step) )

        i += 1
        curr_step = step_base + str(i)


    Logger.info("Loaded skill.",{"skill":file})
    return skill


func cast() -> void:
    if kind == "aoe":
        _handle_aoe()
    elif kind == "around_caster":
        _handle_around_caster()
    elif kind == "status":
        _handle_status()
    elif kind == "targeted":
        _handle_targeted()
    else:
        Logger.warn("Invalid cast type! Returning",
            {"kind":kind,"skill": id})


func _handle_aoe():
    Logger.info("Casted AOE.", {"skill":name})

    var aoe_node = aoe_scene.instantiate()
    aoe_node.position = aoe_location
    caster.get_tree().root.add_child(aoe_node)


func _handle_around_caster():
    pass


func _handle_status():
    if not status_target:
        Logger.warn("No target set status.",{"id":id,"caster":caster})
        return

    for effect in steps:
        effect.apply(caster, status_target)


func _handle_targeted():
    var target: Entity = _get_target()

    if not target:
        Logger.info("Invalid target")
        return

    for effect in steps:
        effect.apply(caster, target)


func _handle_modify_stat(stat: String, amount: int) -> void:
    pass


func _heal(target:Entity, amount:float) -> void:
    target.stats.health += amount


func _damage(target:Entity, amount:float) -> void:
    var remaining_damage = target.stats.health_extra - amount
    target.stats.health_extra -= amount

    # If health_extra is depleted, reduce main health by the remainder
    if remaining_damage < 0:
        target.stats.health += remaining_damage


static func _load_condition(file: String) -> ConditionBase:
    var id_str:= file.replace("con-", "")
    var id_int := int(id_str)

    if id_int == 0:
        Logger.error("Condition ID is 0. This is invalid.",
            {"file": file})

        return

    # If we already loaded the conditon, use the existing object.
    var condition: ConditionBase = con_pool.get(id_int)

    # If this is a new condition, create a new instance of the condition.
    if not condition:
        var script: Resource = load("%s/%s.gd" % [CONDITION_PATH, file])

        if script:
            condition = script.new() as ConditionBase
            con_pool[id_int] = condition 

    Logger.info("Loaded conditon.", {"condition":condition.desc})

    return condition


# Static utility: Checks if a target is valid for a given skill/caster
func _get_target() -> Entity:
    if not caster:
        return

    var target: Entity = targeted_target

    if not target:
        target = caster

    # Self targeting
    if caster == target:
        if can_target_self:
            return caster
        else:
            return

    # Ally and enemy checks
    if caster.team_id == target.team_id && not can_target_friend:
        return
    elif caster.team_id != target.team_id && not can_target_enemy:
        if caster.team_id == target.team_id && not can_target_friend:
            return
        elif caster.team_id != target.team_id && not can_target_enemy:
            return

    return target
