extends Control

@export var non_positional_root: Node
@export var positional_root: Node3D

@export var tracks:Array[DynamicMusicTrack]

@export_group("Prototypes", "proto_")
@export var proto_non_positional_player:AudioStreamPlayer
@export var proto_positional_player:AudioStreamPlayer3D

var selected_track_index:int = 0:
	set(value):
		if not tracks.size() > 0:
			selected_track_index = wrapi(value, 0, tracks.size()-1)
			selected_track_label.text = tracks[selected_track_index].title
		else:
			selected_track_index = -1
			selected_track_label.text = "No tracks!"

@onready var selected_track_label: Label = %SelectedTrack

func start_track(track:DynamicMusicTrack) -> void:
	if track.treat_positional:
		
		var player:AudioStreamPlayer3D = get_player(track)
		
	else:
		
		var player:AudioStreamPlayer = get_player(track)
	
func stop_track(track:DynamicMusicTrack) -> void:
	if track.treat_positional:
		
		var player:AudioStreamPlayer3D = get_player(track)
		player.stop()
		
	else:
		
		var player:AudioStreamPlayer = get_player(track)
		player.stop()
	
func get_player(track:DynamicMusicTrack) -> Variant:
	if track.treat_positional:
		
		for player:AudioStreamPlayer3D in positional_root.get_children():
			if player.stream == track.file:
				return player
				
		## New 3D Player
		var new_player:AudioStreamPlayer3D
		new_player = proto_positional_player.duplicate()
		
		new_player.stream = track.file
		
		positional_root.add_child(new_player)
		return new_player
		
	else:
		
		for player:AudioStreamPlayer in non_positional_root.get_children():
			if player.stream == track.file:
				return player
				
		## New Static Player
		var new_player:AudioStreamPlayer
		new_player = proto_non_positional_player.duplicate()
		
		new_player.stream = track.file
		
		non_positional_root.add_child(new_player)
		return new_player

func _on_start_stop_playback_pressed() -> void:
	start_track(tracks[selected_track_index])
		
func _on_stop_playback_pressed() -> void:
	stop_track(tracks[selected_track_index])


func _on_track_select_prev_pressed() -> void:
	selected_track_index -= 1

func _on_track_select_next_pressed() -> void:
	selected_track_index += 1
