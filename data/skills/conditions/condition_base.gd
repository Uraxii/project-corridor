class_name Condition

const CONDITION_PATH: String  = "res://data/skills/conditions"
const OK: String = ""

var desc: String


func _init() -> void:
    self.desc = "Base condition. Check function always returns true. If everyone has done their jobs, you should NOT be seeing this as output."


static func load(condition_name: String) -> Condition:
    var script_path: String = "%s/%s.gd" % [CONDITION_PATH, condition_name]
    var script: Resource = load(script_path)


    if not script:
        Logger.error("Unable to load condition script!",
            {"path":script_path})

    var condition: Condition = script.new() as Condition

    Logger.info("Loaded conditon.", {"condition":condition.desc})

    return condition


func check(_caster:Entity, _target:Entity, _context:Dictionary) -> bool:
    Logger.warn("Tried to call check on condition base! Verify that check function is impelmented on the condition scripts. Condition will return true.")

    return false
