class_name Stats extends Node

@export var base_health:		float = 100
@onready var current_health:		float = base_health

@export var base_health_regen_rate:	float = 1
@onready var current_health_regen_rate:	float = base_health_regen_rate

@export var base_energy:		float = 50
@onready var current_energy:		float = base_energy

@export var base_energy_regen_rate:	float = 5
@export var current_energy_regen_rate:	float = 5

@export var base_speed:			float = 10
@onready var current_speed:		float = base_speed

@export var base_jump_force:		float = 20
@onready var current_jump_force:	float = base_jump_force

@export var can_air_jump:		bool = false
@export var base_jump_amount:		int = 1
@onready var current_jump_amount:	int = base_jump_amount

@export var base_gravity_scale:		float = 1
@onready var current_gravity_scale:	float = base_gravity_scale

@export var base_ability_points:	int = 5
