class_name EquipedItems extends Resource

signal equiped(item: Item)
signal unequiped(item: Item)

enum ItemSlot
{
    first_available,
    ring1,
    ring2,
    trinket,
}

var curr: Dictionary[Slot, Item] = {
    Slot.ring1: null,
    Slot.ring2: null,
    Slot.trinket: null,
}


func equip(item: Item, slot: Slot) -> void:
    if slot == Slot.first_available:
        for 
        
    equiped.emit(item)


func unequip(slot: Slot) -> void:
    var currently_equiped: Item = curr[slot]
    
    if currently_equiped:
        curr[slot] = null
        unequiped.emit(currently_equiped)
    
