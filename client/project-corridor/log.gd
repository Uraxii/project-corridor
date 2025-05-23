class_name Log

var signals: SignalBus


func _init(signal_bus: SignalBus) -> void:
    signals = signal_bus


func info(message: String) -> void:
    signals.log_new_message.emit(message)
    print(message)
    
    
func error(message: String) -> void:
    signals.log_new_error.emit(message)
    printerr(message)
