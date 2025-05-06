# This file should be set up as an autoload global.
class_name CombatLog extends Node

signal log_entry_created(from: String, to: String, event: String, value: String)


func add_entry(from: String, to: String, event: String, value: String) -> void:
    log_entry_created.emit(from, to, event, value)
    
    await get_tree().process_frame
    
    if not log_entry_created.get_connections():
        return
        
    var msg := "From: %s, To: %s, Event: %s, Value: %s" % [
        from, to, event, value]
        
    Console.log_message(msg)
