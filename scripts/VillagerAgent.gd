extends Node2D
class_name VillagerAgent

@export var villager_name: String = "Villager"
@export_range(20.0, 220.0, 1.0) var move_speed: float = 55.0
@export_range(0.05, 3.0, 0.05) var hunger_drain_per_sec: float = 0.45
@export_range(0.05, 3.0, 0.05) var energy_drain_per_sec: float = 0.35

const MAX_STAT: float = 100.0
const MAX_HUNGER: float = 300.0
const MAX_HYDRATION: float = 1000.0
const REST_POINT := Vector2(180.0, 420.0)
const FOOD_POINT := Vector2(860.0, 170.0)

var hunger: float = MAX_HUNGER
var energy: float = MAX_STAT
var health: float = MAX_STAT
var hydration: float = MAX_HYDRATION
var body_temperature_c: float = 37.0
var last_ambient_temperature_c: float = 23.0
var last_humidity: float = 0.45
var is_sweating: bool = false
var is_shivering: bool = false
var _is_dead: bool = false
var _swim_mode: bool = false
var _is_swimming: bool = false
var _stamina_gene: float = 1.0
var _stuck_timer: float = 0.0
var _stuck_check_position: Vector2 = Vector2.ZERO
var _is_stuck: bool = false
var _stuck_seconds: float = 0.0
var _hunger_energy_tick_timer: float = 0.0
var _notify_death: Callable
var _is_water_position: Callable
var _destination: Vector2
var _arena_rect: Rect2
var _wander_timer: float = 0.0
var _sprite: Sprite2D
var _swim_overlay_fill: Polygon2D
var _swim_overlay_crest: Line2D
var _heart_particles: CPUParticles2D
var _is_horny_visual: bool = false
var _label: RichTextLabel
var inventory: Dictionary = {"wood": 0, "apple": 0, "seed": 0, "fish": 0}
@export var wood_needed_per_build: int = 6
@export_range(0.5, 10.0, 0.1) var chop_duration_seconds: float = 4.0
@export_range(8.0, 48.0, 1.0) var chop_interaction_distance: float = 18.0
@export_range(8.0, 64.0, 1.0) var drop_pickup_distance: float = 18.0
@export_range(0.5, 10.0, 0.1) var fish_duration_seconds: float = 3.2
@export_range(16.0, 96.0, 1.0) var fish_interaction_distance: float = 26.0
@export_range(1, 4, 1) var fish_food_yield_min: int = 1
@export_range(1, 8, 1) var fish_food_yield_max: int = 3
@export_range(5.0, 80.0, 1.0) var apple_hunger_restore: float = 35.0
@export_range(0, 4, 1) var seeds_per_apple_eaten: int = 1
@export_range(0.1, 8.0, 0.1) var eat_cooldown_seconds: float = 2.0
@export_range(0.5, 20.0, 0.5) var seed_plant_try_interval: float = 5.0
@export_range(0.5, 8.0, 0.1) var inventory_popup_seconds: float = 3.0
@export_range(0.1, 3.0, 0.1) var inventory_popup_fade_seconds: float = 0.7
@export_range(0.0, 100.0, 1.0) var home_enter_energy_threshold: float = 24.0
@export_range(0.0, 500.0, 1.0) var home_search_radius: float = 320.0
@export_range(1.0, 30.0, 0.5) var home_stay_seconds: float = 7.0
@export var llm_debug_enabled: bool = true
@export var llm_apply_log_to_output: bool = false
@export_range(0.5, 12.0, 0.1) var speech_bubble_seconds: float = 4.8
@export_range(0.1, 6.0, 0.1) var speech_bubble_fade_seconds: float = 1.8
@export_range(8.0, 120.0, 1.0) var speech_bubble_typewriter_chars_per_sec: float = 42.0
@export var speech_bubble_name_color: Color = Color(0.96, 0.86, 0.36, 1.0)
@export_range(0.0, 1.0, 0.01) var speech_bubble_center_pull_strength: float = 0.12
@export_range(0.0, 96.0, 1.0) var speech_bubble_center_pull_max_offset: float = 28.0
@export_range(0.0, 128.0, 1.0) var speech_bubble_total_max_offset: float = 96.0
@export_range(16.0, 240.0, 1.0) var player_talk_radius: float = 78.0
@export_range(12.0, 120.0, 1.0) var heal_interaction_distance: float = 34.0
@export_range(1.0, 60.0, 0.5) var heal_amount: float = 18.0
@export_range(0.0, 40.0, 0.5) var heal_energy_cost: float = 12.0
@export_range(10.0, 95.0, 1.0) var heal_target_health_threshold: float = 62.0
@export_range(0.0, 0.3, 0.001) var heuristic_social_chat_chance_per_second: float = 0.028
@export_range(0.0, 80.0, 0.5) var heuristic_social_chat_cooldown_min_seconds: float = 9.0
@export_range(0.0, 120.0, 0.5) var heuristic_social_chat_cooldown_max_seconds: float = 22.0
@export_range(0.0, 0.3, 0.001) var heuristic_heal_chance_per_second: float = 0.024
@export_range(0.0, 80.0, 0.5) var heuristic_heal_cooldown_min_seconds: float = 8.0
@export_range(0.0, 120.0, 0.5) var heuristic_heal_cooldown_max_seconds: float = 20.0
@export_range(0.0, 0.3, 0.001) var heuristic_fishing_chance_per_second: float = 0.032
@export_range(0.0, 300.0, 1.0) var heuristic_fishing_hunger_threshold: float = 140.0
@export_range(0.0, 80.0, 0.5) var heuristic_fishing_cooldown_min_seconds: float = 7.0
@export_range(0.0, 120.0, 0.5) var heuristic_fishing_cooldown_max_seconds: float = 18.0
@export_range(8.0, 120.0, 1.0) var campfire_interaction_distance: float = 26.0
@export_range(0.0, 0.3, 0.001) var heuristic_campfire_chance_per_second: float = 0.03
@export_range(0.0, 120.0, 0.5) var heuristic_campfire_cooldown_min_seconds: float = 10.0
@export_range(0.0, 160.0, 0.5) var heuristic_campfire_cooldown_max_seconds: float = 30.0
@export_range(0.0, 20.0, 0.1) var ollama_action_lock_seconds: float = 1.6
@export_range(0.0, 30.0, 1.0) var swim_drown_energy_threshold: float = 20.0
@export_range(1.0, 5.0, 0.1) var swim_energy_drain_multiplier: float = 2.8
@export_range(1.0, 5.0, 0.1) var swim_hunger_drain_multiplier: float = 1.7
@export_range(0.2, 1.0, 0.05) var swim_speed_multiplier: float = 0.55
@export_range(0.5, 20.0, 0.5) var drown_rate_per_sec: float = 5.0
@export_range(0.0, 40.0, 0.5) var hunger_health_damage_threshold: float = 10.0
@export_range(0.5, 10.0, 0.5) var low_hunger_health_drain_per_sec: float = 2.0
@export_range(0.0, 8.0, 0.1) var passive_health_regen_per_sec: float = 0.8
@export_range(0.1, 20.0, 0.1) var energy_cost_per_hp_regen: float = 3.0
@export_range(0.0, 80.0, 0.5) var min_energy_for_hp_regen: float = 8.0
@export_range(0.0, 100.0, 0.5) var llm_decision_energy_cost: float = 20.0
@export_range(1.0, 40.0, 0.5) var energy_per_hunger_point: float = 10.0
@export_range(0.5, 10.0, 0.1) var hunger_to_energy_tick_seconds: float = 1.0
@export_range(0.5, 5.0, 0.5) var hunger_to_energy_hunger_cost_per_tick: float = 1.0
@export_range(2.0, 10.0, 0.5) var stuck_check_interval: float = 3.5
@export_range(4.0, 40.0, 1.0) var stuck_distance_threshold: float = 12.0
@export var thermal_system_enabled: bool = true
@export_range(32.0, 42.0, 0.1) var target_body_temperature_c: float = 37.0
@export_range(0.5, 6.0, 0.1) var thermal_damage_tolerance_c: float = 2.0
@export_range(28.0, 40.0, 0.1) var danger_body_temp_low_c: float = 32.5
@export_range(36.0, 45.0, 0.1) var danger_body_temp_high_c: float = 40.0
@export_range(0.0, 20.0, 0.1) var thermal_damage_per_sec: float = 3.8
@export_range(0.5, 8.0, 0.05) var body_thermal_mass: float = 3.2
@export_range(0.0, 4.0, 0.05) var max_passive_cooling_c_per_sec: float = 0.55
@export_range(0.0, 2.0, 0.01) var heat_transfer_conduction_rate: float = 0.04
@export_range(0.0, 2.0, 0.01) var heat_transfer_convection_rate: float = 0.04
@export_range(0.0, 2.0, 0.01) var heat_transfer_radiation_rate: float = 0.04
@export_range(0.0, 1.0, 0.01) var metabolic_heat_gain_c_per_sec: float = 0.04
@export_range(0.0, 6.0, 0.01) var internal_heat_generation_cap_c_per_sec: float = 3.2
@export_range(0.0, 100.0, 0.5) var internal_heat_energy_cost_per_c: float = 2.0
@export_range(0.0, 6.0, 0.01) var shiver_heat_gain_c_per_sec: float = 3.8
@export_range(0.0, 8.0, 0.01) var shiver_heat_cap_c_per_sec: float = 5.2
@export_range(0.0, 4.0, 0.05) var shiver_start_delta_c: float = 0.35
@export_range(0.0, 20.0, 0.1) var shiver_energy_cost_per_sec: float = 3.0
@export_range(0.0, 4.0, 0.01) var movement_heat_gain_c_per_sec: float = 0.95
@export_range(0.0, 4.0, 0.01) var chopping_heat_gain_c_per_sec: float = 0.75
@export_range(0.0, 8.0, 0.1) var ambient_temp_wave_c: float = 1.2
@export_range(0.05, 2.0, 0.05) var ambient_temp_wave_speed: float = 0.35
@export_range(0.0, 4.0, 0.05) var water_heat_pull_margin_c_per_sec: float = 0.12
@export_range(0.0, 2.0, 0.01) var sweat_cooling_c_per_sec: float = 1.10
@export_range(0.0, 25.0, 0.1) var sweat_hydration_cost_per_sec: float = 4.0
@export_range(0.0, 10.0, 0.1) var sweat_energy_cost_per_sec: float = 0.5
@export_range(0.1, 1.0, 0.01) var hot_ambient_absorption_multiplier: float = 0.55
@export_range(0.5, 2.0, 0.01) var cool_ambient_dissipation_multiplier: float = 1.08
@export_range(0.05, 0.4, 0.01) var solar_gain_multiplier: float = 0.1
@export_range(0.0, 1.0, 0.01) var tree_shade_solar_block: float = 0.88
@export_range(0.0, 2.0, 0.01) var overheat_sweat_extra_cooling_per_sec: float = 0.45
@export_range(0.0, 5.0, 0.05) var hydration_drain_per_sec: float = 0.22
@export_range(0.0, 40.0, 0.5) var drink_recovery_per_sec: float = 15.0
@export_range(0.0, 1000.0, 1.0) var hydration_seek_threshold: float = 340.0
@export_range(0.0, 4.0, 0.05) var homeostasis_temp_tolerance_c: float = 0.4

const CHOP_ANIM_LOOPS_PER_ACTION: float = 4.0

var _is_walkable: Callable
var _find_world_path: Callable
var _request_build_site: Callable
var _place_build_part: Callable
var _release_build_site: Callable
var _get_tree_cells: Callable
var _get_tree_world_position: Callable
var _get_tree_render_z_for_position: Callable
var _reserve_tree: Callable
var _chop_tree: Callable
var _release_tree: Callable
var _request_drop_target: Callable
var _pickup_reserved_drop: Callable
var _release_drop_target: Callable
var _try_auto_plant_seed: Callable
var _get_nearest_home: Callable
var _enter_home: Callable
var _leave_home: Callable
var _request_crafting_table_access: Callable
var _craft_stage_item: Callable
var _get_stage_wood_cost: Callable
var _find_player_target: Callable
var _speak_to_nearby_player: Callable
var _find_injured_player_target: Callable
var _heal_nearby_player: Callable
var _evaluate_llm_decision: Callable
var _record_long_term_memory: Callable
var _sample_water_current_velocity: Callable
var _sample_thermal_environment: Callable
var _find_nearest_water_world_position: Callable
var _sample_tree_shade_factor: Callable
var _claim_tile: Callable
var _trade_with_nearby_player: Callable
var _is_horny_state: Callable
var _is_conversation_pause_active: Callable
var _get_cactus_water_bottle: Callable
var _manage_campfire: Callable

var _build_cell: Vector2i = Vector2i(-9999, -9999)
var _build_world_position: Vector2 = Vector2.ZERO
var _build_approach_world_position: Vector2 = Vector2.ZERO
var _build_total_steps: int = 0
var _build_step_index: int = 0
var _build_step_timer: float = 0.0
var _has_build_site: bool = false
var _build_structure_type: String = "house"
var _build_requires_crafting: bool = true
var _build_stage_wood_costs: Array[int] = []
var _held_stage_item_index: int = -1
var _craft_table_world_position: Vector2 = Vector2.ZERO
var _has_craft_target: bool = false
var _craft_table_wood_needed: int = 0
var _avoidance_turn_sign: float = 1.0
var _path_waypoints: Array[Vector2] = []
var _path_goal_world_position: Vector2 = Vector2(INF, INF)
var _path_recalc_cooldown: float = 0.0
var _home_cell: Vector2i = Vector2i(-9999, -9999)
var _home_world_position: Vector2 = Vector2.ZERO
var _has_home_target: bool = false
var _is_inside_home: bool = false
var _inside_home_timer: float = 0.0

var _chop_cell: Vector2i = Vector2i(-9999, -9999)
var _chop_world_position: Vector2 = Vector2.ZERO
var _has_chop_target: bool = false
var _chop_timer: float = 0.0
var _find_tree_cooldown: float = 0.0
var _drop_target_id: int = -1
var _drop_world_position: Vector2 = Vector2.ZERO
var _has_drop_target: bool = false
var _eat_cooldown: float = 0.0
var _seed_plant_cooldown: float = 0.0
var _inventory_popup: Node2D
var _inventory_popup_bg: Sprite2D
var _inventory_popup_rows: Dictionary = {}
var _inventory_popup_timer: float = 0.0
var _speech_bubble: Node2D
var _speech_bubble_bg: Sprite2D
var _speech_bubble_label: RichTextLabel
var _speech_bubble_timer: float = 0.0
var _speech_bubble_is_thinking: bool = false
var _speech_bubble_thinking_elapsed: float = 0.0
var _speech_bubble_full_body_text: String = ""
var _speech_bubble_visible_chars: int = 0
var _speech_bubble_typewriter_progress: float = 0.0
var _speech_bubble_hold_until_next: bool = false
var _speech_bubble_anchor_base: Vector2 = Vector2(-36.0, -62.0)
var _speech_bubble_avoid_offset_x: float = 0.0
var _speech_bubble_avoid_offset_y: float = 0.0
var _speech_bubble_center_pull_offset_x: float = 0.0
var _physical_genes: Dictionary = {}
var _llm_genes: Dictionary = {}
var _neural_network: NeuralNetwork = null
var _neural_network_enabled: bool = true
var _neural_network_update_timer: float = 0.0
var _last_neural_network_outputs: Dictionary = {}
var _llm_decision_timer: float = 0.0
var _llm_preferred_target: String = ""
var _llm_goal_text: String = ""
var _llm_last_action: String = ""
var _llm_last_source: String = ""
var _llm_last_status: String = ""
var _llm_last_decision_age: float = 0.0
var _ollama_action_lock_timer: float = 0.0
var _water_seek_cooldown: float = 0.0
var _drop_target_stale_timer: float = 0.0
var _player_target_name: String = ""
var _player_target_world_position: Vector2 = Vector2.ZERO
var _has_player_target: bool = false
var _pending_talk_message: String = ""
var _pending_talk_target_name: String = ""
var _heuristic_social_chat_cooldown: float = 0.0
var _pending_heal_target_name: String = ""
var _heuristic_heal_cooldown: float = 0.0
var _heuristic_fishing_cooldown: float = 0.0
var _heuristic_campfire_cooldown: float = 0.0
var _overhead_hidden_for_conversation: bool = false
var _fish_world_position: Vector2 = Vector2.ZERO
var _has_fish_target: bool = false
var _fish_timer: float = 0.0
var _pending_campfire_action: String = ""
var _campfire_target_world_position: Vector2 = Vector2.ZERO
var _has_campfire_target: bool = false

