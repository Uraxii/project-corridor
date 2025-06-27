class_name ModuleManager extends Node

signal load_new_module(module: Module)
signal register_new_hook(
    source: Object, signal_name: String, module: Module, handler_func: Callable)

var hook_sources: Dictionary[String, Object] = {
    #"modules": Modules,
    "combat_log": CombatLog,
    "console": Console,
    "commands": Commands,
    "entity": Entities,
    "network": NetCmd,
    "world": WorldManager,
}

# { Module, is enabled }
var modules: Dictionary[Module, bool] = {}


func _ready() -> void:
    if "--test-modules" in OS.get_cmdline_args():
        _test_modules()


func load_module(path: String) -> void:
    var resource = load("%s/main.gd" % path)
    
    if not resource:
        return
    
    var module := resource.new() as Module
    var err = module.load_metadata(path)
    
    if err:
        return

    module.setup()
    
    var hooks = module.get_hooks()
    
    for source_name in hooks.keys():
        for signal_name in hooks[source_name]:
            for handler_func in hooks[source_name][signal_name]:
                hook_signal(source_name, signal_name, handler_func, module)
        
    load_new_module.emit(module)
    
    #Logger.info("Loaded adddon.",
    #    {"metadata": module.get_metadata(), "hooks": module.get_hooks()})
    
    modules[module] = true
    
    module.after_setup()


func hook_signal(source_name: String, signal_name: String,
    handler_func: Callable, module: Module
) -> void:
    if not handler_func:
        Logger.error("Handler method is null!", {"module":module})
        
        return
    
    var source_obj: Object = hook_sources.get(source_name)
    
    if not source_obj:
        Logger.error("Source is not valid!", 
            {"module":module,"source":source_name})
        
        return
        
    if not source_obj.has_signal(signal_name):
        Logger.error("Source does not have that signal!",
            {"module":module,"source object":source_obj,"singal":signal_name})
            
    source_obj.connect(signal_name, handler_func)
    
    register_new_hook.emit(source_obj, signal_name, module, handler_func)


func _test_modules() -> void:
    var module_dirs := DirAccess.get_directories_at(
        "res://modules/test_modules")
    
    for dir_name in module_dirs:
        load_module("res://modules/test_modules/%s" % dir_name)
    
    WorldManager.reload()
