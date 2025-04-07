class_name StatusEffectView extends Node

@onready var progress_bar = $ProgressBar
@onready var icon: TextureRect = $Icon
@onready var remaining_time = $RemainingTime
@onready var timer = $Timer

var skill: Skill = null


func initialize(skill: Skill) -> void:
        self.skill = skill
        icon.texture = skill.icon

        if skill.effect_duration == 0:
                return

        timer.wait_time = skill.effect_remaining_time
        timer.start()

        remaining_time.text = '%3.1f' % timer.time_left
        progress_bar.value = (timer.time_left/skill.effect_duration) * 100

        if not skill or skill.effect_remaining_time <= 0:
                queue_free.call_deferred()