var _tool_sprite: AnimatedSprite2D

@export var building_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var build_start_chance_per_second: float = 0.12
@export_range(0.2, 5.0, 0.1) var build_step_interval_seconds: float = 1.1

func setup(
	start_position: Vector2,
	arena_rect: Rect2,
	sprite_texture: Texture2D,
	display_name: String,
	is_walkable: Callable = Callable(),
	find_world_path: Callable = Callable(),
	request_build_site: Callable = Callable(),
	place_build_part: Callable = Callable(),
	release_build_site: Callable = Callable(),
	get_tree_cells: Callable = Callable(),
	get_tree_world_position: Callable = Callable(),
	get_tree_render_z_for_position: Callable = Callable(),
	reserve_tree: Callable = Callable(),
	chop_tree: Callable = Callable(),
	release_tree: Callable = Callable(),
	request_drop_target: Callable = Callable(),
	pickup_reserved_drop: Callable = Callable(),
	release_drop_target: Callable = Callable(),
	try_auto_plant_seed: Callable = Callable(),
	get_nearest_home: Callable = Callable(),
	enter_home: Callable = Callable(),
	leave_home: Callable = Callable(),
	request_crafting_table_access: Callable = Callable(),
	craft_stage_item: Callable = Callable(),
	get_stage_wood_cost: Callable = Callable(),
	find_player_target: Callable = Callable(),
	speak_to_nearby_player: Callable = Callable(),
	find_injured_player_target: Callable = Callable(),
	heal_nearby_player: Callable = Callable(),
	in_game_debug_ui_enabled: bool = true,
	evaluate_llm_decision: Callable = Callable(),
	record_long_term_memory: Callable = Callable(),
	physical_genes: Dictionary = {},
	llm_genes: Dictionary = {},
	notify_death: Callable = Callable(),
	is_water_position: Callable = Callable(),
	sample_water_current_velocity: Callable = Callable(),
	sample_thermal_environment: Callable = Callable(),
	find_nearest_water_world_position: Callable = Callable(),
	sample_tree_shade_factor: Callable = Callable(),
	claim_tile: Callable = Callable(),
	trade_with_nearby_player: Callable = Callable(),
	is_horny_state: Callable = Callable(),
	is_conversation_pause_active: Callable = Callable(),
	get_cactus_water_bottle: Callable = Callable(),
	manage_campfire: Callable = Callable()
) -> void:
	position = start_position
	z_index = 2
	_arena_rect = arena_rect
	villager_name = display_name
	_is_walkable = is_walkable
	_find_world_path = find_world_path
	_request_build_site = request_build_site
	_place_build_part = place_build_part
	_release_build_site = release_build_site
	_get_tree_cells = get_tree_cells
	_get_tree_world_position = get_tree_world_position
	_get_tree_render_z_for_position = get_tree_render_z_for_position
	_reserve_tree = reserve_tree
	_chop_tree = chop_tree
	_release_tree = release_tree
	_request_drop_target = request_drop_target
	_pickup_reserved_drop = pickup_reserved_drop
	_release_drop_target = release_drop_target
	_try_auto_plant_seed = try_auto_plant_seed
	_get_nearest_home = get_nearest_home
	_enter_home = enter_home
	_leave_home = leave_home
	_request_crafting_table_access = request_crafting_table_access
	_craft_stage_item = craft_stage_item
	_get_stage_wood_cost = get_stage_wood_cost
	_find_player_target = find_player_target
	_speak_to_nearby_player = speak_to_nearby_player
	_find_injured_player_target = find_injured_player_target
	_heal_nearby_player = heal_nearby_player
	llm_debug_enabled = in_game_debug_ui_enabled
	_evaluate_llm_decision = evaluate_llm_decision
	_record_long_term_memory = record_long_term_memory
	_notify_death = notify_death
	_is_water_position = is_water_position
	_sample_water_current_velocity = sample_water_current_velocity
	_sample_thermal_environment = sample_thermal_environment
	_find_nearest_water_world_position = find_nearest_water_world_position
	_sample_tree_shade_factor = sample_tree_shade_factor
	_claim_tile = claim_tile
	_trade_with_nearby_player = trade_with_nearby_player
	_is_horny_state = is_horny_state
	_is_conversation_pause_active = is_conversation_pause_active
	_get_cactus_water_bottle = get_cactus_water_bottle
	_manage_campfire = manage_campfire
	_physical_genes = physical_genes.duplicate(true)
	_llm_genes = llm_genes.duplicate(true)
	_apply_physical_genes()
	_initialize_neural_network(_llm_genes)
	var initial_llm_delay_min: float = minf(4.0, _get_llm_decision_interval_seconds())
	var initial_llm_delay_max: float = maxf(initial_llm_delay_min, _get_llm_decision_interval_seconds())
	_llm_decision_timer = randf_range(initial_llm_delay_min, initial_llm_delay_max)
	_hunger_energy_tick_timer = randf_range(0.2, maxf(0.2, hunger_to_energy_tick_seconds))
	_heuristic_social_chat_cooldown = randf_range(2.0, 8.0)
	_destination = position
	_stuck_check_position = start_position

	_sprite = Sprite2D.new()
	_sprite.texture = sprite_texture
	_sprite.centered = true
	add_child(_sprite)
	_setup_horny_particles_ui()
	_setup_swim_overlay_ui()

	# Tool sprite (tools.png uses columns for tool type; column 0 = axe, column 4 = fishing rod)
	var tools_tex: Texture2D = load("res://tools.png") as Texture2D
	if tools_tex:
		var tool_columns: int = 5
		var frame_size: int = maxi(1, mini(32, mini(int(tools_tex.get_height()), int(floor(float(tools_tex.get_width()) / maxf(1.0, float(tool_columns)))))))
		var row_count: int = maxi(1, int(floor(float(tools_tex.get_height()) / maxf(1.0, float(frame_size)))))
		var frames := SpriteFrames.new()
		frames.add_animation("chop")
		frames.set_animation_loop("chop", true)
		frames.set_animation_speed("chop", float(row_count) * CHOP_ANIM_LOOPS_PER_ACTION / maxf(0.1, chop_duration_seconds))
		for row in row_count:
			var at := AtlasTexture.new()
			at.atlas = tools_tex
			at.region = Rect2(0, row * frame_size, frame_size, frame_size)
			frames.add_frame("chop", at)
		frames.add_animation("fish")
		frames.set_animation_loop("fish", true)
		frames.set_animation_speed("fish", float(row_count) * CHOP_ANIM_LOOPS_PER_ACTION / maxf(2.0, fish_duration_seconds))
		for row in row_count:
			var fish_at := AtlasTexture.new()
			fish_at.atlas = tools_tex
			fish_at.region = Rect2(4 * frame_size, row * frame_size, frame_size, frame_size)
			frames.add_frame("fish", fish_at)
		_tool_sprite = AnimatedSprite2D.new()
		_tool_sprite.sprite_frames = frames
		_tool_sprite.position = Vector2(10.0, -6.0)
		_tool_sprite.scale = Vector2(1.4, 1.4) if frame_size <= 16 else Vector2(0.7, 0.7)
		_tool_sprite.z_index = 5
		_tool_sprite.visible = false
		add_child(_tool_sprite)

	_label = RichTextLabel.new()
	_label.position = Vector2(-30.0, -30.0)
	_label.size = Vector2(112.0, 42.0)
	_label.scale = Vector2(0.55, 0.55)
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("normal_font_size", 12)
	_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95, 0.96))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	_label.add_theme_constant_override("outline_size", 2)
	add_child(_label)
	_setup_inventory_popup_ui()
	_setup_speech_bubble_ui()
	_update_swim_overlay()
	_update_label()
	queue_redraw()

func _draw() -> void:
	var shadow_offset_y: float = 0.9 if _is_swimming else 6.0
	var shadow_scale: Vector2 = Vector2(0.70, 0.23) if _is_swimming else Vector2(1.0, 0.38)
	draw_set_transform(Vector2(0.0, shadow_offset_y), 0.0, shadow_scale)
	draw_circle(Vector2.ZERO, 7.0, Color(0.0, 0.0, 0.0, 0.31))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _setup_swim_overlay_ui() -> void:
	_swim_overlay_fill = Polygon2D.new()
	_swim_overlay_fill.polygon = PackedVector2Array([
		Vector2(-9.0, -1.0),
		Vector2(9.0, -1.0),
		Vector2(8.0, 9.0),
		Vector2(-8.0, 9.0)
	])
	_swim_overlay_fill.color = Color(0.12, 0.48, 0.88, 0.50)
	_swim_overlay_fill.z_index = 2
	_swim_overlay_fill.visible = false
	add_child(_swim_overlay_fill)

	_swim_overlay_crest = Line2D.new()
	_swim_overlay_crest.points = PackedVector2Array([Vector2(-9.0, -1.0), Vector2(9.0, -1.0)])
	_swim_overlay_crest.width = 1.5
	_swim_overlay_crest.default_color = Color(0.4, 0.75, 1.0, 0.75)
	_swim_overlay_crest.z_index = 3
	_swim_overlay_crest.visible = false
	add_child(_swim_overlay_crest)

func _update_swim_overlay() -> void:
	if _swim_overlay_fill:
		_swim_overlay_fill.visible = _is_swimming
	if _swim_overlay_crest:
		_swim_overlay_crest.visible = _is_swimming

func _setup_horny_particles_ui() -> void:
	_heart_particles = CPUParticles2D.new()
	_heart_particles.position = Vector2(0.0, -14.0)
	_heart_particles.z_index = 6
	_heart_particles.amount = 4
	_heart_particles.lifetime = 1.6
	_heart_particles.one_shot = false
	_heart_particles.emitting = false
	_heart_particles.initial_velocity_min = 2.0
	_heart_particles.initial_velocity_max = 6.0
	_heart_particles.spread = 20.0
	_heart_particles.gravity = Vector2(0.0, -7.0)
	_heart_particles.scale_amount_min = 0.35
	_heart_particles.scale_amount_max = 0.62
	_heart_particles.color = Color(1.0, 0.36, 0.64, 0.95)
	_heart_particles.texture = _create_heart_particle_texture()
	_heart_particles.visible = false
	add_child(_heart_particles)

func _create_heart_particle_texture() -> Texture2D:
	var image := Image.create(10, 10, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var pink := Color(1.0, 0.36, 0.64, 0.95)
	var pixels := [
		Vector2i(2, 1), Vector2i(3, 1), Vector2i(6, 1), Vector2i(7, 1),
		Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3),
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4),
		Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5),
		Vector2i(4, 6), Vector2i(5, 6),
		Vector2i(4, 7), Vector2i(5, 7)
	]
	for p in pixels:
		image.set_pixel(p.x, p.y, pink)
	return ImageTexture.create_from_image(image)

func _update_horny_particles() -> void:
	var now_horny: bool = false
	if _is_horny_state.is_valid():
		now_horny = bool(_is_horny_state.call(villager_name))
	if now_horny == _is_horny_visual:
		return
	_is_horny_visual = now_horny
	if _heart_particles:
		_heart_particles.visible = _is_horny_visual
		_heart_particles.emitting = _is_horny_visual

