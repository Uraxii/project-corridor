class_name Main extends Node

enum ServerMode {
	CLIENT,
	HEADLESS_SERVER
}

var server_mode: ServerMode = ServerMode.CLIENT
var shard_config: Dictionary = {}


func _ready() -> void:
	var args := ArgParser.parse()
	
	print("Args=", args)
	
	# Check if running as headless server
	if _is_server_mode(args):
		server_mode = ServerMode.HEADLESS_SERVER
		_initialize_server(args)
	else:
		server_mode = ServerMode.CLIENT
		_initialize_client(args)


func _is_server_mode(args: Dictionary) -> bool:
	"""Check if we should run as a headless server."""
	return args.has("headless") or args.has("server") or args.has("shard-id")


func _initialize_server(args: Dictionary) -> void:
	"""Initialize as a headless server shard."""
	print("Initializing as headless server...")
	
	# Parse server-specific arguments
	shard_config = {
		"shard_id": args.get("shard-id", "unknown"),
		"shard_type": args.get("shard-type", "hub"), 
		"port": int(args.get("port", "9000")),
		"max_players": int(args.get("max-players", "4")),
		"manager_host": args.get("manager-host", "localhost"),
		"manager_port": int(args.get("manager-port", "8081"))
	}
	
	print("Shard config: ", shard_config)
	
	# Load the init scene first to set up global managers
	var init_scene = load("res://scenes/init.tscn")
	if init_scene:
		var init_instance = init_scene.instantiate()
		get_tree().root.add_child(init_instance)
		
		# Wait a frame for globals to initialize
		await get_tree().process_frame
		
		# Now start the server manager
		var server_manager = ServerManager.new()
		get_tree().root.add_child(server_manager)
		server_manager.initialize_shard(shard_config)
	else:
		push_error("Failed to load init scene for server mode")


func _initialize_client(args: Dictionary) -> void:
	"""Initialize as a normal client."""
	print("Initializing as client...")
	if args.has("auto_connect"):
		# Auto-connect logic for client testing
		pass
