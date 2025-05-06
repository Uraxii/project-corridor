class_name GameWorldManager extends Node

signal game_load_start()
signal game_load_finish()


func reload() -> void:
    #Logger.info("Reloading world.")
    
    game_load_start.emit()
    game_load_finish.emit()