func _update_thermal_state(delta: float) -> void:
	if not thermal_system_enabled:
		return
	if _is_inside_home:
		# Shelter guarantees stable homeostasis.
		last_ambient_temperature_c = target_body_temperature_c
		last_humidity = 0.45
		is_sweating = false
		is_shivering = false
		body_temperature_c = lerpf(body_temperature_c, target_body_temperature_c, clampf(6.0 * delta, 0.0, 1.0))
		hydration = clampf(hydration + drink_recovery_per_sec * 0.25 * delta, 0.0, MAX_HYDRATION)
		return
	var ambient_temp: float = last_ambient_temperature_c
	var humidity: float = last_humidity
	var sun_intensity: float = 0.0
	var water_influence: float = 0.0
	if _sample_thermal_environment.is_valid():
		var climate_variant: Variant = _sample_thermal_environment.call(position)
		if climate_variant is Dictionary:
			var climate: Dictionary = climate_variant
			ambient_temp = float(climate.get("ambient_temp_c", ambient_temp))
			humidity = clampf(float(climate.get("humidity", humidity)), 0.0, 1.0)
			sun_intensity = clampf(float(climate.get("sun_intensity", 0.0)), 0.0, 1.0)
			water_influence = clampf(float(climate.get("water_influence", 0.0)), 0.0, 1.0)
	var tree_shade: float = 0.0
	if _sample_tree_shade_factor.is_valid():
		var shade_variant: Variant = _sample_tree_shade_factor.call(position)
		if shade_variant is float or shade_variant is int:
			tree_shade = clampf(float(shade_variant), 0.0, 1.0)
	# Add a local short-cycle ambient variation so temperature visibly evolves over time.
	var t: float = float(Time.get_ticks_msec()) * 0.001
	ambient_temp += sin(t * ambient_temp_wave_speed + position.x * 0.003 + position.y * 0.0021) * ambient_temp_wave_c
	last_ambient_temperature_c = ambient_temp
	last_humidity = humidity

	var skin_melanin: float = clampf(float(_physical_genes.get("skin_melanin", 0.5)), 0.0, 1.0)
	var radiation_absorb: float = lerpf(0.82, 1.24, skin_melanin)
	var radiation_emit: float = lerpf(1.18, 0.84, skin_melanin)
	var conduction_coeff: float = heat_transfer_conduction_rate * (1.0 + water_influence * 1.2)
	var convection_coeff: float = heat_transfer_convection_rate * (1.0 + (0.45 if _is_swimming else 0.0))
	var radiation_coeff: float = heat_transfer_radiation_rate * radiation_emit
	var internal_heat: float = metabolic_heat_gain_c_per_sec
	if _has_chop_target and _chop_timer > 0.0:
		internal_heat += chopping_heat_gain_c_per_sec
	elif position.distance_to(_destination) > 5.0:
		var move_factor: float = clampf(position.distance_to(_destination) / 24.0, 0.8, 1.0)
		internal_heat += movement_heat_gain_c_per_sec * move_factor
	var cold_delta: float = (target_body_temperature_c - homeostasis_temp_tolerance_c) - body_temperature_c
	is_shivering = cold_delta > shiver_start_delta_c and energy > 0.5
	var shiver_heat: float = 0.0
	if is_shivering:
		shiver_heat = shiver_heat_gain_c_per_sec * clampf(cold_delta / 1.0, 0.8, 1.0)
		shiver_heat = clampf(shiver_heat, 0.0, shiver_heat_cap_c_per_sec)
		energy = clampf(energy - shiver_energy_cost_per_sec * delta, 0.0, MAX_STAT)
	internal_heat = clampf(internal_heat, 0.0, maxf(0.0, internal_heat_generation_cap_c_per_sec))
	internal_heat += shiver_heat
	if internal_heat > 0.0 and internal_heat_energy_cost_per_c > 0.0:
		var heat_energy_cost: float = internal_heat * internal_heat_energy_cost_per_c * delta
		if energy < heat_energy_cost:
			var scale: float = energy / maxf(0.001, heat_energy_cost)
			internal_heat *= clampf(scale, 0.0, 1.0)
			heat_energy_cost = energy
		energy = clampf(energy - heat_energy_cost, 0.0, MAX_STAT)
	var effective_sun: float = sun_intensity * (1.0 - tree_shade * tree_shade_solar_block)
	var solar_gain: float = effective_sun * radiation_absorb * solar_gain_multiplier
	var transfer_coeff: float = maxf(0.0, conduction_coeff + convection_coeff + radiation_coeff)
	var thermal_mass: float = maxf(0.5, body_thermal_mass)
	var ambient_delta: float = ambient_temp - body_temperature_c
	var ambient_exchange_rate: float = (ambient_delta * transfer_coeff) / thermal_mass
	if ambient_exchange_rate > 0.0:
		ambient_exchange_rate *= hot_ambient_absorption_multiplier
	else:
		ambient_exchange_rate *= cool_ambient_dissipation_multiplier
	if not _is_swimming and ambient_exchange_rate < 0.0:
		ambient_exchange_rate = maxf(ambient_exchange_rate, -maxf(0.0, max_passive_cooling_c_per_sec))
	var positive_gain_rate: float = maxf(0.0, internal_heat + solar_gain)
	body_temperature_c += ambient_exchange_rate * delta
	body_temperature_c += (internal_heat + solar_gain) * delta
	if _is_swimming:
		# In water, ensure net cooling by a margin, without runaway overcooling.
		var net_rate_before_water_pull: float = ambient_exchange_rate + internal_heat + solar_gain
		var target_cooling_rate: float = -maxf(0.0, water_heat_pull_margin_c_per_sec)
		if net_rate_before_water_pull > target_cooling_rate:
			var extra_pull_rate: float = net_rate_before_water_pull - target_cooling_rate
			body_temperature_c -= extra_pull_rate * delta

	var hydration_penalty: float = clampf((400.0 - hydration) / 400.0, 0.0, 1.0)
	var sweat_effectiveness: float = maxf(0.2, 1.0 - humidity) * (1.0 - hydration_penalty * 0.55)
	is_sweating = body_temperature_c > target_body_temperature_c + homeostasis_temp_tolerance_c and hydration > 1.0
	if is_sweating:
		var overheat: float = maxf(0.0, body_temperature_c - (target_body_temperature_c + homeostasis_temp_tolerance_c))
		var sweat_cooling: float = (sweat_cooling_c_per_sec + overheat_sweat_extra_cooling_per_sec * clampf(overheat / 2.0, 0.0, 1.0)) * sweat_effectiveness
		body_temperature_c -= sweat_cooling * delta
		hydration = clampf(hydration - sweat_hydration_cost_per_sec * maxf(0.15, sweat_effectiveness) * delta, 0.0, MAX_HYDRATION)
		# Sweating itself costs energy.
		energy = clampf(energy - sweat_energy_cost_per_sec * delta, 0.0, MAX_STAT)

	hydration = clampf(hydration - hydration_drain_per_sec * delta, 0.0, MAX_HYDRATION)
	if _is_swimming:
		hydration = clampf(hydration + drink_recovery_per_sec * 0.35 * delta, 0.0, MAX_HYDRATION)

	var high_damage_threshold: float = target_body_temperature_c + thermal_damage_tolerance_c
	var low_damage_threshold: float = target_body_temperature_c - thermal_damage_tolerance_c
	if body_temperature_c > high_damage_threshold:
		var over: float = body_temperature_c - high_damage_threshold
		health = clampf(health - over * thermal_damage_per_sec * delta, 0.0, MAX_STAT)
	elif body_temperature_c < low_damage_threshold:
		var under: float = low_damage_threshold - body_temperature_c
		health = clampf(health - under * thermal_damage_per_sec * delta, 0.0, MAX_STAT)
	body_temperature_c = clampf(body_temperature_c, 28.0, 45.0)

func _apply_thermal_homeostasis(delta: float) -> void:
	if not thermal_system_enabled:
		return
	if _is_dead:
		return
	if _is_swimming and hydration < MAX_HYDRATION and body_temperature_c > target_body_temperature_c - 0.2:
		hydration = clampf(hydration + 0.25, 0.0, MAX_HYDRATION)
	var needs_water: bool = hydration < hydration_seek_threshold
	var too_hot: bool = body_temperature_c > target_body_temperature_c + 0.9
	# Drink from a cactus bottle if carrying one and thirsty
	if needs_water and int(inventory.get("cactus_bottle", 0)) > 0:
		hydration = clampf(hydration + drink_recovery_per_sec * 2.0, 0.0, MAX_HYDRATION)
		# Bottle refills near water automatically; just tick it as used water
	if (needs_water or too_hot) and _find_nearest_water_world_position.is_valid() and _water_seek_cooldown <= 0.0:
		var water_target_variant: Variant = _find_nearest_water_world_position.call(position, 22)
		if water_target_variant is Vector2:
			var water_target: Vector2 = water_target_variant
			if is_finite(water_target.x) and is_finite(water_target.y):
				if _llm_preferred_target != "custom" or not is_finite(_destination.x) or not is_finite(_destination.y) or not _is_water_position.call(_destination):
					_destination = water_target
					_llm_preferred_target = "custom"
				if needs_water and position.distance_to(water_target) < drop_pickup_distance * 1.5:
					hydration = clampf(hydration + drink_recovery_per_sec * delta, 0.0, MAX_HYDRATION)
	if body_temperature_c < target_body_temperature_c - 0.9 and _is_swimming:
		_swim_mode = false
		_destination = _random_arena_point(false)
	# Last-resort temperature control: seek home when temp is dangerously far from safe range
	# and the passive mechanisms (sweat/shiver/water) aren't keeping up.
	var thermal_shelter_emergency: bool = _is_thermal_shelter_emergency()
	if thermal_shelter_emergency and not _is_inside_home:
		if _has_drop_target:
			_cancel_drop_target()
		if _has_fish_target:
			_cancel_fishing_target()
		if _has_chop_target:
			_cancel_chop()
		_try_choose_home_target(true)
		if _has_home_target:
			_llm_preferred_target = "home"

func _process(delta: float) -> void:
	if _is_dead:
		return
	if _is_conversation_pause_active.is_valid() and bool(_is_conversation_pause_active.call(villager_name)):
		_set_overhead_hidden_for_conversation(true)
		_update_horny_particles()
		_update_render_depth()
		_update_speech_bubble(delta)
		_inventory_popup_timer = maxf(0.0, _inventory_popup_timer - delta)
		return
	_set_overhead_hidden_for_conversation(false)
	_update_horny_particles()
	_update_render_depth()
	var hunger_drain: float = hunger_drain_per_sec
	if _is_swimming:
		hunger_drain *= swim_hunger_drain_multiplier
	hunger = clampf(hunger - hunger_drain * delta, 0.0, MAX_HUNGER)
	# Activity-scaled energy drain
	var activity_drain: float = energy_drain_per_sec
	if _has_chop_target and _chop_timer > 0.0:
		activity_drain *= 2.2
	elif _is_swimming:
		activity_drain *= swim_energy_drain_multiplier
	energy = clampf(energy - activity_drain * delta, 0.0, MAX_STAT)
	# Water detection
	var prev_swimming := _is_swimming
	if _is_water_position.is_valid():
		_is_swimming = bool(_is_water_position.call(position))
	else:
		_is_swimming = false
	if _is_swimming != prev_swimming:
		_update_swim_overlay()
	_update_thermal_state(delta)
	# Swimming extra energy drain (stamina-scaled)
	if _is_swimming:
		energy = clampf(energy - (1.2 / maxf(0.1, _stamina_gene)) * delta, 0.0, MAX_STAT)
	# Health damage from drowning or severe hunger
	if _is_swimming and energy < swim_drown_energy_threshold:
		health = clampf(health - (drown_rate_per_sec / maxf(0.1, _stamina_gene)) * delta, 0.0, MAX_STAT)
	elif hunger < hunger_health_damage_threshold:
		health = clampf(health - low_hunger_health_drain_per_sec * delta, 0.0, MAX_STAT)
	if health < MAX_STAT and passive_health_regen_per_sec > 0.0 and energy_cost_per_hp_regen > 0.0 and energy > min_energy_for_hp_regen:
		# Regeneration converts available energy into health without dropping below the regen floor.
		var missing_hp: float = MAX_STAT - health
		var max_regen_by_rate: float = passive_health_regen_per_sec * delta
		var max_regen_by_energy: float = (energy - min_energy_for_hp_regen) / energy_cost_per_hp_regen
		var regen_hp: float = minf(minf(missing_hp, max_regen_by_rate), maxf(0.0, max_regen_by_energy))
		if regen_hp > 0.0:
			health = clampf(health + regen_hp, 0.0, MAX_STAT)
			energy = clampf(energy - regen_hp * energy_cost_per_hp_regen, 0.0, MAX_STAT)
	if health <= 0.0:
		_die(_determine_death_reason())
		return
	_eat_cooldown = maxf(0.0, _eat_cooldown - delta)
	_seed_plant_cooldown = maxf(0.0, _seed_plant_cooldown - delta)
	_path_recalc_cooldown = maxf(0.0, _path_recalc_cooldown - delta)
	_ollama_action_lock_timer = maxf(0.0, _ollama_action_lock_timer - delta)
	_water_seek_cooldown = maxf(0.0, _water_seek_cooldown - delta)
	_heuristic_social_chat_cooldown = maxf(0.0, _heuristic_social_chat_cooldown - delta)
	_heuristic_heal_cooldown = maxf(0.0, _heuristic_heal_cooldown - delta)
	_heuristic_fishing_cooldown = maxf(0.0, _heuristic_fishing_cooldown - delta)
	_heuristic_campfire_cooldown = maxf(0.0, _heuristic_campfire_cooldown - delta)
	if _has_drop_target:
		_drop_target_stale_timer -= delta
		if _drop_target_stale_timer <= 0.0:
			_drop_target_stale_timer = 5.0
			if not _request_drop_target.is_valid() or _drop_target_id < 0:
				_cancel_drop_target()
	_llm_last_decision_age += delta
	_tick_llm_decision(delta)
	_update_neural_network_decision(delta)
	_update_inventory_popup(delta)
	_update_speech_bubble(delta)
	_update_inside_home(delta)
	if _is_inside_home:
		_update_label()
		return

	_try_resume_pending_talk()
	_try_resume_pending_heal()
	_try_resume_pending_campfire()
	_try_heuristic_healing(delta)
	_try_heuristic_social_chat(delta)
	_try_heuristic_fishing(delta)
	_try_heuristic_campfire(delta)

	_try_eat_apple()
	_apply_thermal_homeostasis(delta)
	var has_locked_llm_target: bool = (
		_has_drop_target
		or _has_build_site
		or _has_chop_target
		or _has_home_target
		or _has_player_target
		or _has_fish_target
		or _has_campfire_target
		or (_llm_preferred_target == "custom" and is_finite(_destination.x) and is_finite(_destination.y))
	)
	var lock_autonomy: bool = _llm_last_source == "ollama" and _ollama_action_lock_timer > 0.0 and has_locked_llm_target
	# Critical hunger overrides LLM lock — always seek food when starving.
	if hunger < 35.0:
		lock_autonomy = false
	if not lock_autonomy:
		_try_auto_plant_seed_now()
		_try_choose_home_target()
		if not _has_drop_target:
			_try_find_drop_target()
		if _has_build_site:
			_try_prepare_stage_item(delta)
		elif not _has_chop_target:
			_find_tree_cooldown -= delta
			if _find_tree_cooldown <= 0.0:
				_find_tree_cooldown = 2.0
				_try_find_tree()
		if not _has_build_site:
			_try_start_building(delta)

	var target: Vector2 = _choose_target(delta)
	var move_target: Vector2 = _get_move_target(target)
	var offset: Vector2 = move_target - position
	if offset.length() > 2.0:
		if _has_chop_target or _has_fish_target:
			_set_tool_visible(false)
		var next_position: Vector2 = position + offset.normalized() * _effective_move_speed() * delta
		var drifted_next_position: Vector2 = next_position + _get_water_current_push(delta)
		if _can_walk(drifted_next_position, _has_home_target and not _is_inside_home, _home_cell):
			position = drifted_next_position
		elif _can_walk(next_position, _has_home_target and not _is_inside_home, _home_cell):
			position = next_position
		else:
			_path_waypoints.clear()
			_path_recalc_cooldown = 0.0
			if not _try_step_around_obstacle(target, delta):
				_path_goal_world_position = Vector2(INF, INF)
			if not (_has_build_site or _has_drop_target or _has_chop_target or _has_home_target):
				_destination = _random_arena_point(_swim_mode)
				_wander_timer = 0.0
	else:
		if _has_home_target and not _is_inside_home:
			_try_enter_home()
		elif _has_campfire_target:
			if position.distance_to(_campfire_target_world_position) <= campfire_interaction_distance:
				_try_resume_pending_campfire()
			elif position.distance_to(_campfire_target_world_position) > campfire_interaction_distance * 3.2:
				_has_campfire_target = false
				_pending_campfire_action = ""
		elif _has_drop_target:
			var drop_distance: float = position.distance_to(_drop_world_position)
			if drop_distance <= drop_pickup_distance:
				_collect_drop_target()
			else:
				_path_waypoints.clear()
				_path_goal_world_position = Vector2(INF, INF)
				if drop_distance > drop_pickup_distance * 2.5:
					_cancel_drop_target()
		elif _has_fish_target:
			var fish_distance: float = position.distance_to(_fish_world_position)
			if fish_distance <= fish_interaction_distance:
				_set_tool_visible(true)
				_fish_timer += delta
				if _tool_sprite and not _tool_sprite.is_playing():
					_tool_sprite.play("fish")
				if _fish_timer >= fish_duration_seconds:
					_finish_fishing()
			else:
				_set_tool_visible(false)
				_fish_timer = 0.0
				if fish_distance > fish_interaction_distance * 2.5:
					_cancel_fishing_target()
		elif _has_chop_target:
			var chop_distance: float = position.distance_to(_chop_world_position)
			if chop_distance <= chop_interaction_distance:
				_set_tool_visible(true)
				_chop_timer += delta
				if _tool_sprite and not _tool_sprite.is_playing():
					_tool_sprite.play("chop")
				if _chop_timer >= chop_duration_seconds:
					_finish_chop()
			else:
				_set_tool_visible(false)
				_chop_timer = 0.0
		elif _has_build_site and _held_stage_item_index != _build_step_index:
			_try_craft_current_stage_item()
		elif _has_build_site:
			_build_step_timer += delta
			if _build_step_timer >= build_step_interval_seconds:
				_build_step_timer = 0.0
				var build_step_wood_cost: int = _current_stage_wood_cost()
				if int(inventory.get("wood", 0)) < build_step_wood_cost:
					# Do not allow free build/repair placement if wood was spent after reservation.
					_held_stage_item_index = -1
					_has_craft_target = false
					_try_prepare_stage_item(delta)
				else:
					if _place_current_build_step():
						if not _build_requires_crafting:
							inventory["wood"] = maxi(0, int(inventory.get("wood", 0)) - build_step_wood_cost)
							_refresh_inventory_popup_counts()
						_held_stage_item_index = -1
						_build_step_index += 1
						_has_craft_target = false
						if _build_step_index >= _build_total_steps:
							_finish_build_site()
					else:
						_has_craft_target = false
		else:
			_destination = _random_arena_point(_swim_mode)

	_update_hunger_energy_refill(delta)
	# Stuck detection
	_stuck_timer -= delta
	if _stuck_timer <= 0.0:
		_stuck_timer = stuck_check_interval
		var has_target := _has_chop_target or _has_drop_target or _has_build_site or _has_home_target or _has_player_target or (_llm_preferred_target != "" and _llm_preferred_target != "wander")
		if has_target and position.distance_to(_stuck_check_position) < stuck_distance_threshold:
			_is_stuck = true
			_stuck_seconds += stuck_check_interval
			_llm_decision_timer = minf(_llm_decision_timer, 0.2)
		else:
			_is_stuck = false
			_stuck_seconds = 0.0
		_stuck_check_position = position

	_update_render_depth()
	_update_label()

