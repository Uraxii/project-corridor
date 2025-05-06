# Global Console
extends Node

signal log_new_message(message: String)
signal log_new_debug(message: String)
signal log_new_warning(message: String)
signal log_new_error(message: String)
signal log_new_announcment(message: String)

var history: Array[String] = []


func log_message(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    log_new_message.emit(message)
    
    if not log_new_message.get_connections():
        Logger.info(message)


func log_debug(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    log_new_debug.emit(message)
    
    if not log_new_debug.get_connections():
        Logger.info(message)


func log_warning(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    log_new_warning.emit(message)
    
    if not log_new_warning.get_connections():
        Logger.warn(message)
    
        
func log_error(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    log_new_error.emit(message)
    
    if not log_new_error.get_connections():
        Logger.warn(message)


func log_announcement(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    log_new_announcment.emit(message)
    
    if not log_new_announcment.get_connections():
        Logger.info(message)
