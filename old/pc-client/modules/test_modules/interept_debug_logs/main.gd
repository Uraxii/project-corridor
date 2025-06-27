extends Module

var hooks: Dictionary = {
    "console" = {
        "log_new_debug" = [
            func(msg:String):Logger.info("Intercepted Debug Log.", {"log":msg})
        ]
    },
}


func get_hooks():
    return hooks


func after_setup():
    Console.log_debug(
        "This is a log message from the Intercept Debug Logs module.")