func _set_overhead_hidden_for_conversation(hidden: bool) -> void:
	if _overhead_hidden_for_conversation == hidden:
		return
	_overhead_hidden_for_conversation = hidden
	if _label != null:
		_label.visible = not hidden
	if _inventory_popup != null:
		_inventory_popup.visible = not hidden and _inventory_popup_timer > 0.0

func _choose_target(delta: float) -> Vector2:
	var llm_target: Vector2 = _choose_llm_biased_target(delta)
	if is_finite(llm_target.x) and is_finite(llm_target.y):
		return llm_target

	var carried_food: int = int(inventory.get("apple", 0)) + int(inventory.get("fish", 0)) + int(inventory.get("prickly_pear", 0))
	var urgent_food_need: bool = hunger < 45.0 and carried_food <= 0
	if _has_build_site and not urgent_food_need:
		if _held_stage_item_index != _build_step_index and _has_craft_target:
			return _craft_table_world_position
		return _build_approach_world_position

	if _has_drop_target:
		return _drop_world_position
	if _has_player_target:
		return _player_target_world_position
	if _has_campfire_target:
		return _campfire_target_world_position
	if _has_fish_target:
		return _fish_world_position
	if _has_home_target:
		return _home_world_position
	if _has_chop_target:
		return _chop_world_position
	if _has_build_site:
		if _held_stage_item_index != _build_step_index and _has_craft_target:
			return _craft_table_world_position
		return _build_approach_world_position

	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.5, 4.5)
		_swim_mode = _should_consider_swimming(0.18)
		_destination = _random_arena_point(_swim_mode)
	return _destination

func _choose_llm_biased_target(delta: float) -> Vector2:
	match _llm_preferred_target:
		"drop":
			if _has_drop_target:
				return _drop_world_position
		"player":
			if _has_player_target:
				return _player_target_world_position
		"home":
			if _has_home_target:
				return _home_world_position
		"tree":
			if _has_chop_target:
				return _chop_world_position
		"build":
			if _has_build_site:
				if _held_stage_item_index != _build_step_index and _has_craft_target:
					return _craft_table_world_position
				return _build_approach_world_position
		"campfire":
			if _has_campfire_target:
				return _campfire_target_world_position
		"wander":
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_wander_timer = randf_range(1.5, 3.2)
				_swim_mode = _should_consider_swimming(0.18)
				_destination = _random_arena_point(_swim_mode)
			return _destination
		"custom":
			if not is_finite(_destination.x) or not is_finite(_destination.y):
				_llm_preferred_target = "wander"
				return Vector2(INF, INF)
			if position.distance_to(_destination) <= 14.0:
				# If this was a water destination, apply a cooldown so thermal system
				# doesn't immediately re-send us back and cause jitter.
				if _is_water_position.is_valid() and bool(_is_water_position.call(_destination)):
					_water_seek_cooldown = 5.0
				_llm_preferred_target = "wander"
				return Vector2(INF, INF)
			return _destination
	return Vector2(INF, INF)

func _apply_physical_genes() -> void:
	if _physical_genes.is_empty():
		return
	var metabolism: float = clampf(float(_physical_genes.get("metabolism", 1.0)), 0.55, 1.9)
	var move_mult: float = clampf(float(_physical_genes.get("move_speed_multiplier", metabolism)), 0.6, 2.1)
	move_speed *= move_mult
	# Stamina is inversely proportional to speed: fast NPCs tire faster and drown quicker
	_stamina_gene = clampf(1.0 / maxf(0.1, move_mult), 0.4, 2.0)
	energy_drain_per_sec *= clampf(float(_physical_genes.get("energy_drain_multiplier", metabolism)), 0.6, 2.2)
	# Low stamina (fast NPC) also accelerates energy drain
	energy_drain_per_sec *= clampf(1.0 / maxf(0.1, _stamina_gene), 0.5, 2.5)
	hunger_drain_per_sec *= clampf(float(_physical_genes.get("hunger_drain_multiplier", 0.7 + metabolism * 0.45)), 0.5, 2.2)

func _get_llm_decision_interval_seconds() -> float:
	if _physical_genes.is_empty():
		return 15.0
	return clampf(float(_physical_genes.get("llm_decision_interval_seconds", 15.0)), 15.0, 120.0)

func _tick_llm_decision(delta: float) -> void:
	if not _evaluate_llm_decision.is_valid():
		return
	_llm_decision_timer -= delta
	if _llm_decision_timer > 0.0:
		return
	_llm_decision_timer = _get_llm_decision_interval_seconds()
	_run_llm_decision()

func _run_llm_decision() -> void:
	if not _evaluate_llm_decision.is_valid():
		return
	# Thinking has a resource cost: every LLM call consumes energy.
	energy = clampf(energy - llm_decision_energy_cost, 0.0, MAX_STAT)
	var sensory := {
		"position": position,
		"destination": _destination,
		"inside_home": _is_inside_home,
		"has_home_target": _has_home_target,
		"home_world_position": _home_world_position,
		"has_drop_target": _has_drop_target,
		"drop_world_position": _drop_world_position,
		"has_tree_target": _has_chop_target,
		"tree_world_position": _chop_world_position,
		"has_build_site": _has_build_site,
		"build_world_position": _build_world_position,
		"build_approach_world_position": _build_approach_world_position,
		"craft_table_world_position": _craft_table_world_position,
		"held_stage_item_index": _held_stage_item_index,
		"build_step_index": _build_step_index,
		"build_total_steps": _build_total_steps,
		"is_chopping": _has_chop_target and _chop_timer > 0.0,
		"is_moving": position.distance_to(_destination) > 4.0
	}
	var state := {
		"hunger": hunger,
		"energy": energy,
		"health": health,
		"body_temperature_c": body_temperature_c,
		"ambient_temperature_c": last_ambient_temperature_c,
		"is_swimming": _is_swimming,
		"is_stuck": _is_stuck,
		"stuck_for_seconds": _stuck_seconds if _is_stuck else 0.0,
		"stuck_target": _llm_preferred_target if _is_stuck else "",
		"inventory": inventory.duplicate(true),
		"has_drop_target": _has_drop_target,
		"has_player_target": _has_player_target,
		"player_target_name": _player_target_name,
		"player_target_world_position": _player_target_world_position,
		"has_chop_target": _has_chop_target,
		"has_build_site": _has_build_site,
		"has_campfire_target": _has_campfire_target,
		"has_home_target": _has_home_target,
		"is_inside_home": _is_inside_home,
		"sensory": sensory
	}
	var decision_variant: Variant = _evaluate_llm_decision.call(villager_name, state, _physical_genes, _llm_genes)
	if decision_variant is Dictionary:
		_apply_received_llm_decision(decision_variant)

func apply_ready_llm_decision(decision: Dictionary) -> void:
	_apply_received_llm_decision(decision)
	_llm_decision_timer = maxf(_llm_decision_timer, 0.6)

func _apply_received_llm_decision(decision: Dictionary) -> void:
	if llm_apply_log_to_output:
		print("[LLM-APPLY][%s] source=%s status=%s action=%s target=%s raw=%s" % [
			villager_name,
			str(decision.get("decision_source", "heuristic")),
			str(decision.get("llm_status", "")),
			str(decision.get("action", "")),
			str(decision.get("preferred_target", "")),
			JSON.stringify(decision).substr(0, 220)
		])
	_apply_llm_action(decision)
	_llm_last_action = str(decision.get("action", ""))
	_llm_last_source = str(decision.get("decision_source", "heuristic"))
	_llm_last_status = str(decision.get("llm_status", ""))
	_llm_last_decision_age = 0.0
	if _llm_last_source == "ollama":
		_ollama_action_lock_timer = ollama_action_lock_seconds
	if decision.has("preferred_target"):
		_llm_preferred_target = str(decision.get("preferred_target", ""))
	if decision.has("goal_text"):
		_llm_goal_text = str(decision.get("goal_text", ""))
	var memory_entry: String = str(decision.get("memory_entry", ""))
	var remember: bool = bool(decision.get("remember", false))
	var memory_type: String = str(decision.get("memory_type", "status"))
	if _llm_last_source != "ollama":
		remember = false
	if remember and not memory_entry.is_empty() and _record_long_term_memory.is_valid():
		_record_long_term_memory.call(villager_name, memory_type, memory_entry)

func _apply_llm_action(decision: Dictionary) -> void:
	var action: String = str(decision.get("action", "")).to_lower()
	# Clear swim mode for non-swim actions unless already in water (need to escape)
	if action != "swim" and not _is_swimming:
		_swim_mode = false
	match action:
		"cut_tree":
			_try_find_tree()
			if _has_chop_target:
				_llm_preferred_target = "tree"
		"collect_drop":
			_try_find_drop_target()
			if _has_drop_target:
				_llm_preferred_target = "drop"
		"go_home", "rest":
			_try_choose_home_target()
			if _has_home_target:
				_llm_preferred_target = "home"
		"go_to_player":
			var preferred_player_name: String = str(decision.get("target_player_name", ""))
			_try_find_player_target(preferred_player_name)
			if _has_player_target:
				_llm_preferred_target = "player"
		"talk_to_nearby_player":
			var message: String = str(decision.get("speech_text", "")).strip_edges()
			var talk_target_name: String = str(decision.get("target_player_name", ""))
			if _try_talk_to_nearby_player(message, talk_target_name):
				_llm_preferred_target = "player"
		"heal_nearby_player":
			var heal_target_name: String = str(decision.get("target_player_name", ""))
			if _try_find_injured_player_target(heal_target_name):
				_pending_heal_target_name = _player_target_name if not _player_target_name.is_empty() else heal_target_name
				_try_heal_nearby_player(_pending_heal_target_name)
				if _has_player_target or not _pending_heal_target_name.is_empty():
					_llm_preferred_target = "player"
		"fish":
			_try_find_fishing_spot()
			if _has_fish_target:
				_llm_preferred_target = "water"
		"trade_with_nearby_player":
			var trade_target_name: String = str(decision.get("target_player_name", ""))
			var give_item: String = str(decision.get("give_item", "")).to_lower().strip_edges()
			var give_amount: int = max(0, int(decision.get("give_amount", 0)))
			var request_item: String = str(decision.get("request_item", "")).to_lower().strip_edges()
			var request_amount: int = max(0, int(decision.get("request_amount", 0)))
			var trade_message: String = str(decision.get("speech_text", "")).strip_edges()
			if _try_trade_with_nearby_player(trade_target_name, give_item, give_amount, request_item, request_amount, trade_message):
				_llm_preferred_target = "player"
		"claim_tile":
			var claim_world_pos_variant: Variant = decision.get("world_position", null)
			var claim_world_pos: Vector2 = position
			if claim_world_pos_variant is Vector2:
				claim_world_pos = claim_world_pos_variant
			_try_claim_tile(claim_world_pos, str(decision.get("memory_entry", "")))
			_llm_preferred_target = "custom"
		"build":
			_try_start_building(10.0)
			if _has_build_site:
				_llm_preferred_target = "build"
		"build_campfire":
			_queue_campfire_action("build")
			if _has_campfire_target or not _pending_campfire_action.is_empty():
				_llm_preferred_target = "campfire"
		"light_campfire":
			_queue_campfire_action("light")
			if _has_campfire_target or not _pending_campfire_action.is_empty():
				_llm_preferred_target = "campfire"
		"extinguish_campfire":
			_queue_campfire_action("extinguish")
			if _has_campfire_target or not _pending_campfire_action.is_empty():
				_llm_preferred_target = "campfire"
		"destroy_campfire":
			_queue_campfire_action("destroy")
			if _has_campfire_target or not _pending_campfire_action.is_empty():
				_llm_preferred_target = "campfire"
		"move_random", "wander":
			_swim_mode = _should_consider_swimming(0.18)
			_destination = _random_arena_point(_swim_mode)
			_path_waypoints.clear()
			_path_goal_world_position = Vector2(INF, INF)
			_llm_preferred_target = "wander"
		"move_to":
			var world_pos_variant: Variant = decision.get("world_position", null)
			if world_pos_variant is Vector2:
				var world_pos: Vector2 = world_pos_variant
				if _can_walk(world_pos):
					_has_player_target = false
					_destination = world_pos
					_path_waypoints.clear()
					_path_goal_world_position = Vector2(INF, INF)
					_llm_preferred_target = "custom"
		"swim":
			# Enable swimming mode so water tiles become walkable
			if _should_consider_swimming(0.55):
				_swim_mode = true
				_destination = _random_arena_point(true)
				_path_waypoints.clear()
				_path_goal_world_position = Vector2(INF, INF)
				_llm_preferred_target = "wander"
			else:
				_swim_mode = false
				_llm_preferred_target = "wander"

func _try_find_player_target(preferred_name: String = "") -> void:
	if not _find_player_target.is_valid():
		return
	var allow_swimming: bool = _should_consider_swimming(0.08)
	var target_variant: Variant = _find_player_target.call(villager_name, position, preferred_name, allow_swimming)
	if not (target_variant is Dictionary):
		return
	var target: Dictionary = target_variant
	var target_position_variant: Variant = target.get("world_position", null)
	if not (target_position_variant is Vector2):
		return
	_player_target_world_position = target_position_variant
	_player_target_name = str(target.get("name", preferred_name))
	_has_player_target = true
	_swim_mode = allow_swimming

