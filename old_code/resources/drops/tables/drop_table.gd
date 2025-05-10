class_name DropTable extends Resource

# Liklihood of dropping x amount of items
@export var drop_count_weights: Dictionary[int, int] = {1:0}
# Liklihood of each item droppping.
@export var drops: Array[Drop] = []


func get_drops() -> Array[Drop]:
    Logger.error("get_drops not fully implemented!")
    
    var loot: Array[Drop] = []
    var next_drop: Drop

    var drop_count := 1
    
    while drop_count > 0:
        next_drop = drops.filter(func(drop: Drop): return drop.drop_limit > 0
            ).pick_random()
        
        loot.append(next_drop)
            
        next_drop.drop_limit -= 1
        
        drop_count -= 1
    
    return loot
