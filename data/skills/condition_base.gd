class_name Condition

const CONDITION_PATH:   String  = "res://data/skills/conditions"
const OK: String = ""

# Pool of conditions that have already been loaded.
# Conditions are duplicated as needed.
# Also saves us a trip to disk after a skill has been loaded for the first time.
static var pool: Dictionary[String, Condition] = {}

var desc: String


func _init() -> void:
    self.desc = "Base condition. Check function always returns true. If everyone has done their jobs, you should NOT be seeing this as output."


static func load(condition_name: String) -> Condition:
    # If we already loaded the conditon, use the existing object.
    var condition: Condition = pool.get(condition_name)

    # If this is a new condition, create a new instance of the condition.
    if not condition:
        var script: Resource = load(
            "%s/%s.gd" % [CONDITION_PATH, condition_name])

        if script:
            condition = script.new() as Condition
            pool[condition_name] = condition 

    Logger.info("Loaded conditon.", {"condition":condition.desc})

    return condition


func check(_caster:Entity, _target:Entity, _context) -> String:
    Logger.warn("Tried to call check on condition base! Verify that check function is impelmented on the condition scripts. Condition will return true.")

    return "Called the base Condition check function."