func _try_talk_to_nearby_player(message: String, preferred_name: String = "") -> bool:
	if not _speak_to_nearby_player.is_valid():
		return false
	var final_message: String = message.strip_edges()
	if final_message.is_empty():
		var fallback_lines: Array[String] = [
			"How is your day going?",
			"Want to chat for a bit?",
			"What are you up to?",
			"Need help with anything?"
		]
		final_message = fallback_lines[randi() % fallback_lines.size()]
	var result_variant: Variant = _speak_to_nearby_player.call(villager_name, position, final_message, preferred_name)
	if result_variant is bool:
		return bool(result_variant)
	if result_variant is Dictionary:
		var result: Dictionary = result_variant
		var target_position_variant: Variant = result.get("world_position", null)
		if target_position_variant is Vector2:
			_player_target_world_position = target_position_variant
			_has_player_target = true
			_player_target_name = str(result.get("target_name", preferred_name))
		if bool(result.get("spoken", false)):
			_pending_talk_message = ""
			_pending_talk_target_name = ""
			return true
		# Not in range yet: still treat this as success so the NPC walks toward the target.
		if _has_player_target:
			_pending_talk_message = final_message
			_pending_talk_target_name = _player_target_name if not _player_target_name.is_empty() else preferred_name
			return true
	return false

func _try_resume_pending_talk() -> void:
	if _pending_talk_message.is_empty():
		return
	if _is_conversation_pause_active.is_valid() and bool(_is_conversation_pause_active.call(villager_name)):
		return
	if not _has_player_target:
		if not _pending_talk_target_name.is_empty():
			_try_find_player_target(_pending_talk_target_name)
		return
	if position.distance_to(_player_target_world_position) > player_talk_radius:
		return
	_try_talk_to_nearby_player(_pending_talk_message, _pending_talk_target_name)

func _try_find_injured_player_target(preferred_name: String = "") -> bool:
	if not _find_injured_player_target.is_valid():
		return false
	var allow_swimming: bool = _should_consider_swimming(0.04)
	var target_variant: Variant = _find_injured_player_target.call(villager_name, position, preferred_name, allow_swimming, heal_target_health_threshold)
	if not (target_variant is Dictionary):
		return false
	var target: Dictionary = target_variant
	var target_position_variant: Variant = target.get("world_position", null)
	if not (target_position_variant is Vector2):
		return false
	_player_target_world_position = target_position_variant
	_player_target_name = str(target.get("name", preferred_name))
	_has_player_target = true
	_swim_mode = allow_swimming
	return true

func _try_heal_nearby_player(preferred_name: String = "") -> bool:
	if not _heal_nearby_player.is_valid():
		return false
	var result_variant: Variant = _heal_nearby_player.call(villager_name, position, preferred_name, heal_amount, heal_interaction_distance, heal_energy_cost)
	if not (result_variant is Dictionary):
		return false
	var result: Dictionary = result_variant
	var target_position_variant: Variant = result.get("world_position", null)
	if target_position_variant is Vector2:
		_player_target_world_position = target_position_variant
		_has_player_target = true
		_player_target_name = str(result.get("target_name", preferred_name))
	if bool(result.get("healed", false)):
		_pending_heal_target_name = ""
		_has_player_target = false
		_player_target_name = ""
		_heuristic_heal_cooldown = _next_heuristic_heal_cooldown()
		return true
	var reason: String = str(result.get("reason", ""))
	if reason in ["no_target", "missing_npc", "not_injured", "low_energy"]:
		_pending_heal_target_name = ""
		if reason != "low_energy":
			_has_player_target = false
			_player_target_name = ""
		_heuristic_heal_cooldown = minf(6.0, maxf(1.0, _next_heuristic_heal_cooldown() * 0.35))
	return false

func _try_resume_pending_heal() -> void:
	if _pending_heal_target_name.is_empty():
		return
	if _is_conversation_pause_active.is_valid() and bool(_is_conversation_pause_active.call(villager_name)):
		return
	if not _has_player_target:
		_try_find_injured_player_target(_pending_heal_target_name)
		return
	if position.distance_to(_player_target_world_position) > heal_interaction_distance:
		return
	_try_heal_nearby_player(_pending_heal_target_name)

func _next_heuristic_social_chat_cooldown() -> float:
	var min_seconds: float = maxf(0.0, heuristic_social_chat_cooldown_min_seconds)
	var max_seconds: float = maxf(min_seconds, heuristic_social_chat_cooldown_max_seconds)
	if max_seconds <= min_seconds:
		return min_seconds
	return randf_range(min_seconds, max_seconds)

func _next_heuristic_fishing_cooldown() -> float:
	var min_seconds: float = maxf(0.0, heuristic_fishing_cooldown_min_seconds)
	var max_seconds: float = maxf(min_seconds, heuristic_fishing_cooldown_max_seconds)
	if max_seconds <= min_seconds:
		return min_seconds
	return randf_range(min_seconds, max_seconds)

func _next_heuristic_heal_cooldown() -> float:
	var min_seconds: float = maxf(0.0, heuristic_heal_cooldown_min_seconds)
	var max_seconds: float = maxf(min_seconds, heuristic_heal_cooldown_max_seconds)
	if max_seconds <= min_seconds:
		return min_seconds
	return randf_range(min_seconds, max_seconds)

func _next_heuristic_campfire_cooldown() -> float:
	var min_seconds: float = maxf(0.0, heuristic_campfire_cooldown_min_seconds)
	var max_seconds: float = maxf(min_seconds, heuristic_campfire_cooldown_max_seconds)
	if max_seconds <= min_seconds:
		return min_seconds
	return randf_range(min_seconds, max_seconds)

func _try_heuristic_campfire(delta: float) -> void:
	if heuristic_campfire_chance_per_second <= 0.0:
		return
	if _heuristic_campfire_cooldown > 0.0:
		return
	if not _pending_campfire_action.is_empty() or _has_campfire_target:
		return
	if _is_inside_home or _is_swimming:
		return
	if _has_build_site or _has_drop_target or _has_fish_target:
		return
	if _has_chop_target and _chop_timer > 0.0:
		return
	if not _manage_campfire.is_valid():
		return

	var chance_this_frame: float = clampf(heuristic_campfire_chance_per_second * maxf(0.0, delta), 0.0, 1.0)
	if randf() >= chance_this_frame:
		return

	var cold_bias: bool = body_temperature_c < (target_body_temperature_c - homeostasis_temp_tolerance_c * 0.6)
	var night_bias: bool = (last_ambient_temperature_c + 1.0) < target_body_temperature_c
	if cold_bias or night_bias:
		var probe_light: Variant = _manage_campfire.call(villager_name, position, "light", campfire_interaction_distance, int(inventory.get("wood", 0)))
		if probe_light is Dictionary:
			var probe_light_data: Dictionary = probe_light
			if bool(probe_light_data.get("performed", false)) or probe_light_data.has("target_world_position"):
				_queue_campfire_action("light")
				return
		if int(inventory.get("wood", 0)) >= 1:
			_queue_campfire_action("build")
			return

	if body_temperature_c > target_body_temperature_c + homeostasis_temp_tolerance_c and randf() < 0.35:
		_queue_campfire_action("extinguish")
		return

	if int(inventory.get("wood", 0)) <= 0 and randf() < 0.2:
		_queue_campfire_action("destroy")

func _try_heuristic_healing(delta: float) -> void:
	if heuristic_heal_chance_per_second <= 0.0:
		return
	if _heuristic_heal_cooldown > 0.0:
		return
	if not _pending_heal_target_name.is_empty():
		return
	if not _pending_talk_message.is_empty():
		return
	if _has_fish_target or _has_drop_target or _has_build_site or _has_home_target:
		return
	if _has_chop_target and _chop_timer > 0.0:
		return
	if _is_inside_home or _is_swimming or _is_thermal_shelter_emergency():
		return
	if hunger < 60.0 or energy < heal_energy_cost + 12.0 or health < 40.0:
		return
	var compassion: float = clampf(float(_llm_genes.get("compassion", 0.5)), 0.0, 1.0)
	var selfish: float = clampf(float(_llm_genes.get("selfish", 0.5)), 0.0, 1.0)
	var drive: float = clampf(0.18 + compassion * 0.95 - selfish * 0.55, 0.08, 1.15)
	var chance_this_frame: float = clampf(heuristic_heal_chance_per_second * drive * maxf(0.0, delta), 0.0, 1.0)
	if randf() >= chance_this_frame:
		return
	if not _try_find_injured_player_target(""):
		_heuristic_heal_cooldown = minf(5.0, maxf(1.2, _next_heuristic_heal_cooldown() * 0.3))
		return
	_pending_heal_target_name = _player_target_name
	if position.distance_to(_player_target_world_position) <= heal_interaction_distance:
		if _try_heal_nearby_player(_pending_heal_target_name):
			return
	_heuristic_heal_cooldown = _next_heuristic_heal_cooldown()

func _try_heuristic_social_chat(delta: float) -> void:
	if heuristic_social_chat_chance_per_second <= 0.0:
		return
	if _heuristic_social_chat_cooldown > 0.0:
		return
	if not _pending_heal_target_name.is_empty():
		return
	if _pending_talk_message.length() > 0:
		return
	if _is_inside_home or _is_swimming:
		return
	if _has_fish_target or (_has_chop_target and _chop_timer > 0.0):
		return
	if hunger < 55.0 or energy < 24.0 or health < 28.0:
		return
	var talkative: float = clampf(float(_llm_genes.get("talkative", 0.5)), 0.0, 1.0)
	var compassion: float = clampf(float(_llm_genes.get("compassion", 0.5)), 0.0, 1.0)
	var selfish: float = clampf(float(_llm_genes.get("selfish", 0.5)), 0.0, 1.0)
	var bravery: float = _get_bravery()
	var drive: float = clampf(0.30 + talkative * 0.90 + compassion * 0.35 + bravery * 0.15 - selfish * 0.45, 0.12, 1.65)
	var chance_this_frame: float = clampf(heuristic_social_chat_chance_per_second * drive * maxf(0.0, delta), 0.0, 1.0)
	if randf() >= chance_this_frame:
		return
	_try_find_player_target("")
	if not _has_player_target:
		_heuristic_social_chat_cooldown = minf(4.0, maxf(1.0, _next_heuristic_social_chat_cooldown() * 0.25))
		return
	if position.distance_to(_player_target_world_position) > player_talk_radius * 1.05:
		_heuristic_social_chat_cooldown = minf(5.0, maxf(1.2, _next_heuristic_social_chat_cooldown() * 0.35))
		return
	var opener_pool: Array[String] = [
		"How are things going over there?",
		"Want to chat for a minute?",
		"Need a hand with anything?",
		"What have you been working on?",
		"Anything interesting happening nearby?"
	]
	var opener: String = opener_pool[randi() % opener_pool.size()]
	if _try_talk_to_nearby_player(opener, _player_target_name):
		_heuristic_social_chat_cooldown = _next_heuristic_social_chat_cooldown()
	else:
		_heuristic_social_chat_cooldown = minf(6.0, maxf(1.0, _next_heuristic_social_chat_cooldown() * 0.3))

func _try_heuristic_fishing(delta: float) -> void:
	if heuristic_fishing_chance_per_second <= 0.0:
		return
	if _heuristic_fishing_cooldown > 0.0:
		return
	if _has_fish_target or _has_drop_target or _has_player_target or _has_build_site or _has_home_target:
		return
	if _is_inside_home or _is_swimming:
		return
	if _has_chop_target and _chop_timer > 0.0:
		return
	if hunger > heuristic_fishing_hunger_threshold:
		return
	if energy < 18.0 or health < 25.0:
		return
	var apple_count: int = int(inventory.get("apple", 0))
	var fish_count: int = int(inventory.get("fish", 0))
	if apple_count > 0 or fish_count > 1:
		return
	var chance_this_frame: float = clampf(heuristic_fishing_chance_per_second * maxf(0.0, delta), 0.0, 1.0)
	if randf() >= chance_this_frame:
		return
	_try_find_fishing_spot()
	if _has_fish_target:
		_heuristic_fishing_cooldown = _next_heuristic_fishing_cooldown()
	else:
		_heuristic_fishing_cooldown = minf(5.0, maxf(1.2, _next_heuristic_fishing_cooldown() * 0.3))

func _find_reachable_fishing_position(water_world_position: Vector2) -> Vector2:
	var candidate_directions: Array[Vector2] = [
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.DOWN,
		Vector2(-1.0, -1.0).normalized(),
		Vector2(1.0, -1.0).normalized(),
		Vector2(-1.0, 1.0).normalized(),
		Vector2(1.0, 1.0).normalized()
	]
	var preferred_offset: float = minf(maxf(8.0, fish_interaction_distance - 6.0), 20.0)
	var sample_offsets: Array[float] = [
		preferred_offset,
		maxf(8.0, preferred_offset - 6.0),
		minf(maxf(8.0, preferred_offset + 4.0), maxf(8.0, fish_interaction_distance - 1.0))
	]
	for sample_offset in sample_offsets:
		for direction in candidate_directions:
			var candidate: Vector2 = water_world_position + direction * sample_offset
			if _can_walk(candidate):
				return candidate
	return Vector2(INF, INF)

func _try_find_fishing_spot() -> void:
	if _has_fish_target or _is_inside_home:
		return
	if not _find_nearest_water_world_position.is_valid():
		return
	var water_variant: Variant = _find_nearest_water_world_position.call(position, 24)
	if not (water_variant is Vector2):
		return
	var water_world_position: Vector2 = water_variant
	if not is_finite(water_world_position.x) or not is_finite(water_world_position.y):
		return
	var fishing_world_position: Vector2 = _find_reachable_fishing_position(water_world_position)
	if not is_finite(fishing_world_position.x) or not is_finite(fishing_world_position.y):
		return
	_fish_world_position = fishing_world_position
	_has_fish_target = true
	_fish_timer = 0.0
	_swim_mode = false

func _finish_fishing() -> void:
	if position.distance_to(_fish_world_position) > fish_interaction_distance + 4.0:
		_cancel_fishing_target()
		return
	var caught_count: int = fish_food_yield_min
	if fish_food_yield_max > fish_food_yield_min:
		caught_count = randi_range(fish_food_yield_min, fish_food_yield_max)
	_add_inventory("fish", caught_count, true)
	_cancel_fishing_target()

func _cancel_fishing_target() -> void:
	_has_fish_target = false
	_fish_timer = 0.0
	_fish_world_position = Vector2.ZERO

func _try_trade_with_nearby_player(preferred_name: String, give_item: String, give_amount: int, request_item: String, request_amount: int, message: String = "") -> bool:
	if not _trade_with_nearby_player.is_valid():
		return false
	var trade_result_variant: Variant = _trade_with_nearby_player.call(villager_name, position, preferred_name, give_item, give_amount, request_item, request_amount, message)
	if not (trade_result_variant is Dictionary):
		return false
	var trade_result: Dictionary = trade_result_variant
	if bool(trade_result.get("traded", false)):
		var target_position_variant: Variant = trade_result.get("world_position", null)
		if target_position_variant is Vector2:
			_player_target_world_position = target_position_variant
			_has_player_target = true
			_player_target_name = str(trade_result.get("target_name", preferred_name))
		return true
	return false

func _try_claim_tile(world_position: Vector2, note: String = "") -> void:
	if not _claim_tile.is_valid():
		return
	_claim_tile.call(villager_name, world_position, note.substr(0, 120))

