class_name EntityNew extends Node3D

@export var stats       := EntityStats.new()
@export var equipment   := Equipment.new()

var health := HealthComponenet.new()


#region Godot Callback Functions
func _ready() -> void:
    stats.level_up.connect(_on_stat_change)
    equip.change_equpment.connect(_on_stat_change)
#endregion


func _on_stat_change() -> void:
    var new_max_hp := stats.get_max_hp()
    
    for item in equipment.equiped:
        
