class_name DynamicMusicTrack extends Resource

const MUSIC_BUS:StringName = &"Music"

## Audio resource.
@export var file:AudioStream

## Title of the song.
@export_placeholder("Song Title") var title:String

## Tempo; Beats per minute.
@export var bpm:int

## Time signature.
@export var time_signature:Vector2i = Vector2i(4,4)

## Name, Beat Count.
@export var markers:Dictionary[StringName, int] = {"start": 0}

@export_group("Treatment", "treat_")
@export var treat_positional:bool = false

var is_playing:bool = false

func _init() -> void: prnt("Loaded %s." % [title])

func set_bpm_from_track() -> void:
	var _bpm:float = file._get_bpm()
	if _bpm != null:
		if _bpm > 0.0:
			bpm = _bpm
			return
	push_error("Track doesn't have BPM set. Check import settings.")

func prnt(x) -> void:
	## Print log. Swap me out some day.
	print_debug(x)