func _get_move_target(goal_target: Vector2) -> Vector2:
	if goal_target.distance_to(position) <= 12.0:
		_path_waypoints.clear()
		_path_goal_world_position = Vector2(INF, INF)
		return goal_target
	_refresh_path_to(goal_target)
	while not _path_waypoints.is_empty() and position.distance_to(_path_waypoints[0]) <= 8.0:
		_path_waypoints.remove_at(0)
	if not _path_waypoints.is_empty():
		return _path_waypoints[0]
	if _can_walk(goal_target, _has_home_target and not _is_inside_home, _home_cell):
		return goal_target
	return position

func _refresh_path_to(goal_target: Vector2) -> void:
	if not _find_world_path.is_valid():
		return
	if _path_recalc_cooldown > 0.0 and _path_goal_world_position.distance_to(goal_target) <= 8.0 and not _path_waypoints.is_empty():
		return
	var path_variant: Variant = _find_world_path.call(position, goal_target, _has_home_target and not _is_inside_home, _home_cell, _swim_mode or _is_swimming)
	if path_variant is Array:
		var new_path: Array[Vector2] = []
		for point in path_variant:
			if point is Vector2:
				new_path.append(point)
		_path_waypoints = new_path
		_path_goal_world_position = goal_target
		_path_recalc_cooldown = 0.5

func _try_step_around_obstacle(blocked_target: Vector2, delta: float) -> bool:
	var forward: Vector2 = blocked_target - position
	if forward.length() <= 0.001:
		return false
	forward = forward.normalized()
	var step_distance: float = move_speed * delta
	var preferred_sign: float = _avoidance_turn_sign if _avoidance_turn_sign != 0.0 else 1.0
	var angles: Array[float] = [
		preferred_sign * PI * 0.25,
		preferred_sign * PI * 0.5,
		preferred_sign * PI * 0.75,
		-preferred_sign * PI * 0.25,
		-preferred_sign * PI * 0.5,
		-preferred_sign * PI * 0.75,
		PI
	]
	for angle in angles:
		var direction: Vector2 = forward.rotated(angle)
		var candidate: Vector2 = position + direction * step_distance
		if not _can_walk(candidate, _has_home_target and not _is_inside_home, _home_cell):
			continue
		position = candidate
		_avoidance_turn_sign = 1.0 if angle >= 0.0 else -1.0
		return true
	_avoidance_turn_sign *= -1.0
	return false

func _random_arena_point(allow_swimming: bool = false) -> Vector2:
	# Wander within a radius around the current position — works for infinite worlds.
	var wander_radius: float = 380.0
	for _attempt in 48:
		var angle := randf() * TAU
		var dist := randf_range(30.0, wander_radius)
		var candidate := position + Vector2(cos(angle), sin(angle)) * dist
		if _can_walk_mode(candidate, _has_home_target and not _is_inside_home, _home_cell, allow_swimming) and _path_cost_to(candidate, allow_swimming) < INF:
			return candidate
	return position

func _try_find_tree() -> void:
	if _has_chop_target or _has_drop_target:
		return
	if _has_build_site:
		var wood_target: int = _current_stage_wood_cost()
		if _held_stage_item_index != _build_step_index:
			wood_target = maxi(wood_target, _craft_table_wood_needed)
		if int(inventory.get("wood", 0)) >= wood_target:
			return
	elif inventory.get("wood", 0) >= wood_needed_per_build:
		return
	if not _get_tree_cells.is_valid() or not _get_tree_world_position.is_valid() or not _reserve_tree.is_valid():
		return

	var cells: Variant = _get_tree_cells.call()
	if not (cells is Array) or (cells as Array).is_empty():
		return

	var candidates: Array[Dictionary] = []
	for c in (cells as Array):
		if not (c is Vector2i):
			continue
		var wp: Variant = _get_tree_world_position.call(c)
		if not (wp is Vector2):
			continue
		candidates.append({"cell": c, "world_position": wp, "direct_distance": position.distance_to(wp as Vector2)})

	if candidates.is_empty():
		return
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("direct_distance", INF)) < float(b.get("direct_distance", INF)))
	var best_cell: Vector2i = Vector2i(-9999, -9999)
	var best_position: Vector2 = Vector2.ZERO
	var best_score: float = INF
	var best_requires_swim: bool = false
	for i in mini(8, candidates.size()):
		var candidate: Dictionary = candidates[i]
		var world_position: Vector2 = candidate.get("world_position", position)
		var land_cost: float = _path_cost_to(world_position, false)
		var swim_cost: float = _path_cost_to(world_position, true)
		var score: float = land_cost
		var requires_swim: bool = false
		if swim_cost < INF:
			var swim_score: float = swim_cost * _swim_penalty_multiplier(0.02)
			if swim_score < score:
				score = swim_score
				requires_swim = true
		if score < best_score:
			best_score = score
			best_cell = candidate.get("cell", Vector2i(-9999, -9999))
			best_position = world_position
			best_requires_swim = requires_swim

	if best_cell == Vector2i(-9999, -9999):
		return

	var reserved: Variant = _reserve_tree.call(villager_name, best_cell)
	if not (reserved is bool) or not reserved:
		return

	_swim_mode = best_requires_swim
	_chop_cell = best_cell
	_chop_world_position = best_position
	_has_chop_target = true
	_chop_timer = 0.0

func _try_find_drop_target() -> void:
	if _has_drop_target or _is_inside_home:
		return
	if _has_build_site and hunger >= 45.0:
		return
	if not _request_drop_target.is_valid():
		return

	var preferred: String = ""
	var apples_on_hand: int = int(inventory.get("apple", 0))
	# Hunger-first behavior: keep seeking apples proactively when hunger is low.
	if hunger < 45.0:
		preferred = "apple"
	elif apples_on_hand <= 0:
		preferred = "apple"
	elif int(inventory.get("seed", 0)) <= 0:
		preferred = "seed"
	else:
		return

	var hunger_ratio: float = 1.0 - clampf(hunger / MAX_HUNGER, 0.0, 1.0)
	var swim_bias: float = hunger_ratio * 0.35
	if hunger < 45.0:
		swim_bias += 0.25
	var allow_swimming: bool = _should_consider_swimming(swim_bias)
	var drop_data_variant: Variant = _request_drop_target.call(villager_name, position, preferred, allow_swimming)
	if not (drop_data_variant is Dictionary):
		return
	var drop_data: Dictionary = drop_data_variant
	if not drop_data.has("id") or not drop_data.has("world_position"):
		return
	var maybe_id: Variant = drop_data["id"]
	var maybe_pos: Variant = drop_data["world_position"]
	if not (maybe_id is int) or not (maybe_pos is Vector2):
		return
	_drop_target_id = maybe_id
	_drop_world_position = maybe_pos
	_has_drop_target = true
	_swim_mode = allow_swimming
	_drop_target_stale_timer = 5.0

func _current_stage_wood_cost() -> int:
	if not _has_build_site:
		return wood_needed_per_build
	if _build_step_index >= 0 and _build_step_index < _build_stage_wood_costs.size():
		return max(1, int(_build_stage_wood_costs[_build_step_index]))
	if _get_stage_wood_cost.is_valid():
		var cost_variant: Variant = _get_stage_wood_cost.call(_build_step_index)
		if cost_variant is int:
			return max(1, int(cost_variant))
	return max(1, wood_needed_per_build)

func _try_prepare_stage_item(delta: float) -> void:
	if not _has_build_site:
		return
	if _held_stage_item_index == _build_step_index:
		return
	if int(inventory.get("wood", 0)) < _current_stage_wood_cost():
		if not _has_chop_target:
			_find_tree_cooldown -= delta
			if _find_tree_cooldown <= 0.0:
				_find_tree_cooldown = 1.5
				_try_find_tree()
		return
	if not _build_requires_crafting:
		_held_stage_item_index = _build_step_index
		_has_craft_target = false
		return
	if not _has_craft_target and _request_crafting_table_access.is_valid():
		var table_data_variant: Variant = _request_crafting_table_access.call(villager_name, position, int(inventory.get("wood", 0)))
		if table_data_variant is Dictionary:
			var table_data: Dictionary = table_data_variant
			if table_data.get("needs_wood", false):
				_craft_table_wood_needed = max(_craft_table_wood_needed, int(table_data.get("wood_cost", 0)))
				if not _has_chop_target:
					_find_tree_cooldown -= delta
					if _find_tree_cooldown <= 0.0:
						_find_tree_cooldown = 1.2
						_try_find_tree()
				return
			if table_data.get("built_table", false):
				_craft_table_wood_needed = 0
				var table_cost: int = int(table_data.get("wood_cost", 0))
				if table_cost > 0:
					inventory["wood"] = maxi(0, int(inventory.get("wood", 0)) - table_cost)
					_refresh_inventory_popup_counts()
			var maybe_pos: Variant = table_data.get("world_position", null)
			if maybe_pos is Vector2 and (table_data.get("has_table", false) or table_data.get("built_table", false)):
				_craft_table_wood_needed = 0
				_craft_table_world_position = maybe_pos
				_has_craft_target = true

func _try_craft_current_stage_item() -> void:
	if not _has_build_site:
		return
	if _held_stage_item_index == _build_step_index:
		return
	if not _craft_stage_item.is_valid():
		return
	if not _has_craft_target:
		_try_prepare_stage_item(0.0)
		return

	var crafted_variant: Variant = _craft_stage_item.call(villager_name, _build_step_index, position, int(inventory.get("wood", 0)))
	if not (crafted_variant is Dictionary):
		return
	var crafted_data: Dictionary = crafted_variant
	if crafted_data.get("crafted", false):
		var wood_cost: int = int(crafted_data.get("wood_cost", _current_stage_wood_cost()))
		inventory["wood"] = maxi(0, int(inventory.get("wood", 0)) - wood_cost)
		_refresh_inventory_popup_counts()
		_held_stage_item_index = _build_step_index
		_craft_table_wood_needed = 0
		_has_craft_target = false
		_show_inventory_popup()
		return
	if crafted_data.get("needs_wood", false):
		_has_craft_target = false
		return
	if crafted_data.get("needs_table", false):
		_has_craft_target = false
		return

func _collect_drop_target() -> void:
	if not _has_drop_target:
		return
	if position.distance_to(_drop_world_position) > drop_pickup_distance + 1.5:
		return
	if not _pickup_reserved_drop.is_valid():
		_cancel_drop_target()
		return
	var collected_variant: Variant = _pickup_reserved_drop.call(villager_name, _drop_target_id)
	if collected_variant is Dictionary:
		var collected: Dictionary = collected_variant
		for key in collected.keys():
			_add_inventory(key, int(collected[key]), true)
	_cancel_drop_target()

func _cancel_drop_target() -> void:
	if _has_drop_target and _release_drop_target.is_valid():
		_release_drop_target.call(villager_name, _drop_target_id)
	_has_drop_target = false
	_drop_target_id = -1

func _queue_campfire_action(action: String) -> void:
	var clean_action: String = action.strip_edges().to_lower()
	if clean_action.is_empty():
		return
	_pending_campfire_action = clean_action
	_has_campfire_target = false
	_try_resume_pending_campfire()

func _try_resume_pending_campfire() -> void:
	if _pending_campfire_action.is_empty():
		return
	if not _manage_campfire.is_valid():
		_pending_campfire_action = ""
		_has_campfire_target = false
		return
	var result_variant: Variant = _manage_campfire.call(villager_name, position, _pending_campfire_action, campfire_interaction_distance, int(inventory.get("wood", 0)))
	if not (result_variant is Dictionary):
		return
	var result: Dictionary = result_variant
	if bool(result.get("performed", false)):
		var wood_cost: int = int(result.get("wood_cost", 0))
		if wood_cost > 0:
			inventory["wood"] = maxi(0, int(inventory.get("wood", 0)) - wood_cost)
			_refresh_inventory_popup_counts()
		var wood_refund: int = int(result.get("wood_refund", 0))
		if wood_refund > 0:
			_add_inventory("wood", wood_refund, true)
		_pending_campfire_action = ""
		_has_campfire_target = false
		_heuristic_campfire_cooldown = _next_heuristic_campfire_cooldown()
		return

	var target_world_position_variant: Variant = result.get("target_world_position", null)
	if target_world_position_variant is Vector2:
		_campfire_target_world_position = target_world_position_variant
		_has_campfire_target = true
	else:
		_has_campfire_target = false

	var reason: String = str(result.get("reason", ""))
	if reason in ["needs_wood", "no_target", "unknown_action", "missing_layer", "blocked", "missing_target", "already_lit", "already_unlit"]:
		_pending_campfire_action = ""
		_has_campfire_target = false
		if reason == "needs_wood":
			_try_find_tree()
		_heuristic_campfire_cooldown = minf(8.0, maxf(1.0, _next_heuristic_campfire_cooldown() * 0.35))

func _is_thermal_shelter_emergency() -> bool:
	if not thermal_system_enabled:
		return false
	var high_damage_threshold: float = target_body_temperature_c + thermal_damage_tolerance_c
	var low_damage_threshold: float = target_body_temperature_c - thermal_damage_tolerance_c
	if body_temperature_c >= high_damage_threshold or body_temperature_c <= low_damage_threshold:
		return true
	var too_cold_danger: bool = body_temperature_c < target_body_temperature_c - thermal_damage_tolerance_c * 0.7
	var too_hot_danger: bool = body_temperature_c > target_body_temperature_c + thermal_damage_tolerance_c * 0.7
	return too_cold_danger or too_hot_danger


func _try_choose_home_target(force_home: bool = false) -> void:
	if _is_inside_home or _has_home_target:
		return
	if not force_home and (_has_build_site or _has_chop_target or _has_drop_target):
		return
	if not force_home and energy > home_enter_energy_threshold:
		return
	if not _get_nearest_home.is_valid():
		return

	var home_data_variant: Variant = _get_nearest_home.call(villager_name, position, force_home)
	if not (home_data_variant is Dictionary):
		return
	var home_data: Dictionary = home_data_variant
	var maybe_cell: Variant = home_data.get("cell", null)
	var maybe_pos: Variant = home_data.get("world_position", null)
	var maybe_dist: Variant = home_data.get("distance", INF)
	if not (maybe_cell is Vector2i) or not (maybe_pos is Vector2):
		return
	if not force_home and float(maybe_dist) > home_search_radius:
		return

	_home_cell = maybe_cell
	_home_world_position = maybe_pos
	_has_home_target = true

func _try_enter_home() -> void:
	if _is_inside_home or not _has_home_target:
		return
	if not _enter_home.is_valid():
		_has_home_target = false
		return
	var entered: Variant = _enter_home.call(villager_name, _home_cell)
	if entered is bool and entered:
		_is_inside_home = true
		_has_home_target = false
		_inside_home_timer = home_stay_seconds
		_set_tool_visible(false)
	else:
		_has_home_target = false

func _update_inside_home(delta: float) -> void:
	if not _is_inside_home:
		return
	_inside_home_timer = maxf(0.0, _inside_home_timer - delta)
	energy = minf(MAX_STAT, energy + 18.0 * delta)
	hunger = minf(MAX_HUNGER, hunger + 4.0 * delta)
	health = minf(MAX_STAT, health + 5.0 * delta)
	if _inside_home_timer <= 0.0 or energy >= 95.0:
		_leave_home_now()

func _leave_home_now() -> void:
	if not _is_inside_home:
		return
	if _leave_home.is_valid():
		_leave_home.call(villager_name)
	_is_inside_home = false
	_inside_home_timer = 0.0
	_destination = _random_arena_point(false)

