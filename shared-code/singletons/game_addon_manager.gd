class_name GameAddonManager extends Node

signal load_new_addon(addon: Addon)
signal register_new_hook(
    source: Object, signal_name: String, addon: Addon, handler_func: Callable)

var hook_sources: Dictionary[String, Object] = {
    "addon_manager": AddonManager,
    "combat_log": CombatLogger,
    "console": Console,
    "commands": Commands,
    "entity": EntityManager,
    #"network": Network,
    "world": WorldManager,
}

# { Addon, is enabled }
var addons: Dictionary[Addon, bool] = {}


func _ready() -> void:
    if "--test-addons" in OS.get_cmdline_args():
        _test_addons()


func load_addon(path: String) -> void:
    var resource = load("%s/main.gd" % path)
    
    if not resource:
        return
    
    var addon := resource.new() as Addon
    var err = addon.load_metadata(path)
    
    if err:
        return

    addon.setup()
    
    var hooks = addon.get_hooks()
    
    for source_name in hooks.keys():
        for signal_name in hooks[source_name]:
            for handler_func in hooks[source_name][signal_name]:
                hook_signal(source_name, signal_name, handler_func, addon)
        
    load_new_addon.emit(addon)
    
    #Logger.info("Loaded adddon.",
    #    {"metadata": addon.get_metadata(), "hooks": addon.get_hooks()})
    
    addons[addon] = true
    
    addon.after_setup()


func hook_signal(source_name: String, signal_name: String,
    handler_func: Callable, addon: Addon
) -> void:
    if not handler_func:
        Logger.error("Handler method is null!", {"addon":addon})
        
        return
    
    var source_obj: Object = hook_sources.get(source_name)
    
    if not source_obj:
        Logger.error("Source is not valid!", 
            {"addon":addon,"source":source_name})
        
        return
        
    if not source_obj.has_signal(signal_name):
        Logger.error("Source does not have that signal!",
            {"addon":addon,"source object":source_obj,"singal":signal_name})
            
    source_obj.connect(signal_name, handler_func)
    
    register_new_hook.emit(source_obj, signal_name, addon, handler_func)


func _test_addons() -> void:
    var addon_dirs := DirAccess.get_directories_at("res://addons/test_addons")
    
    for dir_name in addon_dirs:
        load_addon("res://addons/test_addons/%s" % dir_name)
    
    WorldManager.reload()
