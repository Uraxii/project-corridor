class_name SkillNew extends Node

const INVALID_ID:   int     = -1
const INVALID_NAME: String  = "INVALID_NAME"
const CONFIG_PATH:  String  = "res://skills/configs"
const ICON_PATH:    String = "res://skills/icons"

static var aoe_scene: Resource = preload("res://shared-code/skills/aoe.tscn")

#region Skill Info
var id:             int
var title:          String
var desc:           String
var kind:           String
var icon:           ImageTexture

var start_cast:     Callable
var conditions:     Array[Condition] = []
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

#region AOE Data
var aoe_on_exit:    bool     # Should the appied skill be removed upon exiting the area?
var aoe_delay:      float    # Amount of time to wait before casting after being placed
var aoe_size:       float    # Area radius/size
var aoe_duration:   float    # Duration of the area effect
var aoe_timer:      float    # Tracks remaining area duration
var aoe_tick_rate:  float    # Rate of area effect periodic application
var aoe_tick_timer: float    # Tracks ticks for area periodic effects

var aoe_targets:    Array[Entity] = []
var aoe_location:   Vector3
var aoe_rotation:   Vector3
#endregion

#region Status Effect Data
var status_type:        String  # Type of status effect
var status_duration:    float   # Duration of the effect
var status_timer:       float   # Tracks remaining time for status effect
var status_tick_rate:   float   # How often status ticks (for DoT/HoT)
var status_tick_timer:  float   # Tracks ticks for periodic effects

var status_target:      Entity
#endregion

var start_cast_functions: Dictionary[String, Callable] = {}
var steps: Array[SkillStep]
var caster: Entity
var target: Entity
var is_cast_canceled: bool

# region Static Functions
static func load(file:String="", skill_id:int=0) -> SkillNew:
    if not file.is_empty():
        skill_id = int(file.replace("skill-", "").replace(".cfg", ""))
    else:
        file = "skill-%d.cfg" % skill_id

    if skill_id == 0:
        printerr("Skill ID is 0. This is not allowed.", {"file": file})
        return

    var cfg := ConfigFile.new()
    var df = "%s/%s" % [CONFIG_PATH, file]
    var err = cfg.load(df)

    if err:
        printerr("Could not parse skill file!",
            {"path":df,"error":error_string(err)})
        return

    if not cfg.has_section("skill"):
        printerr("Invalid skill configuration file!",
            {"skill":file, "issue":"No 'skill' section."})
        return

    var skill := SkillNew.new()

    skill.start_cast_functions = {
        "targeted": skill._start_targeted_cast,
        "aoe":      skill._start_aoe_cast,}

    skill.id    = skill_id
    skill.title  = cfg.get_value("skill", "title", INVALID_NAME)

    if skill.title == INVALID_NAME:
        skill.title = str(skill.id)
        print("Skill does not define title!",
            {"id":skill.id})

    skill.desc = cfg.get_value("skill", "desc", "")

    var icon_file: String = cfg.get_value("skill", "icon", "skill_default_icon")

    if icon_file == "skill_default_icon":
        print("Skill does not define icon!",
            {"id":skill.id,"name":skill.name})

    var icon_image: Image = Image.load_from_file(
        "%s/%s.png" % [ICON_PATH, icon_file])

    if icon_image:
        skill.icon = ImageTexture.create_from_image(icon_image)
    else:
        print("Failed to load skill icon!",
            {"skill":skill.id,"icon":icon_file})

    # Expecting an Array[String], but we cannot strictly enforce that here
    var con_files: Array = cfg.get_value("skill", "conditions", [])

    for script in con_files:
        # If the value is not a string, print a warning and skip it.
        if script is not String:
            print("Bad condition file type!",
                {"skill":file,
                    "expected type":TYPE_STRING_NAME,
                    "got type": type_string(typeof(script))})

        var con: Condition = Condition.load(script)

        if con:
            skill.conditions.append(con)

    skill.kind = cfg.get_value("skill", "cast_type", "")

    if skill.kind.is_empty():
        printerr("Skill does not define cast_type!",
            {"id":skill.id,"name":skill.title})

        return

    skill.start_cast = skill.start_cast_functions[skill.kind]

    skill.cooldown  = cfg.get_value("skill", "cooldown", 1)
    skill.max_range = cfg.get_value("skill", "max_range", 10)

    # --- Status section ---
    skill.status_type        = cfg.get_value("status", "type", "")
    skill.status_duration    = cfg.get_value("status", "duration", 0.0)
    skill.status_timer       = skill.status_duration
    skill.status_tick_rate   = cfg.get_value("status", "tick_rate", 0.0)
    skill.status_tick_timer  = 0.0

    # --- Area section ---
    skill.aoe_delay    = cfg.get_value("aoe", "cast_delay", 0.2)
    skill.aoe_size          = cfg.get_value("aoe", "size", 0.0)
    skill.aoe_duration      = cfg.get_value("aoe", "duration", 0.0)
    skill.aoe_timer         = skill.aoe_duration
    skill.aoe_tick_rate     = cfg.get_value("aoe", "tick_rate", 0.0)
    skill.aoe_tick_timer    = 0.0

    var i := 1
    var step_base = "step-"
    var curr_step= step_base + str(i)

    while cfg.has_section(curr_step):
        skill.steps.append( SkillStep.new(cfg, curr_step) )

        i += 1
        curr_step = step_base + str(i)


    print("Loaded skill.",{"name":skill.title,"file":file})

    return skill
#endregion

func run_cast():
    for s in steps:
        var result := s.effect.apply(caster, target, s.effect_context)
        print("Applied effect", {"result":result})


func _start_aoe_cast():
    aoe_location = await _run_select_aoe_location()
    aoe_rotation = caster.body.global_rotation

    if is_cast_canceled:
        return

    #GameManager.queue_area_cast.rpc(
                #id,
                #caster.name,
                #aoe_location,
                #aoe_rotation)

    print("Casted AOE.", {"skill":title})

    var aoe_node = aoe_scene.instantiate()
    aoe_node.position = aoe_location
    caster.get_tree().root.add_child(aoe_node)


func _start_directional_cast():
    pass


func _start_targeted_cast():
    # These are client side checks. This logic *must* be moved to the server.

    print("skill called", {"skill":self})

    if not caster:
        printerr("No caster!", {"skill":title})
        return

    target = caster.target

    if not target:
        print("No target. Target set to caster.")
        target = caster

    for con in conditions:
        if not con.check(caster, target, {}):
            print("Condition failed!", {"condition":con})

            return

    #GameManager.queue_targeted_cast(id, caster.name, target.name)


func _run_select_aoe_location() -> Vector3:
    is_cast_canceled = false

    while not is_cast_canceled:
        await caster.get_tree().process_frame

        if caster.input.select_location:
            var viewport = caster.get_viewport()
            var camera = viewport.get_camera_3d()
            var mouse_pos = viewport.get_mouse_position()
            # Create a ray from the camera
            var from = camera.project_ray_origin(mouse_pos)
            var to = from + camera.project_ray_normal(mouse_pos) * 1000

            # Y-normal plane at origin
            var plane = Plane(Vector3(0, 1, 0), 0)
            var position_3d = plane.intersects_ray(from, to)

            return position_3d

        if caster.input.cancel:
            is_cast_canceled = true

    return Vector3.ZERO