func _update_render_depth() -> void:
	if not _get_tree_render_z_for_position.is_valid():
		return
	var z_variant: Variant = _get_tree_render_z_for_position.call(position, _is_inside_home, z_index)
	if z_variant is int:
		z_index = int(z_variant)

func _try_eat_apple() -> void:
	if _eat_cooldown > 0.0:
		return
	if hunger >= MAX_HUNGER - 0.001:
		return
	var apple_count: int = int(inventory.get("apple", 0))
	var fish_count: int = int(inventory.get("fish", 0))
	var pear_count: int = int(inventory.get("prickly_pear", 0))
	if apple_count <= 0 and fish_count <= 0 and pear_count <= 0:
		return
	if apple_count > 0:
		inventory["apple"] = maxi(0, apple_count - 1)
	elif fish_count > 0:
		inventory["fish"] = maxi(0, fish_count - 1)
	else:
		inventory["prickly_pear"] = maxi(0, pear_count - 1)
		# Prickly pear also provides a little hydration
		hydration = clampf(hydration + 80.0, 0.0, MAX_HYDRATION)
	_refresh_inventory_popup_counts()
	if seeds_per_apple_eaten > 0:
		_add_inventory("seed", seeds_per_apple_eaten, false)
	hunger = minf(MAX_HUNGER, hunger + apple_hunger_restore)
	_eat_cooldown = eat_cooldown_seconds

func _try_auto_plant_seed_now() -> void:
	if _seed_plant_cooldown > 0.0:
		return
	if int(inventory.get("seed", 0)) <= 0:
		return
	if not _try_auto_plant_seed.is_valid():
		return
	var planted_variant: Variant = _try_auto_plant_seed.call(villager_name, int(inventory.get("seed", 0)))
	if planted_variant is int and int(planted_variant) > 0:
		inventory["seed"] = maxi(0, int(inventory.get("seed", 0)) - int(planted_variant))
		_refresh_inventory_popup_counts()
	_seed_plant_cooldown = seed_plant_try_interval

func _finish_chop() -> void:
	if position.distance_to(_chop_world_position) > chop_interaction_distance + 1.5:
		_cancel_chop()
		return
	if _chop_tree.is_valid():
		var gained: Variant = _chop_tree.call(villager_name, _chop_cell)
		if gained is int:
			_add_inventory("wood", int(gained), true)
	_set_tool_visible(false)
	_has_chop_target = false
	_chop_timer = 0.0

func _cancel_chop() -> void:
	if _release_tree.is_valid():
		_release_tree.call(villager_name, _chop_cell)
	_set_tool_visible(false)
	_has_chop_target = false
	_chop_timer = 0.0

func _set_tool_visible(vis: bool) -> void:
	if _tool_sprite:
		_tool_sprite.visible = vis
		if not vis and _tool_sprite.is_playing():
			_tool_sprite.stop()

func _try_start_building(delta: float) -> void:
	if _has_build_site or _has_chop_target:
		return
	if not building_enabled:
		return
	if not _request_build_site.is_valid():
		return
	if randf() >= build_start_chance_per_second * delta:
		return

	var site_data_variant: Variant = _request_build_site.call(villager_name, inventory.get("wood", 0))
	if not (site_data_variant is Dictionary):
		return

	var site_data: Dictionary = site_data_variant
	if site_data.get("needs_wood", false):
		return
	if not site_data.has("cell"):
		return
	if not site_data.has("world_position"):
		return
	if not site_data.has("approach_world_position"):
		return
	if not site_data.has("total_steps"):
		return

	var maybe_cell: Variant = site_data["cell"]
	var maybe_world_position: Variant = site_data["world_position"]
	var maybe_approach_world_position: Variant = site_data["approach_world_position"]
	var maybe_total_steps: Variant = site_data["total_steps"]
	if not (maybe_cell is Vector2i):
		return
	if not (maybe_world_position is Vector2):
		return
	if not (maybe_approach_world_position is Vector2):
		return
	if not (maybe_total_steps is int):
		return

	_build_cell = maybe_cell
	_build_world_position = maybe_world_position
	_build_approach_world_position = maybe_approach_world_position
	_build_total_steps = max(0, maybe_total_steps)
	_build_structure_type = str(site_data.get("structure_type", "house"))
	_build_requires_crafting = bool(site_data.get("requires_crafting", true))
	_build_stage_wood_costs.clear()
	var stage_costs_variant: Variant = site_data.get("stage_wood_costs", [])
	if stage_costs_variant is Array:
		for value in stage_costs_variant:
			_build_stage_wood_costs.append(int(value))
	_build_step_index = 0
	_build_step_timer = 0.0
	_has_build_site = _build_total_steps > 0
	_held_stage_item_index = -1
	_has_craft_target = false
	_craft_table_wood_needed = 0
	var carried_food: int = int(inventory.get("apple", 0)) + int(inventory.get("fish", 0)) + int(inventory.get("prickly_pear", 0))
	if _has_build_site and _has_drop_target and (hunger >= 45.0 or carried_food > 0):
		_cancel_drop_target()

func _add_inventory(item_key: String, amount: int, show_popup: bool) -> void:
	if amount == 0:
		return
	inventory[item_key] = int(inventory.get(item_key, 0)) + amount
	inventory[item_key] = maxi(0, int(inventory[item_key]))
	_refresh_inventory_popup_counts()
	if show_popup and amount > 0:
		_show_inventory_popup()

func _setup_inventory_popup_ui() -> void:
	_inventory_popup = Node2D.new()
	_inventory_popup.position = Vector2(24.0, -24.0)
	_inventory_popup.visible = false
	add_child(_inventory_popup)

	_inventory_popup_bg = Sprite2D.new()
	_inventory_popup_bg.centered = false
	_inventory_popup_bg.position = Vector2(-6.0, -8.0)
	_inventory_popup.add_child(_inventory_popup_bg)

	var icons := {
		"wood": _create_wood_icon_texture(),
		"apple": _create_food_icon_texture(Vector2i(0, 0)),
		"seed": _create_food_icon_texture(Vector2i(3, 0)),
		"stage": _create_stage_item_icon_texture()
	}
	var keys: Array[String] = ["wood", "apple", "seed", "stage"]
	for i in keys.size():
		var key: String = keys[i]
		var row := Node2D.new()
		row.position = Vector2(0.0, float(i) * 14.0)
		_inventory_popup.add_child(row)

		var icon := Sprite2D.new()
		icon.texture = icons.get(key, _create_wood_icon_texture())
		icon.scale = Vector2(0.75, 0.75)
		icon.centered = true
		icon.position = Vector2(0.0, 0.0)
		row.add_child(icon)

		var count := Label.new()
		count.position = Vector2(8.0, -8.0)
		count.size = Vector2(52.0, 14.0)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		count.add_theme_font_size_override("font_size", 10)
		row.add_child(count)

		_inventory_popup_rows[key] = {"row": row, "count": count}

	_refresh_inventory_popup_counts()

func _setup_speech_bubble_ui() -> void:
	_speech_bubble = Node2D.new()
	_speech_bubble.position = _speech_bubble_anchor_base
	_speech_bubble.scale = Vector2(0.55, 0.55)
	_speech_bubble.visible = false
	_speech_bubble.z_index = 1000  # Ensure bubbles render on top
	add_child(_speech_bubble)

	_speech_bubble_bg = Sprite2D.new()
	_speech_bubble_bg.centered = false
	_speech_bubble_bg.position = Vector2(-6.0, -8.0)
	_speech_bubble_bg.texture = _create_inventory_bg_texture(144, 42)
	_speech_bubble.add_child(_speech_bubble_bg)

	_speech_bubble_label = RichTextLabel.new()
	_speech_bubble_label.position = Vector2(0.0, -3.0)
	_speech_bubble_label.size = Vector2(132.0, 36.0)
	_speech_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_bubble_label.scroll_active = false
	_speech_bubble_label.bbcode_enabled = false
	_speech_bubble_label.add_theme_font_size_override("normal_font_size", 9)
	_speech_bubble.add_child(_speech_bubble_label)
	_render_speech_bubble_text("")

func set_speech_bubble_avoid_offset_x(offset_x: float) -> void:
	_speech_bubble_avoid_offset_x = clampf(offset_x, -96.0, 96.0)
	_apply_speech_bubble_position()

func set_speech_bubble_avoid_offset_y(offset_y: float) -> void:
	_speech_bubble_avoid_offset_y = clampf(offset_y, -48.0, 48.0)
	_apply_speech_bubble_position()

func get_speech_bubble_anchor_global() -> Vector2:
	return global_position + _speech_bubble_anchor_base

func _apply_speech_bubble_position() -> void:
	if _speech_bubble == null:
		return
	var final_offset_x: float = _speech_bubble_avoid_offset_x
	# Suppress center pull when in conversation (offset > 20px)
	if absf(_speech_bubble_avoid_offset_x) < 20.0:
		final_offset_x += _speech_bubble_center_pull_offset_x
	final_offset_x = clampf(final_offset_x, -speech_bubble_total_max_offset, speech_bubble_total_max_offset)
	var final_position: Vector2 = _speech_bubble_anchor_base + Vector2(final_offset_x, _speech_bubble_avoid_offset_y)
	_speech_bubble.position = final_position

func _update_speech_bubble_center_pull() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		_speech_bubble_center_pull_offset_x = 0.0
		return
	var visible_rect: Rect2 = viewport.get_visible_rect()
	var screen_center_x: float = visible_rect.position.x + visible_rect.size.x * 0.5
	var canvas_transform: Transform2D = viewport.get_canvas_transform()
	var speaker_screen_x: float = (canvas_transform * global_position).x
	var to_center_x: float = screen_center_x - speaker_screen_x
	_speech_bubble_center_pull_offset_x = clampf(
		to_center_x * speech_bubble_center_pull_strength,
		-speech_bubble_center_pull_max_offset,
		speech_bubble_center_pull_max_offset
	)

func show_thinking_bubble(hold_until_next: bool = false) -> void:
	if _speech_bubble == null:
		return
	_speech_bubble_is_thinking = true
	_speech_bubble_hold_until_next = hold_until_next
	_speech_bubble_thinking_elapsed = 0.0
	_speech_bubble_full_body_text = "."
	_speech_bubble_visible_chars = _speech_bubble_full_body_text.length()
	_speech_bubble_typewriter_progress = 0.0
	_speech_bubble.visible = true
	_speech_bubble.modulate = Color(1, 1, 1, 1)
	_speech_bubble_timer = -1.0 if hold_until_next else maxf(0.6, speech_bubble_seconds)
	_render_speech_bubble_text(".")

func show_chat_bubble(message: String) -> void:
	if _speech_bubble == null:
		return
	var final_message: String = message.strip_edges().substr(0, 96)
	if final_message.is_empty():
		return
	_speech_bubble_is_thinking = false
	_speech_bubble_hold_until_next = true
	_speech_bubble_full_body_text = final_message
	_speech_bubble_visible_chars = 0
	_speech_bubble_typewriter_progress = 0.0
	_render_speech_bubble_text("")
	_speech_bubble.visible = true
	_speech_bubble.modulate = Color(1, 1, 1, 1)
	_speech_bubble_timer = -1.0

func fade_chat_bubble() -> void:
	if _speech_bubble == null or not _speech_bubble.visible:
		return
	_speech_bubble_hold_until_next = false
	_speech_bubble_is_thinking = false
	_speech_bubble_timer = maxf(0.2, speech_bubble_fade_seconds)

func _render_speech_bubble_text(body_text: String) -> void:
	if _speech_bubble_label == null:
		return
	_speech_bubble_label.clear()
	_speech_bubble_label.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	_speech_bubble_label.push_color(speech_bubble_name_color)
	_speech_bubble_label.add_text(villager_name)
	_speech_bubble_label.pop()
	_speech_bubble_label.add_text(": ")
	_speech_bubble_label.add_text(body_text)
	_speech_bubble_label.pop()

func _update_speech_bubble_typewriter(delta: float) -> void:
	if _speech_bubble_is_thinking:
		return
	if _speech_bubble_visible_chars >= _speech_bubble_full_body_text.length():
		return
	_speech_bubble_typewriter_progress += delta * maxf(1.0, speech_bubble_typewriter_chars_per_sec)
	var reveal_chars: int = int(floor(_speech_bubble_typewriter_progress))
	if reveal_chars <= 0:
		return
	_speech_bubble_typewriter_progress -= float(reveal_chars)
	_speech_bubble_visible_chars = mini(_speech_bubble_full_body_text.length(), _speech_bubble_visible_chars + reveal_chars)
	_render_speech_bubble_text(_speech_bubble_full_body_text.substr(0, _speech_bubble_visible_chars))

func _update_speech_bubble(delta: float) -> void:
	if _speech_bubble == null or not _speech_bubble.visible:
		return
	if _speech_bubble_is_thinking:
		_speech_bubble_thinking_elapsed += delta
		var dots: int = int(floor(_speech_bubble_thinking_elapsed * 4.0)) % 4
		if dots <= 0:
			dots = 1
		_render_speech_bubble_text(".".repeat(dots))
	else:
		_update_speech_bubble_typewriter(delta)
	if not _speech_bubble_hold_until_next:
		_speech_bubble_timer = maxf(0.0, _speech_bubble_timer - delta)
		if _speech_bubble_timer <= 0.0:
			_speech_bubble_is_thinking = false
			_speech_bubble_full_body_text = ""
			_speech_bubble_visible_chars = 0
			_speech_bubble_typewriter_progress = 0.0
			_speech_bubble.visible = false
			return
	var alpha: float = 1.0
	if not _speech_bubble_hold_until_next and _speech_bubble_timer < speech_bubble_fade_seconds:
		alpha = clampf(_speech_bubble_timer / maxf(0.001, speech_bubble_fade_seconds), 0.0, 1.0)
	_speech_bubble.modulate = Color(1, 1, 1, alpha)
	_update_speech_bubble_center_pull()
	_apply_speech_bubble_position()

func _create_inventory_bg_texture(width: int, height: int) -> Texture2D:
	var w: int = maxi(8, width)
	var h: int = maxi(8, height)
	var r: int = 4
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var inside := true
			if x < r and y < r:
				inside = Vector2(float(x - r), float(y - r)).length() <= float(r)
			elif x > w - r - 1 and y < r:
				inside = Vector2(float(x - (w - r - 1)), float(y - r)).length() <= float(r)
			elif x < r and y > h - r - 1:
				inside = Vector2(float(x - r), float(y - (h - r - 1))).length() <= float(r)
			elif x > w - r - 1 and y > h - r - 1:
				inside = Vector2(float(x - (w - r - 1)), float(y - (h - r - 1))).length() <= float(r)
			if inside:
				image.set_pixel(x, y, Color(0.05, 0.05, 0.05, 0.62))
	return ImageTexture.create_from_image(image)

func _create_wood_icon_texture() -> Texture2D:
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(3, 9):
		for x in range(1, 11):
			image.set_pixel(x, y, Color(0.56, 0.35, 0.17, 1.0))
	for y in range(4, 8):
		for x in range(1, 3):
			image.set_pixel(x, y, Color(0.70, 0.52, 0.30, 1.0))
	return ImageTexture.create_from_image(image)

