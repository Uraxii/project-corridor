class_name DynamicMusicTrack extends Resource

@export var track:AudioStream


@export_placeholder("Song Title") var title:String

## Tempo; Beats per minute.
@export var bpm:int

## Time signature.
@export var time_signature:Vector2i = Vector2i(4,4)

## Name, Beat Count.
@export var markers:Dictionary[StringName, int] = {"start": 0}


func set_bpm_from_track() -> void:
	var _bpm:float = track._get_bpm()
	if _bpm != null:
		if _bpm > 0.0:
			bpm = _bpm
			return
	push_error("Track doesn't have BPM set. Check import settings.")
