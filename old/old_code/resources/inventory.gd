class_name Inventory extends Resource

enum ErrorCode
{
    ok,
    full,
    invalid_type,
    not_in_inventory,
}

class slot:
    var item:   Item
    var count:  int = 0:
        set(value):
            count = clamp(value, 0, item.tags["max_stack"])
            
    # Returns amount of overflow
    func increase(amount: int) -> int:
        var over_flow := (count + amount) - item.tags["max_stack"]
        
        # We are less than the max stack. Therfore, no overflow.
        if over_flow < 0:
            over_flow = 0
            
        count += amount
        
        return over_flow
        
    # Returns amount remaining.
    func decrease(amount: int) -> int:
        count -= amount
        
        return count
            

# Empty means any item can be added
@export var accepts:    Array["String"] = []
@export var size:       int = 10
@export var slots:      Array[slot] = []


func add(item: Item) -> ErrorCode:
    if len(accepts) > 0 and item.kind not in accepts:
        return ErrorCode.invalid_type
        
    if len(slots) >= size:
        return ErrorCode.full
    
    return ErrorCode.ok


func remove(item: Item) -> ErrorCode:
    if not slots.has(item):
        return ErrorCode.not_in_inventory
        
    items[item] -= 1
