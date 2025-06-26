extends Node

var entities:   Array[Entity]       = []

var casts:      Array[SkillNewer]   = []
var statuses:   Array[SkillNewer]   = []
var stack:      Array[StackEffect]  = []


func process_stack() -> void:
    var all_skills = casts + statuses
    
    #stack = all_skills.map()
    
    for skill in stack:
        print("Skill on stack", {"skill": skill})
        
    decrement_status_timers()
    
    statuses = statuses.filter(
        func(skill:SkillNewer): return skill.time_remaining > 0)
        

func decrement_status_timers() -> void:
    var network_delta: float = Network.polling_rate
    
    var to_remove: Array[int] = []
    var i: int = len(statuses) - 1
    
    for skill in statuses:
        skill.time_remaining -= network_delta

        if skill.next_tick <= 0:
            statuses[i].next_tick = statuses[i].tick_interval

        skill.next_tick -= network_delta


func sort_by_speed(left:SkillNewer, right:SkillNewer) -> int:
    if right.speed == left.speed:
        return 0
        
    if right.speed < left.speed:
        return -1
    
    # right.speed > left.speed
    return 1