func _create_food_icon_texture(atlas_coords: Vector2i) -> Texture2D:
	var tex: Texture2D = load("res://foods.png") as Texture2D
	if tex == null:
		tex = _load_food_texture_from_pixil()
	if tex == null:
		return _create_wood_icon_texture()
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(float(atlas_coords.x * 16), float(atlas_coords.y * 16), 16.0, 16.0)
	return at

func _create_stage_item_icon_texture() -> Texture2D:
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(1, 11):
		for x in range(1, 11):
			image.set_pixel(x, y, Color(0.23, 0.62, 0.85, 0.95))
	for y in range(2, 10):
		for x in range(2, 10):
			image.set_pixel(x, y, Color(0.73, 0.90, 0.98, 0.95))
	return ImageTexture.create_from_image(image)

func _load_food_texture_from_pixil() -> Texture2D:
	if not FileAccess.file_exists("res://Foods.pixil"):
		return null
	var file := FileAccess.open("res://Foods.pixil", FileAccess.READ)
	if file == null:
		return null
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return null
	var root: Dictionary = parsed
	if not root.has("frames"):
		return null
	var frames: Variant = root["frames"]
	if not (frames is Array) or (frames as Array).is_empty():
		return null
	var frame0: Variant = (frames as Array)[0]
	if not (frame0 is Dictionary):
		return null
	var frame0_dict: Dictionary = frame0
	if not frame0_dict.has("layers"):
		return null
	var layers: Variant = frame0_dict["layers"]
	if not (layers is Array) or (layers as Array).is_empty():
		return null
	var layer0: Variant = (layers as Array)[0]
	if not (layer0 is Dictionary):
		return null
	var layer0_dict: Dictionary = layer0
	if not layer0_dict.has("src"):
		return null
	var src: String = str(layer0_dict["src"])
	var marker := "base64,"
	var marker_index: int = src.find(marker)
	if marker_index == -1:
		return null
	var bytes: PackedByteArray = Marshalls.base64_to_raw(src.substr(marker_index + marker.length()))
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _refresh_inventory_popup_counts() -> void:
	if _inventory_popup_rows.is_empty():
		return
	var visible_count: int = 0
	for key in _inventory_popup_rows.keys():
		var row: Dictionary = _inventory_popup_rows[key]
		var row_node: Node2D = row.get("row")
		var count: Label = row.get("count")
		var amount: int = 0
		if key == "stage":
			amount = 1 if _held_stage_item_index >= 0 else 0
		else:
			amount = int(inventory.get(key, 0))
		if row_node:
			row_node.visible = amount > 0
			if amount > 0:
				row_node.position = Vector2(0.0, float(visible_count) * 14.0)
				visible_count += 1
		if count:
			count.text = "x%d" % amount

	if _inventory_popup_bg:
		if visible_count <= 0:
			_inventory_popup_bg.visible = false
		else:
			_inventory_popup_bg.visible = true
			_inventory_popup_bg.texture = _create_inventory_bg_texture(66, visible_count * 14 + 8)

func _show_inventory_popup() -> void:
	if _inventory_popup == null:
		return
	_refresh_inventory_popup_counts()
	if _inventory_popup_bg != null and not _inventory_popup_bg.visible:
		return
	_inventory_popup_timer = inventory_popup_seconds
	_inventory_popup.visible = true
	_inventory_popup.modulate = Color(1, 1, 1, 1)

func _update_inventory_popup(delta: float) -> void:
	if _inventory_popup == null or not _inventory_popup.visible:
		return
	_inventory_popup_timer -= delta
	if _inventory_popup_timer <= 0.0:
		_inventory_popup.visible = false
		return
	var alpha: float = 1.0
	if _inventory_popup_timer <= inventory_popup_fade_seconds:
		alpha = clampf(_inventory_popup_timer / maxf(0.001, inventory_popup_fade_seconds), 0.0, 1.0)
	_inventory_popup.modulate = Color(1, 1, 1, alpha)

func _place_current_build_step() -> bool:
	if not _place_build_part.is_valid():
		return false
	if _build_step_index < 0 or _build_step_index >= _build_total_steps:
		return false

	var placed_variant: Variant = _place_build_part.call(villager_name, _build_cell, _build_step_index)
	if placed_variant is bool:
		return placed_variant
	return false

func _finish_build_site() -> void:
	var built_world_position: Vector2 = _build_world_position
	if _claim_tile.is_valid() and (is_finite(built_world_position.x) and is_finite(built_world_position.y)):
		_try_claim_tile(built_world_position, "claimed after building")
	_has_build_site = false
	_build_structure_type = "house"
	_build_requires_crafting = true
	_build_stage_wood_costs.clear()
	_build_step_index = 0
	_build_total_steps = 0
	_build_step_timer = 0.0
	_held_stage_item_index = -1
	_has_craft_target = false
	_build_approach_world_position = Vector2.ZERO
	_craft_table_wood_needed = 0

func _cancel_build_site() -> void:
	if _has_build_site and _release_build_site.is_valid():
		_release_build_site.call(villager_name, _build_cell)
	_finish_build_site()

func _closest_walkable_target(target: Vector2) -> Vector2:
	if _can_walk(target):
		return target

	for radius in [24.0, 48.0, 72.0, 96.0, 120.0, 144.0, 168.0, 192.0]:
		for i in 8:
			var angle: float = TAU * float(i) / 8.0
			var candidate: Vector2 = target + Vector2.RIGHT.rotated(angle) * radius
			if _can_walk(candidate):
				return candidate

	return _random_arena_point(false)

func _get_swim_fear() -> float:
	return clampf(float(_llm_genes.get("swim_fear", 0.5)), 0.0, 1.0)

func _get_bravery() -> float:
	return clampf(float(_llm_genes.get("bravery", 0.5)), 0.0, 1.0)

func _exploration_bias() -> float:
	var primary_goal: String = str(_llm_genes.get("primary_goal", ""))
	if primary_goal == "explore":
		return 0.18
	var goals_variant: Variant = _llm_genes.get("goals", [])
	if goals_variant is Array and (goals_variant as Array).has("explore"):
		return 0.12
	return 0.0

func _swim_penalty_multiplier(bias: float = 0.0) -> float:
	var bravery_bonus: float = (_get_bravery() - 0.5) * 0.18
	var effective_fear: float = clampf(_get_swim_fear() - bias - _exploration_bias() * 0.35 - bravery_bonus, 0.0, 1.0)
	var fear_curve: float = effective_fear * effective_fear
	var penalty: float = lerpf(1.1, 9.5, fear_curve)
	if effective_fear >= 0.82:
		penalty *= 1.35
	if _is_stuck:
		penalty *= 0.6
	if _is_swimming:
		penalty *= 0.78
	if energy < 35.0 or health < 40.0:
		penalty *= 1.7
	return penalty

func _should_consider_swimming(bias: float = 0.0) -> bool:
	if _is_swimming:
		return true
	var swim_fear: float = _get_swim_fear()
	var bravery_bonus: float = (_get_bravery() - 0.5) * 0.18
	var willingness: float = bias + _exploration_bias() * 0.35 + bravery_bonus - swim_fear * swim_fear * 1.15
	if _is_stuck:
		willingness += 0.55
	if energy < 35.0 or health < 40.0:
		willingness -= 0.45
	if swim_fear >= 0.75 and not _is_stuck and bias < 0.45:
		return false
	return willingness > 0.0

func _path_cost_to(goal_target: Vector2, allow_swimming: bool = false) -> float:
	if not _find_world_path.is_valid():
		return position.distance_to(goal_target) if _can_walk_mode(goal_target, _has_home_target and not _is_inside_home, _home_cell, allow_swimming) else INF
	var path_variant: Variant = _find_world_path.call(position, goal_target, _has_home_target and not _is_inside_home, _home_cell, allow_swimming)
	if not (path_variant is Array):
		return INF
	var total: float = 0.0
	var current: Vector2 = position
	var found_point: bool = false
	for point in (path_variant as Array):
		if not (point is Vector2):
			continue
		found_point = true
		total += current.distance_to(point)
		current = point
	if found_point:
		return total
	return 0.0 if position.distance_to(goal_target) <= 12.0 else INF

func _can_walk_mode(world_position: Vector2, allow_home_entry: bool = false, target_home_cell: Vector2i = Vector2i(-9999, -9999), allow_swimming: bool = false) -> bool:
	if _is_walkable.is_valid():
		return bool(_is_walkable.call(world_position, villager_name, allow_home_entry, target_home_cell, position, allow_swimming))
	return true

func _can_walk(world_position: Vector2, allow_home_entry: bool = false, target_home_cell: Vector2i = Vector2i(-9999, -9999)) -> bool:
	return _can_walk_mode(world_position, allow_home_entry, target_home_cell, _swim_mode or _is_swimming)

func _exit_tree() -> void:
	_leave_home_now()

func _update_label() -> void:
	if _label == null:
		return
	var role_color: String = "#9ad8ff" if _is_swimming else "#f4f2d0"
	if _is_horny_visual:
		role_color = "#ff95c9"
	var target_label: String = _llm_preferred_target.substr(0, mini(12, _llm_preferred_target.length())) if not _llm_preferred_target.is_empty() else "idle"
	var action_label: String = _llm_last_action.substr(0, mini(16, _llm_last_action.length())) if not _llm_last_action.is_empty() else target_label
	var target_color := "#d8d8d8"
	match _llm_preferred_target:
		"tree":
			target_color = "#8fd19e"
		"drop":
			target_color = "#f5d66e"
		"home":
			target_color = "#a9c3ff"
		"player":
			target_color = "#f7b38a"
		"build":
			target_color = "#c9a7ff"
		"wander", "custom":
			target_color = "#b8d8de"
	var lines: Array[String] = [
		"[center][color=%s]%s[/color][/center]" % [role_color, villager_name],
		"[center][color=#f3cc5e]H:%d[/color] [color=#7de5a1]E:%d[/color] [color=#ff8f8f]HP:%d[/color] [color=%s]A:%s[/color][/center]" % [int(hunger), int(energy), int(health), target_color, action_label]
	]
	_label.text = "\n".join(lines)

func _effective_move_speed() -> float:
	var speed: float = move_speed
	if energy < 15.0:
		speed *= 0.35
	if _is_swimming:
		speed *= swim_speed_multiplier
	return maxf(8.0, speed)

func _update_hunger_energy_refill(delta: float) -> void:
	_hunger_energy_tick_timer -= delta
	if _hunger_energy_tick_timer > 0.0:
		return
	var tick_seconds: float = maxf(0.1, hunger_to_energy_tick_seconds)
	while _hunger_energy_tick_timer <= 0.0:
		_hunger_energy_tick_timer += tick_seconds
		_apply_hunger_energy_tick()

func _apply_hunger_energy_tick() -> void:
	var hunger_cost: float = maxf(0.001, hunger_to_energy_hunger_cost_per_tick)
	var energy_gain: float = hunger_cost * maxf(0.001, energy_per_hunger_point)
	if hunger < hunger_cost:
		return
	# Apply only full ticks so the ratio remains exact: -1 hunger +10 energy.
	if energy > MAX_STAT - energy_gain:
		return
	hunger = maxf(0.0, hunger - hunger_cost)
	energy = minf(MAX_STAT, energy + energy_gain)

func _convert_hunger_to_energy(requested_energy_gain: float) -> void:
	if requested_energy_gain <= 0.0 or hunger <= 0.0 or energy >= MAX_STAT:
		return
	var energy_gain: float = minf(requested_energy_gain, MAX_STAT - energy)
	var hunger_needed: float = energy_gain / maxf(0.001, energy_per_hunger_point)
	var hunger_used: float = minf(hunger, hunger_needed)
	hunger = maxf(0.0, hunger - hunger_used)
	energy = minf(MAX_STAT, energy + hunger_used * energy_per_hunger_point)

func _get_water_current_push(delta: float) -> Vector2:
	if not _is_swimming or not _sample_water_current_velocity.is_valid():
		return Vector2.ZERO
	var sampled: Variant = _sample_water_current_velocity.call(position)
	if sampled is Vector2:
		# Low stamina gets pushed around more by the current.
		var drift_scale: float = clampf(1.0 / maxf(0.1, _stamina_gene), 0.7, 2.0)
		return (sampled as Vector2) * drift_scale * delta
	return Vector2.ZERO

func _determine_death_reason() -> String:
	if _is_swimming and energy < swim_drown_energy_threshold:
		return "drowning"
	var high_damage_threshold: float = target_body_temperature_c + thermal_damage_tolerance_c
	var low_damage_threshold: float = target_body_temperature_c - thermal_damage_tolerance_c
	if body_temperature_c > high_damage_threshold:
		return "extreme heat"
	if body_temperature_c < low_damage_threshold:
		return "extreme cold"
	if hunger < hunger_health_damage_threshold:
		return "starvation"
	return "health collapse"

## Initialize neural network from genes
func _initialize_neural_network(genes: Dictionary) -> void:
	if genes.is_empty():
		# Create a default network if no genes provided
		var default_hidden_layers: Array[int] = [16, 8]
		_neural_network = NeuralNetwork.new(SensoryInput.SENSE_INDEX.TOTAL_SENSES, default_hidden_layers, SensoryInput.ACTION_INDEX.TOTAL_ACTIONS)
		return
	
	# Try to load network from genes
	_neural_network = NeuralNetwork.from_genes(genes)
	if _neural_network == null:
		# Fallback to default if loading fails
		var fallback_hidden_layers: Array[int] = [16, 8]
		_neural_network = NeuralNetwork.new(SensoryInput.SENSE_INDEX.TOTAL_SENSES, fallback_hidden_layers, SensoryInput.ACTION_INDEX.TOTAL_ACTIONS)

## Update neural network based on sensory inputs (runs periodically to avoid every-frame overhead)
func _update_neural_network_decision(delta: float) -> void:
	if not _neural_network_enabled or _neural_network == null:
		return
	
	# Update every 0.1 seconds instead of every frame for performance
	_neural_network_update_timer -= delta
	if _neural_network_update_timer > 0.0:
		return
	
	_neural_network_update_timer = 0.1
	
	# Gather sensory inputs
	var world_state = _gather_world_state()
	var sensory_inputs = SensoryInput.gather_sensory_inputs(self, world_state)
	
	# Forward pass through network
	var network_outputs = _neural_network.forward(sensory_inputs)
	
	# Interpret outputs as action priorities
	_last_neural_network_outputs = SensoryInput.interpret_action_outputs(network_outputs)

## Gather world state information for sensory inputs
func _gather_world_state() -> Dictionary:
	# This is a simplified version - in a full implementation, you'd call world functions
	# to get nearby NPCs and players
	var world_state = {
		"time_of_day": Time.get_ticks_msec() / 1000.0,
		"nearby_players_count": 0,
		"nearby_npcs_count": 0
	}
	return world_state

## Get neural network action priorities
func get_neural_network_actions() -> Dictionary:
	return _last_neural_network_outputs.duplicate()

## Get neural network for gene inspection
func get_neural_network() -> NeuralNetwork:
	return _neural_network

func _die(reason: String = "unknown") -> void:
	if _is_dead:
		return
	_is_dead = true
	_set_tool_visible(false)
	if _inventory_popup:
		_inventory_popup.visible = false
	if _speech_bubble:
		_speech_bubble.visible = false
	if _notify_death.is_valid():
		_notify_death.call(villager_name, reason)
	queue_free()
