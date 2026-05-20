extends Node2D

const VillagerAgent = preload("res://scripts/VillagerAgent.gd")
const VILLAGER_TEXTURES: Array[Texture2D] = [
	preload("res://sprites/villager.png"),
	preload("res://sprites/villager2.png"),
	preload("res://sprites/villager3.png")
]

@onready var chat_bridge: ChatBridge = $ChatBridge
@onready var terrain: TileMapLayer = $Terrain
@onready var world_camera: Camera2D = $Camera2D

@export var auto_generate_terrain: bool = false
@export var blocked_terrain_tiles: Array[Vector2i] = [
	Vector2i(2, 3)
]
@export var enable_villager_building: bool = true
@export var foundation_layer_path: NodePath = NodePath("TileMapLayer2")
@export var floor_layer_path: NodePath = NodePath("TileMapLayer5")
@export var walls_layer_path: NodePath = NodePath("TileMapLayer3")
@export var roof_layer_path: NodePath = NodePath("TileMapLayer4")
@export var foundation_atlas: Vector2i = Vector2i(0, 0)
@export var floor_atlas: Vector2i = Vector2i(1, 0)
@export var walls_atlas: Vector2i = Vector2i(1, 1)
@export var roof_atlas: Vector2i = Vector2i(0, 1)
@export var tent_layer_path: NodePath = NodePath("TileMapLayer4")
@export var tent_behind_layer_path: NodePath = NodePath("TileMapLayer6")
@export var tent_atlas: Vector2i = Vector2i(0, 3)
@export var tent_collapsed_atlas: Vector2i = Vector2i(1, 3)
@export var campfire_layer_path: NodePath = NodePath("TileMapLayer5")
@export var campfire_unlit_atlas: Vector2i = Vector2i(2, 3)
@export var campfire_lit_atlas: Vector2i = Vector2i(3, 2)
@export var campfire_fire_texture_path: String = "res://fire.png"
@export_range(1, 8, 1) var campfire_fire_frame_rows: int = 3
@export var campfire_fire_frame_size: Vector2i = Vector2i(30, 30)
@export var campfire_fire_frame_margin: Vector2i = Vector2i(1, 1)
@export var campfire_fire_frame_separation: Vector2i = Vector2i(2, 2)
@export_range(1.0, 40.0, 0.5) var campfire_fire_fps: float = 9.0
@export_range(0.3, 4.0, 0.05) var campfire_fire_scale: float = 1.0
@export_range(-180.0, 180.0, 1.0) var campfire_fire_rotation_degrees: float = 0.0
@export_range(-48.0, 48.0, 0.5) var campfire_fire_y_offset: float = -4.0
@export var foundation_source_id: int = 2
@export var floor_source_id: int = 2
@export var walls_source_id: int = 0
@export var roof_source_id: int = 0
@export var tent_source_id: int = 0
@export var tent_collapsed_source_id: int = 0
@export var campfire_source_id: int = 3
@export var build_stage_wood_costs: Array[int] = [2, 2, 3, 4]
@export_range(1, 20, 1) var tent_build_wood_cost: int = 3
@export_range(0.0, 1.0, 0.01) var tent_build_choice_chance: float = 0.45
@export_range(10.0, 400.0, 1.0) var tent_max_health: float = 100.0
@export_range(0.0, 10.0, 0.01) var tent_decay_per_second: float = 0.5
@export_range(30.0, 1200.0, 1.0) var tent_collapsed_repair_window_seconds: float = 300.0
@export_range(1, 20, 1) var tent_repair_wood_cost: int = 2
@export_range(1.0, 200.0, 1.0) var tent_repair_health_gain: float = 45.0
@export_range(0, 20, 1) var tent_final_decay_wood_drop: int = 2

# Weather system
@export_range(30.0, 600.0, 10.0) var weather_transition_interval_seconds: float = 120.0
@export_range(0.0, 1.0, 0.1) var rainy_weather_probability: float = 0.35
@export_range(0.0, 1.0, 0.1) var thunderstorm_probability: float = 0.2
@export_range(1.0, 5.0, 0.1) var rainy_decay_multiplier: float = 1.5
@export_range(2.0, 10.0, 0.1) var thunderstorm_decay_multiplier: float = 3.0
@export_range(1.0, 10.0, 0.1) var occupied_decay_multiplier: float = 2.5
@export_range(50.0, 1200.0, 10.0) var rain_emission_rate: float = 520.0
@export_range(40.0, 1000.0, 10.0) var rain_speed_min: float = 110.0
@export_range(80.0, 1500.0, 10.0) var rain_speed_max: float = 210.0
@export_range(0.2, 1.0, 0.01) var rainy_light_dim_multiplier: float = 0.9
@export_range(0.2, 1.0, 0.01) var thunderstorm_light_dim_multiplier: float = 0.78
@export_range(1.0, 30.0, 0.5) var thunderstorm_lightning_min_interval: float = 4.5
@export_range(1.0, 45.0, 0.5) var thunderstorm_lightning_max_interval: float = 10.0
@export_range(0.05, 1.0, 0.01) var thunderstorm_flash_peak_alpha: float = 0.28
@export_range(0.5, 8.0, 0.1) var thunderstorm_flash_fade_speed: float = 2.8
@export_range(0.05, 1.0, 0.01) var thunderstorm_bolt_visible_seconds: float = 0.18
@export var lightning_ignites_flammables: bool = true
@export_range(0.5, 6.0, 0.1) var lightning_fire_radius_tiles: float = 1.6
@export_range(0.5, 60.0, 0.5) var lightning_fire_duration_seconds: float = 10.0
@export_range(0.0, 1.0, 0.01) var lightning_tree_ignite_chance: float = 0.95
@export_range(0.0, 1.0, 0.01) var lightning_grass_ignite_chance: float = 0.65
@export_range(0.0, 1.0, 0.01) var lightning_building_ignite_chance: float = 0.9
@export_range(0.0, 1.0, 0.01) var lightning_tent_ignite_chance: float = 0.98
@export_range(0.0, 100.0, 0.5) var lightning_strike_damage: float = 48.0
@export_range(0.0, 100.0, 0.5) var lightning_fire_damage_per_second: float = 18.0
@export_range(0.0, 200.0, 1.0) var lightning_tent_burn_damage_per_second: float = 70.0
@export_range(16.0, 420.0, 1.0) var lightning_fire_light_radius: float = 96.0
@export_range(0.0, 4.0, 0.05) var lightning_fire_light_energy: float = 1.2

@export_range(1, 20, 1) var campfire_build_wood_cost: int = 2
@export_range(0.0, 1200.0, 1.0) var campfire_burn_duration_seconds: float = 210.0
@export_range(12.0, 360.0, 1.0) var campfire_search_radius: float = 180.0
@export_range(8.0, 120.0, 1.0) var campfire_destroy_wood_refund: int = 1
@export_range(16.0, 360.0, 1.0) var campfire_warmth_radius: float = 108.0
@export_range(0.0, 24.0, 0.1) var campfire_warmth_bonus_c: float = 7.5
@export_range(16.0, 420.0, 1.0) var campfire_light_radius: float = 112.0
@export_range(0.0, 4.0, 0.05) var campfire_light_energy: float = 1.35
@export_range(8.0, 160.0, 1.0) var crafting_table_interaction_radius: float = 48.0
@export_range(64.0, 900.0, 1.0) var crafting_table_search_radius: float = 320.0
@export_range(1, 40, 1) var crafting_table_build_wood_cost: int = 8
@export_range(0.2, 1.0, 0.01) var occupied_home_alpha: float = 0.58
@export var crafting_table_texture_path: String = "res://workshop.png"
@export var crafting_table_atlas: Vector2i = Vector2i(0, 0)
@export var crafting_table_tile_size: Vector2i = Vector2i(32, 32)
@export var foundation_offset: Vector2i = Vector2i.ZERO
@export var floor_offset: Vector2i = Vector2i.ZERO
@export var walls_offset: Vector2i = Vector2i.ZERO
@export var roof_offset: Vector2i = Vector2i.ZERO
@export var build_site_padding_cells: int = 1
@export var enable_layer_shadows: bool = true
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.28)
@export var shadow_radius: float = 16.0
@export var shadow_squish: float = 0.35
@export var shadow_y_offset: float = 24.0
@export var shadow_layer_drop_per_z: float = 2.0
@export var building_shadow_drop_per_phase: float = 3.0
@export_range(0.0, 24.0, 0.5) var shadow_softness: float = 6.0
@export_range(1, 12, 1) var shadow_soft_steps: int = 6
@export_range(0.2, 1.5, 0.01) var tent_shadow_scale: float = 0.62
@export_range(-24.0, 24.0, 0.5) var tent_shadow_vertical_adjustment: float = -14.0
@export var tree_layer_path: NodePath = NodePath("plant layer")
@export var tree_atlas_coords: Array[Vector2i] = []
@export var tree_source_id: int = 0
@export var wood_per_tree: int = 3
@export var wood_cost_per_building: int = 6
@export var tree_growth_stages: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
@export_range(2.0, 120.0, 1.0) var tree_growth_step_seconds: float = 20.0
@export_range(0.0, 1.0, 0.01) var apple_drop_chance: float = 0.75
@export_range(3.0, 180.0, 1.0) var apple_decompose_min_seconds: float = 24.0
@export_range(3.0, 180.0, 1.0) var apple_decompose_max_seconds: float = 42.0
@export_range(4.0, 300.0, 1.0) var mature_tree_apple_min_seconds: float = 70.0
@export_range(4.0, 300.0, 1.0) var mature_tree_apple_max_seconds: float = 130.0
@export_range(0.0, 1.0, 0.01) var mature_tree_apple_chance: float = 0.22
@export var foods_texture_path: String = "res://foods.png"
@export var food_item_tile_size: Vector2i = Vector2i(16, 16)
@export var apple_drop_atlas: Vector2i = Vector2i(0, 0)
@export var seed_drop_atlas: Vector2i = Vector2i(3, 0)
@export var seed_auto_plant_tree_threshold: int = 8
@export var seed_auto_plant_attempts: int = 24
@export var tree_drop_radius: float = 12.0
@export var tree_drop_min_y_offset: float = 6.0
@export_range(80.0, 3000.0, 10.0) var npc_drop_spawn_radius: float = 900.0
@export_range(8.0, 96.0, 1.0) var tree_depth_influence_radius: float = 28.0
@export_range(0.2, 0.9, 0.05) var tree_depth_midpoint_ratio: float = 0.45
@export var drop_shadow_radius: float = 8.0
@export var drop_shadow_squish: float = 0.45
@export var drop_shadow_alpha: float = 0.24
@export var building_shadow_lift: float = -12.0
@export var roof_shadow_extra_cells: float = 1.0
@export var camera_phase_player_seconds: float = 8.0
@export var camera_phase_region_seconds: float = 7.0
@export var camera_phase_action_seconds: float = 7.0
@export var camera_phase_overview_seconds: float = 9.0
@export var camera_follow_smoothing: float = 3.2
@export var camera_zoom_smoothing: float = 2.2
@export var camera_focus_zoom_multiplier: float = 0.78
@export var camera_region_zoom_multiplier: float = 1.25
@export var camera_action_zoom_multiplier: float = 0.92
@export var camera_overview_zoom_multiplier: float = 1.8
@export var camera_max_zoom_multiplier: float = 1.8
@export var camera_manual_focus_seconds: float = 20.0
@export var camera_cycle_enabled: bool = true
@export var camera_cycle_npcs_only: bool = false
@export var camera_region_points: Array[Vector2] = []

# Infinite map generation
@export var infinite_map: bool = true
@export var island_noise_seed: int = 0
@export var island_noise_frequency: float = 0.013
@export var island_land_threshold: float = 0.24
@export var island_beach_width: float = 0.07
@export var tree_noise_frequency: float = 0.045
@export var tree_density_threshold: float = 0.82
@export var chunk_load_radius: int = 3
@export var chunk_generation_budget_per_frame: int = 1
@export_range(0.02, 0.5, 0.01) var chunk_generation_interval_seconds: float = 0.08
@export_range(0.5, 300.0, 0.1) var llm_min_decision_interval_seconds: float = 15.0
@export_range(0.5, 300.0, 0.1) var llm_max_decision_interval_seconds: float = 300.0
@export_range(10, 200, 1) var llm_long_term_memory_limit: int = 64
@export_range(0.0, 10.0, 0.1) var recent_event_dedupe_seconds: float = 1.2
@export_range(0.5, 30.0, 0.1) var stale_state_prune_interval_seconds: float = 5.0
@export var llm_use_chatgpt: bool = true
@export var llm_provider: String = "ollama"
@export var llm_openai_endpoint: String = "http://localhost:11434/api/generate"
@export var llm_model: String = "gemma4:e2b"
@export_range(0.0, 1.0, 0.05) var llm_temperature: float = 0.25
@export_range(8, 256, 1) var llm_num_predict: int = 48
@export_range(0.0, 1.0, 0.05) var baby_name_llm_temperature: float = 0.85
@export_range(8, 256, 1) var baby_name_llm_num_predict: int = 96
@export_range(1, 80, 1) var baby_name_repeat_avoid_count: int = 24
@export var baby_name_show_thinking_bubble: bool = false
@export var baby_name_defer_pause_until_response: bool = true
@export_range(0.5, 120.0, 0.5) var llm_request_timeout_seconds: float = 30.0
@export_range(0.5, 60.0, 0.5) var llm_api_request_min_interval_seconds: float = 1.0
@export_range(1, 8, 1) var llm_max_concurrent_requests: int = 1
@export_range(1, 64, 1) var llm_queue_soft_limit: int = 2
@export_range(1, 128, 1) var llm_queue_hard_limit: int = 6
@export var llm_compact_prompt_mode: bool = true
@export_range(24.0, 320.0, 1.0) var llm_player_awareness_radius: float = 180.0
@export_range(20.0, 180.0, 1.0) var llm_talk_distance: float = 78.0
@export_range(16.0, 220.0, 1.0) var llm_trade_distance: float = 74.0
@export var biological_mating_enabled: bool = true
@export_range(8.0, 160.0, 1.0) var biological_mating_distance: float = 26.0
@export_range(2.0, 60.0, 0.5) var horny_window_seconds: float = 14.0
@export_range(10.0, 240.0, 1.0) var mating_cooldown_seconds: float = 48.0
@export_range(0.1, 10.0, 0.1) var mating_check_interval_seconds: float = 0.75
@export var conversation_lock_enabled: bool = true
@export_range(0.5, 12.0, 0.1) var conversation_turn_seconds: float = 1.8
@export_range(2, 30, 1) var conversation_max_turns: int = 10
@export_range(0, 20, 1) var conversation_min_turns_before_leave: int = 7
@export_range(0.0, 1.0, 0.01) var conversation_leave_chance_per_turn: float = 0.05
@export_range(0.2, 2.0, 0.01) var conversation_camera_zoom_multiplier: float = 1.65
@export var conversation_pause_all_villagers: bool = true
@export var conversation_generic_require_llm: bool = true
@export_range(0, 6, 1) var conversation_generic_llm_retry_limit: int = 2
@export var conversation_generic_defer_pause_until_response: bool = true
@export_range(32, 512, 1) var conversation_replay_llm_num_predict: int = 240
@export_range(8.0, 120.0, 1.0) var conversation_pair_spacing: float = 30.0
@export_range(1.0, 24.0, 0.5) var conversation_pair_recenter_speed: float = 10.0
@export var llm_dialogue_requires_speech_text: bool = true
@export_range(1, 200, 1) var max_villager_population: int = 24
@export_range(0.0, 0.2, 0.001) var gene_mutation_chance: float = 0.02
@export_range(0.01, 0.8, 0.01) var gene_mutation_strength: float = 0.16
@export_range(20.0, 240.0, 1.0) var claim_awareness_radius: float = 92.0
@export_range(0.2, 5.0, 0.1) var claim_observation_interval_seconds: float = 1.0
@export_range(0.5, 20.0, 0.5) var claim_observation_cooldown_seconds: float = 6.0
@export var llm_debug_log_to_output: bool = false
@export var in_game_debug_ui_enabled: bool = true
@export var dev_console_enabled: bool = true
@export var runtime_counter_overlay_enabled: bool = true
@export_range(0.1, 5.0, 0.1) var runtime_counter_refresh_seconds: float = 0.5
@export_range(0, 8, 1) var llm_prompt_recent_event_limit: int = 2
@export_range(0, 8, 1) var llm_prompt_memory_limit: int = 1
@export_range(0, 6, 1) var llm_prompt_nearby_player_limit: int = 1
@export_range(1, 20, 1) var initial_villager_count: int = 3
@export var npc_inspector_enabled: bool = true
@export_range(10.0, 140.0, 1.0) var npc_inspector_click_radius: float = 28.0
@export_range(2, 30, 1) var npc_inspector_memory_rows: int = 8
@export_range(2, 30, 1) var npc_inspector_thought_rows: int = 8
@export_range(2, 30, 1) var npc_conversation_history_limit: int = 10
@export_range(10.0, 900.0, 5.0) var dead_npc_index_retention_seconds: float = 180.0
@export_range(32, 600, 1) var direction_word_catalog_size: int = 220
@export var water_wave_enabled: bool = true
@export_range(0.05, 0.8, 0.01) var water_wave_interval_seconds: float = 0.22
@export_range(8, 120, 1) var water_wave_radius_tiles: int = 26
@export_range(4.0, 90.0, 1.0) var water_current_speed: float = 24.0
@export_range(0.0008, 0.05, 0.0001) var water_current_noise_scale: float = 0.012
@export_range(0.0, 8.0, 0.1) var water_float_bob_amplitude: float = 1.8
@export_range(0.2, 8.0, 0.1) var water_float_bob_speed: float = 2.4
@export var wind_current_enabled: bool = true
@export_range(0.5, 80.0, 0.5) var seed_wind_speed: float = 28.0
@export_range(0.0005, 0.05, 0.0001) var wind_current_noise_scale: float = 0.006
@export_range(0.0, 0.95, 0.01) var wind_gust_deadzone: float = 0.42
@export_range(0.1, 20.0, 0.1) var seed_mass: float = 1.0
@export_range(0.0, 10.0, 0.1) var seed_ground_static_threshold: float = 2.8
@export_range(0.0, 10.0, 0.1) var seed_water_static_threshold: float = 0.45
@export_range(30.0, 300.0, 10.0) var seed_dry_ground_decay_seconds: float = 120.0
@export_range(0.0, 1.0, 0.05) var seed_water_planting_chance: float = 0.04
@export_range(0.0, 12.0, 0.1) var seed_ground_damping: float = 1.2
@export_range(0.0, 12.0, 0.1) var seed_water_damping: float = 0.6
@export_range(1.0, 140.0, 1.0) var seed_max_speed: float = 34.0
@export_range(0.0, 12.0, 0.1) var drop_shadow_ground_offset: float = 1.6
@export_range(0.0, 12.0, 0.1) var drop_shadow_floating_offset: float = 6.0
@export_range(0.0, 1.0, 0.01) var drop_shadow_floating_alpha_scale: float = 0.62
@export_range(20, 1000, 1) var max_ground_drop_count: int = 220
@export_range(1, 100, 1) var drop_cull_batch_size: int = 12
@export_range(1, 64, 1) var drop_path_candidate_limit: int = 8
@export_range(40.0, 1200.0, 10.0) var drop_target_max_direct_distance: float = 320.0
@export_range(0.02, 0.5, 0.01) var ground_drop_update_interval_seconds: float = 0.08
@export_range(1, 100, 1) var water_seed_plant_attempts_per_tick: int = 12
@export var thermal_system_enabled: bool = true
@export_range(5.0, 50.0, 0.1) var ambient_base_temperature_c: float = 28.0
@export_range(0.0, 25.0, 0.1) var climate_heat_variation_c: float = 4.5
@export_range(0.0, 25.0, 0.1) var climate_sun_heating_c: float = 13.0
@export_range(0.0, 20.0, 0.1) var climate_water_cooling_c: float = 4.0
# How many degrees warmer the peak of day is vs the base, and how much colder at night.
@export_range(0.0, 20.0, 0.1) var day_night_temp_swing_c: float = 8.0
@export_range(0.0, 1.0, 0.01) var ambient_base_humidity: float = 0.44
@export_range(0.0, 1.0, 0.01) var climate_humidity_variation: float = 0.25
@export_range(0.0, 1.0, 0.01) var climate_water_humidity_boost: float = 0.36
@export_range(0.0002, 0.03, 0.0001) var climate_heat_noise_scale: float = 0.0038
@export_range(0.0002, 0.03, 0.0001) var climate_humidity_noise_scale: float = 0.0048
@export_range(8.0, 260.0, 1.0) var climate_water_influence_radius: float = 96.0
@export var biome_system_enabled: bool = true
@export_range(0.0002, 0.03, 0.0001) var biome_noise_scale: float = 0.0032
@export_range(-1.0, 1.0, 0.01) var desert_biome_threshold: float = 0.24
@export_range(0.0, 1.0, 0.01) var desert_cactus_density: float = 0.08
@export_range(0.0, 25.0, 0.1) var desert_temperature_bonus_c: float = 5.8
@export_range(0.0, 1.0, 0.01) var desert_humidity: float = 0.0
@export_range(0.0, 0.1, 0.001) var prickly_pear_drop_chance: float = 0.012
@export_range(30.0, 600.0, 5.0) var prickly_pear_regrow_seconds: float = 120.0
@export var show_heat_map_overlay: bool = false
@export var show_humidity_map_overlay: bool = false
@export_range(0.03, 0.7, 0.01) var climate_overlay_alpha: float = 0.48
@export_range(0.1, 2.0, 0.05) var climate_overlay_refresh_seconds: float = 0.4
@export var day_night_visual_enabled: bool = true
@export_range(0.05, 1.0, 0.01) var night_min_brightness: float = 0.32
@export_range(0.5, 2.0, 0.01) var day_max_brightness: float = 1.0
@export_range(0.1, 10.0, 0.1) var day_night_brightness_lerp_speed: float = 2.5
@export var show_claims_overlay: bool = true
@export_range(0.05, 0.9, 0.01) var claims_overlay_alpha: float = 0.28
@export_range(0.5, 3.0, 0.1) var claims_overlay_outline_width: float = 1.0
@export var show_time_of_day_ui: bool = true
@export_range(0.05, 2.0, 0.05) var time_of_day_ui_refresh_seconds: float = 0.2

var _arena_rect := Rect2(Vector2(90.0, 100.0), Vector2(980.0, 600.0))
var _villagers: Array[VillagerAgent] = []
var _blocked_tile_lookup: Dictionary = {}
var _shadow_overlay: Node2D
var _claims_overlay: Node2D
var _claims_overlay_layer: CanvasLayer
var _claims_overlay_last_visible: bool = false
var _climate_overlay: Node2D
var _climate_overlay_last_visible: bool = false
var _climate_overlay_timer: float = 0.0
var _day_night_modulate: CanvasModulate
var _current_day_night_brightness: float = 1.0
var _climate_grayscale_material: ShaderMaterial = null
var _climate_original_materials: Dictionary = {}
var _tile_bottom_cache: Dictionary = {}
var _shadow_texture: ImageTexture
var _shadow_texture_origin: Vector2 = Vector2.ZERO
var _build_phase_layers: Array[TileMapLayer] = []
var _build_phase_atlas: Array[Vector2i] = []
var _build_phase_source_ids: Array[int] = []
var _build_phase_offsets: Array[Vector2i] = []
var _reserved_build_cells: Dictionary = {}
var _tent_build_layer: TileMapLayer = null
var _tent_behind_layer: TileMapLayer = null
var _tent_decay_state: Dictionary = {}
var _current_weather: String = "none"
var _weather_transition_timer: float = 0.0
var _rain_particles: CPUParticles2D = null
var _weather_fx_layer: CanvasLayer = null
var _rain_overlay: Node2D = null
var _rain_streaks: Array[Dictionary] = []
var _rain_streak_texture: Texture2D = null
var _last_weather_canvas_origin: Vector2 = Vector2(INF, INF)
var _last_weather_canvas_scale: Vector2 = Vector2(INF, INF)
@export_range(0.0, 4.0, 0.05) var rain_camera_compensation_strength: float = 1.0
@export_range(0.0, 4.0, 0.05) var rain_zoom_compensation_strength: float = 1.0
@export_range(0.5, 3.0, 0.05) var rain_streak_size_multiplier: float = 1.45
@export_range(80.0, 900.0, 10.0) var rain_offscreen_padding: float = 320.0
var _lightning_flash_rect: ColorRect = null
var _lightning_bolt_overlay: Node2D = null
var _lightning_strike_timer: float = 0.0
var _lightning_flash_alpha: float = 0.0
var _lightning_bolt_timer: float = 0.0
var _lightning_bolt_points: Array[Vector2] = []
var _lightning_fires: Dictionary = {}
var _untracked_scan_timer: float = 0.0
var _reserved_tree_cells: Dictionary = {}
var _cached_tree_layer: TileMapLayer = null
var _crafting_table_root: Node2D
var _crafting_table_positions: Array[Vector2] = []
var _crafting_table_texture: Texture2D
var _home_occupants: Dictionary = {}
var _villager_home_cell: Dictionary = {}
var _home_owner_by_cell: Dictionary = {}
var _revealed_home_tiles: Dictionary = {}
var _home_transparency_overlay: Node2D = null
var _shelter_cells: Dictionary = {}
var _tree_growth_timers: Dictionary = {}
var _tree_fruit_timers: Dictionary = {}
var _campfire_layer: TileMapLayer = null
var _campfires: Dictionary = {}
var _campfire_light_root: Node2D = null
var _campfire_light_texture: Texture2D = null
var _campfire_fx_root: Node2D = null
var _campfire_fire_texture: Texture2D = null
var _campfire_fire_frames: SpriteFrames = null
var _drop_layer: Node2D
var _food_texture: Texture2D
var _apple_drop_texture: Texture2D
var _seed_drop_texture: Texture2D
var _wood_drop_texture: Texture2D
var _drop_shadow_texture: Texture2D
var _ground_drops: Dictionary = {}
var _reserved_drop_ids: Dictionary = {}
var _next_drop_id: int = 1
var _ground_drop_update_accumulator: float = 0.0
var _water_seed_plant_budget_remaining: int = 0
var _mature_tree_count_cache: int = -1
var _camera_base_zoom: Vector2 = Vector2.ONE
var _camera_target_position: Vector2 = Vector2.ZERO
var _camera_target_zoom: Vector2 = Vector2.ONE
var _camera_phase_time_left: float = 0.0
var _camera_phase_index: int = -1
var _camera_current_player_index: int = 0
var _camera_current_region_index: int = 0
var _camera_player_rotator: int = 0
var _camera_region_rotator: int = 0
var _camera_phase_order: Array[int] = [0, 1, 2, 3]
var _camera_cycle_last_npcs_only: bool = false
var _camera_last_positions: Dictionary = {}
var _camera_manual_focus_name: String = ""
var _camera_manual_focus_time_left: float = 0.0
var _generated_chunks: Dictionary = {}
var _queued_chunks: Dictionary = {}
var _pending_chunk_queue: Array[Vector2i] = []
var _pending_chunk_cursor: int = 0
var _last_stream_chunk: Vector2i = Vector2i(2147483647, 2147483647)
var _chunk_generation_time_left: float = 0.0
var _water_wave_timer: float = 0.0
var _water_wave_time: float = 0.0
var _terrain_noise: FastNoiseLite = null
var _tree_spawn_noise: FastNoiseLite = null
var _water_current_noise_x: FastNoiseLite = null
var _water_current_noise_y: FastNoiseLite = null
var _wind_current_noise_x: FastNoiseLite = null
var _wind_current_noise_y: FastNoiseLite = null
var _heat_noise: FastNoiseLite = null
var _humidity_noise: FastNoiseLite = null
var _biome_noise: FastNoiseLite = null
var _cactus_layer: Node2D
var _cactus_texture: Texture2D
var _spawned_cactus_cells: Dictionary = {}
var _cactus_pear_timers: Dictionary = {}  # cell -> seconds until next prickly pear drops
var _npc_physical_genes: Dictionary = {}
var _npc_llm_genes: Dictionary = {}
var _npc_llm_contexts: Dictionary = {}
var _npc_last_llm_decisions: Dictionary = {}
var _npc_last_llm_request_time: Dictionary = {}
var _npc_pending_llm_state: Dictionary = {}
var _npc_llm_status: Dictionary = {}
var _npc_last_llm_error: Dictionary = {}
var _npc_last_llm_success_time: Dictionary = {}
var _npc_recent_thoughts: Dictionary = {}
var _npc_claims: Dictionary = {}
var _claim_observation_cooldowns: Dictionary = {}
var _claim_observation_timer: float = 0.0
var _npc_next_horny_time: Dictionary = {}
var _npc_horny_until: Dictionary = {}
var _npc_last_mate_time: Dictionary = {}
var _recent_event_cooldowns: Dictionary = {}
var _stale_state_prune_timer: float = 0.0
var _llm_api_key: String = ""
var _llm_request_queue: Array[String] = []
var _llm_active_requests: Dictionary = {}
var _npc_inspector_layer: CanvasLayer
var _npc_inspector_panel: PanelContainer
var _npc_inspector_title: Label
var _npc_overview_text: RichTextLabel
var _npc_genes_text: RichTextLabel
var _npc_memories_text: RichTextLabel
var _npc_events_text: RichTextLabel
var _npc_thoughts_text: RichTextLabel
var _npc_conversations_text: RichTextLabel
var _inspected_villager_name: String = ""
var _inspected_tent_cell: Vector2i = Vector2i(-9999, -9999)
var _camera_follow_index_layer: CanvasLayer
var _camera_follow_index_panel: PanelContainer
var _camera_follow_subtitle: Label
var _camera_follow_scroller: ScrollContainer
var _camera_follow_cards_root: VBoxContainer
var _camera_follow_toggle_button: Button
var _camera_follow_cards_visible: bool = true
var _runtime_counter_layer: CanvasLayer
var _runtime_counter_label: Label
var _runtime_counter_timer: float = 0.0
var _event_notification_layer: CanvasLayer
var _event_notification_panel: PanelContainer
var _event_notification_label: Label
var _event_notification_queue: Array[String] = []
var _event_notification_timer: float = 0.0
var _dev_console_layer: CanvasLayer
var _dev_console_panel: PanelContainer
var _dev_console_output: RichTextLabel
var _dev_console_input: LineEdit
var _dev_console_lines: Array[String] = []
var _dev_console_visible: bool = false
var _dev_console_max_lines: int = 80
var _time_of_day_layer: CanvasLayer
var _time_of_day_panel: PanelContainer
var _time_of_day_label: Label
var _time_of_day_ui_timer: float = 0.0
var _camera_follow_panel_expanded_bottom: float = 286.0
var _camera_follow_panel_collapsed_bottom: float = 58.0
var _camera_follow_ui_update_interval: float = 0.25
var _camera_follow_ui_timer: float = 0.0
var _camera_follow_ui_signature: String = ""
var _npc_inspector_ui_update_interval: float = 0.2
var _npc_inspector_ui_timer: float = 0.0
var _npc_index_records: Dictionary = {}
var _npc_index_order: Array[String] = []
var _npc_conversations: Dictionary = {}
var _direction_word_vectors: Dictionary = {}
var _mating_update_timer: float = 0.0
var _pending_baby_name_jobs: Dictionary = {}
var _next_baby_name_job_id: int = 1
var _baby_name_job_queue: Array[int] = []
var _active_baby_name_job_id: int = -1
var _recent_baby_names: Array[String] = []
var _prefetched_baby_names: Array[Dictionary] = []
var _baby_name_prefetch_request: HTTPRequest
var _baby_name_prefetch_target_pool_size: int = 3
var _pending_generic_conversation_jobs: Dictionary = {}
var _pending_generic_conversation_pairs: Dictionary = {}
var _next_generic_conversation_job_id: int = 1
var _active_locked_conversation: Dictionary = {}
var _llm_requests_paused_for_conversation: bool = false
var _conversation_overlay: CanvasLayer
var _conversation_overlay_rect: ColorRect
var _conversation_overlay_fade_timer: float = 0.0
var _conversation_overlay_fade_duration: float = 0.5
var _conversation_overlay_target_alpha: float = 0.0
@export_range(0.0, 10.0, 0.1) var conversation_energy_drain_per_sec: float = 1.5

const MAP_WIDTH: int = 80
const MAP_HEIGHT: int = 45
const TERRAIN_SOURCE_ID: int = 0
const CHUNK_SIZE: int = 16
const BFS_MAX_CELLS: int = 4000
const TILE_ALT_ROT_0: int = 0
const TILE_ALT_ROT_90: int = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
const TILE_ALT_ROT_180: int = TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
const TILE_ALT_ROT_270: int = TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V
const EVENT_NOTIFICATION_SECONDS: float = 4.0
const SUN_CYCLE_SPEED: float = 0.018
const CAMERA_PHASE_PLAYER: int = 0
const CAMERA_PHASE_REGION: int = 1
const CAMERA_PHASE_ACTION: int = 2
const CAMERA_PHASE_OVERVIEW: int = 3
const GRASS_TILES: Array[Vector2i] = [
	Vector2i(3, 3)
]
const DESERT_MIDDLE_TILE: Vector2i = Vector2i(3, 2)
const DESERT_BOTTOM_EDGE_TILE: Vector2i = Vector2i(4, 2)
const PATH_TILES: Array[Vector2i] = [Vector2i(1, 5), Vector2i(2, 5), Vector2i(1, 6), Vector2i(2, 6)]
const WATER_TILES: Array[Vector2i] = [Vector2i(2, 3)]
const REAL_DIRECTION_WORDS: Array[String] = [
	"anchor", "apex", "ardor", "ascent", "balance", "beacon", "bloom", "bond", "brave", "breeze",
	"bridge", "bright", "calm", "candid", "care", "center", "chance", "chant", "charge", "clarity",
	"climb", "compass", "craft", "curious", "daring", "dawn", "deep", "devotion", "discipline", "drift",
	"drive", "duty", "echo", "edge", "ember", "empathy", "endure", "ethic", "explore", "faith",
	"fervor", "flame", "flow", "flourish", "focus", "forge", "fortune", "freedom", "friend", "future",
	"gentle", "glimmer", "glow", "grace", "grit", "ground", "growth", "guard", "guide", "harbor",
	"harmony", "hearth", "heart", "horizon", "humor", "hunger", "ideal", "ignite", "intent", "joy",
	"journey", "kinship", "kindle", "labor", "learn", "legacy", "light", "lively", "loyal", "lumen",
	"mercy", "method", "mission", "momentum", "motive", "muse", "nature", "noble", "oath", "open",
	"order", "origin", "patience", "path", "peace", "peak", "persist", "pioneer", "pledge", "poise",
	"power", "purpose", "quest", "quiet", "radiant", "rally", "reason", "refine", "renew", "resolve",
	"rhythm", "rise", "root", "sail", "safety", "savor", "scale", "search", "secure", "sense",
	"serene", "service", "shelter", "shine", "signal", "skill", "spark", "spirit", "stable", "stand",
	"star", "steady", "steward", "still", "storm", "strength", "stride", "study", "swift", "temper",
	"thrive", "tidal", "torch", "trail", "trust", "truth", "unity", "valor", "venture", "verve",
	"vigil", "vigor", "vision", "vital", "wander", "warmth", "watch", "wave", "will", "wisdom",
	"wonder", "zeal"
]

func _ready() -> void:
	randomize()
	_initialize_llm_bridge()
	if _llm_backend_ready():
		_request_baby_name_prefetch()
	_initialize_direction_word_space()
	_setup_camera_follow_index_ui()
	_setup_npc_inspector_ui()
	_setup_runtime_counter_overlay()
	_setup_event_notification_ui()
	_setup_time_of_day_ui()
	_setup_dev_console_ui()
	_init_climate_noise()
	_init_biome_noise()
	_init_water_current_noise()
	_init_wind_current_noise()
	_rebuild_blocked_tile_lookup()
	_rebuild_build_phase_cache()
	_setup_crafting_tables()
	_setup_cactus_system()
	_initialize_drop_system()
	if auto_generate_terrain:
		if infinite_map:
			_init_infinite_noise()
			_generate_starting_island()
		else:
			_build_terrain()
	_initialize_tree_growth_from_map()
	_setup_campfire_system()
	_rebuild_tent_decay_state_from_layers()
	_setup_weather_system()
	_setup_shadow_overlay()
	_setup_claims_overlay()
	_setup_climate_overlay()
	_setup_day_night_lighting()
	_setup_conversation_overlay()
	chat_bridge.join_requested.connect(_on_join_requested)
	_spawn_initial_villagers()
	_initialize_camera_cycle()

func _process(delta: float) -> void:
	_update_day_night_lighting(delta)
	_update_conversation_overlay_fade(delta)
	if _has_active_locked_conversation():
		_update_weather(delta)
		_update_lightning_fires(delta)
		_update_locked_conversation(delta)
		_resolve_villager_overlap(delta)
		_update_camera_cycle(delta)
		_camera_follow_ui_timer -= delta
		if _camera_follow_ui_timer <= 0.0:
			_camera_follow_ui_timer = _camera_follow_ui_update_interval
			_update_camera_follow_index_ui()
		_npc_inspector_ui_timer -= delta
		if _npc_inspector_ui_timer <= 0.0:
			_npc_inspector_ui_timer = _npc_inspector_ui_update_interval
			_update_npc_inspector_ui()
		if _runtime_counter_label != null:
			_runtime_counter_timer -= delta
			if _runtime_counter_timer <= 0.0:
				_runtime_counter_timer = maxf(0.1, runtime_counter_refresh_seconds)
				_update_runtime_counter_overlay()
		_update_time_of_day_ui(delta)
		_update_event_notification_ui(delta)
		return

	_update_tree_growth(delta)
	_update_tree_fruiting(delta)
	_update_campfires(delta)
	_update_weather(delta)
	_update_lightning_fires(delta)
	_update_tent_decay(delta)
	_scan_untracked_tent_tiles(delta)
	var drop_step: float = maxf(0.02, ground_drop_update_interval_seconds)
	_ground_drop_update_accumulator += delta
	var drop_iterations: int = 0
	while _ground_drop_update_accumulator >= drop_step and drop_iterations < 3:
		_water_seed_plant_budget_remaining = max(0, water_seed_plant_attempts_per_tick)
		_update_ground_drop_decay(drop_step)
		_ground_drop_update_accumulator -= drop_step
		drop_iterations += 1
	_update_claim_observations(delta)
	_update_biological_mating(delta)
	_update_cactus_drops(delta)
	_update_camera_cycle(delta)
	_camera_follow_ui_timer -= delta
	if _camera_follow_ui_timer <= 0.0:
		_camera_follow_ui_timer = _camera_follow_ui_update_interval
		_update_camera_follow_index_ui()
	_water_wave_time += delta
	if infinite_map and _terrain_noise != null:
		_chunk_generation_time_left -= delta
		if _chunk_generation_time_left <= 0.0:
			_stream_chunks_around_camera()
			_chunk_generation_time_left = chunk_generation_interval_seconds
	if water_wave_enabled:
		_update_water_wave_animation(delta)
	if _claims_overlay != null:
			_pump_llm_queue()
			_pump_baby_name_prefetch()
			_claims_overlay_last_visible = show_claims_overlay
			_claims_overlay.visible = show_claims_overlay
			if show_claims_overlay:
				_claims_overlay.queue_redraw()
	if _climate_overlay != null:
		var climate_visible: bool = show_heat_map_overlay or show_humidity_map_overlay
		if _climate_overlay_last_visible != climate_visible:
			_climate_overlay_last_visible = climate_visible
			_set_climate_overlay_background_grayscale(climate_visible)
			_climate_overlay.visible = climate_visible
			if climate_visible:
				_climate_overlay.queue_redraw()
		if climate_visible:
			_climate_overlay_timer -= delta
			if _climate_overlay_timer <= 0.0:
				_climate_overlay_timer = maxf(0.05, climate_overlay_refresh_seconds)
				_climate_overlay.queue_redraw()
	_pump_llm_queue()
	_npc_inspector_ui_timer -= delta
	if _npc_inspector_ui_timer <= 0.0:
		_npc_inspector_ui_timer = _npc_inspector_ui_update_interval
		_update_npc_inspector_ui()
	if _runtime_counter_label != null:
		_runtime_counter_timer -= delta
		if _runtime_counter_timer <= 0.0:
			_runtime_counter_timer = maxf(0.1, runtime_counter_refresh_seconds)
			_update_runtime_counter_overlay()
	_update_time_of_day_ui(delta)
	_update_event_notification_ui(delta)
	_stale_state_prune_timer -= delta
	if _stale_state_prune_timer <= 0.0:
		_stale_state_prune_timer = maxf(0.5, stale_state_prune_interval_seconds)
		_prune_stale_npc_runtime_state()
	_resolve_villager_overlap(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if dev_console_enabled and key_event.pressed and not key_event.is_echo() and key_event.keycode == KEY_F1:
			_set_dev_console_visible(not _dev_console_visible)
			get_viewport().set_input_as_handled()
			return
		if _dev_console_visible:
			if key_event.pressed and not key_event.is_echo() and key_event.keycode == KEY_ESCAPE:
				_set_dev_console_visible(false)
				get_viewport().set_input_as_handled()
			return
	if _dev_console_visible:
		return
	if not npc_inspector_enabled:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.is_echo() and key_event.keycode == KEY_ESCAPE:
			_close_npc_inspector()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if not mouse_event.pressed or mouse_event.is_echo():
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_world: Vector2 = get_global_mouse_position()
		var picked: VillagerAgent = _pick_villager_at_world_position(clicked_world)
		if picked != null:
			_inspected_villager_name = picked.villager_name
			_inspected_tent_cell = Vector2i(-9999, -9999)
			if _npc_inspector_panel != null:
				_npc_inspector_panel.visible = true
			_update_npc_inspector_ui()
		else:
			var tent_cell: Vector2i = _pick_tent_cell_at_world_position(clicked_world)
			if tent_cell != Vector2i(-9999, -9999):
				_inspected_villager_name = ""
				_inspected_tent_cell = tent_cell
				if _npc_inspector_panel != null:
					_npc_inspector_panel.visible = true
				_update_npc_inspector_ui()
			else:
				_close_npc_inspector()
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_close_npc_inspector()

func _setup_npc_inspector_ui() -> void:
	_npc_inspector_layer = CanvasLayer.new()
	_npc_inspector_layer.name = "NpcInspectorUI"
	add_child(_npc_inspector_layer)

	_npc_inspector_panel = PanelContainer.new()
	_npc_inspector_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_npc_inspector_panel.offset_left = -760.0
	_npc_inspector_panel.offset_top = 16.0
	_npc_inspector_panel.offset_right = -16.0
	_npc_inspector_panel.offset_bottom = 500.0
	_npc_inspector_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_npc_inspector_layer.add_child(_npc_inspector_panel)
	_npc_inspector_panel.visible = false

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_npc_inspector_panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)

	_npc_inspector_title = Label.new()
	_npc_inspector_title.text = "NPC Inspector"
	_npc_inspector_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_npc_inspector_title)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(30.0, 24.0)
	close_button.pressed.connect(_on_npc_inspector_close_pressed)
	header.add_child(close_button)

	var cards := GridContainer.new()
	cards.columns = 2
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cards)

	var overview_card := _create_npc_inspector_card("Overview & Inventory")
	_npc_overview_text = overview_card["text"]
	cards.add_child(overview_card["panel"])

	var genes_card := _create_npc_inspector_card("Genes")
	_npc_genes_text = genes_card["text"]
	cards.add_child(genes_card["panel"])

	var memory_card := _create_npc_inspector_card("Long-term Memories")
	_npc_memories_text = memory_card["text"]
	cards.add_child(memory_card["panel"])

	var events_card := _create_npc_inspector_card("Recent Events")
	_npc_events_text = events_card["text"]
	cards.add_child(events_card["panel"])

	var thoughts_card := _create_npc_inspector_card("Recent Thoughts")
	_npc_thoughts_text = thoughts_card["text"]
	cards.add_child(thoughts_card["panel"])

	var conversations_card := _create_npc_inspector_card("Conversations")
	_npc_conversations_text = conversations_card["text"]
	cards.add_child(conversations_card["panel"])

	_update_npc_inspector_ui()

func _setup_runtime_counter_overlay() -> void:
	if not in_game_debug_ui_enabled or not runtime_counter_overlay_enabled:
		return
	_runtime_counter_layer = CanvasLayer.new()
	_runtime_counter_layer.name = "RuntimeCounterOverlay"
	add_child(_runtime_counter_layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -350.0
	panel.offset_top = -168.0
	panel.offset_right = -10.0
	panel.offset_bottom = -10.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.06, 0.09, 0.82)
	panel_style.border_color = Color(0.34, 0.52, 0.70, 0.9)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", panel_style)
	_runtime_counter_layer.add_child(panel)

	_runtime_counter_label = Label.new()
	_runtime_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_runtime_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_runtime_counter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_runtime_counter_label.add_theme_font_size_override("font_size", 11)
	_runtime_counter_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 0.98))
	_runtime_counter_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.72))
	_runtime_counter_label.add_theme_constant_override("outline_size", 1)
	_runtime_counter_label.text = "Runtime counters initializing..."
	panel.add_child(_runtime_counter_label)

	_runtime_counter_timer = 0.0
	_update_runtime_counter_overlay()

func _setup_event_notification_ui() -> void:
	_event_notification_layer = CanvasLayer.new()
	_event_notification_layer.name = "EventNotificationUI"
	add_child(_event_notification_layer)

	_event_notification_panel = PanelContainer.new()
	_event_notification_panel.anchor_left = 0.5
	_event_notification_panel.anchor_right = 0.5
	_event_notification_panel.anchor_top = 0.0
	_event_notification_panel.anchor_bottom = 0.0
	_event_notification_panel.offset_left = -280.0
	_event_notification_panel.offset_right = 280.0
	_event_notification_panel.offset_top = 10.0
	_event_notification_panel.offset_bottom = 52.0
	_event_notification_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.17, 0.92)
	style.border_color = Color(0.9, 0.75, 0.32, 0.96)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	_event_notification_panel.add_theme_stylebox_override("panel", style)
	_event_notification_layer.add_child(_event_notification_panel)

	_event_notification_label = Label.new()
	_event_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_event_notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_event_notification_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_event_notification_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_notification_label.add_theme_font_size_override("font_size", 12)
	_event_notification_label.add_theme_color_override("font_color", Color(0.98, 0.98, 0.96, 1.0))
	_event_notification_panel.add_child(_event_notification_label)
	_event_notification_panel.visible = false

func _setup_dev_console_ui() -> void:
	if not dev_console_enabled:
		return
	_dev_console_layer = CanvasLayer.new()
	_dev_console_layer.name = "DevConsoleUI"
	_dev_console_layer.layer = 120
	add_child(_dev_console_layer)

	_dev_console_panel = PanelContainer.new()
	_dev_console_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dev_console_panel.offset_left = 12.0
	_dev_console_panel.offset_right = 548.0
	_dev_console_panel.offset_top = -286.0
	_dev_console_panel.offset_bottom = -12.0
	_dev_console_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var console_style := StyleBoxFlat.new()
	console_style.bg_color = Color(0.05, 0.06, 0.08, 0.93)
	console_style.border_color = Color(0.35, 0.62, 0.82, 0.95)
	console_style.border_width_left = 1
	console_style.border_width_right = 1
	console_style.border_width_top = 1
	console_style.border_width_bottom = 1
	console_style.corner_radius_top_left = 8
	console_style.corner_radius_top_right = 8
	console_style.corner_radius_bottom_left = 8
	console_style.corner_radius_bottom_right = 8
	console_style.content_margin_left = 10.0
	console_style.content_margin_right = 10.0
	console_style.content_margin_top = 8.0
	console_style.content_margin_bottom = 8.0
	_dev_console_panel.add_theme_stylebox_override("panel", console_style)
	_dev_console_layer.add_child(_dev_console_panel)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 6)
	_dev_console_panel.add_child(root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	var title := Label.new()
	title.text = "Dev Console"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var hint := Label.new()
	hint.text = "F1 toggle"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.68, 0.77, 0.86, 0.95))
	header.add_child(hint)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.custom_minimum_size = Vector2(52.0, 24.0)
	clear_button.pressed.connect(_clear_dev_console_output)
	header.add_child(clear_button)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(28.0, 24.0)
	close_button.pressed.connect(func() -> void: _set_dev_console_visible(false))
	header.add_child(close_button)

	_dev_console_output = RichTextLabel.new()
	_dev_console_output.fit_content = false
	_dev_console_output.scroll_following = true
	_dev_console_output.bbcode_enabled = false
	_dev_console_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dev_console_output.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_console_output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dev_console_output.custom_minimum_size = Vector2(0.0, 200.0)
	_dev_console_output.add_theme_font_size_override("normal_font_size", 11)
	_dev_console_output.add_theme_color_override("default_color", Color(0.92, 0.96, 1.0, 1.0))
	_dev_console_output.add_theme_color_override("selection_color", Color(0.45, 0.66, 0.86, 0.35))
	root.add_child(_dev_console_output)

	_dev_console_input = LineEdit.new()
	_dev_console_input.placeholder_text = "help, weather rainy, spawn npc 3, give wood Iris 10"
	_dev_console_input.clear_button_enabled = true
	_dev_console_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dev_console_input.text_submitted.connect(_on_dev_console_text_submitted)
	root.add_child(_dev_console_input)

	_set_dev_console_visible(false)
	_append_dev_console_line("Dev console ready. Type 'help' for commands.")

func _queue_event_notification(text: String) -> void:
	var msg: String = text.strip_edges().substr(0, 180)
	if msg.is_empty():
		return
	_event_notification_queue.append(msg)
	if _event_notification_timer <= 0.0:
		_show_next_event_notification()

func _show_next_event_notification() -> void:
	if _event_notification_panel == null or _event_notification_label == null:
		return
	if _event_notification_queue.is_empty():
		_event_notification_panel.visible = false
		_event_notification_timer = 0.0
		return
	_event_notification_label.text = _event_notification_queue.pop_front()
	_event_notification_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_event_notification_panel.visible = true
	_event_notification_timer = EVENT_NOTIFICATION_SECONDS

func _update_event_notification_ui(delta: float) -> void:
	if _event_notification_panel == null:
		return
	if _event_notification_timer > 0.0:
		_event_notification_timer -= delta
		if _event_notification_timer <= 0.0:
			_event_notification_timer = 0.0
		return
	if _event_notification_panel.visible:
		_event_notification_panel.modulate.a = maxf(0.0, _event_notification_panel.modulate.a - delta * 3.5)
		if _event_notification_panel.modulate.a <= 0.0:
			_event_notification_panel.visible = false

func _set_dev_console_visible(visible: bool) -> void:
	_dev_console_visible = visible and dev_console_enabled and _dev_console_panel != null and _dev_console_input != null
	if _dev_console_panel != null:
		_dev_console_panel.visible = _dev_console_visible
	if _dev_console_visible:
		_dev_console_input.text = _dev_console_input.text
		call_deferred("_focus_dev_console_input")
	else:
		if _dev_console_input != null:
			_dev_console_input.release_focus()

func _focus_dev_console_input() -> void:
	if _dev_console_visible and _dev_console_input != null:
		_dev_console_input.grab_focus()

func _clear_dev_console_output() -> void:
	_dev_console_lines.clear()
	if _dev_console_output != null:
		_dev_console_output.text = ""

func _append_dev_console_line(text: String) -> void:
	var line: String = text.strip_edges()
	if line.is_empty():
		return
	_dev_console_lines.append(line)
	while _dev_console_lines.size() > _dev_console_max_lines:
		_dev_console_lines.pop_front()
	if _dev_console_output != null:
		_dev_console_output.text = _join_string_array(_dev_console_lines, "\n")

func _join_string_array(values: Array, separator: String) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	if parts.is_empty():
		return ""
	var result: String = parts[0]
	for i in range(1, parts.size()):
		result += separator + parts[i]
	return result

func _on_dev_console_text_submitted(text: String) -> void:
	var command_line: String = text.strip_edges()
	if command_line.is_empty():
		return
	_append_dev_console_line("> %s" % command_line)
	_dev_console_input.clear()
	var result: String = _execute_dev_console_command(command_line)
	if not result.is_empty():
		_append_dev_console_line(result)

func _execute_dev_console_command(command_line: String) -> String:
	var tokens: Array = command_line.strip_edges().split(" ", false)
	if tokens.is_empty():
		return ""
	var command: String = str(tokens[0]).to_lower()
	if command == "help":
		return "Commands: help | weather <none|rainy|thunderstorm|next> | speed <value|reset|pause|resume> | spawn npc [count] [name] | list npcs | give wood <name> <amount> | status"
	if command == "speed" or command == "timescale":
		if tokens.size() < 2:
			return "Game speed: %.2f" % Engine.time_scale
		var speed_arg: String = str(tokens[1]).to_lower()
		if speed_arg == "reset" or speed_arg == "normal" or speed_arg == "1":
			Engine.time_scale = 1.0
			return "Game speed reset to 1.00"
		if speed_arg == "pause":
			Engine.time_scale = 0.0
			return "Game paused"
		if speed_arg == "resume":
			Engine.time_scale = 1.0
			return "Game resumed at 1.00"
		var parsed_speed: float = float(speed_arg)
		if parsed_speed <= 0.0:
			return "Game speed must be greater than 0"
		Engine.time_scale = clampf(parsed_speed, 0.05, 8.0)
		return "Game speed set to %.2f" % Engine.time_scale
	if command == "weather":
		if tokens.size() < 2:
			return "Weather: %s" % _current_weather
		var mode: String = str(tokens[1])
		if mode == "next":
			_transition_weather()
			return "Weather advanced to %s" % _current_weather
		if set_weather_mode(mode):
			return "Weather set to %s" % _current_weather
		return "Unknown weather mode: %s" % mode
	if command == "spawn" or command == "add":
		if tokens.size() < 2:
			return "Usage: spawn npc [count] [name]"
		var subject: String = str(tokens[1]).to_lower()
		if subject != "npc" and subject != "npcs" and subject != "villager" and subject != "villagers":
			return "Usage: spawn npc [count] [name]"
		var args: Array[String] = []
		for i in range(2, tokens.size()):
			args.append(str(tokens[i]))
		var count: int = 1
		var base_name: String = "DevNPC"
		if not args.is_empty() and args[0].is_valid_int():
			count = maxi(1, int(args[0]))
			if args.size() > 1:
				base_name = _join_string_array(args.slice(1, args.size()), " ")
		else:
			if not args.is_empty():
				base_name = _join_string_array(args, " ")
		var spawned_names: Array[String] = []
		for _i in range(count):
			var unique_name: String = _make_unique_name(base_name)
			spawn_villager(unique_name)
			spawned_names.append(unique_name)
		return "Spawned %d NPC(s): %s" % [spawned_names.size(), _join_string_array(spawned_names, ", ")]
	if command == "list":
		if tokens.size() >= 2 and str(tokens[1]).to_lower() == "npcs":
			var active_names: Array[String] = []
			for villager in _get_active_villagers():
				active_names.append(villager.villager_name)
			if active_names.is_empty():
				return "No active NPCs."
			return "Active NPCs (%d): %s" % [active_names.size(), _join_string_array(active_names, ", ")]
	if command == "status":
		return "Weather=%s | NPCs=%d | Living=%d" % [_current_weather, _get_active_villagers().size(), _count_living_villagers()]
	if command == "give":
		if tokens.size() < 4 or str(tokens[1]).to_lower() != "wood":
			return "Usage: give wood <name> <amount>"
		var amount_token: String = str(tokens[tokens.size() - 1])
		if not amount_token.is_valid_int():
			return "Usage: give wood <name> <amount>"
		var amount: int = maxi(1, int(amount_token))
		var target_name: String = ""
		for i in range(2, tokens.size() - 1):
			target_name += (" " if not target_name.is_empty() else "") + str(tokens[i])
		if target_name.is_empty():
			var villagers: Array[VillagerAgent] = _get_active_villagers()
			if villagers.is_empty():
				return "No active NPCs to give wood to."
			target_name = villagers[0].villager_name
		var target_villager: VillagerAgent = _get_villager_by_name(target_name)
		if target_villager == null:
			return "NPC not found: %s" % target_name
		target_villager.inventory["wood"] = maxi(0, int(target_villager.inventory.get("wood", 0)) + amount)
		target_villager._refresh_inventory_popup_counts()
		return "Gave %d wood to %s" % [amount, target_name]
	return "Unknown command: %s" % command_line

func set_weather_mode(mode: String) -> bool:
	var normalized: String = mode.strip_edges().to_lower()
	if normalized == "clear" or normalized == "none":
		_current_weather = "none"
	elif normalized == "rain" or normalized == "rainy":
		_current_weather = "rainy"
	elif normalized == "storm" or normalized == "thunderstorm":
		_current_weather = "thunderstorm"
	else:
		return false
	_weather_transition_timer = weather_transition_interval_seconds
	_sync_weather_visuals()
	return true
	if not _event_notification_panel.visible and not _event_notification_queue.is_empty():
		_show_next_event_notification()

func _setup_time_of_day_ui() -> void:
	if not show_time_of_day_ui:
		return
	_time_of_day_layer = CanvasLayer.new()
	_time_of_day_layer.name = "TimeOfDayUI"
	add_child(_time_of_day_layer)

	_time_of_day_panel = PanelContainer.new()
	_time_of_day_panel.anchor_left = 0.5
	_time_of_day_panel.anchor_right = 0.5
	_time_of_day_panel.anchor_top = 0.0
	_time_of_day_panel.anchor_bottom = 0.0
	_time_of_day_panel.offset_left = -128.0
	_time_of_day_panel.offset_right = 128.0
	_time_of_day_panel.offset_top = 58.0
	_time_of_day_panel.offset_bottom = 88.0
	_time_of_day_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.08, 0.12, 0.78)
	panel_style.border_color = Color(0.55, 0.73, 0.92, 0.92)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_top = 4.0
	panel_style.content_margin_bottom = 4.0
	_time_of_day_panel.add_theme_stylebox_override("panel", panel_style)
	_time_of_day_layer.add_child(_time_of_day_panel)

	_time_of_day_label = Label.new()
	_time_of_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_of_day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_of_day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_time_of_day_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_time_of_day_label.add_theme_font_size_override("font_size", 13)
	_time_of_day_label.add_theme_color_override("font_color", Color(0.97, 0.98, 1.0, 0.98))
	_time_of_day_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.7))
	_time_of_day_label.add_theme_constant_override("outline_size", 1)
	_time_of_day_panel.add_child(_time_of_day_label)

	_time_of_day_ui_timer = 0.0
	_update_time_of_day_ui(0.0)

func _update_time_of_day_ui(delta: float) -> void:
	if _time_of_day_panel == null or _time_of_day_label == null:
		return
	_time_of_day_panel.visible = show_time_of_day_ui
	if not show_time_of_day_ui:
		return
	_time_of_day_ui_timer -= delta
	if _time_of_day_ui_timer > 0.0:
		return
	_time_of_day_ui_timer = maxf(0.05, time_of_day_ui_refresh_seconds)
	var phase: float = fmod(_water_wave_time * SUN_CYCLE_SPEED, TAU)
	var day_fraction: float = fmod(phase / TAU, 1.0)
	if day_fraction < 0.0:
		day_fraction += 1.0
	var total_minutes: int = int(floor(day_fraction * 24.0 * 60.0))
	total_minutes = posmod(total_minutes, 24 * 60)
	var hour: int = total_minutes / 60
	var minute: int = total_minutes % 60
	var sun: float = _sun_intensity()
	var period_text: String = "☀️" if sun >= 0.5 else "🌑"
	_time_of_day_label.text = "%02d:%02d  %s" % [hour, minute, period_text]

func _count_conversation_threads() -> int:
	var total: int = 0
	for owner_variant in _npc_conversations.keys():
		var owner_name: String = str(owner_variant)
		var threads: Dictionary = _npc_conversations.get(owner_name, {})
		total += threads.size()
	return total

func _count_conversation_messages() -> int:
	var total: int = 0
	for owner_variant in _npc_conversations.keys():
		var owner_name: String = str(owner_variant)
		var threads: Dictionary = _npc_conversations.get(owner_name, {})
		for partner_variant in threads.keys():
			var partner_name: String = str(partner_variant)
			var thread: Array = threads.get(partner_name, [])
			total += thread.size()
	return total

func _count_context_items(context_key: String) -> int:
	var total: int = 0
	for npc_variant in _npc_llm_contexts.keys():
		var npc_name: String = str(npc_variant)
		var context: Dictionary = _npc_llm_contexts.get(npc_name, {})
		var items: Array = context.get(context_key, [])
		total += items.size()
	return total

func _update_runtime_counter_overlay() -> void:
	if _runtime_counter_label == null:
		return
	var active_villagers: Array[VillagerAgent] = _get_active_villagers()
	var active_count: int = active_villagers.size()
	var living_count: int = 0
	for villager in active_villagers:
		if not villager._is_dead:
			living_count += 1

	var dead_index_count: int = 0
	for name_variant in _npc_index_records.keys():
		var npc_name: String = str(name_variant)
		var rec: Dictionary = _npc_index_records.get(npc_name, {})
		if bool(rec.get("dead", false)):
			dead_index_count += 1

	var queue_count: int = _llm_request_queue.size()
	var active_requests: int = _llm_active_requests.size()
	var contexts: int = _npc_llm_contexts.size()
	var recent_events_total: int = _count_context_items("recent_events")
	var memories_total: int = _count_context_items("long_term_memories")
	var claim_events_total: int = _count_context_items("nearby_claim_events")
	var thoughts_owners: int = _npc_recent_thoughts.size()
	var claims_owners: int = _npc_claims.size()
	var claim_cooldowns: int = _claim_observation_cooldowns.size()
	var conv_threads: int = _count_conversation_threads()
	var conv_messages: int = _count_conversation_messages()
	var drop_count: int = _ground_drops.size()
	var direction_word_count: int = _direction_word_vectors.size()

	_runtime_counter_label.text = "Runtime Counters\n" \
		+ "NPC active/living/deadIndex: %d/%d/%d\n" % [active_count, living_count, dead_index_count] \
		+ "LLM queue/active/contexts: %d/%d/%d\n" % [queue_count, active_requests, contexts] \
		+ "Events/memories/claimEvents: %d/%d/%d\n" % [recent_events_total, memories_total, claim_events_total] \
		+ "Thought owners/claim owners: %d/%d\n" % [thoughts_owners, claims_owners] \
		+ "Claim cooldown keys: %d\n" % claim_cooldowns \
		+ "Conversation threads/messages: %d/%d\n" % [conv_threads, conv_messages] \
		+ "Ground drops/direction words: %d/%d" % [drop_count, direction_word_count]

func _setup_camera_follow_index_ui() -> void:
	_camera_follow_index_layer = CanvasLayer.new()
	_camera_follow_index_layer.name = "CameraFollowIndexUI"
	add_child(_camera_follow_index_layer)

	_camera_follow_index_panel = PanelContainer.new()
	_camera_follow_index_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_camera_follow_index_panel.offset_left = 10.0
	_camera_follow_index_panel.offset_top = 10.0
	_camera_follow_index_panel.offset_right = 318.0
	_camera_follow_index_panel.offset_bottom = _camera_follow_panel_expanded_bottom
	_camera_follow_index_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.09, 0.13, 0.82)
	panel_style.border_color = Color(0.38, 0.56, 0.72, 0.95)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 9
	panel_style.corner_radius_top_right = 9
	panel_style.corner_radius_bottom_left = 9
	panel_style.corner_radius_bottom_right = 9
	panel_style.content_margin_left = 8.0
	panel_style.content_margin_right = 8.0
	panel_style.content_margin_top = 6.0
	panel_style.content_margin_bottom = 6.0
	_camera_follow_index_panel.add_theme_stylebox_override("panel", panel_style)
	_camera_follow_index_layer.add_child(_camera_follow_index_panel)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 2)
	_camera_follow_index_panel.add_child(root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 6)
	root.add_child(header)

	var title := Label.new()
	title.text = "Village Ledger"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.88, 0.95, 1.0, 0.98))
	title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	title.add_theme_constant_override("outline_size", 2)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_camera_follow_toggle_button = Button.new()
	_camera_follow_toggle_button.custom_minimum_size = Vector2(24.0, 22.0)
	_camera_follow_toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_camera_follow_toggle_button.pressed.connect(_toggle_camera_follow_cards)
	header.add_child(_camera_follow_toggle_button)

	_camera_follow_subtitle = Label.new()
	_camera_follow_subtitle.text = "All villagers"
	_camera_follow_subtitle.add_theme_font_size_override("font_size", 10)
	_camera_follow_subtitle.add_theme_color_override("font_color", Color(0.66, 0.78, 0.90, 0.92))
	root.add_child(_camera_follow_subtitle)

	_camera_follow_scroller = ScrollContainer.new()
	_camera_follow_scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_camera_follow_scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_camera_follow_scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_camera_follow_scroller)

	_camera_follow_cards_root = VBoxContainer.new()
	_camera_follow_cards_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_camera_follow_cards_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_camera_follow_cards_root.add_theme_constant_override("separation", 6)
	_camera_follow_scroller.add_child(_camera_follow_cards_root)

	_apply_camera_follow_cards_visibility()

	_camera_follow_ui_timer = 0.0
	_update_camera_follow_index_ui()

func _toggle_camera_follow_cards() -> void:
	_camera_follow_cards_visible = not _camera_follow_cards_visible
	_apply_camera_follow_cards_visibility()
	if _camera_follow_cards_visible:
		_camera_follow_ui_timer = 0.0
		_update_camera_follow_index_ui()

func _apply_camera_follow_cards_visibility() -> void:
	if _camera_follow_toggle_button != null:
		_camera_follow_toggle_button.text = "-" if _camera_follow_cards_visible else "+"
	if _camera_follow_subtitle != null:
		_camera_follow_subtitle.visible = _camera_follow_cards_visible
	if _camera_follow_scroller != null:
		_camera_follow_scroller.visible = _camera_follow_cards_visible
	if _camera_follow_index_panel != null:
		_camera_follow_index_panel.offset_bottom = _camera_follow_panel_expanded_bottom if _camera_follow_cards_visible else _camera_follow_panel_collapsed_bottom

func _update_camera_follow_index_ui() -> void:
	if _camera_follow_index_panel == null or _camera_follow_cards_root == null:
		return
	_camera_follow_index_panel.visible = true
	_refresh_npc_index_records()
	var signature_parts: Array[String] = ["visible=%s" % str(_camera_follow_cards_visible)]
	for npc_name in _npc_index_order:
		var rec: Dictionary = _npc_index_records.get(npc_name, {})
		if rec.is_empty():
			continue
		signature_parts.append("%s|%s|%d|%d|%d" % [npc_name, str(rec.get("dead", false)), int(rec.get("hunger", 0)), int(rec.get("energy", 0)), int(rec.get("health", 0))])
	if not _camera_follow_cards_visible:
		var collapsed_sig: String = "|".join(signature_parts)
		if collapsed_sig == _camera_follow_ui_signature:
			return
		_camera_follow_ui_signature = collapsed_sig
		return
	var followed_name: String = ""
	if camera_cycle_enabled and _camera_phase_index >= 0 and not _camera_phase_order.is_empty():
		var phase: int = _camera_phase_order[_camera_phase_index]
		if phase == CAMERA_PHASE_PLAYER:
			var villagers := _get_active_villagers()
			if not villagers.is_empty():
				var followed_index: int = clampi(_camera_current_player_index, 0, villagers.size() - 1)
				followed_name = villagers[followed_index].villager_name
	signature_parts.append("followed=%s" % followed_name)
	var signature: String = "|".join(signature_parts)
	if signature == _camera_follow_ui_signature:
		return
	_camera_follow_ui_signature = signature

	for child in _camera_follow_cards_root.get_children():
		child.queue_free()

	if _npc_index_order.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No villagers yet"
		empty_label.add_theme_font_size_override("font_size", 11)
		empty_label.add_theme_color_override("font_color", Color(0.7, 0.76, 0.82, 0.9))
		_camera_follow_cards_root.add_child(empty_label)
		return

	for i in _npc_index_order.size():
		var npc_name: String = _npc_index_order[i]
		var record: Dictionary = _npc_index_records.get(npc_name, {})
		if record.is_empty():
			continue
		var is_dead: bool = bool(record.get("dead", false))
		var h: int = int(record.get("hunger", 0))
		var e: int = int(record.get("energy", 0))
		var hp: int = int(record.get("health", 0))
		var dead_reason: String = str(record.get("dead_reason", ""))
		var dead_time_text: String = str(record.get("dead_time_text", ""))
		_camera_follow_cards_root.add_child(_build_npc_index_card(i + 1, npc_name, h, e, hp, is_dead, npc_name == followed_name, dead_reason, dead_time_text))

func _build_npc_index_card(index: int, npc_name: String, hunger: int, energy: int, health: int, is_dead: bool, is_followed: bool, dead_reason: String = "", dead_time_text: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	if is_dead:
		card.tooltip_text = "Died: %s\nReason: %s" % [dead_time_text if not dead_time_text.is_empty() else "unknown", dead_reason if not dead_reason.is_empty() else "unknown"]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.22, 0.22, 0.68) if is_dead else Color(0.09, 0.16, 0.22, 0.92)
	style.border_color = Color(0.38, 0.38, 0.38, 0.88) if is_dead else (Color(0.98, 0.82, 0.36, 0.96) if is_followed else Color(0.38, 0.56, 0.72, 0.95))
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 6.0
	card.add_theme_stylebox_override("panel", style)

	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_on_npc_index_card_left_clicked(npc_name)
				get_tree().root.set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_on_npc_index_card_right_clicked(npc_name)
				get_tree().root.set_input_as_handled()
	)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	card.add_child(body)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	body.add_child(top_row)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dead_suffix: String = "  ✖ DEAD" if is_dead else ""
	name_label.text = "#%d  %s%s" % [index, npc_name.substr(0, 20), dead_suffix]
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 0.96) if is_dead else Color(0.92, 0.96, 1.0, 0.98))
	top_row.add_child(name_label)

	if is_followed:
		var cam_label := Label.new()
		cam_label.text = "📷"
		cam_label.add_theme_font_size_override("font_size", 13)
		cam_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42, 0.98))
		top_row.add_child(cam_label)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 6)
	body.add_child(stats_row)
	stats_row.add_child(_make_npc_stat_chip("H %d" % hunger, Color(0.33, 0.26, 0.08, 0.92), Color(0.99, 0.85, 0.44, 0.98), is_dead))
	stats_row.add_child(_make_npc_stat_chip("E %d" % energy, Color(0.08, 0.25, 0.15, 0.92), Color(0.58, 0.92, 0.62, 0.98), is_dead))
	stats_row.add_child(_make_npc_stat_chip("HP %d" % health, Color(0.33, 0.10, 0.10, 0.92), Color(1.0, 0.56, 0.56, 0.98), is_dead))

	return card

func _on_npc_index_card_left_clicked(npc_name: String) -> void:
	# Temporarily focus this villager, then resume automatic cycle.
	var villagers := _get_active_villagers()
	for i in villagers.size():
		if villagers[i].villager_name == npc_name:
			_camera_current_player_index = i
			_camera_manual_focus_name = npc_name
			_camera_manual_focus_time_left = maxf(0.1, camera_manual_focus_seconds)
			_camera_target_position = villagers[i].position
			_camera_target_zoom = _camera_base_zoom * camera_focus_zoom_multiplier
			break

func _on_npc_index_card_right_clicked(npc_name: String) -> void:
	# Open inspector for this villager
	if not npc_inspector_enabled:
		return
	_inspected_villager_name = npc_name
	_inspected_tent_cell = Vector2i(-9999, -9999)
	if _npc_inspector_panel != null:
		_npc_inspector_panel.visible = true
	_update_npc_inspector_ui()

func _make_npc_stat_chip(text: String, bg_color: Color, fg_color: Color, is_dead: bool) -> PanelContainer:
	var chip := PanelContainer.new()
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color(0.24, 0.24, 0.24, 0.86) if is_dead else bg_color
	chip_style.corner_radius_top_left = 5
	chip_style.corner_radius_top_right = 5
	chip_style.corner_radius_bottom_left = 5
	chip_style.corner_radius_bottom_right = 5
	chip_style.content_margin_left = 6.0
	chip_style.content_margin_right = 6.0
	chip_style.content_margin_top = 2.0
	chip_style.content_margin_bottom = 2.0
	chip.add_theme_stylebox_override("panel", chip_style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72, 0.95) if is_dead else fg_color)
	chip.add_child(label)
	return chip

func _refresh_npc_index_records() -> void:
	var now: float = Time.get_unix_time_from_system()
	var active: Array[VillagerAgent] = _get_active_villagers()
	var active_lookup: Dictionary = {}
	for villager in active:
		var v_name: String = villager.villager_name
		active_lookup[v_name] = true
		if not _npc_index_records.has(v_name):
			_npc_index_order.append(v_name)
		_npc_index_records[v_name] = {
			"dead": false,
			"hunger": int(villager.hunger),
			"energy": int(villager.energy),
			"health": int(villager.health),
			"dead_at": -1.0,
			"dead_reason": "",
			"dead_time_text": ""
		}

	var kept_order: Array[String] = []
	for npc_name in _npc_index_order:
		if not _npc_index_records.has(npc_name):
			continue
		var record: Dictionary = _npc_index_records[npc_name]
		var is_dead: bool = bool(record.get("dead", false))
		if is_dead and not active_lookup.has(npc_name):
			var dead_at: float = float(record.get("dead_at", now))
			if now - dead_at >= dead_npc_index_retention_seconds:
				_npc_index_records.erase(npc_name)
				continue
		kept_order.append(npc_name)
	_npc_index_order = kept_order

func _create_npc_inspector_card(title: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 13)
	box.add_child(label)

	var text := RichTextLabel.new()
	text.fit_content = false
	text.scroll_active = true
	text.bbcode_enabled = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text)

	return {"panel": panel, "text": text}

func _on_npc_inspector_close_pressed() -> void:
	_close_npc_inspector()

func _close_npc_inspector() -> void:
	_inspected_villager_name = ""
	_inspected_tent_cell = Vector2i(-9999, -9999)
	if _npc_inspector_panel != null:
		_npc_inspector_panel.visible = false

func _pick_villager_at_world_position(world_position: Vector2) -> VillagerAgent:
	var best: VillagerAgent = null
	var best_dist: float = npc_inspector_click_radius
	for villager in _get_active_villagers():
		var d: float = villager.position.distance_to(world_position)
		if d <= best_dist:
			best = villager
			best_dist = d
	return best

func _pick_tent_cell_at_world_position(world_position: Vector2) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-9999, -9999)
	var best_dist: float = npc_inspector_click_radius
	# Search tracked tents
	for cell_variant in _tent_decay_state.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		var layer: TileMapLayer = _find_tent_layer_for_cell(cell)
		var cell_world: Vector2
		if layer != null:
			cell_world = layer.to_global(layer.map_to_local(cell))
		elif terrain != null:
			cell_world = terrain.to_global(terrain.map_to_local(cell))
		else:
			continue
		var d: float = cell_world.distance_to(world_position)
		if d <= best_dist:
			best_dist = d
			best_cell = cell
	# Also scan tile layers for any tent tiles not yet tracked
	for scan_layer in [_tent_build_layer, _tent_behind_layer]:
		if scan_layer == null:
			continue
		var local_pos: Vector2 = scan_layer.to_local(world_position)
		var center_cell: Vector2i = scan_layer.local_to_map(local_pos)
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var check_cell: Vector2i = center_cell + Vector2i(dx, dy)
				if _tent_decay_state.has(check_cell):
					continue
				if not _is_configured_tent_tile(scan_layer, check_cell) and not _is_configured_collapsed_tent_tile(scan_layer, check_cell):
					continue
				var cell_world: Vector2 = scan_layer.to_global(scan_layer.map_to_local(check_cell))
				var d: float = cell_world.distance_to(world_position)
				if d <= best_dist:
					best_dist = d
					best_cell = check_cell
					_register_or_refresh_tent_decay(check_cell)
	return best_cell

func _format_dict_lines(title: String, data: Dictionary) -> Array[String]:
	var lines: Array[String] = [title]
	var keys: Array = data.keys()
	keys.sort()
	for key in keys:
		lines.append("  %s: %s" % [str(key), str(data.get(key, ""))])
	if keys.is_empty():
		lines.append("  (none)")
	return lines

func _format_memory_lines(title: String, memories: Array) -> Array[String]:
	var lines: Array[String] = []
	if not title.is_empty():
		lines.append(title)
	if memories.is_empty():
		lines.append("  (none)")
		return lines
	var start: int = maxi(0, memories.size() - npc_inspector_memory_rows)
	for i in range(start, memories.size()):
		var row: Variant = memories[i]
		if row is Dictionary:
			var row_dict: Dictionary = row
			var type_text: String = str(row_dict.get("type", row_dict.get("text", "")))
			var text: String = str(row_dict.get("text", ""))
			if text.is_empty():
				text = str(row_dict)
			lines.append("  - %s %s" % [type_text, text])
		else:
			lines.append("  - %s" % str(row))
	return lines

func _append_recent_thought(villager_name: String, thought: String) -> void:
	if thought.strip_edges().is_empty():
		return
	var thoughts: Array = _npc_recent_thoughts.get(villager_name, [])
	thoughts.append({
		"t": Time.get_unix_time_from_system(),
		"text": thought.substr(0, 220)
	})
	if thoughts.size() > 24:
		thoughts = thoughts.slice(thoughts.size() - 24, thoughts.size())
	_npc_recent_thoughts[villager_name] = thoughts

func _format_thought_lines(title: String, thoughts: Array) -> Array[String]:
	var lines: Array[String] = []
	if not title.is_empty():
		lines.append(title)
	if thoughts.is_empty():
		lines.append("  (none)")
		return lines
	var start: int = maxi(0, thoughts.size() - npc_inspector_thought_rows)
	for i in range(start, thoughts.size()):
		var row: Variant = thoughts[i]
		if row is Dictionary:
			var row_dict: Dictionary = row
			lines.append("  - %s" % str(row_dict.get("text", "")))
		else:
			lines.append("  - %s" % str(row))
	return lines

func _format_timestamp(unix_time: float) -> String:
	if unix_time <= 0.0:
		return "unknown"
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(int(unix_time))
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
		int(dt.get("second", 0))
	]

func _push_conversation_entry(owner_name: String, other_name: String, entry: Dictionary) -> void:
	var owner_threads: Dictionary = _npc_conversations.get(owner_name, {})
	var thread: Array = owner_threads.get(other_name, [])
	thread.append(entry)
	var limit: int = maxi(2, npc_conversation_history_limit)
	if thread.size() > limit:
		thread = thread.slice(thread.size() - limit, thread.size())
	owner_threads[other_name] = thread
	_npc_conversations[owner_name] = owner_threads

func _append_conversation_message(from_name: String, to_name: String, text: String) -> void:
	var clean_text: String = text.strip_edges().substr(0, 120)
	if clean_text.is_empty():
		return
	var entry := {
		"t": Time.get_unix_time_from_system(),
		"from": from_name,
		"to": to_name,
		"text": clean_text
	}
	_push_conversation_entry(from_name, to_name, entry)
	_push_conversation_entry(to_name, from_name, entry)

func _get_recent_conversation(owner_name: String, other_name: String, limit: int = 10) -> Array:
	if owner_name.is_empty() or other_name.is_empty():
		return []
	var owner_threads: Dictionary = _npc_conversations.get(owner_name, {})
	var thread: Array = owner_threads.get(other_name, [])
	if limit <= 0:
		return thread.duplicate(true)
	if thread.size() <= limit:
		return thread.duplicate(true)
	return thread.slice(thread.size() - limit, thread.size())

func _format_conversation_lines(owner_name: String, threads: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var partners: Array = threads.keys()
	partners.sort()
	if partners.is_empty():
		lines.append("  (no conversations yet)")
		return lines
	for partner_variant in partners:
		var partner_name: String = str(partner_variant)
		lines.append("With %s:" % partner_name)
		var recent: Array = _get_recent_conversation(owner_name, partner_name, npc_conversation_history_limit)
		if recent.is_empty():
			lines.append("  (none)")
			continue
		for row in recent:
			if row is Dictionary:
				var row_dict: Dictionary = row
				var from_name: String = str(row_dict.get("from", ""))
				var prefix: String = "You" if from_name == owner_name else partner_name
				lines.append("  %s: %s" % [prefix, str(row_dict.get("text", ""))])
			else:
				lines.append("  %s" % str(row))
		lines.append("")
	if not lines.is_empty() and lines[lines.size() - 1].is_empty():
		lines.remove_at(lines.size() - 1)
	return lines

func _update_npc_inspector_ui() -> void:
	if _npc_inspector_panel == null:
		return
	if not npc_inspector_enabled:
		_npc_inspector_panel.visible = false
		return
	if _inspected_villager_name.is_empty() and _inspected_tent_cell == Vector2i(-9999, -9999):
		_npc_inspector_panel.visible = false
		return
	if _inspected_villager_name.is_empty() and _inspected_tent_cell != Vector2i(-9999, -9999):
		var tent_entry: Dictionary = _tent_decay_state.get(_inspected_tent_cell, {})
		if tent_entry.is_empty():
			_close_npc_inspector()
			return
		var tent_health: float = float(tent_entry.get("health", tent_max_health))
		var tent_collapsed: bool = bool(tent_entry.get("collapsed", false))
		var collapse_timer: float = float(tent_entry.get("collapse_timer", 0.0))
		var owner_name: String = str(_home_owner_by_cell.get(_inspected_tent_cell, tent_entry.get("owner", "")))
		var tent_layer: TileMapLayer = _find_tent_layer_for_cell(_inspected_tent_cell)
		var tent_world: Vector2 = terrain.to_global(terrain.map_to_local(_inspected_tent_cell)) if terrain != null else Vector2.ZERO
		if tent_layer != null:
			tent_world = tent_layer.to_global(tent_layer.map_to_local(_inspected_tent_cell))

		_npc_inspector_title.text = "Inspector - TP/Tent"
		var status_text: String = "Collapsed" if tent_collapsed else "Standing"
		var overview_lines: Array[String] = [
			"Type: TP/Tent",
			"Status: %s" % status_text,
			"Health: %.1f / %.1f" % [maxf(0.0, tent_health), tent_max_health],
			"Cell: (%d, %d)" % [_inspected_tent_cell.x, _inspected_tent_cell.y],
			"World: (%.1f, %.1f)" % [tent_world.x, tent_world.y],
			"Owner: %s" % (owner_name if not owner_name.is_empty() else "(none)"),
			"Decay Rate: %.3f/s" % maxf(0.0, tent_decay_per_second),
			"Repair Cost: %d wood" % max(1, tent_repair_wood_cost),
			"Repair Gain: %.1f health" % maxf(1.0, tent_repair_health_gain)
		]
		if tent_collapsed:
			overview_lines.append("Repair Window Left: %.1fs" % maxf(0.0, collapse_timer))
		else:
			overview_lines.append("Repair Needed: %s" % ("Yes" if _tent_requires_repair(_inspected_tent_cell) else "No"))

		_npc_overview_text.text = "\n".join(overview_lines)
		_npc_genes_text.text = "N/A for structures"
		_npc_memories_text.text = "N/A for structures"
		_npc_events_text.text = "N/A for structures"
		_npc_thoughts_text.text = "N/A for structures"
		if _npc_conversations_text != null:
			_npc_conversations_text.text = "N/A for structures"
		_npc_inspector_panel.visible = true
		return

	var record: Dictionary = (_npc_index_records.get(_inspected_villager_name, {}) as Dictionary).duplicate(true)
	var villager: VillagerAgent = _get_villager_by_name(_inspected_villager_name)
	var is_dead_record: bool = villager == null and bool(record.get("dead", false))
	if villager == null and not is_dead_record:
		_close_npc_inspector()
		return

	var inventory: Dictionary = villager.inventory.duplicate(true) if villager != null else (record.get("inventory_snapshot", {}) as Dictionary).duplicate(true)
	var physical: Dictionary = (_npc_physical_genes.get(_inspected_villager_name, {}) as Dictionary).duplicate(true)
	var llm_genes: Dictionary = (_npc_llm_genes.get(_inspected_villager_name, {}) as Dictionary).duplicate(true)
	var context: Dictionary = (_npc_llm_contexts.get(_inspected_villager_name, {}) as Dictionary).duplicate(true)
	var memories: Array = context.get("long_term_memories", [])
	var events: Array = context.get("recent_events", [])
	var thoughts: Array = _npc_recent_thoughts.get(_inspected_villager_name, [])
	var conversations: Dictionary = (_npc_conversations.get(_inspected_villager_name, {}) as Dictionary).duplicate(true)

	var display_name: String = villager.villager_name if villager != null else _inspected_villager_name
	var hunger_value: int = int(villager.hunger) if villager != null else int(record.get("hunger", 0))
	var energy_value: int = int(villager.energy) if villager != null else int(record.get("energy", 0))
	var health_value: int = int(villager.health) if villager != null else int(record.get("health", 0))
	var hydration_value: int = int(villager.hydration) if villager != null else int(record.get("hydration", 0))
	var body_temp_value: float = villager.body_temperature_c if villager != null else float(record.get("body_temp_c", 0.0))
	var ambient_temp_value: float = villager.last_ambient_temperature_c if villager != null else float(record.get("ambient_temp_c", 0.0))
	var humidity_value: float = villager.last_humidity if villager != null else float(record.get("humidity", 0.0))
	var position_value: Vector2 = villager.position if villager != null else Vector2(float(record.get("pos_x", 0.0)), float(record.get("pos_y", 0.0)))
	var dead_reason: String = str(record.get("dead_reason", ""))
	var dead_time_text: String = str(record.get("dead_time_text", ""))

	_npc_inspector_title.text = "NPC Inspector - %s" % display_name
	var overview_lines: Array[String] = [
		"Name: %s" % display_name,
		"Status: %s" % ("DEAD" if is_dead_record else "ALIVE"),
		"Vitals: H:%d E:%d HP:%d W:%d" % [hunger_value, energy_value, health_value, hydration_value],
		"Thermal: Body %.1fC | Ambient %.1fC | Humidity %d%%" % [body_temp_value, ambient_temp_value, int(humidity_value * 100.0)],
		"Position: (%.1f, %.1f)" % [position_value.x, position_value.y],
		"",
	]
	if is_dead_record:
		overview_lines.append("Death: %s" % (dead_time_text if not dead_time_text.is_empty() else "unknown"))
		overview_lines.append("Death Reason: %s" % (dead_reason if not dead_reason.is_empty() else "unknown"))
		overview_lines.append("")
	overview_lines.append_array(_format_dict_lines("Inventory:", inventory))

	var genes_lines: Array[String] = []
	genes_lines.append_array(_format_dict_lines("Physical Genes:", physical))
	genes_lines.append("")
	genes_lines.append_array(_format_dict_lines("LLM Genes:", llm_genes))

	_npc_overview_text.text = "\n".join(overview_lines)
	_npc_genes_text.text = "\n".join(genes_lines)
	_npc_memories_text.text = "\n".join(_format_memory_lines("", memories))
	_npc_events_text.text = "\n".join(_format_memory_lines("", events))
	_npc_thoughts_text.text = "\n".join(_format_thought_lines("", thoughts))
	if _npc_conversations_text != null:
		_npc_conversations_text.text = "\n".join(_format_conversation_lines(_inspected_villager_name, conversations))
	_npc_inspector_panel.visible = true

func _initialize_llm_bridge() -> void:
	if not llm_use_chatgpt:
		return

	var provider: String = _get_llm_provider()
	if provider == "openai":
		_llm_api_key = OS.get_environment("OPENAI_API_KEY").strip_edges()
		if _llm_api_key.is_empty():
			_llm_api_key = OS.get_environment("CHATGPT_API_KEY").strip_edges()
		if _llm_api_key.is_empty():
			_llm_api_key = OS.get_environment("OPENAI_KEY").strip_edges()

	if provider == "openai" and _llm_api_key.is_empty():
		push_warning("OpenAI mode is enabled but no API key was found in OPENAI_API_KEY/CHATGPT_API_KEY/OPENAI_KEY.")
		return

func _pump_llm_queue() -> void:
	if not llm_use_chatgpt:
		return
	if _llm_requests_paused_for_conversation:
		return
	if _has_pending_generic_conversation_generation():
		return
	while _llm_active_requests.size() < llm_max_concurrent_requests and not _llm_request_queue.is_empty():
		var villager_name: String = _llm_request_queue.pop_front()
		if not _npc_pending_llm_state.has(villager_name):
			continue
		if not _npc_llm_genes.has(villager_name) or not _npc_physical_genes.has(villager_name):
			continue
		if _llm_active_requests.has(villager_name):
			continue
		_start_llm_request(villager_name)

func _pump_baby_name_prefetch() -> void:
	if not _llm_backend_ready():
		return
	if _llm_requests_paused_for_conversation or _has_active_locked_conversation():
		return
	if _has_pending_generic_conversation_generation():
		return
	if _prefetched_baby_names.size() >= _baby_name_prefetch_target_pool_size:
		return
	if _baby_name_prefetch_request != null and is_instance_valid(_baby_name_prefetch_request):
		return
	if not _llm_request_queue.is_empty() or not _llm_active_requests.is_empty():
		return
	_request_baby_name_prefetch()

func _request_baby_name_prefetch() -> void:
	var system_prompt: String = "Return ONLY JSON with keys speech_text, first_name, and last_name. speech_text must be one natural sentence of dialogue where the speaker proposes a baby name to the listener. Use short human names, title case, no symbols, no markdown, no extra keys."
	var user_payload: Dictionary = {
		"speaker": "ParentA",
		"listener": "ParentB",
		"turn": "propose",
		"prior_line": "We need a first and last name for our baby.",
		"current_candidate": {"first_name": "", "last_name": ""}
	}
	var request := HTTPRequest.new()
	request.timeout = maxf(_get_llm_request_timeout_seconds(), 45.0)
	add_child(request)
	_baby_name_prefetch_request = request
	request.request_completed.connect(_on_baby_name_prefetch_completed.bind(request), CONNECT_ONE_SHOT)
	var err: int = request.request(
		llm_openai_endpoint,
		_build_llm_request_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify(_build_baby_name_request_body(system_prompt, JSON.stringify(user_payload)))
	)
	if err != OK:
		_abort_http_request(request)
		_baby_name_prefetch_request = null

func _on_baby_name_prefetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest) -> void:
	if is_instance_valid(request):
		request.queue_free()
	_baby_name_prefetch_request = null
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return
	var response_text: String = body.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(response_text)
	var content: String = ""
	if parsed is Dictionary:
		content = _extract_llm_response_content(parsed)
	if content.is_empty():
		content = response_text
	var payload: Dictionary = _extract_baby_name_dialogue_payload(content)
	var speech_text: String = str(payload.get("speech_text", "")).strip_edges()
	var first_name: String = _sanitize_name_part(str(payload.get("first_name", "")))
	var last_name: String = _sanitize_name_part(str(payload.get("last_name", "")))
	if first_name.is_empty() or last_name.is_empty():
		return
	_prefetched_baby_names.append({"speech_text": speech_text, "first_name": first_name, "last_name": last_name})
	if _prefetched_baby_names.size() > _baby_name_prefetch_target_pool_size:
		_prefetched_baby_names = _prefetched_baby_names.slice(_prefetched_baby_names.size() - _baby_name_prefetch_target_pool_size, _prefetched_baby_names.size())

func _cancel_all_llm_requests_for_conversation() -> void:
	for queued_name in _llm_request_queue:
		_npc_llm_status[queued_name] = "paused_for_conversation"
	_llm_request_queue.clear()

	var active_names: Array = _llm_active_requests.keys()
	for name_variant in active_names:
		var villager_name: String = str(name_variant)
		var request_variant: Variant = _llm_active_requests.get(villager_name, null)
		if request_variant is HTTPRequest and is_instance_valid(request_variant):
			_abort_http_request(request_variant as HTTPRequest)
		_npc_llm_status[villager_name] = "paused_for_conversation"
		_npc_last_llm_error[villager_name] = "paused_for_conversation"
	_llm_active_requests.clear()
	if _baby_name_prefetch_request != null and is_instance_valid(_baby_name_prefetch_request):
		_abort_http_request(_baby_name_prefetch_request)
		_baby_name_prefetch_request = null

func _start_llm_request(villager_name: String) -> void:
	var state: Dictionary = _npc_pending_llm_state[villager_name]
	var llm_genes: Dictionary = _npc_llm_genes[villager_name]
	var physical_genes: Dictionary = _npc_physical_genes[villager_name]
	var context: Dictionary = _npc_llm_contexts.get(villager_name, {})
	var prompt_payload: Dictionary = _compact_llm_prompt_payload(villager_name, state, physical_genes, llm_genes, context)
	var request_body: Dictionary = _build_llm_request_body(prompt_payload)
	var headers: PackedStringArray = _build_llm_request_headers()
	var request := HTTPRequest.new()
	request.timeout = _get_llm_request_timeout_seconds()
	add_child(request)
	request.request_completed.connect(_on_llm_request_completed.bind(villager_name, request), CONNECT_ONE_SHOT)

	var err: int = request.request(
		llm_openai_endpoint,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(request_body)
	)
	if err != OK:
		_npc_llm_status[villager_name] = "request_error"
		_npc_last_llm_error[villager_name] = "request error %d" % err
		_log_llm(villager_name, "request start failed: error=%d endpoint=%s" % [err, llm_openai_endpoint])
		_abort_http_request(request)
		push_warning("Failed to start ChatGPT request for %s (error %d)." % [villager_name, err])
		return

	_llm_active_requests[villager_name] = request
	_npc_last_llm_request_time[villager_name] = Time.get_unix_time_from_system()
	_npc_llm_status[villager_name] = "requesting"
	if llm_debug_log_to_output:
		_log_llm(villager_name, "requesting endpoint=%s model=%s timeout=%.1fs payload=%s" % [llm_openai_endpoint, llm_model, request.timeout, JSON.stringify(request_body).substr(0, 320)])

func _get_llm_request_timeout_seconds() -> float:
	if _get_llm_provider() == "ollama":
		return maxf(llm_request_timeout_seconds, 45.0)
	return llm_request_timeout_seconds

func _get_llm_provider() -> String:
	var provider: String = llm_provider.strip_edges().to_lower()
	if provider.is_empty():
		provider = "ollama"
	return provider

func _build_llm_request_headers() -> PackedStringArray:
	var headers: PackedStringArray = ["Content-Type: application/json"]
	if _get_llm_provider() == "openai" and not _llm_api_key.is_empty():
		headers.append("Authorization: Bearer %s" % _llm_api_key)
	return headers

func _abort_http_request(request: HTTPRequest) -> void:
	if not is_instance_valid(request):
		return
	request.cancel_request()
	request.queue_free()

func _log_llm(villager_name: String, message: String) -> void:
	if not llm_debug_log_to_output:
		return
	print("[LLM][%s] %s" % [villager_name, message])

func _slice_recent_items(items: Array, limit: int) -> Array:
	if limit <= 0:
		return []
	if items.size() <= limit:
		return items.duplicate(true)
	return items.slice(items.size() - limit, items.size())

func _compact_conversation_entries(entries: Array, limit: int, text_limit: int = 72) -> Array:
	var compact: Array = []
	var rows: Array = _slice_recent_items(entries, limit)
	for row in rows:
		if row is Dictionary:
			var d: Dictionary = row
			compact.append({
				"from": str(d.get("from", "")).substr(0, 20),
				"text": str(d.get("text", "")).substr(0, text_limit)
			})
		else:
			compact.append({
				"from": "",
				"text": str(row).substr(0, text_limit)
			})
	return compact

func _build_state_relevance_tags(state: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var hunger: float = float(state.get("hunger", 100.0))
	var energy: float = float(state.get("energy", 100.0))
	if hunger < 35.0:
		tags.append("food")
		tags.append("apple")
		tags.append("drop")
	if energy < 30.0:
		tags.append("home")
		tags.append("rest")
		tags.append("sleep")
	if bool(state.get("has_build_site", false)):
		tags.append("build")
		tags.append("wood")
		tags.append("home")
	if bool(state.get("has_chop_target", false)):
		tags.append("tree")
		tags.append("wood")
	if bool(state.get("is_stuck", false)):
		tags.append("stuck")
		tags.append("blocked")
		tags.append("path")
	if bool(state.get("is_swimming", false)):
		tags.append("water")
		tags.append("swim")
	if bool(state.get("has_player_target", false)):
		tags.append("player")
		tags.append("talk")
	return tags

func _select_relevant_context_items(items: Array, limit: int, relevance_tags: Array[String]) -> Array:
	if limit <= 0 or items.is_empty():
		return []
	var selected: Array = []
	for i in range(items.size() - 1, -1, -1):
		if selected.size() >= limit:
			break
		var row: Variant = items[i]
		if not (row is Dictionary):
			continue
		var row_dict: Dictionary = row
		var text: String = str(row_dict.get("text", "")).to_lower()
		if relevance_tags.is_empty():
			selected.append(row_dict)
			continue
		for tag in relevance_tags:
			if text.findn(tag) >= 0:
				selected.append(row_dict)
				break
	selected.reverse()
	if selected.is_empty():
		return _slice_recent_items(items, limit)
	return selected

func _compact_llm_prompt_payload(villager_name: String, state: Dictionary, physical_genes: Dictionary, llm_genes: Dictionary, context: Dictionary) -> Dictionary:
	var compact_mode: bool = llm_compact_prompt_mode
	var event_limit: int = mini(llm_prompt_recent_event_limit, 2) if compact_mode else llm_prompt_recent_event_limit
	var memory_limit: int = mini(llm_prompt_memory_limit, 1) if compact_mode else llm_prompt_memory_limit
	var relevance_tags: Array[String] = _build_state_relevance_tags(state)
	var recent_events: Array = _select_relevant_context_items(context.get("recent_events", []), event_limit, relevance_tags)
	var long_term_memories: Array = _select_relevant_context_items(context.get("long_term_memories", []), memory_limit, relevance_tags)
	var nearest_player: Dictionary = state.get("nearest_player", {})
	if not nearest_player.is_empty():
		nearest_player = nearest_player.duplicate(true)
		var nearest_conversation_limit: int = 1 if compact_mode else mini(4, npc_conversation_history_limit)
		nearest_player["recent_conversation"] = _compact_conversation_entries(nearest_player.get("recent_conversation", []), nearest_conversation_limit)
		var nearest_player_minimal := {
			"name": str(nearest_player.get("name", "")),
			"distance": float(nearest_player.get("distance", INF)),
			"recent_conversation": nearest_player.get("recent_conversation", [])
		}
		nearest_player = nearest_player_minimal
	var nearest_water_variant: Variant = state.get("nearest_water_world_position", null)
	var nearest_water: Dictionary = {}
	if nearest_water_variant is Vector2:
		var nearest_water_pos: Vector2 = nearest_water_variant
		nearest_water = {"x": nearest_water_pos.x, "y": nearest_water_pos.y}
	var inventory: Dictionary = state.get("inventory", {})
	var compact_status: Dictionary = {
		"hunger": float(state.get("hunger", 100.0)),
		"energy": float(state.get("energy", 100.0)),
		"health": float(state.get("health", 100.0)),
		"is_horny": bool(state.get("is_horny", false)),
		"is_swimming": bool(state.get("is_swimming", false)),
		"is_stuck": bool(state.get("is_stuck", false)),
		"stuck_for_seconds": float(state.get("stuck_for_seconds", 0.0)),
		"stuck_target": str(state.get("stuck_target", "")),
		"wood": int(inventory.get("wood", 0)),
		"apple": int(inventory.get("apple", 0)),
		"seed": int(inventory.get("seed", 0))
	}
	compact_status["nearest_water"] = nearest_water
	var payload: Dictionary = {
		"villager_name": villager_name,
		"goals": _slice_recent_items(context.get("goals", []), 1) if compact_mode else context.get("goals", []),
		"memory_policy": {
			"requires_remember_flag": true,
			"allowed_memory_types": context.get("allowed_memory_types", ["status", "social"])
		},
		"physical": {
			"decision_interval_seconds": float(physical_genes.get("llm_decision_interval_seconds", 4.0))
		},
		"personality": {
			"primary_goal": str(llm_genes.get("primary_goal", "explore")),
			"swim_fear": float(llm_genes.get("swim_fear", 0.5)),
			"compassion": float(llm_genes.get("compassion", 0.5)),
			"selfish": float(llm_genes.get("selfish", 0.5)),
			"talkative": float(llm_genes.get("talkative", 0.5)),
			"bravery": float(llm_genes.get("bravery", 0.5))
		},
		"status": compact_status if compact_mode else {
			"hunger": float(state.get("hunger", 100.0)),
			"energy": float(state.get("energy", 100.0)),
			"health": float(state.get("health", 100.0)),
			"is_horny": bool(state.get("is_horny", false)),
			"is_swimming": bool(state.get("is_swimming", false)),
			"is_stuck": bool(state.get("is_stuck", false)),
			"stuck_for_seconds": float(state.get("stuck_for_seconds", 0.0)),
			"stuck_target": str(state.get("stuck_target", "")),
			"wood": int(inventory.get("wood", 0)),
			"apple": int(inventory.get("apple", 0)),
			"seed": int(inventory.get("seed", 0)),
			"has_drop_target": bool(state.get("has_drop_target", false)),
			"has_player_target": bool(state.get("has_player_target", false)),
			"player_target_name": str(state.get("player_target_name", "")),
			"has_chop_target": bool(state.get("has_chop_target", false)),
			"has_build_site": bool(state.get("has_build_site", false)),
			"has_home_target": bool(state.get("has_home_target", false)),
			"is_inside_home": bool(state.get("is_inside_home", false)),
			"nearest_water": nearest_water
		},
		"recent_events": recent_events,
		"long_term_memories": long_term_memories,
		"allowed_actions": ["cut_tree", "collect_drop", "go_home", "build", "move_random", "move_to", "go_to_player", "talk_to_nearby_player", "fish", "swim", "claim_tile", "trade_with_nearby_player", "heal_nearby_player", "build_campfire", "light_campfire", "extinguish_campfire", "destroy_campfire"]
	}
	if not nearest_player.is_empty():
		var target_name: String = str(nearest_player.get("name", ""))
		var direct_thread_limit: int = 2 if compact_mode else mini(5, npc_conversation_history_limit)
		payload["conversation_context"] = {
			"target_name": target_name,
			"recent_thread": _compact_conversation_entries(_get_recent_conversation(villager_name, target_name, direct_thread_limit), direct_thread_limit)
		}
		payload["nearest_player"] = nearest_player
	return payload

func _build_llm_request_body(prompt_payload: Dictionary) -> Dictionary:
	var system_prompt: String = "Return JSON only: action, preferred_target, goal_text. Optional: world_position{x,y} for move_to/claim_tile, target_player_name for player actions, speech_text for talk/trade (one sentence, context-aware), trade fields give_item/give_amount/request_item/request_amount, memory_entry/remember/memory_type(status|resources|social|conflict). Allowed actions: cut_tree, collect_drop, go_home, build, move_random, move_to, go_to_player, talk_to_nearby_player, fish, swim, claim_tile, trade_with_nearby_player, heal_nearby_player, build_campfire, light_campfire, extinguish_campfire, destroy_campfire. Use only provided state."
	var user_prompt: String = JSON.stringify(prompt_payload)
	var messages: Array = [
		{
			"role": "system",
			"content": system_prompt
		},
		{
			"role": "user",
			"content": user_prompt
		}
	]

	if _get_llm_provider() == "ollama":
		return {
			"model": llm_model,
			"stream": false,
			"format": "json",
			"keep_alive": "10m",
			"system": system_prompt,
			"prompt": user_prompt,
			"options": {
				"temperature": llm_temperature,
				"num_predict": maxi(8, llm_num_predict)
			}
		}

	return {
		"model": llm_model,
		"temperature": llm_temperature,
		"response_format": {"type": "json_object"},
		"messages": messages
	}

func _llm_backend_ready() -> bool:
	if not llm_use_chatgpt:
		return false
	if _get_llm_provider() == "openai":
		return not _llm_api_key.is_empty()
	return true

func _on_llm_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, villager_name: String, request: HTTPRequest) -> void:
	_llm_active_requests.erase(villager_name)
	_npc_last_llm_request_time[villager_name] = Time.get_unix_time_from_system()
	if is_instance_valid(request):
		request.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_npc_llm_status[villager_name] = "http_error"
		_npc_last_llm_error[villager_name] = "http %d result %d" % [response_code, result]
		_log_llm(villager_name, "http_error result=%d code=%d" % [result, response_code])
		_append_recent_event(villager_name, "llm_http_error")
		return

	var body_text: String = body.get_string_from_utf8()
	_log_llm(villager_name, "response body=%s" % body_text.substr(0, 320))
	var parsed: Variant = JSON.parse_string(body_text)
	if not (parsed is Dictionary):
		_npc_llm_status[villager_name] = "parse_error"
		_npc_last_llm_error[villager_name] = "body parse failed"
		_log_llm(villager_name, "parse_error body parse failed")
		_append_recent_event(villager_name, "llm_parse_error")
		return

	var response_dict: Dictionary = parsed
	var content: String = _extract_llm_response_content(response_dict)
	if content.is_empty():
		_npc_llm_status[villager_name] = "empty_content"
		_npc_last_llm_error[villager_name] = "empty content"
		_log_llm(villager_name, "empty_content extracted response was empty")
		_append_recent_event(villager_name, "llm_empty_content")
		return

	_log_llm(villager_name, "response content=%s" % content.substr(0, 220))
	var decision_variant: Variant = JSON.parse_string(content)
	if not (decision_variant is Dictionary):
		_npc_llm_status[villager_name] = "non_json"
		_npc_last_llm_error[villager_name] = content.substr(0, 80)
		_log_llm(villager_name, "non_json content=%s" % content.substr(0, 220))
		_append_recent_event(villager_name, "llm_non_json_content")
		return

	var decision: Dictionary = _sanitize_llm_decision(decision_variant)
	if decision.is_empty():
		_npc_llm_status[villager_name] = "invalid_decision"
		_npc_last_llm_error[villager_name] = "sanitized empty"
		_log_llm(villager_name, "invalid_decision raw=%s" % JSON.stringify(decision_variant).substr(0, 220))
		_append_recent_event(villager_name, "llm_invalid_decision")
		return

	decision["decision_source"] = _get_llm_provider()
	decision["llm_status"] = "ready"
	_npc_last_llm_decisions[villager_name] = decision
	var villager: VillagerAgent = _get_villager_by_name(villager_name)
	if villager != null:
		villager.apply_ready_llm_decision(decision)
		_npc_last_llm_decisions.erase(villager_name)
	_append_recent_thought(villager_name, "Action: %s | Goal: %s" % [str(decision.get("action", "")), str(decision.get("goal_text", ""))])
	var thought_memory_entry: String = str(decision.get("memory_entry", ""))
	if not thought_memory_entry.strip_edges().is_empty():
		_append_recent_thought(villager_name, thought_memory_entry)
	_npc_llm_status[villager_name] = "ready"
	_npc_last_llm_error.erase(villager_name)
	var now: float = Time.get_unix_time_from_system()
	_npc_last_llm_success_time[villager_name] = now
	_npc_last_llm_request_time[villager_name] = now
	_log_llm(villager_name, "decision_ready decision=%s" % JSON.stringify(decision).substr(0, 220))
	_append_recent_event(villager_name, "llm_decision_ready")

func _extract_llm_response_content(response_dict: Dictionary) -> String:
	if _get_llm_provider() == "ollama":
		return str(response_dict.get("response", "")).strip_edges()

	var choices: Array = response_dict.get("choices", [])
	if choices.is_empty() or not (choices[0] is Dictionary):
		return ""
	var message: Dictionary = (choices[0] as Dictionary).get("message", {})
	return str(message.get("content", "")).strip_edges()

func _coerce_decision_string(value: Variant, default_value: String = "") -> String:
	if value == null:
		return default_value
	var text: String = str(value).strip_edges()
	if text.is_empty():
		return default_value
	if text == "<null>":
		return default_value
	return text

func _coerce_decision_bool(value: Variant, default_value: bool = false) -> bool:
	if value is bool:
		return bool(value)
	if value is int:
		return int(value) != 0
	if value is float:
		return absf(float(value)) > 0.0001
	if value is String:
		var lowered: String = str(value).strip_edges().to_lower()
		if lowered in ["true", "1", "yes", "y"]:
			return true
		if lowered in ["false", "0", "no", "n", ""]:
			return false
	return default_value

func _normalize_llm_action(raw_action: String) -> String:
	var action: String = raw_action.strip_edges().to_lower()
	if action.is_empty():
		return ""
	var alias_map: Dictionary = {
		"seek_wood": "cut_tree",
		"get_wood": "cut_tree",
		"gather_wood": "cut_tree",
		"chop_wood": "cut_tree",
		"collect_wood": "cut_tree",
		"collect_resource": "collect_drop",
		"gather_drop": "collect_drop",
		"pickup_drop": "collect_drop",
		"go_player": "go_to_player",
		"talk_player": "talk_to_nearby_player",
		"talk": "talk_to_nearby_player",
		"idle": "move_random",
		"wander": "move_random",
		"random_move": "move_random",
		"go_build": "build",
		"rest": "go_home",
		"heal": "heal_nearby_player",
		"help_injured": "heal_nearby_player",
		"heal_player": "heal_nearby_player",
		"campfire": "build_campfire",
		"make_campfire": "build_campfire",
		"place_campfire": "build_campfire",
		"ignite_campfire": "light_campfire",
		"light_fire": "light_campfire",
		"put_out_campfire": "extinguish_campfire",
		"extinguish_fire": "extinguish_campfire",
		"remove_campfire": "destroy_campfire"
	}
	if alias_map.has(action):
		return str(alias_map.get(action, action))
	return action

func _sanitize_llm_decision(raw_decision: Dictionary) -> Dictionary:
	var allowed_actions: Array[String] = ["cut_tree", "collect_drop", "go_home", "build", "move_random", "move_to", "go_to_player", "talk_to_nearby_player", "fish", "swim", "claim_tile", "trade_with_nearby_player", "heal_nearby_player", "build_campfire", "light_campfire", "extinguish_campfire", "destroy_campfire"]
	var action: String = _normalize_llm_action(_coerce_decision_string(raw_decision.get("action", ""), ""))
	if not allowed_actions.has(action):
		action = "move_random"

	var preferred_target: String = _coerce_decision_string(raw_decision.get("preferred_target", "wander"), "wander")
	var result: Dictionary = {
		"action": action,
		"preferred_target": preferred_target,
		"goal_text": _coerce_decision_string(raw_decision.get("goal_text", ""), ""),
		"memory_entry": _coerce_decision_string(raw_decision.get("memory_entry", ""), "").substr(0, 220),
		"remember": _coerce_decision_bool(raw_decision.get("remember", false), false),
		"memory_type": _coerce_decision_string(raw_decision.get("memory_type", "status"), "status"),
		"decision_source": _coerce_decision_string(raw_decision.get("decision_source", ""), ""),
		"llm_status": _coerce_decision_string(raw_decision.get("llm_status", ""), ""),
		"target_player_name": _coerce_decision_string(raw_decision.get("target_player_name", ""), "").substr(0, 40),
		"speech_text": _coerce_decision_string(raw_decision.get("speech_text", ""), "").substr(0, 96),
		"give_item": _coerce_decision_string(raw_decision.get("give_item", ""), "").to_lower().substr(0, 16),
		"request_item": _coerce_decision_string(raw_decision.get("request_item", ""), "").to_lower().substr(0, 16),
		"give_amount": maxi(0, int(raw_decision.get("give_amount", 0))),
		"request_amount": maxi(0, int(raw_decision.get("request_amount", 0)))
	}

	var allowed_memory_types: Array[String] = ["status", "resources", "social", "conflict"]
	if not allowed_memory_types.has(str(result.get("memory_type", "status"))):
		result["memory_type"] = "status"
	if str(result.get("memory_entry", "")).strip_edges().is_empty():
		result["remember"] = false

	if action == "move_to" or action == "claim_tile":
		var world_pos_variant: Variant = raw_decision.get("world_position", null)
		if world_pos_variant is Dictionary:
			var wp: Dictionary = world_pos_variant
			result["world_position"] = Vector2(float(wp.get("x", 0.0)), float(wp.get("y", 0.0)))
		elif world_pos_variant is Vector2:
			result["world_position"] = world_pos_variant
		elif action == "move_to":
			result["action"] = "move_random"

	return result

func _get_villager_by_name(villager_name: String) -> VillagerAgent:
	for villager in _get_active_villagers():
		if villager.villager_name == villager_name:
			return villager
	return null

func _get_nearby_player_summaries(villager_name: String, from_world_position: Vector2, radius: float) -> Array:
	var players: Array = []
	for villager in _get_active_villagers():
		if villager.villager_name == villager_name:
			continue
		var distance: float = from_world_position.distance_to(villager.position)
		if distance > radius:
			continue
		players.append({
			"name": villager.villager_name,
			"distance": distance,
			"world_position": villager.position
		})
	players.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("distance", INF)) < float(b.get("distance", INF)))
	return players

func _estimate_world_path_cost(start_world_position: Vector2, end_world_position: Vector2, allow_swimming: bool = false) -> float:
	var path: Array[Vector2] = find_world_path(start_world_position, end_world_position, false, Vector2i(-9999, -9999), allow_swimming)
	if path.is_empty():
		return INF
	var total: float = 0.0
	var current: Vector2 = start_world_position
	for point in path:
		total += current.distance_to(point)
		current = point
	return total

func find_player_target(villager_name: String, from_world_position: Vector2, preferred_name: String = "", allow_swimming: bool = false) -> Dictionary:
	var preferred_clean: String = preferred_name.strip_edges()
	var best_name: String = ""
	var best_position: Vector2 = Vector2.ZERO
	var best_distance: float = INF
	for villager in _get_active_villagers():
		if villager.villager_name == villager_name:
			continue
		if not preferred_clean.is_empty() and villager.villager_name.to_lower() != preferred_clean.to_lower():
			continue
		var distance: float = _estimate_world_path_cost(from_world_position, villager.position, allow_swimming)
		if distance < best_distance:
			best_distance = distance
			best_name = villager.villager_name
			best_position = villager.position
	if best_name.is_empty() and not preferred_clean.is_empty():
		return find_player_target(villager_name, from_world_position, "", allow_swimming)
	if best_name.is_empty():
		return {}
	return {"name": best_name, "world_position": best_position, "distance": best_distance}

func find_injured_player_target(villager_name: String, from_world_position: Vector2, preferred_name: String = "", allow_swimming: bool = false, health_threshold: float = 62.0) -> Dictionary:
	var preferred_clean: String = preferred_name.strip_edges()
	var best_name: String = ""
	var best_position: Vector2 = Vector2.ZERO
	var best_distance: float = INF
	var best_health: float = INF
	var threshold: float = clampf(health_threshold, 1.0, 99.0)
	for villager in _get_active_villagers():
		if villager.villager_name == villager_name:
			continue
		if not preferred_clean.is_empty() and villager.villager_name.to_lower() != preferred_clean.to_lower():
			continue
		if villager.health >= threshold:
			continue
		var distance: float = _estimate_world_path_cost(from_world_position, villager.position, allow_swimming)
		if villager.health < best_health or (is_equal_approx(villager.health, best_health) and distance < best_distance):
			best_health = villager.health
			best_distance = distance
			best_name = villager.villager_name
			best_position = villager.position
	if best_name.is_empty() and not preferred_clean.is_empty():
		return find_injured_player_target(villager_name, from_world_position, "", allow_swimming, health_threshold)
	if best_name.is_empty():
		return {}
	return {"name": best_name, "world_position": best_position, "distance": best_distance, "health": best_health}

func heal_nearby_player(healer_name: String, from_world_position: Vector2, preferred_name: String = "", heal_amount: float = 18.0, interaction_distance: float = 34.0, energy_cost: float = 12.0) -> Dictionary:
	var target: Dictionary = find_injured_player_target(healer_name, from_world_position, preferred_name, false, 99.0)
	if target.is_empty():
		return {"healed": false, "reason": "no_target"}
	var distance: float = float(target.get("distance", INF))
	if distance > interaction_distance:
		return {"healed": false, "reason": "too_far", "target_name": str(target.get("name", "")), "world_position": target.get("world_position", from_world_position), "distance": distance}

	var healer: VillagerAgent = _get_villager_by_name(healer_name)
	var target_name: String = str(target.get("name", ""))
	var patient: VillagerAgent = _get_villager_by_name(target_name)
	if healer == null or patient == null:
		return {"healed": false, "reason": "missing_npc"}
	if healer.energy < energy_cost:
		return {"healed": false, "reason": "low_energy", "target_name": target_name, "world_position": patient.position, "distance": distance}

	var missing_health: float = maxf(0.0, 100.0 - patient.health)
	if missing_health <= 0.5:
		return {"healed": false, "reason": "not_injured", "target_name": target_name, "world_position": patient.position, "distance": distance}
	var applied_heal: float = minf(maxf(0.0, heal_amount), missing_health)
	if applied_heal <= 0.0:
		return {"healed": false, "reason": "not_injured", "target_name": target_name, "world_position": patient.position, "distance": distance}

	healer.energy = clampf(healer.energy - maxf(0.0, energy_cost), 0.0, 100.0)
	patient.health = clampf(patient.health + applied_heal, 0.0, 100.0)
	_append_recent_event(healer_name, "healed %s" % target_name)
	_append_recent_event(target_name, "was healed by %s" % healer_name)
	healer.show_chat_bubble("Hold still, %s." % target_name)
	patient.show_chat_bubble("Thanks, %s." % healer_name)
	return {"healed": true, "target_name": target_name, "world_position": patient.position, "distance": distance, "heal_amount": applied_heal}

func _build_villager_reply(speaker_name: String, target_name: String, message: String) -> String:
	var genes: Dictionary = _npc_llm_genes.get(target_name, {})
	var compassion: float = float(genes.get("compassion", 0.5))
	var funny: float = float(genes.get("funny", 0.0))
	var mean: float = float(genes.get("mean", 0.0))
	var message_hint: String = message.strip_edges().to_lower()
	var recent_thread: Array = _get_recent_conversation(target_name, speaker_name, 3)
	var last_line: String = ""
	if not recent_thread.is_empty() and recent_thread[recent_thread.size() - 1] is Dictionary:
		last_line = str((recent_thread[recent_thread.size() - 1] as Dictionary).get("text", "")).strip_edges().to_lower()
	if funny > 0.72:
		return "Heh, %s. I can work with that." % speaker_name
	if mean > 0.68:
		return "Fine, %s. Make it worth my time." % speaker_name
	if compassion > 0.58:
		return "Alright %s, I hear you." % speaker_name
	if message_hint.find("baby") != -1 or message_hint.find("name") != -1:
		return "That sounds good, %s." % speaker_name
	if last_line.find("?") >= 0:
		if last_line.find("day") >= 0 or last_line.find("doing") >= 0:
			return "Pretty good, %s. I have been keeping busy." % speaker_name
		if last_line.find("work") >= 0 or last_line.find("build") >= 0:
			return "I have been trying to help out where I can, %s." % speaker_name
		if last_line.find("food") >= 0 or last_line.find("hungry") >= 0:
			return "I could use a bite, %s." % speaker_name
		if last_line.find("home") >= 0:
			return "Home sounds pretty good right now, %s." % speaker_name
	var neutral_replies: Array[String] = [
		"Alright %s, I hear you.",
		"Sounds reasonable, %s.",
		"Okay %s, I can do that.",
		"Got it, %s.",
		"That makes sense, %s.",
		"Fair enough, %s."
	]
	return neutral_replies[randi() % neutral_replies.size()] % speaker_name

func speak_to_nearby_player(speaker_name: String, from_world_position: Vector2, message: String, preferred_name: String = "") -> Dictionary:
	var final_message: String = message.strip_edges().substr(0, 96)
	if final_message.is_empty():
		return {"spoken": false}
	if conversation_lock_enabled and conversation_generic_defer_pause_until_response and _llm_backend_ready() and _has_pending_generic_conversation_generation():
		return {"spoken": false, "reason": "conversation_generating"}
	if conversation_lock_enabled and _has_active_locked_conversation():
		if _is_name_in_active_conversation(speaker_name):
			var partner_name: String = _active_conversation_partner_for(speaker_name)
			var partner: VillagerAgent = _get_villager_by_name(partner_name)
			return {
				"spoken": true,
				"target_name": partner_name,
				"world_position": partner.position if partner != null else from_world_position,
				"distance": from_world_position.distance_to(partner.position) if partner != null else 0.0
			}
		return {"spoken": false, "reason": "conversation_busy"}
	var target: Dictionary = find_player_target(speaker_name, from_world_position, preferred_name)
	if target.is_empty():
		return {"spoken": false}
	var distance: float = float(target.get("distance", INF))
	if distance > llm_talk_distance:
		return {
			"spoken": false,
			"target_name": str(target.get("name", "")),
			"world_position": target.get("world_position", from_world_position),
			"distance": distance
		}
	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var target_name: String = str(target.get("name", ""))
	var listener: VillagerAgent = _get_villager_by_name(target_name)
	if conversation_lock_enabled:
		if conversation_generic_defer_pause_until_response and _llm_backend_ready():
			if _start_generic_conversation_replay_job(speaker_name, target_name, final_message):
				return {
					"spoken": true,
					"target_name": target_name,
					"world_position": target.get("world_position", from_world_position),
					"distance": distance
				}
		_start_locked_conversation(speaker_name, target_name, final_message, "generic")
		if _has_active_locked_conversation():
			# Opening line already spoken in _start_locked_conversation; hand next turn to listener.
			_active_locked_conversation["current_speaker"] = target_name
			_active_locked_conversation["current_listener"] = speaker_name
			_active_locked_conversation["turn_index"] = 1
			_active_locked_conversation["turn_timer"] = maxf(0.35, conversation_turn_seconds)
			_active_locked_conversation["max_turns"] = maxi(2, conversation_max_turns)
			_active_locked_conversation["awaiting_generic_llm"] = false
		return {
			"spoken": true,
			"target_name": target_name,
			"world_position": target.get("world_position", from_world_position),
			"distance": distance
		}
	var reply_text: String = _build_villager_reply(speaker_name, target_name, final_message)
	if speaker != null:
		speaker.show_chat_bubble(final_message)
	if listener != null:
		listener.show_chat_bubble(reply_text)
	_append_conversation_message(speaker_name, target_name, final_message)
	_append_conversation_message(target_name, speaker_name, reply_text)
	return {
		"spoken": true,
		"target_name": target_name,
		"world_position": target.get("world_position", from_world_position),
		"distance": distance
	}

func _generic_conversation_pair_key(name_a: String, name_b: String) -> String:
	var a_key: String = name_a.strip_edges().to_lower()
	var b_key: String = name_b.strip_edges().to_lower()
	if a_key <= b_key:
		return "%s|%s" % [a_key, b_key]
	return "%s|%s" % [b_key, a_key]

func _start_generic_conversation_replay_job(speaker_name: String, listener_name: String, opening_line: String) -> bool:
	if speaker_name == listener_name:
		return false
	if _has_active_locked_conversation():
		return false
	if _has_pending_generic_conversation_generation():
		return false
	var pair_key: String = _generic_conversation_pair_key(speaker_name, listener_name)
	if _pending_generic_conversation_pairs.has(pair_key):
		return false
	var max_turns: int = maxi(2, conversation_max_turns)
	var turns_to_generate: int = maxi(1, max_turns - 1)
	var system_prompt: String = "Return ONLY JSON with key turns. turns must be an array of exactly %d short dialogue lines continuing a villager conversation. No markdown, no extra keys." % turns_to_generate
	var user_payload: Dictionary = {
		"speaker": speaker_name,
		"listener": listener_name,
		"opening_line": opening_line,
		"turns_to_generate": turns_to_generate,
		"conversation_goal": "natural village small-talk",
		"speaker_personality": _npc_llm_genes.get(speaker_name, {}),
		"listener_personality": _npc_llm_genes.get(listener_name, {})
	}
	var request := HTTPRequest.new()
	request.timeout = maxf(_get_llm_request_timeout_seconds(), 40.0)
	add_child(request)
	var job_id: int = _next_generic_conversation_job_id
	_next_generic_conversation_job_id += 1
	_pending_generic_conversation_jobs[job_id] = {
		"speaker": speaker_name,
		"listener": listener_name,
		"opening_line": opening_line,
		"turns_to_generate": turns_to_generate,
		"pair_key": pair_key,
		"request": request
	}
	_pending_generic_conversation_pairs[pair_key] = true
	request.request_completed.connect(_on_generic_conversation_replay_completed.bind(job_id, request), CONNECT_ONE_SHOT)
	var replay_num_predict: int = maxi(conversation_replay_llm_num_predict, turns_to_generate * 24 + 32)
	var request_body: Dictionary = _build_locked_conversation_request_body(system_prompt, JSON.stringify(user_payload), replay_num_predict)
	var err: int = request.request(
		llm_openai_endpoint,
		_build_llm_request_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify(request_body)
	)
	if err != OK:
		if is_instance_valid(request):
			request.queue_free()
		_pending_generic_conversation_jobs.erase(job_id)
		_pending_generic_conversation_pairs.erase(pair_key)
		return false
	if llm_debug_log_to_output:
		_log_llm(speaker_name, "generic replay pregen requesting listener=%s turns=%d" % [listener_name, turns_to_generate])
	return true

func _has_pending_generic_conversation_generation() -> bool:
	return not _pending_generic_conversation_jobs.is_empty()

func _extract_generic_replay_turns(content: String, expected_count: int, first_speaker: String, second_speaker: String) -> Array:
	var turns: Array = []
	var normalized_content: String = content.strip_edges()
	if normalized_content.is_empty():
		return turns
	var parsed: Variant = JSON.parse_string(normalized_content)
	if not (parsed is Dictionary):
		var json_start: int = normalized_content.find("{")
		var json_end: int = normalized_content.rfind("}")
		if json_start >= 0 and json_end > json_start:
			var candidate: String = normalized_content.substr(json_start, json_end - json_start + 1)
			parsed = JSON.parse_string(candidate)
	if not (parsed is Dictionary):
		return turns
	var root: Dictionary = parsed
	var raw_turns: Variant = root.get("turns", [])
	if raw_turns is String:
		var lines: Array[String] = str(raw_turns).split("\n", false)
		raw_turns = []
		for row in lines:
			var line_text: String = row.strip_edges()
			if line_text.begins_with("-"):
				line_text = line_text.trim_prefix("-").strip_edges()
			if line_text.begins_with("*"):
				line_text = line_text.trim_prefix("*").strip_edges()
			if not line_text.is_empty():
				(raw_turns as Array).append(line_text)
	if not (raw_turns is Array):
		return turns
	var arr: Array = raw_turns
	for i in range(mini(expected_count, arr.size())):
		var line: String = ""
		var row: Variant = arr[i]
		if row is Dictionary:
			var row_dict: Dictionary = row
			line = str(row_dict.get("line", row_dict.get("text", row_dict.get("speech_text", "")))).strip_edges()
		elif row is String:
			line = str(row).strip_edges()
		line = line.substr(0, 120)
		if line.is_empty():
			continue
		var speaker_name: String = first_speaker if i % 2 == 0 else second_speaker
		turns.append({"speaker": speaker_name, "line": line})
	return turns

func _on_generic_conversation_replay_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, job_id: int, request: HTTPRequest) -> void:
	if is_instance_valid(request):
		request.queue_free()
	if not _pending_generic_conversation_jobs.has(job_id):
		return
	var job: Dictionary = _pending_generic_conversation_jobs[job_id]
	_pending_generic_conversation_jobs.erase(job_id)
	var pair_key: String = str(job.get("pair_key", ""))
	if not pair_key.is_empty():
		_pending_generic_conversation_pairs.erase(pair_key)
	var speaker_name: String = str(job.get("speaker", ""))
	var listener_name: String = str(job.get("listener", ""))
	var opening_line: String = str(job.get("opening_line", ""))
	var turns_to_generate: int = int(job.get("turns_to_generate", maxi(1, conversation_max_turns - 1)))
	if _has_active_locked_conversation():
		return
	var generated_turns: Array = []
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		var response_text: String = body.get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(response_text)
		var content: String = ""
		if parsed is Dictionary:
			content = _extract_llm_response_content(parsed)
		if content.is_empty():
			content = response_text
		generated_turns = _extract_generic_replay_turns(content, turns_to_generate, listener_name, speaker_name)
		if llm_debug_log_to_output:
			_log_llm(speaker_name, "generic replay pregen parsed listener=%s turns=%d expected=%d" % [listener_name, generated_turns.size(), turns_to_generate])
	if generated_turns.is_empty():
		# In deferred mode we avoid live-generation fallback so conversations do not stall turn-by-turn.
		if llm_debug_log_to_output:
			_log_llm(speaker_name, "generic replay pregen failed listener=%s; skipping conversation start" % listener_name)
		if not conversation_generic_defer_pause_until_response:
			_start_locked_conversation(speaker_name, listener_name, opening_line, "generic")
			if _has_active_locked_conversation():
				_active_locked_conversation["current_speaker"] = listener_name
				_active_locked_conversation["current_listener"] = speaker_name
				_active_locked_conversation["turn_index"] = 1
				_active_locked_conversation["turn_timer"] = maxf(0.35, conversation_turn_seconds)
				_active_locked_conversation["max_turns"] = maxi(2, conversation_max_turns)
				_active_locked_conversation["awaiting_generic_llm"] = false
		return
	_start_locked_conversation(speaker_name, listener_name, opening_line, "generic")
	if not _has_active_locked_conversation():
		return
	_active_locked_conversation["replay_pre_generated"] = true
	_active_locked_conversation["pre_generated_turns"] = generated_turns
	_active_locked_conversation["turn_index"] = 0
	_active_locked_conversation["max_turns"] = maxi(1, generated_turns.size())
	_active_locked_conversation["turn_timer"] = maxf(0.35, conversation_turn_seconds * 0.45)

func _has_active_locked_conversation() -> bool:
	if _active_locked_conversation.is_empty():
		return false
	return not str(_active_locked_conversation.get("a", "")).is_empty() and not str(_active_locked_conversation.get("b", "")).is_empty()

func _is_name_in_active_conversation(villager_name: String) -> bool:
	if not _has_active_locked_conversation():
		return false
	var a_name: String = str(_active_locked_conversation.get("a", ""))
	var b_name: String = str(_active_locked_conversation.get("b", ""))
	return villager_name == a_name or villager_name == b_name

func _active_conversation_partner_for(villager_name: String) -> String:
	if not _has_active_locked_conversation():
		return ""
	var a_name: String = str(_active_locked_conversation.get("a", ""))
	var b_name: String = str(_active_locked_conversation.get("b", ""))
	if villager_name == a_name:
		return b_name
	if villager_name == b_name:
		return a_name
	return ""

func _clear_non_participant_bubbles(speaker_name: String, listener_name: String) -> void:
	for villager: VillagerAgent in _villagers:
		if villager != null and villager.villager_name != speaker_name and villager.villager_name != listener_name:
			villager.fade_chat_bubble()

func is_villager_paused_by_conversation(villager_name: String) -> bool:
	if not _has_active_locked_conversation():
		return false
	if conversation_pause_all_villagers:
		return true
	# Legacy mode: only participants in the active locked conversation are paused.
	return _is_name_in_active_conversation(villager_name)

func _start_locked_conversation(speaker_name: String, listener_name: String, opening_line: String, mode: String = "generic") -> void:
	if speaker_name == listener_name:
		return
	if _has_active_locked_conversation():
		_end_locked_conversation("replaced")
	_llm_requests_paused_for_conversation = true
	_cancel_all_llm_requests_for_conversation()
	_start_conversation_overlay_fade()
	_clear_non_participant_bubbles(speaker_name, listener_name)
	_active_locked_conversation = {
		"a": speaker_name,
		"b": listener_name,
		"mode": mode,
		"current_speaker": speaker_name,
		"current_listener": listener_name,
		"turn_timer": maxf(0.3, conversation_turn_seconds),
		"turn_index": 0,
		"max_turns": maxi(2, conversation_max_turns),
		"generic_llm_failures": 0
	}
	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var listener: VillagerAgent = _get_villager_by_name(listener_name)
	if speaker != null:
		speaker.show_chat_bubble(opening_line)
	if listener != null:
		listener.show_chat_bubble("I am listening.")
	_append_conversation_message(speaker_name, listener_name, opening_line)
	_append_recent_event(speaker_name, "started conversation with %s" % listener_name)
	_append_recent_event(listener_name, "started conversation with %s" % speaker_name)

func _update_locked_conversation(delta: float) -> void:
	if not _has_active_locked_conversation():
		return
	var a_name: String = str(_active_locked_conversation.get("a", ""))
	var b_name: String = str(_active_locked_conversation.get("b", ""))
	var a_npc: VillagerAgent = _get_villager_by_name(a_name)
	var b_npc: VillagerAgent = _get_villager_by_name(b_name)
	if a_npc == null or b_npc == null:
		_end_locked_conversation("missing_participant")
		return
	if a_npc != null:
		a_npc.energy = maxf(0.0, a_npc.energy - conversation_energy_drain_per_sec * delta)
	if b_npc != null:
		b_npc.energy = maxf(0.0, b_npc.energy - conversation_energy_drain_per_sec * delta)
	_enforce_locked_conversation_spacing(a_npc, b_npc, delta)
	if bool(_active_locked_conversation.get("pending_end", false)):
		var end_timer: float = float(_active_locked_conversation.get("pending_end_timer", 0.0)) - delta
		_active_locked_conversation["pending_end_timer"] = end_timer
		if end_timer <= 0.0:
			_end_locked_conversation(str(_active_locked_conversation.get("pending_end_reason", "ended")))
		return
	var mode: String = str(_active_locked_conversation.get("mode", "generic"))
	if mode == "baby_naming":
		var a_name_hold: String = str(_active_locked_conversation.get("a", ""))
		var b_name_hold: String = str(_active_locked_conversation.get("b", ""))
		var a_hold: VillagerAgent = _get_villager_by_name(a_name_hold)
		var b_hold: VillagerAgent = _get_villager_by_name(b_name_hold)
		if a_hold == null or b_hold == null:
			_end_locked_conversation("missing_participant")
			return
		_apply_locked_conversation_bubble_offsets(a_hold, b_hold)
		if bool(_active_locked_conversation.get("awaiting_baby_name_llm", false)):
			return

		var baby_timer: float = float(_active_locked_conversation.get("turn_timer", conversation_turn_seconds)) - delta
		_active_locked_conversation["turn_timer"] = baby_timer
		if baby_timer > 0.0:
			return

		var job_id: int = int(_active_locked_conversation.get("baby_job_id", -1))
		if job_id < 0 or not _pending_baby_name_jobs.has(job_id):
			_end_locked_conversation("baby_job_missing")
			return

		var job: Dictionary = _pending_baby_name_jobs[job_id]

		# Handle replay mode: show pre-generated turns
		if bool(_active_locked_conversation.get("replay_pre_generated", false)):
			var turn_index_baby: int = int(_active_locked_conversation.get("turn_index", 0))
			var generated_turns: Array = job.get("generated_turns", [])
			var max_turns_baby: int = maxi(2, int(_active_locked_conversation.get("max_turns", 2)))
			var displayed_line_length: int = 0

			# Show turn if available
			if turn_index_baby < generated_turns.size():
				var turn_data: Dictionary = generated_turns[turn_index_baby]
				var turn_speaker: String = str(turn_data.get("speaker", ""))
				var turn_line: String = str(turn_data.get("line", ""))
				displayed_line_length = turn_line.length()
				var speaker_agent: VillagerAgent = _get_villager_by_name(turn_speaker)
				var listener_name_for_turn: String = b_name_hold if turn_speaker == a_name_hold else a_name_hold
				var listener_agent: VillagerAgent = _get_villager_by_name(listener_name_for_turn)
				if speaker_agent != null:
					if listener_agent != null:
						listener_agent.fade_chat_bubble()
					speaker_agent.show_chat_bubble(turn_line)
			turn_index_baby += 1
			_active_locked_conversation["turn_index"] = turn_index_baby

			# Check if done
			if turn_index_baby >= max_turns_baby or turn_index_baby >= generated_turns.size():
				var first_name: String = str(job.get("proposed_first", "Nova"))
				var last_name: String = str(job.get("proposed_last", "Vale"))
				_spawn_baby_with_name(job_id, first_name, last_name)
				var final_line_hold: float = maxf(1.3, conversation_turn_seconds * 0.8 + float(displayed_line_length) / 28.0)
				_queue_locked_conversation_end("baby_named", final_line_hold)
				return

			# Set up next turn timing
			_active_locked_conversation["turn_timer"] = 3.0  # 3 seconds per turn
			return

		var speaker_name_baby: String = str(_active_locked_conversation.get("current_speaker", a_name_hold))
		var listener_name_baby: String = str(_active_locked_conversation.get("current_listener", b_name_hold))
		var turn_index_baby: int = int(_active_locked_conversation.get("turn_index", 0))
		var max_turns_baby: int = maxi(2, int(_active_locked_conversation.get("max_turns", 2)))
		var is_final_turn_baby: bool = turn_index_baby >= (max_turns_baby - 1)
		var prior_line: String = ""
		var recent_thread: Array = _get_recent_conversation(speaker_name_baby, listener_name_baby, 1)
		if not recent_thread.is_empty() and recent_thread[recent_thread.size() - 1] is Dictionary:
			prior_line = str((recent_thread[recent_thread.size() - 1] as Dictionary).get("text", ""))

		_active_locked_conversation["awaiting_baby_name_llm"] = true
		_active_locked_conversation["turn_timer"] = 0.0
		_start_baby_name_llm_turn(job_id, speaker_name_baby, listener_name_baby, prior_line, is_final_turn_baby)
		return
	if bool(_active_locked_conversation.get("replay_pre_generated", false)) and str(_active_locked_conversation.get("mode", "")) == "generic":
		var gen_a: VillagerAgent = _get_villager_by_name(a_name)
		var gen_b: VillagerAgent = _get_villager_by_name(b_name)
		if gen_a != null and gen_b != null:
			_apply_locked_conversation_bubble_offsets(gen_a, gen_b)
		var replay_timer: float = float(_active_locked_conversation.get("turn_timer", conversation_turn_seconds)) - delta
		_active_locked_conversation["turn_timer"] = replay_timer
		if replay_timer > 0.0:
			return
		var generic_turn_index: int = int(_active_locked_conversation.get("turn_index", 0))
		var generic_turns: Array = _active_locked_conversation.get("pre_generated_turns", [])
		if generic_turn_index < generic_turns.size():
			var generic_turn: Dictionary = generic_turns[generic_turn_index]
			var generic_speaker_name: String = str(generic_turn.get("speaker", ""))
			var generic_line: String = str(generic_turn.get("line", ""))
			var generic_speaker: VillagerAgent = _get_villager_by_name(generic_speaker_name)
			var generic_listener_name: String = b_name if generic_speaker_name == a_name else a_name
			var generic_listener: VillagerAgent = _get_villager_by_name(generic_listener_name)
			if generic_speaker != null:
				if generic_listener != null:
					generic_listener.fade_chat_bubble()
				generic_speaker.show_chat_bubble(generic_line)
			if not generic_speaker_name.is_empty() and not generic_listener_name.is_empty() and not generic_line.is_empty():
				_append_conversation_message(generic_speaker_name, generic_listener_name, generic_line)
		generic_turn_index += 1
		_active_locked_conversation["turn_index"] = generic_turn_index
		if generic_turn_index >= generic_turns.size() or generic_turn_index >= int(_active_locked_conversation.get("max_turns", 2)):
			_queue_locked_conversation_end("replayed", maxf(0.9, conversation_turn_seconds * 0.65))
			return
		_active_locked_conversation["turn_timer"] = maxf(0.35, conversation_turn_seconds * 0.45)
		return
	var speaker_name: String = str(_active_locked_conversation.get("current_speaker", ""))
	var listener_name: String = str(_active_locked_conversation.get("current_listener", ""))
	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var listener: VillagerAgent = _get_villager_by_name(listener_name)
	if speaker == null or listener == null:
		_end_locked_conversation("missing_participant")
		return
	_apply_locked_conversation_bubble_offsets(speaker, listener)
	var timer: float = float(_active_locked_conversation.get("turn_timer", conversation_turn_seconds)) - delta
	_active_locked_conversation["turn_timer"] = timer
	if timer > 0.0:
		return

	var turn_index: int = int(_active_locked_conversation.get("turn_index", 0))
	if _should_leave_locked_conversation(speaker_name, turn_index):
		var leave_line: String = "I have to go now."
		if listener != null:
			listener.fade_chat_bubble()
		speaker.show_chat_bubble(leave_line)
		_append_conversation_message(speaker_name, listener_name, leave_line)
		_queue_locked_conversation_end("left", maxf(0.9, conversation_turn_seconds * 0.65))
		return
	if bool(_active_locked_conversation.get("awaiting_generic_llm", false)):
		return
	if _llm_backend_ready():
		_active_locked_conversation["awaiting_generic_llm"] = true
		if _start_locked_conversation_llm_turn(speaker_name, listener_name, turn_index):
			return
		_active_locked_conversation["awaiting_generic_llm"] = false
		if _handle_locked_generic_llm_failure("request_start"):
			return
	else:
		if _handle_locked_generic_llm_failure("backend_unavailable"):
			return

	var fallback_line: String = _compose_locked_conversation_line(speaker_name, listener_name, turn_index)
	_emit_locked_conversation_turn(speaker_name, listener_name, turn_index, fallback_line)

func _handle_locked_generic_llm_failure(reason: String) -> bool:
	if not conversation_generic_require_llm:
		return false
	if not _has_active_locked_conversation():
		return true
	if str(_active_locked_conversation.get("mode", "")) != "generic":
		return true
	var failures: int = int(_active_locked_conversation.get("generic_llm_failures", 0)) + 1
	_active_locked_conversation["generic_llm_failures"] = failures
	if failures <= maxi(0, conversation_generic_llm_retry_limit):
		_active_locked_conversation["turn_timer"] = 0.35
		_active_locked_conversation["awaiting_generic_llm"] = false
		return true
	_queue_locked_conversation_end("generic_llm_%s" % reason, maxf(0.6, conversation_turn_seconds * 0.5))
	return true

func _enforce_locked_conversation_spacing(a_npc: VillagerAgent, b_npc: VillagerAgent, delta: float) -> void:
	if a_npc == null or b_npc == null:
		return
	if a_npc._is_dead or b_npc._is_dead:
		return
	var midpoint: Vector2 = (a_npc.position + b_npc.position) * 0.5
	var half_spacing: float = maxf(4.0, conversation_pair_spacing * 0.5)
	var a_is_left: bool = a_npc.position.x <= b_npc.position.x
	var target_a: Vector2 = midpoint + Vector2(-half_spacing, 0.0) if a_is_left else midpoint + Vector2(half_spacing, 0.0)
	var target_b: Vector2 = midpoint + Vector2(half_spacing, 0.0) if a_is_left else midpoint + Vector2(-half_spacing, 0.0)
	var weight: float = clampf(delta * conversation_pair_recenter_speed, 0.0, 1.0)
	a_npc.position = a_npc.position.lerp(target_a, weight)
	b_npc.position = b_npc.position.lerp(target_b, weight)

func _apply_locked_conversation_bubble_offsets(first_npc: VillagerAgent, second_npc: VillagerAgent) -> void:
	if first_npc == null or second_npc == null:
		return
	# Detect if bubbles overlap and push them apart dynamically
	# Bubble dimensions at 0.55 scale: 79px wide × 23px high
	var bubble_width: float = 79.0
	var bubble_height: float = 23.0
	
	# Get anchor positions (where bubbles are positioned relative to NPCs)
	var a_bubble_pos: Vector2 = first_npc.get_speech_bubble_anchor_global()
	var b_bubble_pos: Vector2 = second_npc.get_speech_bubble_anchor_global()
	
	# Create bounding boxes for each bubble (centered horizontally on anchor)
	var a_rect: Rect2 = Rect2(a_bubble_pos - Vector2(bubble_width * 0.5, 0), Vector2(bubble_width, bubble_height))
	var b_rect: Rect2 = Rect2(b_bubble_pos - Vector2(bubble_width * 0.5, 0), Vector2(bubble_width, bubble_height))
	
	# Check for overlap
	if not a_rect.intersects(b_rect):
		# No overlap, reset offsets
		first_npc.set_speech_bubble_avoid_offset_x(0.0)
		first_npc.set_speech_bubble_avoid_offset_y(0.0)
		second_npc.set_speech_bubble_avoid_offset_x(0.0)
		second_npc.set_speech_bubble_avoid_offset_y(0.0)
		return
	
	# Overlap detected, push apart
	# Determine which is left/right
	var left_npc: VillagerAgent = first_npc if first_npc.position.x <= second_npc.position.x else second_npc
	var right_npc: VillagerAgent = second_npc if left_npc == first_npc else first_npc
	
	# Calculate overlap amount
	var overlap_x: float = (a_rect.position.x + a_rect.size.x) - b_rect.position.x
	if overlap_x > 0:
		# Push horizontally: left goes left, right goes right
		var push_amount: float = overlap_x * 0.5 + 4.0  # Split overlap + 4px margin
		left_npc.set_speech_bubble_avoid_offset_x(-push_amount)
		right_npc.set_speech_bubble_avoid_offset_x(push_amount)
		
		# Also push vertically for better separation
		left_npc.set_speech_bubble_avoid_offset_y(-12.0)
		right_npc.set_speech_bubble_avoid_offset_y(12.0)
	else:
		# Overlap in Y only, push vertically
		left_npc.set_speech_bubble_avoid_offset_y(-16.0)
		right_npc.set_speech_bubble_avoid_offset_y(16.0)
		left_npc.set_speech_bubble_avoid_offset_x(0.0)
		right_npc.set_speech_bubble_avoid_offset_x(0.0)

func _emit_locked_conversation_turn(speaker_name: String, listener_name: String, turn_index: int, line: String) -> void:
	if not _has_active_locked_conversation():
		return
	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var listener: VillagerAgent = _get_villager_by_name(listener_name)
	if speaker == null or listener == null:
		_end_locked_conversation("missing_participant")
		return
	var final_line: String = line.strip_edges().substr(0, 120)
	if final_line.is_empty():
		final_line = "Tell me more."
	listener.fade_chat_bubble()
	speaker.show_chat_bubble(final_line)
	_append_conversation_message(speaker_name, listener_name, final_line)
	var next_turn_index: int = turn_index + 1
	_active_locked_conversation["turn_index"] = next_turn_index
	if next_turn_index >= int(_active_locked_conversation.get("max_turns", conversation_max_turns)):
		_queue_locked_conversation_end("max_turns", maxf(0.9, conversation_turn_seconds * 0.65))
		return
	_active_locked_conversation["current_speaker"] = listener_name
	_active_locked_conversation["current_listener"] = speaker_name
	_active_locked_conversation["turn_timer"] = maxf(0.3, conversation_turn_seconds)

func _queue_locked_conversation_end(reason: String, hold_seconds: float = 1.0) -> void:
	if not _has_active_locked_conversation():
		return
	_active_locked_conversation["pending_end"] = true
	_active_locked_conversation["pending_end_reason"] = reason
	_active_locked_conversation["pending_end_timer"] = maxf(0.2, hold_seconds)

func _start_locked_conversation_llm_turn(speaker_name: String, listener_name: String, turn_index: int) -> bool:
	if not _has_active_locked_conversation():
		return false
	if str(_active_locked_conversation.get("mode", "")) != "generic":
		return false
	if not _llm_backend_ready():
		return false
	var prior_line: String = ""
	var recent_thread: Array = _get_recent_conversation(speaker_name, listener_name, 1)
	if not recent_thread.is_empty() and recent_thread[recent_thread.size() - 1] is Dictionary:
		prior_line = str((recent_thread[recent_thread.size() - 1] as Dictionary).get("text", "")).strip_edges()
	var system_prompt: String = "Return ONLY JSON with key speech_text. speech_text must be one natural, short reply sentence between villagers, no markdown and no extra keys."
	var user_payload: Dictionary = {
		"speaker": speaker_name,
		"listener": listener_name,
		"turn_index": turn_index,
		"prior_line": prior_line,
		"speaker_personality": _npc_llm_genes.get(speaker_name, {}),
		"listener_personality": _npc_llm_genes.get(listener_name, {})
	}
	var request := HTTPRequest.new()
	request.timeout = maxf(_get_llm_request_timeout_seconds(), 30.0)
	add_child(request)
	request.request_completed.connect(_on_locked_conversation_llm_completed.bind(speaker_name, listener_name, turn_index, request), CONNECT_ONE_SHOT)
	var request_body: Dictionary = _build_locked_conversation_request_body(system_prompt, JSON.stringify(user_payload))
	if llm_debug_log_to_output:
		_log_llm(speaker_name, "conversation_turn requesting listener=%s turn=%d" % [listener_name, turn_index])
	var err: int = request.request(
		llm_openai_endpoint,
		_build_llm_request_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify(request_body)
	)
	if err != OK:
		if is_instance_valid(request):
			request.queue_free()
		return false
	return true

func _build_locked_conversation_request_body(system_prompt: String, user_prompt: String, num_predict_override: int = -1) -> Dictionary:
	var num_predict_value: int = maxi(12, llm_num_predict)
	if num_predict_override > 0:
		num_predict_value = maxi(12, num_predict_override)
	if _get_llm_provider() == "ollama":
		return {
			"model": llm_model,
			"format": "json",
			"stream": false,
			"keep_alive": "10m",
			"system": system_prompt,
			"prompt": user_prompt,
			"options": {
				"temperature": maxf(0.2, llm_temperature),
				"num_predict": num_predict_value
			}
		}
	return {
		"model": llm_model,
		"temperature": maxf(0.2, llm_temperature),
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": user_prompt}
		]
	}

func _on_locked_conversation_llm_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, speaker_name: String, listener_name: String, turn_index: int, request: HTTPRequest) -> void:
	if is_instance_valid(request):
		request.queue_free()
	if not _has_active_locked_conversation():
		return
	if str(_active_locked_conversation.get("mode", "")) != "generic":
		return
	if str(_active_locked_conversation.get("current_speaker", "")) != speaker_name or str(_active_locked_conversation.get("current_listener", "")) != listener_name:
		return
	_active_locked_conversation["awaiting_generic_llm"] = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		if _handle_locked_generic_llm_failure("http_error"):
			return
	var llm_line: String = ""
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		var response_text: String = body.get_string_from_utf8()
		var parsed: Variant = JSON.parse_string(response_text)
		var content: String = ""
		if parsed is Dictionary:
			content = _extract_llm_response_content(parsed)
		if content.is_empty():
			content = response_text
		if not content.is_empty():
			var payload: Variant = JSON.parse_string(content)
			if payload is Dictionary:
				llm_line = str((payload as Dictionary).get("speech_text", "")).strip_edges()
			if llm_line.is_empty():
				llm_line = content.strip_edges()
	if llm_line.is_empty() and _handle_locked_generic_llm_failure("empty_response"):
		return
	if llm_debug_log_to_output:
		_log_llm(speaker_name, "conversation_turn ready listener=%s turn=%d line=%s" % [listener_name, turn_index, llm_line.substr(0, 120)])
	_active_locked_conversation["generic_llm_failures"] = 0
	if llm_line.is_empty() and llm_dialogue_requires_speech_text:
		llm_line = _compose_locked_conversation_line(speaker_name, listener_name, turn_index)
	_emit_locked_conversation_turn(speaker_name, listener_name, turn_index, llm_line)

func _should_leave_locked_conversation(speaker_name: String, turn_index: int) -> bool:
	if turn_index < maxi(0, conversation_min_turns_before_leave):
		return false
	var genes: Dictionary = _npc_llm_genes.get(speaker_name, {})
	var selfish: float = float(genes.get("selfish", 0.5))
	var mean: float = float(genes.get("mean", 0.5))
	var talkative: float = float(genes.get("talkative", 0.5))
	var impulse: float = clampf(conversation_leave_chance_per_turn + selfish * 0.12 + mean * 0.08 - talkative * 0.10, 0.02, 0.65)
	impulse += minf(0.20, float(turn_index) * 0.01)
	return randf() < clampf(impulse, 0.02, 0.82)

func _compose_locked_conversation_line(speaker_name: String, listener_name: String, turn_index: int) -> String:
	var genes: Dictionary = _npc_llm_genes.get(speaker_name, {})
	var compassion: float = float(genes.get("compassion", 0.5))
	var funny: float = float(genes.get("funny", 0.0))
	var mean: float = float(genes.get("mean", 0.0))
	var talkative: float = float(genes.get("talkative", 0.5))
	if mean > 0.72 and randf() < 0.35:
		return "%s, keep this short." % listener_name
	if funny > 0.72 and randf() < 0.45:
		return "If this gets awkward, we blame the weather."
	if compassion > 0.64 and randf() < 0.42:
		return "How are you feeling, %s?" % listener_name
	if talkative > 0.62:
		var openers: Array[String] = [
			"What should we work on next?",
			"How has your day been going?",
			"Want to make a plan together?",
			"Anything you need help with?"
		]
		return openers[turn_index % openers.size()]
	var context_message: String = "conversation"
	var recent_thread: Array = _get_recent_conversation(speaker_name, listener_name, 1)
	if not recent_thread.is_empty() and recent_thread[recent_thread.size() - 1] is Dictionary:
		context_message = str((recent_thread[recent_thread.size() - 1] as Dictionary).get("text", "")).strip_edges()
	return _build_villager_reply(listener_name, speaker_name, context_message)

func _end_locked_conversation(reason: String = "") -> void:
	if not _has_active_locked_conversation():
		_active_locked_conversation.clear()
		return
	var a_name: String = str(_active_locked_conversation.get("a", ""))
	var b_name: String = str(_active_locked_conversation.get("b", ""))
	var mode: String = str(_active_locked_conversation.get("mode", "generic"))
	var baby_job_id: int = int(_active_locked_conversation.get("baby_job_id", -1))
	var a_npc: VillagerAgent = _get_villager_by_name(a_name)
	var b_npc: VillagerAgent = _get_villager_by_name(b_name)
	if a_npc != null:
		a_npc.set_speech_bubble_avoid_offset_x(0.0)
		a_npc.fade_chat_bubble()
	if b_npc != null:
		b_npc.set_speech_bubble_avoid_offset_x(0.0)
		b_npc.fade_chat_bubble()
	if mode == "baby_naming" and baby_job_id >= 0 and reason != "baby_named":
		_pending_baby_name_jobs.erase(baby_job_id)
		if _active_baby_name_job_id == baby_job_id:
			_active_baby_name_job_id = -1
			_pump_baby_name_jobs()
	if not reason.is_empty():
		_append_recent_event(a_name, "conversation ended (%s) with %s" % [reason, b_name])
		_append_recent_event(b_name, "conversation ended (%s) with %s" % [reason, a_name])
	_active_locked_conversation.clear()
	_llm_requests_paused_for_conversation = false
	_end_conversation_overlay_fade()

func claim_tile(villager_name: String, world_position: Vector2, note: String = "") -> Dictionary:
	_ensure_npc_profile(villager_name)
	if terrain == null:
		return {"claimed": false}
	var cell: Vector2i = terrain.local_to_map(terrain.to_local(world_position))
	var existing_claims: Array = _npc_claims.get(villager_name, [])
	for claim_variant in existing_claims:
		if not (claim_variant is Dictionary):
			continue
		var existing_cell_variant: Variant = (claim_variant as Dictionary).get("cell", Vector2i(-9999, -9999))
		if existing_cell_variant is Vector2i and existing_cell_variant == cell:
			return {"claimed": true, "cell": cell, "world_position": terrain.to_global(terrain.map_to_local(cell))}
	var entry := {
		"cell": cell,
		"world_position": terrain.to_global(terrain.map_to_local(cell)),
		"note": note.substr(0, 120),
		"t": Time.get_unix_time_from_system()
	}
	var claims: Array = _npc_claims.get(villager_name, [])
	claims.append(entry)
	if claims.size() > 32:
		claims = claims.slice(claims.size() - 32, claims.size())
	_npc_claims[villager_name] = claims
	var context: Dictionary = _npc_llm_contexts.get(villager_name, {})
	var context_claims: Array = context.get("claims", [])
	context_claims.append(entry)
	if context_claims.size() > 24:
		context_claims = context_claims.slice(context_claims.size() - 24, context_claims.size())
	context["claims"] = context_claims
	_npc_llm_contexts[villager_name] = context
	_append_recent_event(villager_name, "claimed tile (%d,%d)" % [cell.x, cell.y])
	if _claims_overlay != null and show_claims_overlay:
		_claims_overlay.queue_redraw()
	return {"claimed": true, "cell": cell, "world_position": entry["world_position"]}

func _get_reserved_build_site_owner(cell: Vector2i) -> String:
	var entry: Variant = _reserved_build_cells.get(cell, "")
	if entry is Dictionary:
		return str((entry as Dictionary).get("owner", ""))
	return str(entry)

func _get_reserved_build_site_profile(cell: Vector2i) -> String:
	var entry: Variant = _reserved_build_cells.get(cell, {})
	if entry is Dictionary:
		return str((entry as Dictionary).get("profile", "house"))
	return "house"

func _is_reserved_build_site_repair(cell: Vector2i) -> bool:
	var entry: Variant = _reserved_build_cells.get(cell, {})
	if entry is Dictionary:
		return bool((entry as Dictionary).get("repair", false))
	return false

func _make_build_profile_data(profile_name: String) -> Dictionary:
	if profile_name == "tent":
		var tent_layers: Array[TileMapLayer] = []
		var tent_atlas_coords: Array[Vector2i] = []
		var tent_source_ids: Array[int] = []
		var tent_offsets: Array[Vector2i] = []
		if _tent_build_layer != null:
			tent_layers.append(_tent_build_layer)
			tent_atlas_coords.append(tent_atlas)
			tent_source_ids.append(tent_source_id)
			tent_offsets.append(Vector2i.ZERO)
		return {
			"name": "tent",
			"layers": tent_layers,
			"atlas": tent_atlas_coords,
			"source_ids": tent_source_ids,
			"offsets": tent_offsets,
			"stage_wood_costs": [tent_build_wood_cost],
			"requires_crafting": false
		}
	return {
		"name": "house",
		"layers": _build_phase_layers,
		"atlas": _build_phase_atlas,
		"source_ids": _build_phase_source_ids,
		"offsets": _build_phase_offsets,
		"stage_wood_costs": build_stage_wood_costs,
		"requires_crafting": true
	}

func _register_shelter_cell(cell: Vector2i, profile_name: String, owner_name: String = "") -> void:
	_shelter_cells[cell] = profile_name
	if not owner_name.is_empty():
		_home_owner_by_cell[cell] = owner_name

func _get_owned_home_cell(villager_name: String) -> Vector2i:
	if villager_name.is_empty():
		return Vector2i(-9999, -9999)
	for cell_variant in _home_owner_by_cell.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		if str(_home_owner_by_cell.get(cell, "")) != villager_name:
			continue
		if _shelter_cells.has(cell):
			return cell
	return Vector2i(-9999, -9999)

func _home_has_other_occupants(villager_name: String, home_cell: Vector2i) -> bool:
	var occupants_variant: Variant = _home_occupants.get(home_cell, [])
	if not (occupants_variant is Array):
		return false
	for occupant_variant in occupants_variant:
		if str(occupant_variant) != villager_name:
			return true
	return false

func _release_home_ownership(villager_name: String) -> void:
	if villager_name.is_empty():
		return
	for cell_variant in _home_owner_by_cell.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		if str(_home_owner_by_cell.get(cell, "")) == villager_name:
			_home_owner_by_cell.erase(cell)

func _choose_build_profile_name(wood_available: int) -> String:
	var can_build_tent: bool = _tent_build_layer != null and tent_build_wood_cost > 0
	if not can_build_tent:
		return "house"
	if wood_available < wood_cost_per_building:
		return "tent"
	if _crafting_table_positions.is_empty():
		return "tent"
	if randf() < tent_build_choice_chance:
		return "tent"
	return "house"

func trade_with_nearby_player(speaker_name: String, from_world_position: Vector2, preferred_name: String, give_item: String, give_amount: int, request_item: String, request_amount: int, message: String = "") -> Dictionary:
	var target: Dictionary = find_player_target(speaker_name, from_world_position, preferred_name)
	if target.is_empty():
		return {"traded": false, "reason": "no_target"}
	var distance: float = float(target.get("distance", INF))
	if distance > llm_trade_distance:
		return {"traded": false, "reason": "too_far", "target_name": str(target.get("name", "")), "world_position": target.get("world_position", from_world_position), "distance": distance}

	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var target_name: String = str(target.get("name", ""))
	var listener: VillagerAgent = _get_villager_by_name(target_name)
	if speaker == null or listener == null:
		return {"traded": false, "reason": "missing_npc"}

	var final_give_item: String = give_item.strip_edges().to_lower()
	var final_request_item: String = request_item.strip_edges().to_lower()
	var give_n: int = maxi(0, give_amount)
	var request_n: int = maxi(0, request_amount)
	if give_n <= 0 and request_n <= 0:
		return {"traded": false, "reason": "empty_trade"}

	if give_n > 0 and int(speaker.inventory.get(final_give_item, 0)) < give_n:
		return {"traded": false, "reason": "speaker_missing_item"}
	if request_n > 0 and int(listener.inventory.get(final_request_item, 0)) < request_n:
		return {"traded": false, "reason": "listener_missing_item"}

	if give_n > 0:
		speaker.inventory[final_give_item] = maxi(0, int(speaker.inventory.get(final_give_item, 0)) - give_n)
		listener.inventory[final_give_item] = int(listener.inventory.get(final_give_item, 0)) + give_n
	if request_n > 0:
		listener.inventory[final_request_item] = maxi(0, int(listener.inventory.get(final_request_item, 0)) - request_n)
		speaker.inventory[final_request_item] = int(speaker.inventory.get(final_request_item, 0)) + request_n

	var summary: String = "%s traded with %s" % [speaker_name, target_name]
	if give_n > 0:
		summary += " gave %d %s" % [give_n, final_give_item]
	if request_n > 0:
		summary += " received %d %s" % [request_n, final_request_item]
	_append_recent_event(speaker_name, summary)
	_append_recent_event(target_name, summary)

	var final_message: String = message.strip_edges().substr(0, 96)
	if speaker != null and not final_message.is_empty():
		speaker.show_chat_bubble(final_message)
	if listener != null:
		if speaker != null:
			speaker.fade_chat_bubble()
		listener.show_chat_bubble(_build_villager_reply(speaker_name, target_name, final_message if not final_message.is_empty() else "Trade?"))

	return {
		"traded": true,
		"target_name": target_name,
		"world_position": target.get("world_position", from_world_position),
		"distance": distance,
		"give_item": final_give_item,
		"give_amount": give_n,
		"request_item": final_request_item,
		"request_amount": request_n
	}

func _update_claim_observations(delta: float) -> void:
	_claim_observation_timer -= delta
	if _claim_observation_timer > 0.0:
		return
	_claim_observation_timer = claim_observation_interval_seconds
	var now: float = Time.get_unix_time_from_system()
	# Prevent unbounded growth of cooldown keys as NPCs roam and generate new cell combinations.
	for key_variant in _claim_observation_cooldowns.keys():
		var key: String = str(key_variant)
		if now >= float(_claim_observation_cooldowns.get(key, -1.0)):
			_claim_observation_cooldowns.erase(key)
	for observer in _get_active_villagers():
		var observer_name: String = observer.villager_name
		var claims: Array = _npc_claims.get(observer_name, [])
		if claims.is_empty():
			continue
		for intruder in _get_active_villagers():
			if intruder.villager_name == observer_name:
				continue
			if observer.position.distance_to(intruder.position) > claim_awareness_radius:
				continue
			if terrain == null:
				continue
			var intruder_cell: Vector2i = terrain.local_to_map(terrain.to_local(intruder.position))
			for claim_variant in claims:
				if not (claim_variant is Dictionary):
					continue
				var claim: Dictionary = claim_variant
				var claim_cell: Variant = claim.get("cell", Vector2i(-9999, -9999))
				if not (claim_cell is Vector2i):
					continue
				if claim_cell != intruder_cell:
					continue
				var event_key: String = "%s|%s|%d|%d" % [observer_name, intruder.villager_name, intruder_cell.x, intruder_cell.y]
				if now < float(_claim_observation_cooldowns.get(event_key, -1.0)):
					continue
				_claim_observation_cooldowns[event_key] = now + claim_observation_cooldown_seconds
				var text: String = "Saw %s on claimed tile (%d,%d)." % [intruder.villager_name, intruder_cell.x, intruder_cell.y]
				_append_recent_event(observer_name, text)
				var context: Dictionary = _npc_llm_contexts.get(observer_name, {})
				var nearby_claim_events: Array = context.get("nearby_claim_events", [])
				nearby_claim_events.append({"t": now, "text": text, "intruder": intruder.villager_name, "cell": intruder_cell})
				if nearby_claim_events.size() > 24:
					nearby_claim_events = nearby_claim_events.slice(nearby_claim_events.size() - 24, nearby_claim_events.size())
				context["nearby_claim_events"] = nearby_claim_events
				_npc_llm_contexts[observer_name] = context

func _purge_dead_npc_runtime_state(villager_name: String) -> void:
	# Clear per-NPC runtime state so long simulations do not accumulate dead NPC data.
	_npc_physical_genes.erase(villager_name)
	_npc_llm_genes.erase(villager_name)
	_npc_llm_contexts.erase(villager_name)
	_npc_last_llm_decisions.erase(villager_name)
	_npc_last_llm_request_time.erase(villager_name)
	_npc_pending_llm_state.erase(villager_name)
	_npc_llm_status.erase(villager_name)
	_npc_last_llm_error.erase(villager_name)
	_npc_last_llm_success_time.erase(villager_name)
	_npc_recent_thoughts.erase(villager_name)
	_npc_claims.erase(villager_name)
	_camera_last_positions.erase(villager_name)

	if _llm_active_requests.has(villager_name):
		var request_variant: Variant = _llm_active_requests[villager_name]
		if request_variant is HTTPRequest and is_instance_valid(request_variant):
			_abort_http_request(request_variant as HTTPRequest)
		_llm_active_requests.erase(villager_name)
	while _llm_request_queue.has(villager_name):
		_llm_request_queue.erase(villager_name)

	for owner_variant in _npc_conversations.keys():
		var owner_name: String = str(owner_variant)
		var threads: Dictionary = _npc_conversations.get(owner_name, {})
		if threads.has(villager_name):
			threads.erase(villager_name)
		if owner_name == villager_name or threads.is_empty():
			_npc_conversations.erase(owner_name)
		else:
			_npc_conversations[owner_name] = threads

	for cooldown_key_variant in _claim_observation_cooldowns.keys():
		var cooldown_key: String = str(cooldown_key_variant)
		if cooldown_key.begins_with(villager_name + "|") or cooldown_key.find("|" + villager_name + "|") >= 0:
			_claim_observation_cooldowns.erase(cooldown_key)
	for event_key_variant in _recent_event_cooldowns.keys():
		var event_key: String = str(event_key_variant)
		if event_key.begins_with(villager_name + "|"):
			_recent_event_cooldowns.erase(event_key)

func _prune_stale_npc_runtime_state() -> void:
	var active_lookup: Dictionary = {}
	for villager in _get_active_villagers():
		active_lookup[villager.villager_name] = true
	if not _inspected_villager_name.is_empty():
		active_lookup[_inspected_villager_name] = true

	for name_variant in _npc_physical_genes.keys():
		var name: String = str(name_variant)
		if not active_lookup.has(name):
			_purge_dead_npc_runtime_state(name)

	var kept_queue: Array[String] = []
	for queued_name in _llm_request_queue:
		if active_lookup.has(queued_name):
			kept_queue.append(queued_name)
	_llm_request_queue = kept_queue

	var now: float = Time.get_unix_time_from_system()
	for event_key_variant in _recent_event_cooldowns.keys():
		var event_key: String = str(event_key_variant)
		var keep_name: bool = false
		var sep: int = event_key.find("|")
		if sep > 0:
			var event_owner: String = event_key.substr(0, sep)
			keep_name = active_lookup.has(event_owner)
		if (not keep_name) or now >= float(_recent_event_cooldowns.get(event_key, -1.0)):
			_recent_event_cooldowns.erase(event_key)

func _init_water_current_noise() -> void:
	var seed_base: int = island_noise_seed if island_noise_seed != 0 else randi()
	_water_current_noise_x = FastNoiseLite.new()
	_water_current_noise_x.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_water_current_noise_x.seed = seed_base + 113
	_water_current_noise_x.frequency = water_current_noise_scale
	_water_current_noise_x.fractal_type = FastNoiseLite.FRACTAL_FBM
	_water_current_noise_x.fractal_octaves = 2

	_water_current_noise_y = FastNoiseLite.new()
	_water_current_noise_y.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_water_current_noise_y.seed = seed_base + 271
	_water_current_noise_y.frequency = water_current_noise_scale
	_water_current_noise_y.fractal_type = FastNoiseLite.FRACTAL_FBM
	_water_current_noise_y.fractal_octaves = 2

func _init_wind_current_noise() -> void:
	var seed_base: int = island_noise_seed if island_noise_seed != 0 else randi()
	_wind_current_noise_x = FastNoiseLite.new()
	_wind_current_noise_x.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_wind_current_noise_x.seed = seed_base + 901
	_wind_current_noise_x.frequency = wind_current_noise_scale
	_wind_current_noise_x.fractal_type = FastNoiseLite.FRACTAL_FBM
	_wind_current_noise_x.fractal_octaves = 2

	_wind_current_noise_y = FastNoiseLite.new()
	_wind_current_noise_y.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_wind_current_noise_y.seed = seed_base + 1409
	_wind_current_noise_y.frequency = wind_current_noise_scale
	_wind_current_noise_y.fractal_type = FastNoiseLite.FRACTAL_FBM
	_wind_current_noise_y.fractal_octaves = 2

func _init_climate_noise() -> void:
	var seed_base: int = island_noise_seed if island_noise_seed != 0 else randi()
	_heat_noise = FastNoiseLite.new()
	_heat_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_heat_noise.seed = seed_base + 1901
	_heat_noise.frequency = climate_heat_noise_scale
	_heat_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_heat_noise.fractal_octaves = 3

	_humidity_noise = FastNoiseLite.new()
	_humidity_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_humidity_noise.seed = seed_base + 2657
	_humidity_noise.frequency = climate_humidity_noise_scale
	_humidity_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_humidity_noise.fractal_octaves = 3

func _sun_intensity() -> float:
	# Simple day/night cycle with soft dawn/dusk transitions.
	var phase: float = fmod(_water_wave_time * SUN_CYCLE_SPEED, TAU)
	return clampf(0.5 + 0.5 * sin(phase - PI * 0.5), 0.0, 1.0)

func _setup_day_night_lighting() -> void:
	if _day_night_modulate == null:
		_day_night_modulate = CanvasModulate.new()
		_day_night_modulate.name = "DayNightLighting"
		add_child(_day_night_modulate)
	_current_day_night_brightness = day_max_brightness
	_update_day_night_lighting(0.0)

func _update_day_night_lighting(delta: float) -> void:
	if _day_night_modulate == null:
		return
	if not day_night_visual_enabled:
		_current_day_night_brightness = 1.0
		_day_night_modulate.color = Color(1.0, 1.0, 1.0, 1.0)
		return
	var sun: float = _sun_intensity()
	var target_brightness: float = lerpf(night_min_brightness, day_max_brightness, sun)
	if _current_weather == "rainy":
		target_brightness *= rainy_light_dim_multiplier
	elif _current_weather == "thunderstorm":
		target_brightness *= thunderstorm_light_dim_multiplier
	if delta <= 0.0:
		_current_day_night_brightness = target_brightness
	else:
		var weight: float = clampf(delta * day_night_brightness_lerp_speed, 0.0, 1.0)
		_current_day_night_brightness = lerpf(_current_day_night_brightness, target_brightness, weight)
	_current_day_night_brightness = clampf(_current_day_night_brightness, 0.0, 2.0)
	_day_night_modulate.color = Color(
		_current_day_night_brightness,
		_current_day_night_brightness,
		_current_day_night_brightness,
		1.0
	)

func _water_influence_factor(world_position: Vector2) -> float:
	if _is_water_world_position(world_position):
		return 1.0
	var radius: float = maxf(8.0, climate_water_influence_radius)
	var probes: Array[Vector2] = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN,
		Vector2(1.0, 1.0).normalized(),
		Vector2(-1.0, 1.0).normalized(),
		Vector2(1.0, -1.0).normalized(),
		Vector2(-1.0, -1.0).normalized()
	]
	var best: float = 0.0
	for step in [0.34, 0.67, 1.0]:
		var dist: float = radius * step
		for dir in probes:
			var probe: Vector2 = world_position + dir * dist
			if _is_water_world_position(probe):
				best = maxf(best, 1.0 - step)
	return best

func sample_thermal_environment(world_position: Vector2) -> Dictionary:
	if not thermal_system_enabled:
		return {
			"ambient_temp_c": ambient_base_temperature_c,
			"humidity": clampf(ambient_base_humidity, 0.0, 1.0),
			"sun_intensity": 0.0,
			"water_influence": 0.0,
			"in_water": _is_water_world_position(world_position)
		}
	var heat_sample: float = 0.0
	if _heat_noise != null:
		heat_sample = _heat_noise.get_noise_2d(world_position.x, world_position.y)
	var humidity_sample: float = 0.0
	if _humidity_noise != null:
		humidity_sample = _humidity_noise.get_noise_2d(world_position.x + 183.0, world_position.y - 257.0)
	var sun: float = _sun_intensity()
	var water_influence: float = _water_influence_factor(world_position)
	var ambient_temp_c: float = ambient_base_temperature_c + heat_sample * climate_heat_variation_c + sun * climate_sun_heating_c - water_influence * climate_water_cooling_c
	var humidity: float = ambient_base_humidity + humidity_sample * climate_humidity_variation + water_influence * climate_water_humidity_boost
	# Day/night swing: at sun=1 it is +day_night_temp_swing_c above base, at sun=0 it is -day_night_temp_swing_c.
	# Humidity insulates: high humidity damps the swing (like a coastal/cloudy buffer).
	var humidity_insulation: float = clampf(humidity, 0.0, 1.0)
	var day_night_delta: float = (sun * 2.0 - 1.0) * day_night_temp_swing_c * (1.0 - humidity_insulation * 0.65)
	ambient_temp_c += day_night_delta
	ambient_temp_c += _campfire_warmth_bonus_at(world_position)
	if _is_desert_world_position(world_position):
		ambient_temp_c += desert_temperature_bonus_c
		humidity = desert_humidity
	return {
		"ambient_temp_c": ambient_temp_c,
		"humidity": clampf(humidity, 0.0, 1.0),
		"sun_intensity": sun,
		"water_influence": clampf(water_influence, 0.0, 1.0),
		"in_water": _is_water_world_position(world_position)
	}

func find_nearest_water_world_position(from_world_position: Vector2, max_radius_tiles: int = 24) -> Vector2:
	if terrain == null:
		return Vector2(INF, INF)
	var center_cell: Vector2i = terrain.local_to_map(terrain.to_local(from_world_position))
	var max_r: int = maxi(2, max_radius_tiles)
	var best: Vector2 = Vector2(INF, INF)
	var best_dist: float = INF
	for r in range(0, max_r + 1):
		for y in range(center_cell.y - r, center_cell.y + r + 1):
			for x in range(center_cell.x - r, center_cell.x + r + 1):
				if abs(x - center_cell.x) != r and abs(y - center_cell.y) != r:
					continue
				var cell: Vector2i = Vector2i(x, y)
				if terrain.get_cell_source_id(cell) == -1:
					continue
				if terrain.get_cell_atlas_coords(cell) != WATER_TILES[0]:
					continue
				var world_pos: Vector2 = terrain.to_global(terrain.map_to_local(cell))
				var d: float = from_world_position.distance_to(world_pos)
				if d < best_dist:
					best_dist = d
					best = world_pos
		if best_dist < INF:
			break
	return best

func _is_water_world_position(world_position: Vector2) -> bool:
	if terrain == null:
		return false
	var cell: Vector2i = terrain.local_to_map(terrain.to_local(world_position))
	if terrain.get_cell_source_id(cell) == -1:
		return false
	return terrain.get_cell_atlas_coords(cell) == WATER_TILES[0]

func _is_desert_world_position(world_position: Vector2) -> bool:
	if terrain == null:
		return false
	var cell: Vector2i = terrain.local_to_map(terrain.to_local(world_position))
	if terrain.get_cell_source_id(cell) == -1:
		return false
	var atlas: Vector2i = terrain.get_cell_atlas_coords(cell)
	return atlas == DESERT_MIDDLE_TILE or atlas == DESERT_BOTTOM_EDGE_TILE

func _is_desert_biome_cell(cell: Vector2i) -> bool:
	if not biome_system_enabled or _biome_noise == null:
		return false
	return _biome_noise.get_noise_2d(float(cell.x), float(cell.y)) >= desert_biome_threshold

func _init_biome_noise() -> void:
	var biome_seed: int = island_noise_seed if island_noise_seed != 0 else randi()
	_biome_noise = FastNoiseLite.new()
	_biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_biome_noise.seed = biome_seed + 157
	_biome_noise.frequency = biome_noise_scale
	_biome_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_biome_noise.fractal_octaves = 2

func _setup_cactus_system() -> void:
	_cactus_layer = Node2D.new()
	_cactus_layer.name = "CactusLayer"
	_cactus_layer.z_index = 2
	_cactus_layer.y_sort_enabled = true
	add_child(_cactus_layer)
	_cactus_texture = load("res://Cactus.png") as Texture2D

func _clear_cacti() -> void:
	_spawned_cactus_cells.clear()
	_cactus_pear_timers.clear()
	if _cactus_layer == null:
		return
	for child in _cactus_layer.get_children():
		child.queue_free()

func _update_cactus_drops(delta: float) -> void:
	for cell in _cactus_pear_timers.keys():
		_cactus_pear_timers[cell] = float(_cactus_pear_timers[cell]) - delta
		if float(_cactus_pear_timers[cell]) <= 0.0:
			_cactus_pear_timers[cell] = prickly_pear_regrow_seconds
			if randf() < prickly_pear_drop_chance * 8.0:  # extra roll per cycle keeps it rare overall
				var cactus_sprite: Sprite2D = _spawned_cactus_cells.get(cell, null)
				if cactus_sprite != null and is_instance_valid(cactus_sprite):
					_spawn_drop("prickly_pear", cactus_sprite.position, true, 1)

func get_cactus_water_bottle(villager_name: String, world_position: Vector2) -> Dictionary:
	# Called by VillagerAgent when chopping a cactus: gives a refillable water bottle.
	var best_cell: Vector2i = Vector2i(-9999, -9999)
	var best_dist: float = 40.0
	for cell in _spawned_cactus_cells.keys():
		var cactus_sprite: Sprite2D = _spawned_cactus_cells[cell]
		if cactus_sprite == null or not is_instance_valid(cactus_sprite):
			continue
		var d: float = world_position.distance_to(cactus_sprite.position)
		if d < best_dist:
			best_dist = d
			best_cell = cell
	if best_cell == Vector2i(-9999, -9999):
		return {}
	# Harvest: reset the pear timer and return a cactus_bottle
	_cactus_pear_timers[best_cell] = prickly_pear_regrow_seconds
	return {"cactus_bottle": 1}

func _maybe_spawn_cactus(cell: Vector2i) -> void:
	if _cactus_layer == null or _cactus_texture == null or terrain == null:
		return
	if _spawned_cactus_cells.has(cell):
		return
	var density_roll: float = _cell_random01(cell + Vector2i(131, -73))
	if density_roll >= desert_cactus_density:
		return
	var world_position: Vector2 = terrain.to_global(terrain.map_to_local(cell))
	var jitter_x: float = (_cell_random01(cell + Vector2i(29, 41)) * 2.0 - 1.0) * 3.0
	var jitter_y: float = (_cell_random01(cell + Vector2i(-17, 53)) * 2.0 - 1.0) * 2.0
	var cactus_pos: Vector2 = world_position + Vector2(jitter_x, jitter_y)
	# Shadow ellipse drawn as a flat darker sprite below the cactus
	var shadow := Sprite2D.new()
	var shadow_img := Image.create(28, 10, false, Image.FORMAT_RGBA8)
	for sy in range(10):
		for sx in range(28):
			var dx: float = (float(sx) - 13.5) / 13.5
			var dy: float = (float(sy) - 4.5) / 4.5
			if dx * dx + dy * dy <= 1.0:
				shadow_img.set_pixel(sx, sy, Color(0.0, 0.0, 0.0, 0.38))
	shadow.texture = ImageTexture.create_from_image(shadow_img)
	shadow.centered = true
	var cactus_height: float = float(_cactus_texture.get_height())
	var shadow_y_offset: float = maxf(12.0, cactus_height * 0.42)
	shadow.position = cactus_pos + Vector2(0.0, shadow_y_offset)
	shadow.z_index = -1
	_cactus_layer.add_child(shadow)
	var cactus := Sprite2D.new()
	cactus.texture = _cactus_texture
	cactus.centered = true
	cactus.y_sort_enabled = true
	cactus.position = cactus_pos
	_cactus_layer.add_child(cactus)
	_spawned_cactus_cells[cell] = cactus
	# Stagger the first pear drop so not all cacti drop at once
	_cactus_pear_timers[cell] = randf_range(prickly_pear_regrow_seconds * 0.5, prickly_pear_regrow_seconds)

func _sample_water_current(world_position: Vector2) -> Vector2:
	if _water_current_noise_x == null or _water_current_noise_y == null:
		return Vector2.RIGHT
	var sample_x: float = world_position.x + _water_wave_time * 22.0
	var sample_y: float = world_position.y + _water_wave_time * 17.0
	var cx: float = _water_current_noise_x.get_noise_2d(sample_x, sample_y)
	var cy: float = _water_current_noise_y.get_noise_2d(sample_x + 311.0, sample_y - 199.0)
	var current := Vector2(cx, cy)
	if current.length_squared() < 0.0009:
		var angle: float = _water_wave_time + world_position.x * 0.002 + world_position.y * 0.0027
		return Vector2(cos(angle), sin(angle))
	return current.normalized()

func sample_water_current_velocity(world_position: Vector2) -> Vector2:
	if not _is_water_world_position(world_position):
		return Vector2.ZERO
	return _sample_water_current(world_position) * water_current_speed

func _sample_wind_current(world_position: Vector2) -> Vector2:
	if _wind_current_noise_x == null or _wind_current_noise_y == null:
		return Vector2.RIGHT
	var sample_x: float = world_position.x + _water_wave_time * 11.0
	var sample_y: float = world_position.y + _water_wave_time * 9.0
	var wx: float = _wind_current_noise_x.get_noise_2d(sample_x, sample_y)
	var wy: float = _wind_current_noise_y.get_noise_2d(sample_x + 53.0, sample_y - 71.0)
	var current := Vector2(wx, wy)
	var direction: Vector2
	if current.length_squared() < 0.0009:
		var angle: float = _water_wave_time * 0.6 + world_position.x * 0.0011 + world_position.y * 0.0009
		direction = Vector2(cos(angle), sin(angle))
	else:
		direction = current.normalized()

	# Gust strength includes calm pockets so seeds can settle on ground.
	var gust_noise: float = _wind_current_noise_x.get_noise_2d(sample_x * 0.61 + 91.0, sample_y * 0.61 - 47.0)
	var gust_strength: float = clampf((gust_noise + 1.0) * 0.5, 0.0, 1.0)
	gust_strength = clampf((gust_strength - wind_gust_deadzone) / maxf(0.001, 1.0 - wind_gust_deadzone), 0.0, 1.0)
	return direction * gust_strength

func _update_water_wave_animation(delta: float) -> void:
	if terrain == null or world_camera == null:
		return
	_water_wave_timer -= delta
	if _water_wave_timer > 0.0:
		return
	_water_wave_timer = water_wave_interval_seconds

	var center_cell: Vector2i = terrain.local_to_map(terrain.to_local(world_camera.position))
	for y in range(center_cell.y - water_wave_radius_tiles, center_cell.y + water_wave_radius_tiles + 1):
		for x in range(center_cell.x - water_wave_radius_tiles, center_cell.x + water_wave_radius_tiles + 1):
			var cell := Vector2i(x, y)
			if terrain.get_cell_source_id(cell) == -1:
				continue
			if terrain.get_cell_atlas_coords(cell) != WATER_TILES[0]:
				continue
			var world_pos: Vector2 = terrain.to_global(terrain.map_to_local(cell))
			var current: Vector2 = _sample_water_current(world_pos)
			var phase: float = sin(_water_wave_time * 3.1 + float(x) * 0.27 + float(y) * 0.19)
			var alt: int = 0
			if current.x < 0.0:
				alt = TileSetAtlasSource.TRANSFORM_FLIP_H
			if phase > 0.45:
				alt = alt ^ TileSetAtlasSource.TRANSFORM_FLIP_H
			if terrain.get_cell_alternative_tile(cell) != alt:
				terrain.set_cell(cell, TERRAIN_SOURCE_ID, WATER_TILES[0], alt)

func _initialize_camera_cycle() -> void:
	if world_camera == null:
		return
	_camera_base_zoom = world_camera.zoom
	_camera_target_position = _arena_rect.get_center()
	_camera_target_zoom = _camera_base_zoom
	if camera_region_points.is_empty():
		var center := _arena_rect.get_center()
		camera_region_points = [
			center,
			_arena_rect.position + _arena_rect.size * Vector2(0.25, 0.25),
			_arena_rect.position + _arena_rect.size * Vector2(0.75, 0.25),
			_arena_rect.position + _arena_rect.size * Vector2(0.25, 0.75),
			_arena_rect.position + _arena_rect.size * Vector2(0.75, 0.75)
		]
	_camera_phase_time_left = 0.0
	_camera_phase_index = -1
	_camera_cycle_last_npcs_only = camera_cycle_npcs_only
	_rebuild_camera_phase_order()
	_camera_manual_focus_name = ""
	_camera_manual_focus_time_left = 0.0
	for villager in _get_active_villagers():
		_camera_last_positions[villager.villager_name] = villager.position

func _rebuild_camera_phase_order() -> void:
	if camera_cycle_npcs_only:
		_camera_phase_order = [CAMERA_PHASE_PLAYER]
	else:
		_camera_phase_order = [CAMERA_PHASE_PLAYER, CAMERA_PHASE_REGION, CAMERA_PHASE_ACTION, CAMERA_PHASE_OVERVIEW]
	_camera_phase_index = -1
	_camera_phase_time_left = 0.0

func _update_camera_cycle(delta: float) -> void:
	if world_camera == null:
		return
	if _has_active_locked_conversation():
		var a_name: String = str(_active_locked_conversation.get("a", ""))
		var b_name: String = str(_active_locked_conversation.get("b", ""))
		var a: VillagerAgent = _get_villager_by_name(a_name)
		var b: VillagerAgent = _get_villager_by_name(b_name)
		if a != null and b != null:
			_camera_target_position = (a.position + b.position) * 0.5
			_camera_target_zoom = _camera_base_zoom * conversation_camera_zoom_multiplier
			var max_zoom := _camera_base_zoom * camera_max_zoom_multiplier
			_camera_target_zoom.x = minf(_camera_target_zoom.x, max_zoom.x)
			_camera_target_zoom.y = minf(_camera_target_zoom.y, max_zoom.y)
			var follow_conv_weight: float = clampf(camera_follow_smoothing * delta, 0.0, 1.0)
			var zoom_conv_weight: float = clampf(camera_zoom_smoothing * delta, 0.0, 1.0)
			world_camera.position = world_camera.position.lerp(_camera_target_position, follow_conv_weight)
			world_camera.zoom = world_camera.zoom.lerp(_camera_target_zoom, zoom_conv_weight)
			return
		_end_locked_conversation("missing_participant")
		return
	if not camera_cycle_enabled:
		return
	if _camera_cycle_last_npcs_only != camera_cycle_npcs_only:
		_camera_cycle_last_npcs_only = camera_cycle_npcs_only
		_rebuild_camera_phase_order()
	if _camera_phase_order.is_empty():
		_rebuild_camera_phase_order()
	if _camera_manual_focus_time_left > 0.0 and not _camera_manual_focus_name.is_empty():
		var focused: VillagerAgent = _get_villager_by_name(_camera_manual_focus_name)
		if focused != null:
			_camera_target_position = focused.position
			_camera_target_zoom = _camera_base_zoom * camera_focus_zoom_multiplier
			_camera_manual_focus_time_left = maxf(0.0, _camera_manual_focus_time_left - delta)
			var max_manual_zoom := _camera_base_zoom * camera_max_zoom_multiplier
			_camera_target_zoom.x = minf(_camera_target_zoom.x, max_manual_zoom.x)
			_camera_target_zoom.y = minf(_camera_target_zoom.y, max_manual_zoom.y)
			var follow_manual_weight: float = clampf(camera_follow_smoothing * delta, 0.0, 1.0)
			var zoom_manual_weight: float = clampf(camera_zoom_smoothing * delta, 0.0, 1.0)
			world_camera.position = world_camera.position.lerp(_camera_target_position, follow_manual_weight)
			world_camera.zoom = world_camera.zoom.lerp(_camera_target_zoom, zoom_manual_weight)
			if _camera_manual_focus_time_left <= 0.0:
				_camera_manual_focus_name = ""
			return
		_camera_manual_focus_name = ""
		_camera_manual_focus_time_left = 0.0

	if _camera_phase_time_left <= 0.0:
		_advance_camera_phase()
	_camera_phase_time_left -= delta

	var phase: int = _camera_phase_order[_camera_phase_index]
	match phase:
		CAMERA_PHASE_PLAYER:
			_update_camera_player_target()
			_camera_target_zoom = _camera_base_zoom * camera_focus_zoom_multiplier
		CAMERA_PHASE_REGION:
			_update_camera_region_target()
			_camera_target_zoom = _camera_base_zoom * camera_region_zoom_multiplier
		CAMERA_PHASE_ACTION:
			_camera_target_position = _get_action_hotspot(delta)
			_camera_target_zoom = _camera_base_zoom * camera_action_zoom_multiplier
		CAMERA_PHASE_OVERVIEW:
			_camera_target_position = _arena_rect.get_center()
			_camera_target_zoom = _camera_base_zoom * camera_overview_zoom_multiplier

	var max_zoom := _camera_base_zoom * camera_max_zoom_multiplier
	_camera_target_zoom.x = minf(_camera_target_zoom.x, max_zoom.x)
	_camera_target_zoom.y = minf(_camera_target_zoom.y, max_zoom.y)

	var follow_weight: float = clampf(camera_follow_smoothing * delta, 0.0, 1.0)
	var zoom_weight: float = clampf(camera_zoom_smoothing * delta, 0.0, 1.0)
	world_camera.position = world_camera.position.lerp(_camera_target_position, follow_weight)
	world_camera.zoom = world_camera.zoom.lerp(_camera_target_zoom, zoom_weight)

func _advance_camera_phase() -> void:
	if _camera_phase_order.is_empty():
		_rebuild_camera_phase_order()
		if _camera_phase_order.is_empty():
			return
	_camera_phase_index = (_camera_phase_index + 1) % _camera_phase_order.size()
	var phase: int = _camera_phase_order[_camera_phase_index]
	match phase:
		CAMERA_PHASE_PLAYER:
			var villagers := _get_active_villagers()
			if not villagers.is_empty():
				_camera_current_player_index = _camera_player_rotator % villagers.size()
				_camera_player_rotator += 1
		CAMERA_PHASE_REGION:
			if not camera_region_points.is_empty():
				_camera_current_region_index = _camera_region_rotator % camera_region_points.size()
				_camera_region_rotator += 1

	_camera_phase_time_left = _get_camera_phase_duration(phase)

func _get_camera_phase_duration(phase: int) -> float:
	match phase:
		CAMERA_PHASE_PLAYER:
			return maxf(0.8, camera_phase_player_seconds)
		CAMERA_PHASE_REGION:
			return maxf(0.8, camera_phase_region_seconds)
		CAMERA_PHASE_ACTION:
			return maxf(0.8, camera_phase_action_seconds)
		_:
			return maxf(0.8, camera_phase_overview_seconds)

func _update_camera_player_target() -> void:
	var villagers := _get_active_villagers()
	if villagers.is_empty():
		_camera_target_position = _arena_rect.get_center()
		return
	var index: int = clampi(_camera_current_player_index, 0, villagers.size() - 1)
	_camera_target_position = villagers[index].position

func _update_camera_region_target() -> void:
	if camera_region_points.is_empty():
		_camera_target_position = _arena_rect.get_center()
		return
	var index: int = clampi(_camera_current_region_index, 0, camera_region_points.size() - 1)
	_camera_target_position = camera_region_points[index]

func _get_action_hotspot(delta: float) -> Vector2:
	var villagers := _get_active_villagers()
	if villagers.is_empty():
		return _arena_rect.get_center()

	var best_score: float = -1.0
	var best_position: Vector2 = villagers[0].position
	for villager in villagers:
		var pos: Vector2 = villager.position
		var previous: Vector2 = _camera_last_positions.get(villager.villager_name, pos)
		var speed: float = pos.distance_to(previous) / maxf(0.001, delta)
		var nearby_count: int = 0
		for other in villagers:
			if other == villager:
				continue
			if other.position.distance_to(pos) < 130.0:
				nearby_count += 1
		var score: float = speed * 0.06 + float(nearby_count) * 1.4
		if score > best_score:
			best_score = score
			best_position = pos
		_camera_last_positions[villager.villager_name] = pos

	return best_position

func _get_active_villagers() -> Array[VillagerAgent]:
	var active: Array[VillagerAgent] = []
	for villager in _villagers:
		if is_instance_valid(villager):
			active.append(villager)
	_villagers = active
	return active

func _resolve_villager_overlap(delta: float) -> void:
	var villagers: Array[VillagerAgent] = _get_active_villagers()
	if villagers.size() < 2:
		return
	var min_separation: float = 20.0
	var push_strength: float = 42.0 * maxf(0.25, delta)
	for i in range(villagers.size() - 1):
		var a: VillagerAgent = villagers[i]
		if a == null or a._is_dead:
			continue
		for j in range(i + 1, villagers.size()):
			var b: VillagerAgent = villagers[j]
			if b == null or b._is_dead:
				continue
			var offset: Vector2 = b.position - a.position
			var distance: float = offset.length()
			if distance >= min_separation:
				continue
			var direction: Vector2 = offset / distance if distance > 0.001 else Vector2(cos(float(i + j) * 1.37), sin(float(i + j) * 2.11))
			var overlap: float = min_separation - distance
			var push: Vector2 = direction.normalized() * overlap * 0.5
			a.position -= push * push_strength * 0.02
			b.position += push * push_strength * 0.02
			if a._has_player_target and a.position.distance_to(a._player_target_world_position) > 6.0:
				a._path_goal_world_position = Vector2(INF, INF)
			if b._has_player_target and b.position.distance_to(b._player_target_world_position) > 6.0:
				b._path_goal_world_position = Vector2(INF, INF)

func _count_living_villagers() -> int:
	var living: int = 0
	for villager in _get_active_villagers():
		if not villager._is_dead:
			living += 1
	return living

func _restart_if_all_villagers_dead() -> void:
	if _count_living_villagers() <= 0:
		get_tree().reload_current_scene()

func _setup_shadow_overlay() -> void:
	if not enable_layer_shadows:
		return
	_shadow_overlay = Node2D.new()
	_shadow_overlay.z_index = 0
	_shadow_overlay.name = "ShadowOverlay"
	add_child(_shadow_overlay)
	move_child(_shadow_overlay, terrain.get_index() + 1)
	_shadow_overlay.draw.connect(_on_shadow_draw)
	_shadow_overlay.queue_redraw()

func _setup_claims_overlay() -> void:
	_claims_overlay_layer = null
	_claims_overlay = Node2D.new()
	_claims_overlay.z_index = 0
	_claims_overlay.z_as_relative = false
	_claims_overlay.name = "ClaimsOverlay"
	_claims_overlay.visible = show_claims_overlay
	_claims_overlay_last_visible = show_claims_overlay
	add_child(_claims_overlay)
	if terrain != null:
		move_child(_claims_overlay, terrain.get_index() + 1)
	_claims_overlay.draw.connect(_on_claims_overlay_draw)
	if show_claims_overlay:
		_claims_overlay.queue_redraw()

func _setup_climate_overlay() -> void:
	_climate_overlay = Node2D.new()
	_climate_overlay.z_index = 0
	_climate_overlay.name = "ClimateOverlay"
	_climate_overlay_last_visible = show_heat_map_overlay or show_humidity_map_overlay
	_climate_overlay.visible = _climate_overlay_last_visible
	_set_climate_overlay_background_grayscale(_climate_overlay_last_visible)
	add_child(_climate_overlay)
	if terrain != null:
		move_child(_climate_overlay, terrain.get_index() + 1)
	_climate_overlay.draw.connect(_on_climate_overlay_draw)
	if _climate_overlay_last_visible:
		_climate_overlay.queue_redraw()

func _ensure_climate_grayscale_material() -> void:
	if _climate_grayscale_material != null:
		return
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV) * COLOR;
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, vec3(luma), amount);
	COLOR = col;
}
"""
	_climate_grayscale_material = ShaderMaterial.new()
	_climate_grayscale_material.shader = shader

func _set_climate_overlay_background_grayscale(enabled: bool) -> void:
	if enabled:
		_ensure_climate_grayscale_material()
	if terrain != null:
		if enabled:
			if not _climate_original_materials.has(terrain):
				_climate_original_materials[terrain] = terrain.material
			terrain.material = _climate_grayscale_material
		elif _climate_original_materials.has(terrain):
			terrain.material = _climate_original_materials[terrain]
	if not enabled:
		_climate_original_materials.clear()

func _setup_conversation_overlay() -> void:
	pass

func _start_conversation_overlay_fade() -> void:
	pass

func _end_conversation_overlay_fade() -> void:
	pass

func _update_conversation_overlay_fade(delta: float) -> void:
	pass

func _temperature_to_overlay_color(temp_c: float) -> Color:
	var t: float = clampf((temp_c - 8.0) / 36.0, 0.0, 1.0)
	return Color.from_hsv(lerpf(0.62, 0.0, t), 0.75, 0.95, climate_overlay_alpha)

func _humidity_to_overlay_color(humidity: float) -> Color:
	var h: float = clampf(humidity, 0.0, 1.0)
	return Color(0.18, 0.66, 0.98, lerpf(climate_overlay_alpha * 0.2, climate_overlay_alpha * 0.95, h))

func _on_climate_overlay_draw() -> void:
	if terrain == null:
		return
	if not show_heat_map_overlay and not show_humidity_map_overlay:
		return
	var camera_center: Vector2 = world_camera.position if world_camera != null else _arena_rect.get_center()
	var zoom: Vector2 = world_camera.zoom if world_camera != null else Vector2.ONE
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var half_extent: Vector2 = viewport_rect.size * 0.5 * zoom
	var world_rect: Rect2 = Rect2(camera_center - half_extent - Vector2(64.0, 64.0), half_extent * 2.0 + Vector2(128.0, 128.0))
	var min_cell: Vector2i = terrain.local_to_map(terrain.to_local(world_rect.position))
	var max_cell: Vector2i = terrain.local_to_map(terrain.to_local(world_rect.position + world_rect.size))
	var tile_size: Vector2 = Vector2(terrain.tile_set.tile_size) if terrain.tile_set != null else Vector2(16.0, 16.0)
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			if terrain.get_cell_source_id(cell) == -1:
				continue
			var center: Vector2 = terrain.to_global(terrain.map_to_local(cell))
			var climate: Dictionary = sample_thermal_environment(center)
			var rect: Rect2 = Rect2(center - tile_size * 0.5, tile_size)
			if show_heat_map_overlay:
				_climate_overlay.draw_rect(rect, _temperature_to_overlay_color(float(climate.get("ambient_temp_c", ambient_base_temperature_c))), true)
			if show_humidity_map_overlay:
				var hum_col: Color = _humidity_to_overlay_color(float(climate.get("humidity", ambient_base_humidity)))
				var inner_rect: Rect2 = rect.grow(-2.0)
				_climate_overlay.draw_rect(inner_rect, hum_col, false, 1.6)

func _color_for_owner(owner_name: String) -> Color:
	var hash_seed: int = 0
	for i in owner_name.length():
		hash_seed = int((hash_seed * 131 + owner_name.unicode_at(i)) % 9973)
	var hue: float = fmod(float(hash_seed) / 9973.0 + 0.07, 1.0)
	var sat: float = 0.62
	var val: float = 0.92
	var col: Color = Color.from_hsv(hue, sat, val)
	col.a = claims_overlay_alpha
	return col

func _on_claims_overlay_draw() -> void:
	if terrain == null or _npc_claims.is_empty():
		return
	var tile_size: Vector2 = Vector2(terrain.tile_set.tile_size) if terrain.tile_set != null else Vector2(16.0, 16.0)
	var claim_owners_by_cell: Dictionary = {}
	for owner_name_variant in _npc_claims.keys():
		var owner_name: String = str(owner_name_variant)
		var claims: Variant = _npc_claims.get(owner_name, [])
		if not (claims is Array):
			continue
		for claim_variant in claims:
			if not (claim_variant is Dictionary):
				continue
			var claim_cell_variant: Variant = (claim_variant as Dictionary).get("cell", Vector2i(-9999, -9999))
			if not (claim_cell_variant is Vector2i):
				continue
			var claim_cell: Vector2i = claim_cell_variant
			var cell_key: String = "%d,%d" % [claim_cell.x, claim_cell.y]
			var cell_owners: Array = claim_owners_by_cell.get(cell_key, [])
			if not cell_owners.has(owner_name):
				cell_owners.append(owner_name)
			claim_owners_by_cell[cell_key] = cell_owners
	for owner_name in _npc_claims.keys():
		var claims: Variant = _npc_claims.get(owner_name, [])
		if not (claims is Array):
			continue
		var fill_color: Color = _color_for_owner(str(owner_name))
		var outline_color: Color = fill_color.lightened(0.3)
		outline_color.a = 1.0
		for claim_variant in claims:
			if not (claim_variant is Dictionary):
				continue
			var claim: Dictionary = claim_variant
			var cell_variant: Variant = claim.get("cell", Vector2i(-9999, -9999))
			if not (cell_variant is Vector2i):
				continue
			var cell: Vector2i = cell_variant
			var cell_key: String = "%d,%d" % [cell.x, cell.y]
			var cell_owners: Array = claim_owners_by_cell.get(cell_key, [])
			var center: Vector2 = terrain.to_global(terrain.map_to_local(cell))
			var rect := Rect2(center - tile_size * 0.5, tile_size)
			var conflict: bool = cell_owners.size() > 1
			if conflict:
				var conflict_fill: Color = Color(0.92, 0.28, 0.18, claims_overlay_alpha * 0.65)
				var conflict_outline: Color = Color(1.0, 0.55, 0.25, 1.0)
				_claims_overlay.draw_rect(rect.grow(-1.0), conflict_fill, true)
				_claims_overlay.draw_rect(rect, conflict_outline, false, maxf(3.0, claims_overlay_outline_width + 1.0))
				_claims_overlay.draw_line(rect.position, rect.end, conflict_outline, maxf(2.0, claims_overlay_outline_width + 0.5))
				_claims_overlay.draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), conflict_outline, maxf(2.0, claims_overlay_outline_width + 0.5))
			else:
				_claims_overlay.draw_rect(rect, fill_color, true)
				_claims_overlay.draw_rect(rect, outline_color, false, maxf(2.0, claims_overlay_outline_width))

func _on_shadow_draw() -> void:
	var shadow_samples: Array[Dictionary] = []
	for child in get_children():
		if not (child is TileMapLayer) or child == terrain:
			continue
		var layer := child as TileMapLayer
		# Skip campfire layer entirely - campfires use overlays and don't need tilemap shadows
		if layer == _campfire_layer:
			continue
		for cell in layer.get_used_cells():
			if _is_configured_lit_campfire_tile(layer, cell):
				continue
			if _is_configured_collapsed_tent_tile(layer, cell):
				continue
			var world_pos: Vector2 = layer.to_global(layer.map_to_local(cell))
			var shadow_off: Vector2 = _get_tile_shadow_offset(layer, cell)
			shadow_off.y += _get_layer_shadow_adjustment(layer, cell)
			shadow_samples.append({
				"center": world_pos + shadow_off,
				"scale": _get_tree_shadow_scale(layer, cell)
			})

	_rebuild_shadow_texture(shadow_samples)
	if _shadow_texture != null:
		_shadow_overlay.draw_texture(_shadow_texture, _shadow_texture_origin)

func _rebuild_shadow_texture(shadow_samples: Array[Dictionary]) -> void:
	if shadow_samples.is_empty():
		_shadow_texture = null
		return

	var pad: int = int(ceili((shadow_radius + shadow_softness) * 2.0))
	var texture_origin: Vector2 = _arena_rect.position - Vector2(pad, pad)
	var texture_size: Vector2 = _arena_rect.size + Vector2(pad * 2, pad * 2)
	var width: int = maxi(1, int(ceili(texture_size.x)))
	var height: int = maxi(1, int(ceili(texture_size.y)))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	for sample in shadow_samples:
		var center_world: Vector2 = sample.get("center", Vector2.ZERO)
		var scale: float = sample.get("scale", 1.0)
		var center_px: Vector2 = center_world - texture_origin
		_stamp_shadow_into_image(image, center_px, scale)

	_shadow_texture = ImageTexture.create_from_image(image)
	_shadow_texture_origin = texture_origin

func _stamp_shadow_into_image(image: Image, center: Vector2, scale: float = 1.0) -> void:
	var total_radius: float = (shadow_radius + shadow_softness) * maxf(0.25, scale)
	var radius_y: float = total_radius * shadow_squish
	var min_x: int = maxi(0, int(floor(center.x - total_radius)))
	var max_x: int = mini(image.get_width() - 1, int(ceili(center.x + total_radius)))
	var min_y: int = maxi(0, int(floor(center.y - radius_y)))
	var max_y: int = mini(image.get_height() - 1, int(ceili(center.y + radius_y)))
	if min_x > max_x or min_y > max_y:
		return

	for y in range(min_y, max_y + 1):
		var dy: float = (float(y) - center.y) / maxf(0.0001, radius_y)
		for x in range(min_x, max_x + 1):
			var dx: float = (float(x) - center.x) / maxf(0.0001, total_radius)
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist > 1.0:
				continue
			var sample_alpha: float = _shadow_alpha_at_distance(dist)
			if sample_alpha <= 0.0:
				continue
			var current: Color = image.get_pixel(x, y)
			if sample_alpha > current.a:
				image.set_pixel(x, y, Color(shadow_color.r, shadow_color.g, shadow_color.b, sample_alpha))

func _get_tree_shadow_scale(layer: TileMapLayer, cell: Vector2i) -> float:
	if _is_configured_collapsed_tent_tile(layer, cell):
		return 0.0
	if _is_configured_tent_tile(layer, cell):
		return tent_shadow_scale
	var tree_layer := _find_tree_layer()
	if layer != tree_layer:
		return 1.0
	if not _is_tree_cell(layer, cell):
		return 1.0
	if tree_growth_stages.size() <= 1:
		return 1.0
	var index: int = _tree_stage_index(layer.get_cell_atlas_coords(cell))
	if index < 0:
		return 1.0
	var t: float = float(index) / float(tree_growth_stages.size() - 1)
	return lerpf(1.0, 0.58, t)

func _shadow_alpha_at_distance(normalized_distance: float) -> float:
	var inner: float = shadow_radius / maxf(0.0001, shadow_radius + shadow_softness)
	if normalized_distance <= inner:
		return shadow_color.a
	var edge_t: float = (normalized_distance - inner) / maxf(0.0001, 1.0 - inner)
	var smoothness: float = clampf(float(shadow_soft_steps - 1) / 11.0, 0.0, 1.0)
	var exponent: float = lerpf(1.5, 2.6, smoothness)
	return shadow_color.a * (1.0 - pow(edge_t, exponent))

func _get_layer_shadow_adjustment(layer: TileMapLayer, cell: Vector2i) -> float:
	if _is_configured_collapsed_tent_tile(layer, cell):
		return 0.0
	var adjustment: float = float(layer.z_index) * shadow_layer_drop_per_z
	if _is_configured_tent_tile(layer, cell):
		adjustment += tent_shadow_vertical_adjustment
	var phase_index: int = _get_configured_building_phase_index(layer, cell)
	if phase_index >= 0:
		adjustment += float(phase_index) * building_shadow_drop_per_phase
		adjustment += building_shadow_lift
	if _is_configured_roof_tile(layer, cell) and layer.tile_set != null:
		adjustment += float(layer.tile_set.tile_size.y) * roof_shadow_extra_cells
	return adjustment

func _get_configured_building_phase_index(layer: TileMapLayer, cell: Vector2i) -> int:
	if layer == null:
		return -1
	var source_id: int = layer.get_cell_source_id(cell)
	var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
	var foundation_layer: Node = get_node_or_null(foundation_layer_path)
	if layer == foundation_layer and source_id == foundation_source_id and atlas == foundation_atlas:
		return 0
	var floor_layer: Node = get_node_or_null(floor_layer_path)
	if layer == floor_layer and source_id == floor_source_id and atlas == floor_atlas:
		return 1
	var walls_layer: Node = get_node_or_null(walls_layer_path)
	if layer == walls_layer and source_id == walls_source_id and atlas == walls_atlas:
		return 2
	var roof_layer: Node = get_node_or_null(roof_layer_path)
	if layer == roof_layer and source_id == roof_source_id and atlas == roof_atlas:
		return 3
	return -1

func _is_configured_building_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	return _get_configured_building_phase_index(layer, cell) >= 0

func _is_configured_roof_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false
	var roof_layer: Node = get_node_or_null(roof_layer_path)
	if layer != roof_layer:
		return false
	return layer.get_cell_source_id(cell) == roof_source_id and layer.get_cell_atlas_coords(cell) == roof_atlas

func _is_configured_tent_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false
	if layer != _tent_build_layer and layer != _tent_behind_layer:
		return false
	return layer.get_cell_source_id(cell) == tent_source_id and layer.get_cell_atlas_coords(cell) == tent_atlas

func _is_configured_collapsed_tent_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false
	if layer != _tent_build_layer and layer != _tent_behind_layer:
		return false
	return layer.get_cell_source_id(cell) == tent_collapsed_source_id and layer.get_cell_atlas_coords(cell) == tent_collapsed_atlas

func _find_tent_layer_for_cell(cell: Vector2i) -> TileMapLayer:
	if _tent_build_layer != null and _tent_build_layer.get_cell_source_id(cell) != -1:
		return _tent_build_layer
	if _tent_behind_layer != null and _tent_behind_layer.get_cell_source_id(cell) != -1:
		return _tent_behind_layer
	return null

func _set_tent_visual_state(cell: Vector2i, collapsed: bool) -> void:
	var preferred_layer: TileMapLayer = _tent_build_layer
	if _tent_behind_layer != null and _tent_overlaps_tree_canopy(cell):
		preferred_layer = _tent_behind_layer
	if preferred_layer == null:
		return

	if _tent_build_layer != null and _tent_build_layer != preferred_layer:
		_tent_build_layer.erase_cell(cell)
	if _tent_behind_layer != null and _tent_behind_layer != preferred_layer:
		_tent_behind_layer.erase_cell(cell)

	if collapsed:
		preferred_layer.set_cell(cell, tent_collapsed_source_id, tent_collapsed_atlas, 0)
	else:
		preferred_layer.set_cell(cell, tent_source_id, tent_atlas, 0)

func _register_or_refresh_tent_decay(cell: Vector2i) -> void:
	var entry: Dictionary = _tent_decay_state.get(cell, {})
	entry["health"] = clampf(float(entry.get("health", tent_max_health)), 0.0, tent_max_health)
	entry["collapsed"] = bool(entry.get("collapsed", false))
	entry["collapse_timer"] = maxf(0.0, float(entry.get("collapse_timer", 0.0)))
	entry["owner"] = str(_home_owner_by_cell.get(cell, str(entry.get("owner", ""))))
	_tent_decay_state[cell] = entry

func _tent_requires_repair(cell: Vector2i) -> bool:
	var entry: Dictionary = _tent_decay_state.get(cell, {})
	if entry.is_empty():
		return false
	if bool(entry.get("collapsed", false)):
		return float(entry.get("collapse_timer", 0.0)) > 0.0
	return float(entry.get("health", tent_max_health)) < tent_max_health

func _rebuild_tent_decay_state_from_layers() -> void:
	_tent_decay_state.clear()
	var layers: Array[TileMapLayer] = []
	if _tent_build_layer != null:
		layers.append(_tent_build_layer)
	if _tent_behind_layer != null:
		layers.append(_tent_behind_layer)
	for layer in layers:
		for cell in layer.get_used_cells():
			if _is_configured_tent_tile(layer, cell):
				_tent_decay_state[cell] = {
					"health": tent_max_health,
					"collapsed": false,
					"collapse_timer": 0.0,
					"owner": str(_home_owner_by_cell.get(cell, ""))
				}
			elif _is_configured_collapsed_tent_tile(layer, cell):
				_tent_decay_state[cell] = {
					"health": 0.0,
					"collapsed": true,
					"collapse_timer": tent_collapsed_repair_window_seconds,
					"owner": str(_home_owner_by_cell.get(cell, ""))
				}

func _collapse_tent(cell: Vector2i) -> void:
	_set_tent_visual_state(cell, true)
	var entry: Dictionary = _tent_decay_state.get(cell, {})
	entry["health"] = 0.0
	entry["collapsed"] = true
	entry["collapse_timer"] = tent_collapsed_repair_window_seconds
	entry["owner"] = str(_home_owner_by_cell.get(cell, str(entry.get("owner", ""))))
	_tent_decay_state[cell] = entry
	_shelter_cells.erase(cell)
	if _shadow_overlay:
		_shadow_overlay.queue_redraw()

func _finalize_tent_decay(cell: Vector2i) -> void:
	if _tent_build_layer != null:
		_tent_build_layer.erase_cell(cell)
	if _tent_behind_layer != null:
		_tent_behind_layer.erase_cell(cell)
	_reserved_build_cells.erase(cell)
	_tent_decay_state.erase(cell)
	_shelter_cells.erase(cell)
	_home_owner_by_cell.erase(cell)
	_home_occupants.erase(cell)
	for villager_name_variant in _villager_home_cell.keys():
		var villager_name: String = str(villager_name_variant)
		if _villager_home_cell.get(villager_name, Vector2i(-9999, -9999)) == cell:
			_villager_home_cell.erase(villager_name)
	if terrain != null and tent_final_decay_wood_drop > 0:
		var world_pos: Vector2 = terrain.to_global(terrain.map_to_local(cell))
		_spawn_drop("wood", world_pos, true, tent_final_decay_wood_drop)
	if _shadow_overlay:
		_shadow_overlay.queue_redraw()

func _update_tent_decay(delta: float) -> void:
	if _tent_decay_state.is_empty():
		return
	var cells_to_finalize: Array[Vector2i] = []
	for cell_variant in _tent_decay_state.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		var entry: Dictionary = _tent_decay_state.get(cell, {})
		if entry.is_empty():
			continue
		var collapsed: bool = bool(entry.get("collapsed", false))
		if collapsed:
			var timer_left: float = maxf(0.0, float(entry.get("collapse_timer", 0.0)) - delta)
			entry["collapse_timer"] = timer_left
			_tent_decay_state[cell] = entry
			if timer_left <= 0.0:
				cells_to_finalize.append(cell)
			continue
		var active_layer: TileMapLayer = _find_tent_layer_for_cell(cell)
		if active_layer == null:
			# Ghost entry - tile was already removed, clean up state without dropping wood
			_tent_decay_state.erase(cell)
			continue
		if not _is_configured_tent_tile(active_layer, cell):
			# Tile exists but is not the standing atlas
			if _is_configured_collapsed_tent_tile(active_layer, cell):
				# State-visual mismatch: fix state to reflect actual collapsed tile
				entry["collapsed"] = true
				entry["health"] = 0.0
				if float(entry.get("collapse_timer", 0.0)) <= 0.0:
					entry["collapse_timer"] = tent_collapsed_repair_window_seconds
				_tent_decay_state[cell] = entry
			else:
				# Unknown tile at this cell, silently remove ghost entry
				_tent_decay_state.erase(cell)
			continue
		var decay_rate: float = tent_decay_per_second * _get_decay_multiplier()
		var occupants_variant: Variant = _home_occupants.get(cell, [])
		if (occupants_variant is Array) and not (occupants_variant as Array).is_empty():
			decay_rate *= occupied_decay_multiplier
		var health_now: float = float(entry.get("health", tent_max_health)) - maxf(0.0, decay_rate) * delta
		entry["health"] = health_now
		_tent_decay_state[cell] = entry
		if health_now <= 0.0:
			_collapse_tent(cell)
	for cell in cells_to_finalize:
		_finalize_tent_decay(cell)

func _scan_untracked_tent_tiles(delta: float) -> void:
	_untracked_scan_timer -= delta
	if _untracked_scan_timer > 0.0:
		return
	_untracked_scan_timer = 5.0
	for scan_layer in [_tent_build_layer, _tent_behind_layer]:
		if scan_layer == null:
			continue
		for cell in scan_layer.get_used_cells():
			if _tent_decay_state.has(cell):
				continue
			if _is_configured_tent_tile(scan_layer, cell):
				_tent_decay_state[cell] = {
					"health": tent_max_health,
					"collapsed": false,
					"collapse_timer": 0.0,
					"owner": str(_home_owner_by_cell.get(cell, ""))
				}
			elif _is_configured_collapsed_tent_tile(scan_layer, cell):
				_tent_decay_state[cell] = {
					"health": 0.0,
					"collapsed": true,
					"collapse_timer": tent_collapsed_repair_window_seconds,
					"owner": str(_home_owner_by_cell.get(cell, ""))
				}

func _tent_overlaps_tree_canopy(cell: Vector2i) -> bool:
	var tree_layer := _find_tree_layer()
	if tree_layer == null:
		return false
	# A tent is within the tree canopy if the same cell or the cell one row below has a tree
	# (tree sprites extend upward beyond their tile, so a tent above a tree is inside its canopy)
	for dy in [0, 1]:
		if tree_layer.get_cell_source_id(cell + Vector2i(0, dy)) != -1:
			return true
	return false

func _setup_weather_system() -> void:
	if _weather_fx_layer == null:
		_weather_fx_layer = CanvasLayer.new()
		_weather_fx_layer.name = "WeatherFxLayer"
		_weather_fx_layer.layer = 90
		add_child(_weather_fx_layer)
	if _lightning_flash_rect == null:
		_lightning_flash_rect = ColorRect.new()
		_lightning_flash_rect.name = "LightningFlash"
		_lightning_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_lightning_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lightning_flash_rect.color = Color(0.82, 0.9, 1.0, 0.0)
		_lightning_flash_rect.visible = false
		_weather_fx_layer.add_child(_lightning_flash_rect)
	if _rain_overlay == null:
		_rain_overlay = Node2D.new()
		_rain_overlay.name = "RainOverlay"
		_rain_overlay.z_index = 50
		_weather_fx_layer.add_child(_rain_overlay)
		_rain_overlay.draw.connect(_on_rain_overlay_draw)
	_ensure_rain_streak_texture()
	if _lightning_bolt_overlay == null:
		_lightning_bolt_overlay = Node2D.new()
		_lightning_bolt_overlay.name = "LightningBoltOverlay"
		_lightning_bolt_overlay.z_index = 60
		_lightning_bolt_overlay.visible = false
		_weather_fx_layer.add_child(_lightning_bolt_overlay)
		_lightning_bolt_overlay.draw.connect(_on_lightning_bolt_draw)
	_rain_particles = null
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	_last_weather_canvas_origin = canvas_transform.origin
	_last_weather_canvas_scale = Vector2(maxf(0.001, canvas_transform.x.length()), maxf(0.001, canvas_transform.y.length()))
	_lightning_strike_timer = _next_lightning_interval()
	_weather_transition_timer = weather_transition_interval_seconds
	_sync_weather_visuals()

func _sync_weather_visuals() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var target_count: int = 0
	match _current_weather:
		"none":
			target_count = 0
		"rainy":
			target_count = maxi(40, int(viewport_size.x * viewport_size.y / 2400.0))
		"thunderstorm":
			target_count = maxi(70, int(viewport_size.x * viewport_size.y / 1500.0))
		_:
			target_count = 0
	if target_count <= 0:
		_rain_streaks.clear()
		if _rain_overlay != null:
			_rain_overlay.visible = false
			_rain_overlay.queue_redraw()
		_clear_lightning_visuals()
		return
	if _rain_overlay != null:
		_rain_overlay.visible = true
	if _lightning_flash_rect != null:
		_lightning_flash_rect.visible = _lightning_flash_alpha > 0.001
		_lightning_flash_rect.color = Color(0.82, 0.9, 1.0, _lightning_flash_alpha)
	while _rain_streaks.size() < target_count:
		_rain_streaks.append(_make_rain_streak(viewport_size, true))
	while _rain_streaks.size() > target_count:
		_rain_streaks.pop_back()
	if _rain_overlay != null:
		_rain_overlay.queue_redraw()
	if _lightning_bolt_overlay != null and _lightning_bolt_overlay.visible:
		_lightning_bolt_overlay.queue_redraw()

func _make_rain_streak(viewport_size: Vector2, anywhere: bool = false) -> Dictionary:
	var spawn_padding: float = maxf(80.0, rain_offscreen_padding)
	var spawn_y_min: float = -maxf(spawn_padding, viewport_size.y * 0.2)
	var spawn_y_max: float = viewport_size.y + spawn_padding if anywhere else 0.0
	var side_margin: float = maxf(spawn_padding, viewport_size.x * 0.22)
	var start_pos := Vector2(
		randf_range(-side_margin, viewport_size.x + side_margin),
		randf_range(spawn_y_min, spawn_y_max)
	)
	var speed: float = randf_range(rain_speed_min, rain_speed_max)
	# Mostly rightward slant, with occasional near-vertical/left drift to prevent dead corners.
	var drift_ratio: float = randf_range(-0.06, 0.24)
	var drift: float = speed * drift_ratio
	var length: float = randf_range(14.0, 28.0)
	var alpha: float = randf_range(0.18, 0.46)
	var width: float = randf_range(1.0, 2.2)
	return {
		"pos": start_pos,
		"velocity": Vector2(drift, speed),
		"length": length,
		"alpha": alpha,
		"width": width
	}

func _ensure_rain_streak_texture() -> void:
	if _rain_streak_texture != null:
		return
	# Tiny cached streak texture: drawing this repeatedly is cheaper than many dynamic line segments.
	var tex_width: int = 6
	var tex_height: int = 48
	var image := Image.create(tex_width, tex_height, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	for y in range(tex_height):
		var t: float = float(y) / float(tex_height - 1)
		# Keep the head of the drop (bottom) brighter and fade upward into the tail.
		var alpha: float = pow(t, 1.45)
		for x in range(tex_width):
			var x_center_dist: float = absf(float(x) - (float(tex_width - 1) * 0.5)) / maxf(1.0, float(tex_width) * 0.5)
			var edge_fade: float = clampf(1.0 - x_center_dist, 0.0, 1.0)
			image.set_pixel(x, y, Color(0.64, 0.78, 0.98, alpha * edge_fade))
	_rain_streak_texture = ImageTexture.create_from_image(image)

func _draw_rain_streak(pos: Vector2, velocity: Vector2, length: float, alpha: float, width: float) -> void:
	if _rain_overlay == null or _rain_streak_texture == null:
		return
	var tex_size: Vector2 = _rain_streak_texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var angle: float = velocity.angle() - PI * 0.5
	var size_scale: float = maxf(0.1, rain_streak_size_multiplier)
	var scale: Vector2 = Vector2(maxf(0.2, (width * size_scale) / tex_size.x), maxf(0.2, (length * size_scale) / tex_size.y))
	_rain_overlay.draw_set_transform(pos, angle, scale)
	_rain_overlay.draw_texture(_rain_streak_texture, Vector2(-tex_size.x * 0.5, -tex_size.y), Color(1.0, 1.0, 1.0, alpha))
	_rain_overlay.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _on_rain_overlay_draw() -> void:
	if _rain_overlay == null or _rain_streaks.is_empty():
		return
	for streak in _rain_streaks:
		var pos: Vector2 = streak.get("pos", Vector2.ZERO)
		var velocity: Vector2 = streak.get("velocity", Vector2(20.0, 100.0))
		var direction: Vector2 = velocity.normalized()
		var length: float = float(streak.get("length", 18.0))
		var alpha: float = float(streak.get("alpha", 0.7))
		var width: float = float(streak.get("width", 1.4))
		var sample_point: Vector2 = pos - direction * (length * 0.5)
		if _current_weather != "thunderstorm" and not _should_render_rain_at_screen_position(sample_point):
			continue
		_draw_rain_streak(pos, velocity, length, alpha, width)

func _should_render_rain_at_screen_position(screen_position: Vector2) -> bool:
	if _current_weather == "thunderstorm":
		return true
	return not _is_desert_world_position(_screen_to_world_position(screen_position))

func _screen_to_world_position(screen_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_position

func _update_weather(delta: float) -> void:
	# Update weather transition timer
	_weather_transition_timer -= delta
	if _weather_transition_timer <= 0.0:
		_weather_transition_timer = weather_transition_interval_seconds
		_transition_weather()
	_apply_rain_camera_compensation()
	_update_rain_streaks(delta)
	_update_lightning(delta)
	_sync_weather_visuals()

func _apply_rain_camera_compensation() -> void:
	if _rain_streaks.is_empty():
		return
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var canvas_origin: Vector2 = canvas_transform.origin
	var canvas_scale: Vector2 = Vector2(maxf(0.001, canvas_transform.x.length()), maxf(0.001, canvas_transform.y.length()))
	if rain_camera_compensation_strength <= 0.0 and rain_zoom_compensation_strength <= 0.0:
		_last_weather_canvas_origin = canvas_origin
		_last_weather_canvas_scale = canvas_scale
		return
	if not is_finite(_last_weather_canvas_origin.x) or not is_finite(_last_weather_canvas_origin.y):
		_last_weather_canvas_origin = canvas_origin
		_last_weather_canvas_scale = canvas_scale
		return
	if not is_finite(_last_weather_canvas_scale.x) or not is_finite(_last_weather_canvas_scale.y):
		_last_weather_canvas_scale = canvas_scale
		return
	var canvas_delta: Vector2 = canvas_origin - _last_weather_canvas_origin
	var scale_ratio: Vector2 = Vector2(
		canvas_scale.x / maxf(0.001, _last_weather_canvas_scale.x),
		canvas_scale.y / maxf(0.001, _last_weather_canvas_scale.y)
	)
	_last_weather_canvas_origin = canvas_origin
	_last_weather_canvas_scale = canvas_scale
	var has_translation: bool = canvas_delta.length_squared() > 0.0001
	var has_zoom: bool = absf(scale_ratio.x - 1.0) > 0.0001 or absf(scale_ratio.y - 1.0) > 0.0001
	if not has_translation and not has_zoom:
		return
	# Canvas origin moves opposite to camera world motion; applying this offset makes rain drift opposite camera movement.
	var screen_offset: Vector2 = canvas_delta * rain_camera_compensation_strength
	var viewport_center: Vector2 = get_viewport_rect().size * 0.5
	var zoom_blend: Vector2 = Vector2(
		lerpf(1.0, scale_ratio.x, rain_zoom_compensation_strength),
		lerpf(1.0, scale_ratio.y, rain_zoom_compensation_strength)
	)
	for i in range(_rain_streaks.size()):
		var streak: Dictionary = _rain_streaks[i]
		var pos: Vector2 = streak.get("pos", Vector2.ZERO)
		if has_zoom and rain_zoom_compensation_strength > 0.0:
			var from_center: Vector2 = pos - viewport_center
			pos = viewport_center + Vector2(from_center.x * zoom_blend.x, from_center.y * zoom_blend.y)
		if has_translation and rain_camera_compensation_strength > 0.0:
			pos += screen_offset
		streak["pos"] = pos
		_rain_streaks[i] = streak

func _update_lightning(delta: float) -> void:
	if _current_weather != "thunderstorm":
		_lightning_flash_alpha = maxf(0.0, _lightning_flash_alpha - delta * thunderstorm_flash_fade_speed)
		if _lightning_flash_alpha <= 0.001:
			_clear_lightning_visuals()
		return
	_lightning_strike_timer -= delta
	if _lightning_strike_timer <= 0.0:
		_trigger_lightning_strike()
		_lightning_strike_timer = _next_lightning_interval()
	if _lightning_flash_alpha > 0.0:
		_lightning_flash_alpha = maxf(0.0, _lightning_flash_alpha - delta * thunderstorm_flash_fade_speed)
	if _lightning_bolt_timer > 0.0:
		_lightning_bolt_timer = maxf(0.0, _lightning_bolt_timer - delta)
	if _lightning_bolt_overlay != null:
		_lightning_bolt_overlay.visible = _lightning_bolt_timer > 0.0 and not _lightning_bolt_points.is_empty()
		if _lightning_bolt_overlay.visible:
			_lightning_bolt_overlay.queue_redraw()
	if _lightning_flash_rect != null:
		_lightning_flash_rect.visible = _lightning_flash_alpha > 0.001
		_lightning_flash_rect.color = Color(0.82, 0.9, 1.0, _lightning_flash_alpha)

func _next_lightning_interval() -> float:
	return randf_range(minf(thunderstorm_lightning_min_interval, thunderstorm_lightning_max_interval), maxf(thunderstorm_lightning_min_interval, thunderstorm_lightning_max_interval))

func _trigger_lightning_strike() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	_lightning_flash_alpha = thunderstorm_flash_peak_alpha
	_lightning_bolt_timer = thunderstorm_bolt_visible_seconds
	_lightning_bolt_points = _generate_lightning_bolt_points(viewport_size)
	if not _lightning_bolt_points.is_empty():
		var strike_screen: Vector2 = _lightning_bolt_points[_lightning_bolt_points.size() - 1]
		var strike_world: Vector2 = _screen_to_world_position(strike_screen)
		_apply_lightning_strike_effects(strike_world)
	if _lightning_bolt_overlay != null:
		_lightning_bolt_overlay.visible = true
		_lightning_bolt_overlay.queue_redraw()
	if _lightning_flash_rect != null:
		_lightning_flash_rect.visible = true
		_lightning_flash_rect.color = Color(0.82, 0.9, 1.0, _lightning_flash_alpha)

func _generate_lightning_bolt_points(viewport_size: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var x: float = randf_range(viewport_size.x * 0.15, viewport_size.x * 0.85)
	var y: float = -20.0
	points.append(Vector2(x, y))
	var segments: int = randi_range(6, 9)
	var bottom_target: float = randf_range(viewport_size.y * 0.45, viewport_size.y * 0.78)
	for i in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		x += randf_range(-55.0, 55.0)
		x = clampf(x, 20.0, viewport_size.x - 20.0)
		y = lerpf(-20.0, bottom_target, t) + randf_range(-12.0, 12.0)
		points.append(Vector2(x, y))
	return points

func _on_lightning_bolt_draw() -> void:
	if _lightning_bolt_overlay == null or _lightning_bolt_points.size() < 2:
		return
	for i in range(_lightning_bolt_points.size() - 1):
		var from_point: Vector2 = _lightning_bolt_points[i]
		var to_point: Vector2 = _lightning_bolt_points[i + 1]
		_lightning_bolt_overlay.draw_line(from_point, to_point, Color(0.55, 0.72, 1.0, 0.55), 8.0, true)
		_lightning_bolt_overlay.draw_line(from_point, to_point, Color(0.92, 0.97, 1.0, 0.95), 3.0, true)

func _clear_lightning_visuals() -> void:
	_lightning_flash_alpha = 0.0
	_lightning_bolt_timer = 0.0
	_lightning_bolt_points.clear()
	if _lightning_flash_rect != null:
		_lightning_flash_rect.visible = false
		_lightning_flash_rect.color = Color(0.82, 0.9, 1.0, 0.0)
	if _lightning_bolt_overlay != null:
		_lightning_bolt_overlay.visible = false

func _apply_lightning_strike_effects(world_position: Vector2) -> void:
	if terrain == null:
		return
	_damage_villagers_near(world_position, maxf(8.0, lightning_fire_radius_tiles * 26.0), maxf(0.0, lightning_strike_damage))
	if not lightning_ignites_flammables:
		return
	if _campfire_fx_root == null or _campfire_fire_frames == null:
		_setup_campfire_system()
	var center_cell: Vector2i = terrain.local_to_map(terrain.to_local(world_position))
	var radius_cells: int = maxi(1, int(ceil(lightning_fire_radius_tiles)))
	for y in range(-radius_cells, radius_cells + 1):
		for x in range(-radius_cells, radius_cells + 1):
			var cell: Vector2i = center_cell + Vector2i(x, y)
			var cell_world: Vector2 = terrain.to_global(terrain.map_to_local(cell))
			var dist_cells: float = world_position.distance_to(cell_world) / maxf(1.0, float(terrain.tile_set.tile_size.x) if terrain.tile_set != null else 16.0)
			if dist_cells > lightning_fire_radius_tiles:
				continue
			_try_ignite_cell_from_lightning(cell)

func _try_ignite_cell_from_lightning(cell: Vector2i) -> void:
	if terrain == null:
		return
	var tree_layer: TileMapLayer = _find_tree_layer()
	if tree_layer != null and _is_tree_cell(tree_layer, cell):
		if randf() <= lightning_tree_ignite_chance:
			_ignite_lightning_fire(cell, "tree")
		return
	var tent_layer: TileMapLayer = _find_tent_layer_for_cell(cell)
	if tent_layer != null and tent_layer.get_cell_source_id(cell) != -1:
		if randf() <= lightning_tent_ignite_chance:
			_ignite_lightning_fire(cell, "tent")
		return
	for layer in _build_phase_layers:
		if layer == null:
			continue
		if _is_configured_building_tile(layer, cell):
			if randf() <= lightning_building_ignite_chance:
				_ignite_lightning_fire(cell, "building")
			return
	if terrain.get_cell_source_id(cell) == -1:
		return
	var atlas: Vector2i = terrain.get_cell_atlas_coords(cell)
	for grass_atlas in GRASS_TILES:
		if atlas == grass_atlas:
			if randf() <= lightning_grass_ignite_chance:
				_ignite_lightning_fire(cell, "grass")
			return

func _ignite_lightning_fire(cell: Vector2i, kind: String) -> void:
	if terrain == null:
		return
	var world_position: Vector2 = terrain.to_global(terrain.map_to_local(cell))
	if _lightning_fires.has(cell):
		var existing: Dictionary = _lightning_fires.get(cell, {})
		existing["timer"] = maxf(float(existing.get("timer", 0.0)), lightning_fire_duration_seconds)
		existing["kind"] = kind
		_lightning_fires[cell] = existing
		return
	var flame: AnimatedSprite2D = _create_lightning_fire_flame(world_position)
	var light: PointLight2D = _create_lightning_fire_light(world_position)
	_lightning_fires[cell] = {
		"timer": lightning_fire_duration_seconds,
		"kind": kind,
		"flame": flame,
		"light": light
	}

func _create_lightning_fire_flame(world_position: Vector2) -> AnimatedSprite2D:
	if _campfire_fx_root == null or _campfire_fire_frames == null:
		return null
	if _campfire_fire_frames.get_frame_count("burn") <= 0:
		return null
	var flame := AnimatedSprite2D.new()
	flame.sprite_frames = _campfire_fire_frames
	flame.animation = "burn"
	flame.play("burn")
	flame.centered = true
	flame.global_position = world_position + Vector2(0.0, campfire_fire_y_offset)
	flame.scale = Vector2.ONE * maxf(0.1, campfire_fire_scale)
	flame.z_as_relative = false
	flame.z_index = 40
	_campfire_fx_root.add_child(flame)
	return flame

func _create_lightning_fire_light(world_position: Vector2) -> PointLight2D:
	if _campfire_light_root == null or _campfire_light_texture == null:
		return null
	var light := PointLight2D.new()
	light.texture = _campfire_light_texture
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.global_position = world_position
	light.z_as_relative = false
	light.z_index = 39
	var tex_size: float = 128.0
	light.texture_scale = maxf(0.2, lightning_fire_light_radius / tex_size)
	light.energy = maxf(0.0, lightning_fire_light_energy)
	_campfire_light_root.add_child(light)
	return light

func _update_lightning_fires(delta: float) -> void:
	if _lightning_fires.is_empty() or terrain == null:
		return
	for cell_variant in _lightning_fires.keys().duplicate():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		var entry: Dictionary = _lightning_fires.get(cell, {})
		if entry.is_empty():
			continue
		var timer: float = maxf(0.0, float(entry.get("timer", 0.0)) - delta)
		entry["timer"] = timer
		var world_position: Vector2 = terrain.to_global(terrain.map_to_local(cell))
		var flame_variant: Variant = entry.get("flame", null)
		if flame_variant is AnimatedSprite2D and is_instance_valid(flame_variant):
			var flame: AnimatedSprite2D = flame_variant as AnimatedSprite2D
			flame.global_position = world_position + Vector2(0.0, campfire_fire_y_offset)
		var light_variant: Variant = entry.get("light", null)
		if light_variant is PointLight2D and is_instance_valid(light_variant):
			var light: PointLight2D = light_variant as PointLight2D
			light.global_position = world_position
			light.energy = maxf(0.0, lightning_fire_light_energy)
			light.texture_scale = maxf(0.2, lightning_fire_light_radius / 128.0)
		_damage_villagers_near(world_position, maxf(10.0, lightning_fire_radius_tiles * 18.0), maxf(0.0, lightning_fire_damage_per_second) * delta)
		var kind: String = str(entry.get("kind", ""))
		if kind == "tent":
			_damage_tent_from_fire(cell, delta)
		if timer <= 0.0:
			_finalize_lightning_fire(cell, kind)
			if flame_variant is AnimatedSprite2D and is_instance_valid(flame_variant):
				(flame_variant as AnimatedSprite2D).queue_free()
			if light_variant is PointLight2D and is_instance_valid(light_variant):
				(light_variant as PointLight2D).queue_free()
			_lightning_fires.erase(cell)
		else:
			_lightning_fires[cell] = entry

func _damage_tent_from_fire(cell: Vector2i, delta: float) -> void:
	if not _tent_decay_state.has(cell):
		return
	var entry: Dictionary = _tent_decay_state.get(cell, {})
	if entry.is_empty():
		return
	if bool(entry.get("collapsed", false)):
		entry["collapse_timer"] = maxf(0.0, float(entry.get("collapse_timer", 0.0)) - delta * 2.0)
		_tent_decay_state[cell] = entry
		if float(entry.get("collapse_timer", 0.0)) <= 0.0:
			_finalize_tent_decay(cell)
		return
	entry["health"] = maxf(0.0, float(entry.get("health", tent_max_health)) - lightning_tent_burn_damage_per_second * delta)
	_tent_decay_state[cell] = entry
	if float(entry.get("health", 0.0)) <= 0.0:
		_collapse_tent(cell)

func _finalize_lightning_fire(cell: Vector2i, kind: String) -> void:
	if terrain == null:
		return
	match kind:
		"tree":
			_burn_tree_cell(cell)
		"grass":
			_burn_grass_cell(cell)
		"tent":
			if _tent_decay_state.has(cell):
				_finalize_tent_decay(cell)
		"building":
			_burn_building_cell(cell)

func _burn_tree_cell(cell: Vector2i) -> void:
	var layer: TileMapLayer = _find_tree_layer()
	if layer == null:
		return
	if not _is_tree_cell(layer, cell):
		return
	layer.erase_cell(cell)
	_tree_growth_timers.erase(cell)
	_tree_fruit_timers.erase(cell)
	_reserved_tree_cells.erase(cell)
	if _mature_tree_count_cache >= 0:
		_mature_tree_count_cache = maxi(0, _mature_tree_count_cache - 1)
	if _shadow_overlay:
		_shadow_overlay.queue_redraw()

func _burn_grass_cell(cell: Vector2i) -> void:
	if terrain == null:
		return
	if terrain.get_cell_source_id(cell) == -1:
		return
	var atlas: Vector2i = terrain.get_cell_atlas_coords(cell)
	for grass_atlas in GRASS_TILES:
		if atlas == grass_atlas:
			terrain.set_cell(cell, TERRAIN_SOURCE_ID, PATH_TILES[randi() % PATH_TILES.size()], 0)
			return

func _burn_building_cell(cell: Vector2i) -> void:
	for layer in _build_phase_layers:
		if layer == null:
			continue
		if layer.get_cell_source_id(cell) != -1:
			layer.erase_cell(cell)
	if _shelter_cells.has(cell):
		_shelter_cells.erase(cell)
	_home_owner_by_cell.erase(cell)
	_home_occupants.erase(cell)
	for villager_name_variant in _villager_home_cell.keys().duplicate():
		var villager_name: String = str(villager_name_variant)
		if _villager_home_cell.get(villager_name, Vector2i(-9999, -9999)) == cell:
			_villager_home_cell.erase(villager_name)
	if _shadow_overlay:
		_shadow_overlay.queue_redraw()

func _damage_villagers_near(world_position: Vector2, radius: float, damage_amount: float) -> void:
	if damage_amount <= 0.0:
		return
	var safe_radius: float = maxf(1.0, radius)
	for villager in _villagers:
		if villager == null or not is_instance_valid(villager):
			continue
		if villager.health <= 0.0:
			continue
		var d: float = villager.position.distance_to(world_position)
		if d > safe_radius:
			continue
		var t: float = clampf(1.0 - d / safe_radius, 0.0, 1.0)
		villager.health = clampf(villager.health - damage_amount * t, 0.0, 100.0)

func _update_rain_streaks(delta: float) -> void:
	if _rain_overlay == null or _rain_streaks.is_empty():
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var side_margin: float = maxf(rain_offscreen_padding, viewport_size.x * 0.22)
	var bottom_margin: float = maxf(100.0, rain_offscreen_padding * 0.6)
	for i in range(_rain_streaks.size()):
		var streak: Dictionary = _rain_streaks[i]
		var pos: Vector2 = streak.get("pos", Vector2.ZERO)
		var velocity: Vector2 = streak.get("velocity", Vector2(20.0, 100.0))
		pos += velocity * delta
		var length: float = float(streak.get("length", 18.0))
		if pos.y - length > viewport_size.y + bottom_margin or pos.x > viewport_size.x + side_margin or pos.x < -side_margin:
			# Respawn anywhere in the buffered region so rain remains immediately visible after camera movement.
			streak = _make_rain_streak(viewport_size, true)
		else:
			streak["pos"] = pos
		_rain_streaks[i] = streak
	_rain_overlay.queue_redraw()

func _transition_weather() -> void:
	# Roll for weather transition
	var roll: float = randf()
	if _current_weather == "none":
		if roll < rainy_weather_probability:
			_current_weather = "rainy"
		# Otherwise stays "none"
	elif _current_weather == "rainy":
		if roll < thunderstorm_probability:
			_current_weather = "thunderstorm"
		else:
			_current_weather = "none"
	elif _current_weather == "thunderstorm":
		_current_weather = "none"
	_sync_weather_visuals()

func _get_decay_multiplier() -> float:
	if _current_weather == "thunderstorm":
		return thunderstorm_decay_multiplier
	elif _current_weather == "rainy":
		return rainy_decay_multiplier
	return 1.0

func _get_tile_shadow_offset(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	var source_id: int = layer.get_cell_source_id(cell)
	if source_id == -1:
		return Vector2(0.0, shadow_y_offset)
	var atlas_coords: Vector2i = layer.get_cell_atlas_coords(cell)
	var tile_set: TileSet = layer.tile_set
	if tile_set == null:
		return Vector2(0.0, shadow_y_offset)
	var cache_key: String = "%d|%d|%d|%d" % [tile_set.get_instance_id(), source_id, atlas_coords.x, atlas_coords.y]
	if _tile_bottom_cache.has(cache_key):
		return _tile_bottom_cache[cache_key]

	var source = tile_set.get_source(source_id)
	if not (source is TileSetAtlasSource):
		_tile_bottom_cache[cache_key] = Vector2(0.0, shadow_y_offset)
		return Vector2(0.0, shadow_y_offset)

	var atlas := source as TileSetAtlasSource
	var tex: Texture2D = atlas.texture
	if tex == null:
		_tile_bottom_cache[cache_key] = Vector2(0.0, shadow_y_offset)
		return Vector2(0.0, shadow_y_offset)
	var region: Rect2i = atlas.get_tile_texture_region(atlas_coords, 0)
	var img: Image = tex.get_image()
	if img == null:
		_tile_bottom_cache[cache_key] = Vector2(0.0, shadow_y_offset)
		return Vector2(0.0, shadow_y_offset)

	# Scan bottom-up to find the lowest row containing any opaque pixel
	var bottom_row: int = -1
	for row in range(region.position.y + region.size.y - 1, region.position.y - 1, -1):
		for col in range(region.position.x, region.position.x + region.size.x):
			if img.get_pixel(col, row).a > 0.05:
				bottom_row = row
				break
		if bottom_row != -1:
			break

	if bottom_row == -1:
		_tile_bottom_cache[cache_key] = Vector2(0.0, shadow_y_offset)
		return Vector2(0.0, shadow_y_offset)

	# Find horizontal centroid of opaque pixels in the bottom 4 rows
	var x_sum: float = 0.0
	var x_count: int = 0
	var scan_top: int = maxi(bottom_row - 3, region.position.y)
	for row in range(bottom_row, scan_top - 1, -1):
		for col in range(region.position.x, region.position.x + region.size.x):
			if img.get_pixel(col, row).a > 0.05:
				x_sum += float(col - region.position.x)
				x_count += 1

	var scale_x: float = float(tile_set.tile_size.x) / float(region.size.x) if region.size.x > 0 else 1.0
	var scale_y: float = float(tile_set.tile_size.y) / float(region.size.y) if region.size.y > 0 else 1.0

	# Y: position at the bottommost pixel
	# bottom_row is absolute texture coordinate; convert to tile-relative, then to world units
	var pixel_row_in_region: float = float(bottom_row - region.position.y)
	var pixel_fraction: float = pixel_row_in_region / float(region.size.y) if region.size.y > 0 else 0.5
	# Map [0, 1] texture fraction to world [-tile_size/2, tile_size/2]
	var result_y: float = (pixel_fraction * float(tile_set.tile_size.y)) - float(tile_set.tile_size.y) * 0.5 + 16.0

	# X: offset from tile center to horizontal centroid of the visible base
	var tile_center_col: float = float(region.size.x) * 0.5
	var result_x: float = ((x_sum / float(x_count)) - tile_center_col) * scale_x if x_count > 0 else 0.0

	var result := Vector2(result_x, result_y)
	_tile_bottom_cache[cache_key] = result
	return result

func _claim_building_cells(villager_name: String, base_cell: Vector2i, profile_name: String = "house") -> void:
	if terrain == null:
		return
	var profile: Dictionary = _make_build_profile_data(profile_name)
	var profile_offsets: Array = profile.get("offsets", [])
	var footprint_cells: Dictionary = {}
	for offset in profile_offsets:
		if not (offset is Vector2i):
			continue
		footprint_cells[base_cell + (offset as Vector2i)] = true
	if footprint_cells.is_empty():
		footprint_cells[base_cell] = true

	var claim_cells: Dictionary = {}
	for footprint_variant in footprint_cells.keys():
		if not (footprint_variant is Vector2i):
			continue
		var footprint_cell: Vector2i = footprint_variant
		for y in range(-build_site_padding_cells, build_site_padding_cells + 1):
			for x in range(-build_site_padding_cells, build_site_padding_cells + 1):
				claim_cells[footprint_cell + Vector2i(x, y)] = true

	for cell_variant in claim_cells.keys():
		if not (cell_variant is Vector2i):
			continue
		var claim_cell: Vector2i = cell_variant
		var world_pos: Vector2 = terrain.to_global(terrain.map_to_local(claim_cell))
		claim_tile(villager_name, world_pos, "built_home")

func _rebuild_build_phase_cache() -> void:
	_build_phase_layers.clear()
	_build_phase_atlas.clear()
	_build_phase_source_ids.clear()
	_build_phase_offsets.clear()
	_tent_build_layer = null
	_tent_behind_layer = null

	var phase_definitions: Array = [
		{"layer": foundation_layer_path, "atlas": foundation_atlas, "source_id": foundation_source_id, "offset": foundation_offset},
		{"layer": floor_layer_path, "atlas": floor_atlas, "source_id": floor_source_id, "offset": floor_offset},
		{"layer": walls_layer_path, "atlas": walls_atlas, "source_id": walls_source_id, "offset": walls_offset},
		{"layer": roof_layer_path, "atlas": roof_atlas, "source_id": roof_source_id, "offset": roof_offset}
	]

	for phase_data in phase_definitions:
		var layer_node: Node = get_node_or_null(phase_data["layer"])
		if layer_node is TileMapLayer:
			_build_phase_layers.append(layer_node as TileMapLayer)
			_build_phase_atlas.append(phase_data["atlas"])
			_build_phase_source_ids.append(phase_data["source_id"])
			_build_phase_offsets.append(phase_data["offset"])

	var tent_layer_node: Node = get_node_or_null(tent_layer_path)
	if tent_layer_node is TileMapLayer:
		_tent_build_layer = tent_layer_node as TileMapLayer
	var tent_behind_node: Node = get_node_or_null(tent_behind_layer_path)
	if tent_behind_node is TileMapLayer:
		_tent_behind_layer = tent_behind_node as TileMapLayer

func _rebuild_blocked_tile_lookup() -> void:
	_blocked_tile_lookup.clear()
	for tile in blocked_terrain_tiles:
		_blocked_tile_lookup[tile] = true

func is_world_position_walkable(world_position: Vector2, villager_name: String = "", allow_home_entry: bool = false, target_home_cell: Vector2i = Vector2i(-9999, -9999), from_world_position: Vector2 = Vector2(INF, INF), allow_swimming: bool = false) -> bool:
	if terrain == null:
		return true

	var local_position: Vector2 = terrain.to_local(world_position)
	var cell: Vector2i = terrain.local_to_map(local_position)
	var source_id: int = terrain.get_cell_source_id(cell)
	if source_id == -1:
		return false

	var atlas: Vector2i = terrain.get_cell_atlas_coords(cell)
	if _blocked_tile_lookup.has(atlas):
		if allow_swimming and atlas == WATER_TILES[0]:
			pass
		else:
			return false

	if allow_swimming and _is_water_world_position(world_position):
		return true

	if _campfires.has(cell):
		if is_finite(from_world_position.x) and is_finite(from_world_position.y):
			var from_cell_for_fire: Vector2i = terrain.local_to_map(terrain.to_local(from_world_position))
			if from_cell_for_fire == cell:
				return true
		return false

	if _shelter_cells.has(cell):
		if allow_home_entry and cell == target_home_cell:
			return true
		if is_finite(from_world_position.x) and is_finite(from_world_position.y):
			var from_cell: Vector2i = terrain.local_to_map(terrain.to_local(from_world_position))
			if from_cell == cell:
				return true
		return false

	# Block pathing through built structures on first layer unless this villager is entering a chosen home.
	var foundation_node: Node = get_node_or_null(foundation_layer_path)
	if foundation_node is TileMapLayer:
		var foundation := foundation_node as TileMapLayer
		var foundation_cell: Vector2i = foundation.local_to_map(foundation.to_local(world_position))
		if foundation.get_cell_source_id(foundation_cell) != -1:
			if allow_home_entry and foundation_cell == target_home_cell:
				return true
			if is_finite(from_world_position.x) and is_finite(from_world_position.y):
				var from_cell: Vector2i = foundation.local_to_map(foundation.to_local(from_world_position))
				# Allow movement while the villager is already standing in this blocked cell,
				# so they can step out instead of getting permanently stuck.
				if from_cell == foundation_cell:
					return true
			return false

	return true

func find_world_path(start_world_position: Vector2, end_world_position: Vector2, allow_home_entry: bool = false, target_home_cell: Vector2i = Vector2i(-9999, -9999), allow_swimming: bool = false) -> Array[Vector2]:
	if terrain == null:
		return []

	var start_cell: Vector2i = terrain.local_to_map(terrain.to_local(start_world_position))
	var goal_cell: Vector2i = terrain.local_to_map(terrain.to_local(end_world_position))
	if start_cell == goal_cell:
		return [end_world_position]

	if not _is_path_cell_walkable(goal_cell, allow_home_entry, target_home_cell, allow_swimming):
		goal_cell = _find_nearest_pathable_cell(goal_cell, allow_home_entry, target_home_cell, allow_swimming)
		if goal_cell == Vector2i(-9999, -9999):
			return []

	var frontier: Array[Vector2i] = [start_cell]
	var came_from: Dictionary = {start_cell: Vector2i(-9999, -9999)}
	var visited: Dictionary = {start_cell: true}
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
	var found: bool = false
	var index: int = 0
	var best_cell: Vector2i = start_cell
	var best_distance: float = start_cell.distance_squared_to(goal_cell)

	while index < frontier.size() and index < BFS_MAX_CELLS:
		var current: Vector2i = frontier[index]
		index += 1
		var current_distance: float = current.distance_squared_to(goal_cell)
		if current_distance < best_distance:
			best_distance = current_distance
			best_cell = current
		if current == goal_cell:
			found = true
			break
		for direction in directions:
			var next_cell: Vector2i = current + direction
			if visited.has(next_cell):
				continue
			if not _is_path_cell_walkable(next_cell, allow_home_entry, target_home_cell, allow_swimming):
				continue
			visited[next_cell] = true
			came_from[next_cell] = current
			frontier.append(next_cell)

	if not found:
		if best_cell == start_cell:
			return []
		goal_cell = best_cell

	var reverse_cells: Array[Vector2i] = []
	var trace_cell: Vector2i = goal_cell
	while trace_cell != start_cell and trace_cell != Vector2i(-9999, -9999):
		reverse_cells.append(trace_cell)
		trace_cell = came_from.get(trace_cell, Vector2i(-9999, -9999))
	reverse_cells.reverse()

	var result: Array[Vector2] = []
	for cell in reverse_cells:
		result.append(terrain.to_global(terrain.map_to_local(cell)))
	if allow_home_entry and goal_cell == target_home_cell:
		result.append(end_world_position)
	return result

func _is_path_cell_walkable(cell: Vector2i, allow_home_entry: bool = false, target_home_cell: Vector2i = Vector2i(-9999, -9999), allow_swimming: bool = false) -> bool:
	if terrain == null:
		return false
	var world_position: Vector2 = terrain.to_global(terrain.map_to_local(cell))
	return is_world_position_walkable(world_position, "", allow_home_entry, target_home_cell, Vector2(INF, INF), allow_swimming)

func _find_nearest_pathable_cell(origin_cell: Vector2i, allow_home_entry: bool = false, target_home_cell: Vector2i = Vector2i(-9999, -9999), allow_swimming: bool = false) -> Vector2i:
	for radius in range(1, 6):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var candidate: Vector2i = origin_cell + Vector2i(x, y)
				if _is_path_cell_walkable(candidate, allow_home_entry, target_home_cell, allow_swimming):
					return candidate
	return Vector2i(-9999, -9999)

func _get_owned_repairable_tent_cell(villager_name: String) -> Vector2i:
	if villager_name.is_empty():
		return Vector2i(-9999, -9999)
	for cell_variant in _home_owner_by_cell.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		if str(_home_owner_by_cell.get(cell, "")) != villager_name:
			continue
		if not _tent_decay_state.has(cell):
			continue
		if _tent_requires_repair(cell):
			return cell
	return Vector2i(-9999, -9999)

func _reserve_tent_repair_site(villager_name: String, cell: Vector2i) -> Dictionary:
	if terrain == null:
		return {}
	_reserved_build_cells[cell] = {"owner": villager_name, "profile": "tent", "repair": true}
	var tent_profile: Dictionary = _make_build_profile_data("tent")
	var tent_layers: Array = tent_profile.get("layers", [])
	return {
		"cell": cell,
		"world_position": terrain.to_global(terrain.map_to_local(cell)),
		"approach_world_position": _get_build_approach_world_position(cell),
		"total_steps": tent_layers.size(),
		"structure_type": "tent",
		"requires_crafting": false,
		"stage_wood_costs": [max(1, tent_repair_wood_cost)]
	}

func request_build_site(villager_name: String, wood_available: int = 0) -> Dictionary:
	if not enable_villager_building:
		return {}
	var repair_wood_cost: int = max(1, tent_repair_wood_cost)
	var owned_home_cell: Vector2i = _get_owned_home_cell(villager_name)
	if owned_home_cell != Vector2i(-9999, -9999):
		if _tent_decay_state.has(owned_home_cell) and _tent_requires_repair(owned_home_cell):
			if wood_available < repair_wood_cost:
				return {"needs_wood": true, "wood_cost": repair_wood_cost, "structure_type": "tent", "repair": true}
			return _reserve_tent_repair_site(villager_name, owned_home_cell)
		return {}
	var owned_repair_cell: Vector2i = _get_owned_repairable_tent_cell(villager_name)
	if owned_repair_cell != Vector2i(-9999, -9999):
		if wood_available < repair_wood_cost:
			return {"needs_wood": true, "wood_cost": repair_wood_cost, "structure_type": "tent", "repair": true}
		return _reserve_tent_repair_site(villager_name, owned_repair_cell)
	if _build_phase_layers.is_empty() and _tent_build_layer == null:
		return {}
	if _build_phase_atlas.is_empty() and _tent_build_layer == null:
		return {}
	if terrain == null:
		return {}

	for cell in _reserved_build_cells.keys():
		if _get_reserved_build_site_owner(cell) != villager_name:
			continue
		var existing_profile_name: String = _get_reserved_build_site_profile(cell)
		var is_repair_site: bool = _is_reserved_build_site_repair(cell)
		var existing_profile: Dictionary = _make_build_profile_data(existing_profile_name)
		var stage_costs: Array = existing_profile.get("stage_wood_costs", [])
		if is_repair_site and existing_profile_name == "tent":
			stage_costs = [repair_wood_cost]
			if wood_available < repair_wood_cost:
				return {"needs_wood": true, "wood_cost": repair_wood_cost, "structure_type": "tent", "repair": true}
		return {
			"cell": cell,
			"world_position": terrain.to_global(terrain.map_to_local(cell)),
			"approach_world_position": _get_build_approach_world_position(cell),
			"total_steps": (existing_profile.get("layers", []) as Array).size(),
			"structure_type": existing_profile_name,
			"requires_crafting": bool(existing_profile.get("requires_crafting", true)),
			"stage_wood_costs": stage_costs
		}

	var selected_profile_name: String = _choose_build_profile_name(wood_available)
	var selected_profile: Dictionary = _make_build_profile_data(selected_profile_name)
	var selected_layers: Array = selected_profile.get("layers", [])
	if selected_layers.is_empty():
		selected_profile_name = "house"
		selected_profile = _make_build_profile_data(selected_profile_name)
		selected_layers = selected_profile.get("layers", [])
	if selected_layers.is_empty():
		return {}

	for _attempt in 80:
		var point: Vector2 = _random_walkable_world_point()
		var local_position: Vector2 = terrain.to_local(point)
		var cell: Vector2i = terrain.local_to_map(local_position)
		if _can_place_build_at(cell, selected_profile_name):
			_reserved_build_cells[cell] = {"owner": villager_name, "profile": selected_profile_name}
			return {
				"cell": cell,
				"world_position": terrain.to_global(terrain.map_to_local(cell)),
				"approach_world_position": _get_build_approach_world_position(cell),
				"total_steps": selected_layers.size(),
				"structure_type": selected_profile_name,
				"requires_crafting": bool(selected_profile.get("requires_crafting", true)),
				"stage_wood_costs": selected_profile.get("stage_wood_costs", [])
			}

	return {}

func place_build_part(villager_name: String, cell: Vector2i, step_index: int) -> bool:
	var profile_name: String = _get_reserved_build_site_profile(cell)
	var is_repair_site: bool = _is_reserved_build_site_repair(cell)
	var profile: Dictionary = _make_build_profile_data(profile_name)
	var profile_layers: Array = profile.get("layers", [])
	var profile_atlas: Array = profile.get("atlas", [])
	var profile_source_ids: Array = profile.get("source_ids", [])
	var profile_offsets: Array = profile.get("offsets", [])
	if step_index < 0:
		return false
	if step_index >= profile_layers.size():
		return false
	if profile_layers.is_empty():
		return false
	if _get_reserved_build_site_owner(cell) != villager_name:
		return false

	var layer: TileMapLayer = profile_layers[step_index]
	var atlas: Vector2i = profile_atlas[step_index]
	var source_id: int = profile_source_ids[step_index]
	var offset: Vector2i = profile_offsets[step_index]
	var target_cell: Vector2i = cell + offset
	# For tents: if the cell is within a tree's canopy, place on the behind-trees layer
	if profile_name == "tent" and _tent_behind_layer != null and _tent_overlaps_tree_canopy(target_cell):
		layer = _tent_behind_layer
	if profile_name == "tent" and step_index == profile_layers.size() - 1:
		atlas = tent_atlas
		source_id = tent_source_id
	layer.set_cell(target_cell, source_id, atlas, 0)
	if profile_name == "tent" and step_index == profile_layers.size() - 1:
		var entry: Dictionary = _tent_decay_state.get(target_cell, {})
		if is_repair_site:
			var current_health: float = float(entry.get("health", 0.0))
			entry["health"] = clampf(current_health + tent_repair_health_gain, 1.0, tent_max_health)
		else:
			entry["health"] = tent_max_health
		entry["collapsed"] = false
		entry["collapse_timer"] = 0.0
		entry["owner"] = villager_name
		_tent_decay_state[target_cell] = entry

	if step_index >= profile_layers.size() - 1:
		_reserved_build_cells.erase(cell)
		_claim_building_cells(villager_name, cell, profile_name)
		_register_shelter_cell(cell, profile_name, villager_name)

	if _shadow_overlay:
		_shadow_overlay.queue_redraw()
	return true

func release_build_site(villager_name: String, cell: Vector2i) -> void:
	if _get_reserved_build_site_owner(cell) == villager_name:
		_reserved_build_cells.erase(cell)

func _can_place_build_at(cell: Vector2i, profile_name: String = "house") -> bool:
	if _reserved_build_cells.has(cell):
		return false
	var profile: Dictionary = _make_build_profile_data(profile_name)
	var profile_layers: Array = profile.get("layers", [])
	var profile_offsets: Array = profile.get("offsets", [])
	if profile_layers.is_empty():
		return false

	var world_position: Vector2 = terrain.to_global(terrain.map_to_local(cell))
	if not is_world_position_walkable(world_position):
		return false

	for y in range(-build_site_padding_cells, build_site_padding_cells + 1):
		for x in range(-build_site_padding_cells, build_site_padding_cells + 1):
			var check_cell := cell + Vector2i(x, y)
			if _reserved_build_cells.has(check_cell):
				return false
			if _tent_behind_layer != null and _tent_behind_layer.get_cell_source_id(check_cell) != -1:
				return false
			for index in profile_layers.size():
				var layer: TileMapLayer = profile_layers[index]
				var offset: Vector2i = profile_offsets[index]
				if layer.get_cell_source_id(check_cell + offset) != -1:
					return false

	return true

func _get_build_approach_world_position(cell: Vector2i) -> Vector2:
	if terrain == null:
		return Vector2.ZERO
	var center_world: Vector2 = terrain.to_global(terrain.map_to_local(cell))
	var directions: Array[Vector2i] = [
		Vector2i(0, 1),
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1)
	]
	for radius in range(1, 4):
		for direction in directions:
			var candidate_cell: Vector2i = cell + direction * radius
			var candidate_world: Vector2 = terrain.to_global(terrain.map_to_local(candidate_cell))
			if is_world_position_walkable(candidate_world):
				return candidate_world
	return center_world

func _random_walkable_world_point() -> Vector2:
	if infinite_map:
		# For infinite maps sample near origin where the starting island is guaranteed.
		for _attempt in 64:
			var angle := randf() * TAU
			var dist := randf_range(10.0, 300.0)
			var point := Vector2(cos(angle), sin(angle)) * dist
			if is_world_position_walkable(point):
				return point
		return Vector2.ZERO
	for _attempt in 64:
		var point := Vector2(
			randf_range(_arena_rect.position.x + 20.0, _arena_rect.end.x - 20.0),
			randf_range(_arena_rect.position.y + 20.0, _arena_rect.end.y - 20.0)
		)
		if is_world_position_walkable(point):
			return point
	return _arena_rect.get_center()

func _build_terrain() -> void:
	terrain.clear()
	_clear_cacti()

	for y in MAP_HEIGHT:
		for x in MAP_WIDTH:
			var cell := Vector2i(x, y)
			var atlas: Vector2i = GRASS_TILES[randi() % GRASS_TILES.size()]
			if _is_desert_biome_cell(cell):
				atlas = DESERT_MIDDLE_TILE
				if y == MAP_HEIGHT - 1 or not _is_desert_biome_cell(Vector2i(x, y + 1)):
					atlas = DESERT_BOTTOM_EDGE_TILE

			# Border ring for visual framing.
			if x == 0 or y == 0 or x == MAP_WIDTH - 1 or y == MAP_HEIGHT - 1:
				atlas = PATH_TILES[randi() % PATH_TILES.size()]

			# Rest hut zone around VillagerAgent.REST_POINT.
			if x >= 9 and x <= 16 and y >= 23 and y <= 29:
				atlas = PATH_TILES[randi() % PATH_TILES.size()]

			# Food dock zone around VillagerAgent.FOOD_POINT.
			if x >= 50 and x <= 58 and y >= 7 and y <= 14:
				atlas = WATER_TILES[randi() % WATER_TILES.size()]

			terrain.set_cell(cell, TERRAIN_SOURCE_ID, atlas, 0)
			if atlas == DESERT_MIDDLE_TILE:
				_maybe_spawn_cactus(cell)

# ──────────────────────────────────────────────────────────
# Infinite map generation (chunk-based, noise-driven)
# ──────────────────────────────────────────────────────────

func _init_infinite_noise() -> void:
	var actual_seed: int = island_noise_seed if island_noise_seed != 0 else randi()

	_terrain_noise = FastNoiseLite.new()
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_noise.seed = actual_seed
	_terrain_noise.frequency = island_noise_frequency
	_terrain_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_terrain_noise.fractal_octaves = 5
	_terrain_noise.domain_warp_enabled = true
	_terrain_noise.domain_warp_amplitude = 60.0
	_terrain_noise.domain_warp_frequency = 0.004

	_tree_spawn_noise = FastNoiseLite.new()
	_tree_spawn_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_tree_spawn_noise.seed = actual_seed + 7
	_tree_spawn_noise.frequency = tree_noise_frequency
	_tree_spawn_noise.fractal_octaves = 2

	if _biome_noise != null:
		_biome_noise.seed = actual_seed + 157

func _generate_starting_island() -> void:
	_generated_chunks.clear()
	_queued_chunks.clear()
	_pending_chunk_queue.clear()
	_pending_chunk_cursor = 0
	_last_stream_chunk = Vector2i(2147483647, 2147483647)
	if terrain != null:
		terrain.clear()
	var tree_layer := _find_tree_layer()
	if tree_layer != null:
		tree_layer.clear()
	_clear_cacti()
	_tree_growth_timers.clear()
	_tree_fruit_timers.clear()
	_chunk_generation_time_left = 0.0
	# Keep startup cheap: only generate the center chunk immediately.
	_generate_chunk(Vector2i.ZERO)
	_enqueue_chunks_around(Vector2i.ZERO)
	# Expand arena rect to cover the visible spawn area.
	_arena_rect = Rect2(Vector2(-1600.0, -900.0), Vector2(3200.0, 1800.0))

func _stream_chunks_around_camera() -> void:
	if world_camera == null or terrain == null:
		return
	var cam_cell: Vector2i = terrain.local_to_map(terrain.to_local(world_camera.position))
	var cam_chunk := Vector2i(
		int(floor(float(cam_cell.x) / float(CHUNK_SIZE))),
		int(floor(float(cam_cell.y) / float(CHUNK_SIZE)))
	)

	# Only enqueue when crossing into a new chunk, so idle frames stay cheap.
	if cam_chunk != _last_stream_chunk:
		_last_stream_chunk = cam_chunk
		_enqueue_chunks_around(cam_chunk)

	var generated_this_frame: int = 0
	while generated_this_frame < max(1, chunk_generation_budget_per_frame) and _pending_chunk_cursor < _pending_chunk_queue.size():
		var chunk: Vector2i = _pending_chunk_queue[_pending_chunk_cursor]
		_pending_chunk_cursor += 1
		_queued_chunks.erase(chunk)
		if _generated_chunks.has(chunk):
			continue
		_generate_chunk(chunk)
		generated_this_frame += 1

	if _pending_chunk_cursor >= _pending_chunk_queue.size():
		_pending_chunk_queue.clear()
		_pending_chunk_cursor = 0

func _enqueue_chunks_around(center_chunk: Vector2i) -> void:
	for radius in range(0, chunk_load_radius + 1):
		for cy in range(center_chunk.y - radius, center_chunk.y + radius + 1):
			for cx in range(center_chunk.x - radius, center_chunk.x + radius + 1):
				if abs(cx - center_chunk.x) != radius and abs(cy - center_chunk.y) != radius:
					continue
				var chunk := Vector2i(cx, cy)
				if _generated_chunks.has(chunk):
					continue
				if _queued_chunks.has(chunk):
					continue
				_pending_chunk_queue.append(chunk)
				_queued_chunks[chunk] = true

func _get_island_land_value(cell: Vector2i) -> float:
	# Mix noise with radial falloff in tile space (fast and deterministic).
	var dist_tiles: float = Vector2(float(cell.x), float(cell.y)).length()
	# Only a small spawn safety boost near origin; outside that, noise dominates.
	var land_boost: float = clampf((18.0 - dist_tiles) / 18.0, 0.0, 1.0) * 0.32
	return _terrain_noise.get_noise_2d(float(cell.x), float(cell.y)) + land_boost

func _is_land_cell(cell: Vector2i) -> bool:
	return _get_island_land_value(cell) >= island_land_threshold

func _is_land_cell_cached(cell: Vector2i, land_cache: Dictionary) -> bool:
	if land_cache.has(cell):
		return bool(land_cache[cell])
	var value: bool = _is_land_cell(cell)
	land_cache[cell] = value
	return value

func _make_tile(atlas: Vector2i, alternative: int = 0) -> Dictionary:
	return {"atlas": atlas, "alt": alternative}

func _cell_random01(cell: Vector2i) -> float:
	# Cheap deterministic hash for per-cell randomness.
	var n: int = cell.x * 374761393 + cell.y * 668265263 + island_noise_seed * 127
	n = int((n ^ (n >> 13)) * 1274126177)
	n = n ^ (n >> 16)
	return float(n & 0x7fffffff) / 2147483647.0

func _get_island_tile_for_cell(cell: Vector2i, land_cache: Dictionary = {}) -> Dictionary:
	if not _is_land_cell_cached(cell, land_cache):
		return _make_tile(WATER_TILES[0], 0)
	if _is_desert_biome_cell(cell):
		var south_land: bool = _is_land_cell_cached(cell + Vector2i.DOWN, land_cache)
		if not south_land:
			return _make_tile(DESERT_BOTTOM_EDGE_TILE, TILE_ALT_ROT_0)
		return _make_tile(DESERT_MIDDLE_TILE, TILE_ALT_ROT_0)

	var n: bool = _is_land_cell_cached(cell + Vector2i.UP, land_cache)
	var s: bool = _is_land_cell_cached(cell + Vector2i.DOWN, land_cache)
	var w: bool = _is_land_cell_cached(cell + Vector2i.LEFT, land_cache)
	var e: bool = _is_land_cell_cached(cell + Vector2i.RIGHT, land_cache)
	var nw: bool = _is_land_cell_cached(cell + Vector2i(-1, -1), land_cache)
	var ne: bool = _is_land_cell_cached(cell + Vector2i(1, -1), land_cache)
	var se: bool = _is_land_cell_cached(cell + Vector2i(1, 1), land_cache)
	var sw: bool = _is_land_cell_cached(cell + Vector2i(-1, 1), land_cache)

	# (1,4) inner corner only on top side. Never rotate; only mirror left/right.
	if n and w and not nw:
		return _make_tile(Vector2i(1, 4), 0)
	if n and e and not ne:
		return _make_tile(Vector2i(1, 4), TileSetAtlasSource.TRANSFORM_FLIP_H)

	# (4,4) outer corner. Never rotate; only mirror left/right.
	if (not n and not w) or (not s and not w):
		return _make_tile(Vector2i(4, 4), TileSetAtlasSource.TRANSFORM_FLIP_H)
	if (not n and not e) or (not s and not e):
		return _make_tile(Vector2i(4, 4), 0)

	# (4,3) bottom edge. Never rotated or flipped.
	if not s:
		return _make_tile(Vector2i(4, 3), 0)

	# (2,4) top/left/right edges. Left/right are mirrored compared to previous mapping.
	if not n:
		return _make_tile(Vector2i(2, 4), TILE_ALT_ROT_0)
	if not e:
		return _make_tile(Vector2i(2, 4), TILE_ALT_ROT_0)
	if not w:
		return _make_tile(Vector2i(2, 4), TILE_ALT_ROT_0)

	# (3,3) center
	return _make_tile(Vector2i(3, 3), TILE_ALT_ROT_0)

func _generate_chunk(chunk_pos: Vector2i) -> void:
	if _generated_chunks.has(chunk_pos):
		return
	_generated_chunks[chunk_pos] = true

	var tree_layer := _find_tree_layer()
	var mature_tree_atlas: Vector2i = tree_growth_stages[0] if tree_growth_stages.size() > 0 else Vector2i(-1, -1)
	var can_spawn_trees: bool = tree_layer != null and mature_tree_atlas != Vector2i(-1, -1)
	var land_cache: Dictionary = {}

	# Precompute land for chunk + 1 cell border, then reuse during autotiling.
	for dy in range(-1, CHUNK_SIZE + 1):
		for dx in range(-1, CHUNK_SIZE + 1):
			var sample_cell := Vector2i(chunk_pos.x * CHUNK_SIZE + dx, chunk_pos.y * CHUNK_SIZE + dy)
			land_cache[sample_cell] = _is_land_cell(sample_cell)

	for dy in CHUNK_SIZE:
		for dx in CHUNK_SIZE:
			var cell := Vector2i(chunk_pos.x * CHUNK_SIZE + dx, chunk_pos.y * CHUNK_SIZE + dy)
			var tile_data: Dictionary = _get_island_tile_for_cell(cell, land_cache)
			var atlas: Vector2i = tile_data.get("atlas", Vector2i(3, 3))
			var alt: int = int(tile_data.get("alt", 0))
			terrain.set_cell(cell, TERRAIN_SOURCE_ID, atlas, alt)
			if atlas == DESERT_MIDDLE_TILE:
				_maybe_spawn_cactus(cell)

			# Trees only on true interior center tiles so shorelines remain readable.
			if can_spawn_trees and atlas == Vector2i(3, 3) and not _tree_growth_timers.has(cell):
				var tv: float = _cell_random01(cell)
				if tv > tree_density_threshold:
					tree_layer.set_cell(cell, tree_source_id, mature_tree_atlas, 0)
					if _mature_tree_count_cache >= 0:
						_mature_tree_count_cache += 1
					_tree_fruit_timers[cell] = randf_range(mature_tree_apple_min_seconds, mature_tree_apple_max_seconds)

func _spawn_initial_villagers() -> void:
	var default_names := ["Iris", "Milo", "Quinn", "Sage", "River", "Ash", "Fern", "Reed", "Vale", "Bryn",
		"Lark", "Wren", "Cove", "Stone", "Glen", "Moor", "Fen", "Dale", "Blaze", "Flint"]
	for i in initial_villager_count:
		var base_name: String = default_names[i] if i < default_names.size() else ("Villager" + str(i + 1))
		spawn_villager(_make_unique_name(base_name))

func _setup_crafting_tables() -> void:
	_crafting_table_root = Node2D.new()
	_crafting_table_root.name = "CraftingTables"
	_crafting_table_root.z_index = 1
	_crafting_table_root.y_sort_enabled = true
	add_child(_crafting_table_root)

	_crafting_table_texture = load(crafting_table_texture_path) as Texture2D
	if _crafting_table_texture == null:
		_crafting_table_texture = _load_texture_from_pixil("res://Workshop.pixil")
	if _crafting_table_texture != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = _crafting_table_texture
		atlas.region = Rect2(float(crafting_table_atlas.x * crafting_table_tile_size.x), float(crafting_table_atlas.y * crafting_table_tile_size.y), float(crafting_table_tile_size.x), float(crafting_table_tile_size.y))
		_crafting_table_texture = atlas

func place_crafting_table(world_position: Vector2) -> void:
	_crafting_table_positions.append(world_position)
	if _crafting_table_root == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = _crafting_table_texture
	sprite.centered = true
	sprite.y_sort_enabled = true
	sprite.position = world_position
	if sprite.texture == null:
		sprite.visible = false
	_crafting_table_root.add_child(sprite)

func _find_crafting_table_build_spot(center_world_position: Vector2) -> Vector2:
	if is_world_position_walkable(center_world_position):
		return center_world_position
	for _attempt in 28:
		var radius: float = randf_range(20.0, 88.0)
		var angle: float = randf_range(0.0, TAU)
		var candidate: Vector2 = center_world_position + Vector2.RIGHT.rotated(angle) * radius
		if is_world_position_walkable(candidate):
			return candidate
	return _random_walkable_world_point()

func request_crafting_table_access(villager_name: String, from_world_position: Vector2, wood_available: int) -> Dictionary:
	var nearest := get_nearest_crafting_table(from_world_position)
	if not nearest.is_empty() and float(nearest.get("distance", INF)) <= crafting_table_search_radius:
		return {
			"has_table": true,
			"world_position": nearest.get("world_position", from_world_position),
			"distance": nearest.get("distance", INF)
		}

	if wood_available < crafting_table_build_wood_cost:
		return {"needs_wood": true, "wood_cost": crafting_table_build_wood_cost}

	var build_spot: Vector2 = _find_crafting_table_build_spot(from_world_position)
	place_crafting_table(build_spot)
	return {"built_table": true, "world_position": build_spot, "wood_cost": crafting_table_build_wood_cost}

func get_nearest_crafting_table(from_world_position: Vector2) -> Dictionary:
	if _crafting_table_positions.is_empty():
		return {}
	var best: Vector2 = _crafting_table_positions[0]
	var best_dist: float = from_world_position.distance_to(best)
	for pos in _crafting_table_positions:
		var d: float = from_world_position.distance_to(pos)
		if d < best_dist:
			best = pos
			best_dist = d
	return {"world_position": best, "distance": best_dist}

func get_stage_wood_cost(stage_index: int) -> int:
	if stage_index < 0:
		return 1
	if stage_index >= build_stage_wood_costs.size():
		return max(1, wood_cost_per_building)
	return max(1, int(build_stage_wood_costs[stage_index]))

func _setup_campfire_system() -> void:
	var campfire_node: Node = get_node_or_null(campfire_layer_path)
	if campfire_node is TileMapLayer:
		_campfire_layer = campfire_node as TileMapLayer
	else:
		_campfire_layer = null
		_campfires.clear()
		return

	if _campfire_light_root == null or not is_instance_valid(_campfire_light_root):
		_campfire_light_root = Node2D.new()
		_campfire_light_root.name = "CampfireLights"
		_campfire_light_root.z_as_relative = false
		_campfire_light_root.z_index = _campfire_layer.z_index + 1
		add_child(_campfire_light_root)

	if _campfire_fx_root == null or not is_instance_valid(_campfire_fx_root):
		_campfire_fx_root = Node2D.new()
		_campfire_fx_root.name = "CampfireFX"
		_campfire_fx_root.z_as_relative = false
		_campfire_fx_root.z_index = _campfire_layer.z_index + 2
		add_child(_campfire_fx_root)

	if _campfire_light_texture == null:
		var size: int = 128
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center: Vector2 = Vector2(float(size) * 0.5, float(size) * 0.5)
		var radius: float = float(size) * 0.5
		for y in range(size):
			for x in range(size):
				var pos: Vector2 = Vector2(float(x), float(y))
				var t: float = clampf(1.0 - center.distance_to(pos) / radius, 0.0, 1.0)
				var falloff: float = t * t
				img.set_pixel(x, y, Color(1.0, 0.62, 0.20, falloff))
		_campfire_light_texture = ImageTexture.create_from_image(img)

	if _campfire_fire_texture == null:
		_campfire_fire_texture = load(campfire_fire_texture_path) as Texture2D
	if _campfire_fire_frames == null:
		_campfire_fire_frames = SpriteFrames.new()
		_campfire_fire_frames.add_animation("burn")
		_campfire_fire_frames.set_animation_loop("burn", true)
		_campfire_fire_frames.set_animation_speed("burn", maxf(1.0, campfire_fire_fps))
		if _campfire_fire_texture != null:
			# Extract frames from fire.png using configured margin and separation
			# Each row is one frame, with proper spacing accounting
			var frame_start_y: float = float(campfire_fire_frame_margin.y)
			for row in range(max(1, campfire_fire_frame_rows)):
				var frame_x: float = float(campfire_fire_frame_margin.x)
				var frame_y: float = frame_start_y + float(row) * (float(campfire_fire_frame_size.y) + float(campfire_fire_frame_separation.y))
				var frame_tex := AtlasTexture.new()
				frame_tex.atlas = _campfire_fire_texture
				frame_tex.region = Rect2(frame_x, frame_y, float(campfire_fire_frame_size.x), float(campfire_fire_frame_size.y))
				_campfire_fire_frames.add_frame("burn", frame_tex)

	campfire_source_id = _resolve_campfire_source_for_atlas(campfire_unlit_atlas)

	_rebuild_campfires_from_layer()

func _create_campfire_flame(cell: Vector2i) -> AnimatedSprite2D:
	if _campfire_fx_root == null or _campfire_fire_frames == null:
		return null
	if _campfire_fire_frames.get_frame_count("burn") <= 0:
		return null
	var flame := AnimatedSprite2D.new()
	flame.sprite_frames = _campfire_fire_frames
	flame.animation = "burn"
	flame.play("burn")
	flame.centered = true
	flame.global_position = _campfire_world_position(cell) + Vector2(0.0, campfire_fire_y_offset)
	flame.scale = Vector2.ONE * maxf(0.1, campfire_fire_scale)
	flame.rotation = deg_to_rad(campfire_fire_rotation_degrees)
	flame.z_as_relative = false
	flame.z_index = (_campfire_layer.z_index + 2) if _campfire_layer != null else 4
	_campfire_fx_root.add_child(flame)
	return flame

func _is_configured_unlit_campfire_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false
	if layer.get_cell_source_id(cell) == -1:
		return false
	return layer.get_cell_atlas_coords(cell) == campfire_unlit_atlas

func _is_configured_lit_campfire_tile(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false
	if layer.get_cell_source_id(cell) == -1:
		return false
	var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
	return atlas == campfire_lit_atlas or atlas == Vector2i(3, 3)

func _resolve_campfire_source_for_atlas(atlas_coords: Vector2i) -> int:
	if _campfire_layer == null or _campfire_layer.tile_set == null:
		return campfire_source_id
	var tile_set: TileSet = _campfire_layer.tile_set
	if campfire_source_id >= 0:
		var preferred_variant: Variant = tile_set.get_source(campfire_source_id)
		if preferred_variant is TileSetAtlasSource:
			var preferred_source: TileSetAtlasSource = preferred_variant as TileSetAtlasSource
			if preferred_source.has_tile(atlas_coords):
				return campfire_source_id
	for i in range(tile_set.get_source_count()):
		var source_id: int = tile_set.get_source_id(i)
		var source_variant: Variant = tile_set.get_source(source_id)
		if not (source_variant is TileSetAtlasSource):
			continue
		var atlas_source: TileSetAtlasSource = source_variant as TileSetAtlasSource
		if atlas_source.has_tile(atlas_coords):
			return source_id
	return campfire_source_id

func _rebuild_campfires_from_layer() -> void:
	_campfires.clear()
	if _campfire_layer == null:
		return
	if _campfire_light_root != null:
		for child in _campfire_light_root.get_children():
			if is_instance_valid(child):
				child.queue_free()
	if _campfire_fx_root != null:
		for child in _campfire_fx_root.get_children():
			if is_instance_valid(child):
				child.queue_free()
	var unlit_source_id: int = _resolve_campfire_source_for_atlas(campfire_unlit_atlas)
	for cell in _campfire_layer.get_used_cells():
		if not (_is_configured_unlit_campfire_tile(_campfire_layer, cell) or _is_configured_lit_campfire_tile(_campfire_layer, cell)):
			continue
		var lit: bool = _is_configured_lit_campfire_tile(_campfire_layer, cell)
		if lit:
			# Normalize old lit-tile representation to unlit base + animated flame overlay.
			_campfire_layer.set_cell(cell, unlit_source_id, campfire_unlit_atlas, 0)
		var entry: Dictionary = {
			"owner": "",
			"lit": lit,
			"fuel_seconds": campfire_burn_duration_seconds if lit else 0.0,
			"light": null,
			"flame": null
		}
		if lit:
			entry["light"] = _create_campfire_light(cell)
			entry["flame"] = _create_campfire_flame(cell)
		_campfires[cell] = entry

func _campfire_world_position(cell: Vector2i) -> Vector2:
	if _campfire_layer != null:
		return _campfire_layer.to_global(_campfire_layer.map_to_local(cell))
	if terrain != null:
		return terrain.to_global(terrain.map_to_local(cell))
	return Vector2.ZERO

func _create_campfire_light(cell: Vector2i) -> PointLight2D:
	if _campfire_light_root == null:
		return null
	var light := PointLight2D.new()
	light.texture = _campfire_light_texture
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.global_position = _campfire_world_position(cell)
	light.z_as_relative = false
	light.z_index = (_campfire_layer.z_index + 1) if _campfire_layer != null else 3
	var tex_size: float = 128.0
	light.texture_scale = maxf(0.2, campfire_light_radius / tex_size)
	light.energy = campfire_light_energy
	_campfire_light_root.add_child(light)
	return light

func _set_campfire_lit_state(cell: Vector2i, lit: bool) -> bool:
	if _campfire_layer == null:
		return false
	if not _campfires.has(cell):
		return false
	var entry: Dictionary = _campfires[cell]
	if bool(entry.get("lit", false)) == lit:
		return true
	entry["lit"] = lit
	var unlit_source_id: int = _resolve_campfire_source_for_atlas(campfire_unlit_atlas)
	_campfire_layer.set_cell(cell, unlit_source_id, campfire_unlit_atlas, 0)
	if lit:
		entry["fuel_seconds"] = maxf(1.0, float(entry.get("fuel_seconds", 0.0)))
		entry["light"] = _create_campfire_light(cell)
		entry["flame"] = _create_campfire_flame(cell)
	else:
		var light_variant: Variant = entry.get("light", null)
		if light_variant is PointLight2D and is_instance_valid(light_variant):
			(light_variant as PointLight2D).queue_free()
		entry["light"] = null
		var flame_variant: Variant = entry.get("flame", null)
		if flame_variant is AnimatedSprite2D and is_instance_valid(flame_variant):
			(flame_variant as AnimatedSprite2D).queue_free()
		entry["flame"] = null
	_campfires[cell] = entry
	return true

func _update_campfires(delta: float) -> void:
	if _campfires.is_empty():
		return
	var sun: float = _sun_intensity()
	var night_factor: float = clampf(1.0 - sun, 0.0, 1.0)
	for cell_variant in _campfires.keys().duplicate():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		var entry: Dictionary = _campfires.get(cell, {})
		if bool(entry.get("lit", false)):
			entry["fuel_seconds"] = maxf(0.0, float(entry.get("fuel_seconds", 0.0)) - delta)
			if float(entry.get("fuel_seconds", 0.0)) <= 0.0:
				_set_campfire_lit_state(cell, false)
				entry = _campfires.get(cell, entry)
		var light_variant: Variant = entry.get("light", null)
		if light_variant is PointLight2D and is_instance_valid(light_variant):
			var light: PointLight2D = light_variant as PointLight2D
			light.global_position = _campfire_world_position(cell)
			light.energy = lerpf(campfire_light_energy * 0.25, campfire_light_energy, night_factor)
			light.enabled = bool(entry.get("lit", false))
		var flame_variant: Variant = entry.get("flame", null)
		if flame_variant is AnimatedSprite2D and is_instance_valid(flame_variant):
			var flame: AnimatedSprite2D = flame_variant as AnimatedSprite2D
			flame.global_position = _campfire_world_position(cell) + Vector2(0.0, campfire_fire_y_offset)
			flame.visible = bool(entry.get("lit", false))
		_campfires[cell] = entry

func _campfire_warmth_bonus_at(world_position: Vector2) -> float:
	if _campfires.is_empty() or campfire_warmth_bonus_c <= 0.0:
		return 0.0
	var radius: float = maxf(8.0, campfire_warmth_radius)
	var bonus: float = 0.0
	for cell_variant in _campfires.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		var entry: Dictionary = _campfires.get(cell, {})
		if not bool(entry.get("lit", false)):
			continue
		var d: float = world_position.distance_to(_campfire_world_position(cell))
		if d > radius:
			continue
		var t: float = clampf(1.0 - d / radius, 0.0, 1.0)
		bonus = maxf(bonus, campfire_warmth_bonus_c * (t * t))
	return bonus

func _can_place_campfire_at(cell: Vector2i) -> bool:
	if terrain == null or _campfire_layer == null:
		return false
	if _campfires.has(cell):
		return false
	if _reserved_build_cells.has(cell):
		return false
	if _shelter_cells.has(cell):
		return false
	if terrain.get_cell_source_id(cell) == -1:
		return false
	if terrain.get_cell_atlas_coords(cell) == WATER_TILES[0]:
		return false
	for layer in _build_phase_layers:
		if layer != null and layer.get_cell_source_id(cell) != -1:
			return false
	if _tent_build_layer != null and _tent_build_layer.get_cell_source_id(cell) != -1:
		return false
	if _tent_behind_layer != null and _tent_behind_layer.get_cell_source_id(cell) != -1:
		return false
	var tree_layer: TileMapLayer = _find_tree_layer()
	if tree_layer != null and tree_layer.get_cell_source_id(cell) != -1:
		return false
	var world_pos: Vector2 = terrain.to_global(terrain.map_to_local(cell))
	return is_world_position_walkable(world_pos)

func _find_campfire_build_cell(from_world_position: Vector2) -> Vector2i:
	if terrain == null:
		return Vector2i(-9999, -9999)
	var center_cell: Vector2i = terrain.local_to_map(terrain.to_local(from_world_position))
	for _attempt in range(48):
		var angle: float = randf() * TAU
		var radius: float = randf_range(18.0, maxf(20.0, campfire_search_radius))
		var candidate_world: Vector2 = from_world_position + Vector2.RIGHT.rotated(angle) * radius
		var candidate_cell: Vector2i = terrain.local_to_map(terrain.to_local(candidate_world))
		if _can_place_campfire_at(candidate_cell):
			return candidate_cell
	for y in range(-4, 5):
		for x in range(-4, 5):
			var candidate: Vector2i = center_cell + Vector2i(x, y)
			if _can_place_campfire_at(candidate):
				return candidate
	return Vector2i(-9999, -9999)

func _find_nearest_campfire_cell(from_world_position: Vector2, require_lit: bool, require_unlit: bool) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-9999, -9999)
	var best_dist: float = INF
	for cell_variant in _campfires.keys():
		if not (cell_variant is Vector2i):
			continue
		var cell: Vector2i = cell_variant
		var entry: Dictionary = _campfires.get(cell, {})
		var lit: bool = bool(entry.get("lit", false))
		if require_lit and not lit:
			continue
		if require_unlit and lit:
			continue
		var world_pos: Vector2 = _campfire_world_position(cell)
		var d: float = from_world_position.distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best_cell = cell
	return best_cell

func manage_campfire(villager_name: String, from_world_position: Vector2, action: String, interaction_distance: float, wood_available: int) -> Dictionary:
	if _campfire_layer == null or terrain == null:
		return {"performed": false, "reason": "missing_layer"}
	var clean_action: String = action.strip_edges().to_lower()
	var target_cell: Vector2i = Vector2i(-9999, -9999)
	if clean_action == "build":
		if wood_available < campfire_build_wood_cost:
			return {"performed": false, "reason": "needs_wood", "wood_cost": campfire_build_wood_cost}
		target_cell = _find_campfire_build_cell(from_world_position)
		if target_cell == Vector2i(-9999, -9999):
			print("DEBUG: No suitable campfire build cell found near ", from_world_position)
	else:
		var need_lit: bool = clean_action == "extinguish"
		var need_unlit: bool = clean_action == "light"
		target_cell = _find_nearest_campfire_cell(from_world_position, need_lit, need_unlit)

	if target_cell == Vector2i(-9999, -9999):
		return {"performed": false, "reason": "no_target"}

	var target_world_position: Vector2 = _campfire_world_position(target_cell)
	var d: float = from_world_position.distance_to(target_world_position)
	if d > maxf(8.0, interaction_distance):
		return {
			"performed": false,
			"reason": "too_far",
			"target_cell": target_cell,
			"target_world_position": target_world_position
		}

	match clean_action:
		"build":
			if not _can_place_campfire_at(target_cell):
				print("DEBUG: Campfire build blocked at cell ", target_cell)
				return {"performed": false, "reason": "blocked", "target_cell": target_cell, "target_world_position": target_world_position}
			var build_source_id: int = _resolve_campfire_source_for_atlas(campfire_unlit_atlas)
			print("DEBUG: Setting campfire at cell ", target_cell, " with source_id=", build_source_id, " atlas=", campfire_unlit_atlas)
			_campfire_layer.set_cell(target_cell, build_source_id, campfire_unlit_atlas, 0)
			_campfires[target_cell] = {"owner": villager_name, "lit": false, "fuel_seconds": 0.0, "light": null, "flame": null}
			print("DEBUG: Campfire successfully placed at ", target_cell, " and registered in _campfires dict")
			# Verify what's actually in the tilemap now
			var actual_source: int = _campfire_layer.get_cell_source_id(target_cell)
			var actual_atlas: Vector2i = _campfire_layer.get_cell_atlas_coords(target_cell)
			print("DEBUG: Verification - actual source_id=", actual_source, " actual_atlas=", actual_atlas, " expected_atlas=", campfire_unlit_atlas)
			print("DEBUG: Campfire layer z_index=", _campfire_layer.z_index)
			return {
				"performed": true,
				"action": "build",
				"wood_cost": campfire_build_wood_cost,
				"target_cell": target_cell,
				"target_world_position": target_world_position
			}
		"light":
			if not _campfires.has(target_cell):
				return {"performed": false, "reason": "missing_target"}
			var light_entry: Dictionary = _campfires.get(target_cell, {})
			if bool(light_entry.get("lit", false)):
				return {"performed": false, "reason": "already_lit"}
			light_entry["fuel_seconds"] = maxf(campfire_burn_duration_seconds, float(light_entry.get("fuel_seconds", 0.0)))
			_campfires[target_cell] = light_entry
			_set_campfire_lit_state(target_cell, true)
			return {"performed": true, "action": "light", "target_cell": target_cell, "target_world_position": target_world_position}
		"extinguish":
			if not _campfires.has(target_cell):
				return {"performed": false, "reason": "missing_target"}
			var extinguish_entry: Dictionary = _campfires.get(target_cell, {})
			if not bool(extinguish_entry.get("lit", false)):
				return {"performed": false, "reason": "already_unlit"}
			_set_campfire_lit_state(target_cell, false)
			return {"performed": true, "action": "extinguish", "target_cell": target_cell, "target_world_position": target_world_position}
		"destroy":
			if not _campfires.has(target_cell):
				return {"performed": false, "reason": "missing_target"}
			var destroy_entry: Dictionary = _campfires.get(target_cell, {})
			var light_variant: Variant = destroy_entry.get("light", null)
			if light_variant is PointLight2D and is_instance_valid(light_variant):
				(light_variant as PointLight2D).queue_free()
			var flame_variant: Variant = destroy_entry.get("flame", null)
			if flame_variant is AnimatedSprite2D and is_instance_valid(flame_variant):
				(flame_variant as AnimatedSprite2D).queue_free()
			_campfires.erase(target_cell)
			_campfire_layer.erase_cell(target_cell)
			return {
				"performed": true,
				"action": "destroy",
				"wood_refund": max(0, campfire_destroy_wood_refund),
				"target_cell": target_cell,
				"target_world_position": target_world_position
			}
	return {"performed": false, "reason": "unknown_action"}

func _villager_has_reserved_build_site(villager_name: String) -> bool:
	for cell in _reserved_build_cells.keys():
		if _get_reserved_build_site_owner(cell) == villager_name:
			return true
	return false

func craft_stage_item(villager_name: String, stage_index: int, crafter_world_position: Vector2, wood_available: int) -> Dictionary:
	if not _villager_has_reserved_build_site(villager_name):
		return {"no_site": true}
	var reserved_profile_name: String = "house"
	var reserved_is_repair: bool = false
	for cell in _reserved_build_cells.keys():
		if _get_reserved_build_site_owner(cell) == villager_name:
			reserved_profile_name = _get_reserved_build_site_profile(cell)
			reserved_is_repair = _is_reserved_build_site_repair(cell)
			break
	var profile: Dictionary = _make_build_profile_data(reserved_profile_name)
	var profile_layers: Array = profile.get("layers", [])
	var stage_costs: Array = profile.get("stage_wood_costs", [])
	var requires_crafting: bool = bool(profile.get("requires_crafting", true))
	if stage_index < 0 or stage_index >= profile_layers.size():
		return {"invalid_stage": true}
	var cost: int = tent_build_wood_cost if reserved_profile_name == "tent" else get_stage_wood_cost(stage_index)
	if reserved_profile_name == "tent" and reserved_is_repair:
		cost = max(1, tent_repair_wood_cost)
	if stage_index >= 0 and stage_index < stage_costs.size():
		cost = max(1, int(stage_costs[stage_index]))
	if not requires_crafting:
		if wood_available < cost:
			return {"needs_wood": true, "wood_cost": cost}
		return {"crafted": true, "wood_cost": cost, "stage_index": stage_index}
	if _crafting_table_positions.is_empty():
		return {"needs_table": true}

	var nearest := get_nearest_crafting_table(crafter_world_position)
	if nearest.is_empty() or nearest.get("distance", INF) > crafting_table_interaction_radius:
		return {"needs_table": true}

	if wood_available < cost:
		return {"needs_wood": true, "wood_cost": cost}

	return {"crafted": true, "wood_cost": cost, "stage_index": stage_index}

func get_nearest_home(villager_name: String, from_world_position: Vector2, allow_occupied: bool = false) -> Dictionary:
	var owned_cell: Vector2i = _get_owned_home_cell(villager_name)
	if owned_cell != Vector2i(-9999, -9999):
		var owned_pos: Vector2 = terrain.to_global(terrain.map_to_local(owned_cell)) if terrain != null else Vector2.ZERO
		return {"cell": owned_cell, "world_position": owned_pos, "distance": from_world_position.distance_to(owned_pos), "owned": true}

	var best_cell := Vector2i(-9999, -9999)
	var best_pos := Vector2.ZERO
	var best_dist: float = INF
	for cell_variant in _shelter_cells.keys():
		if not (cell_variant is Vector2i):
			continue
		var shelter_cell: Vector2i = cell_variant
		var owner_name: String = str(_home_owner_by_cell.get(shelter_cell, ""))
		if not owner_name.is_empty() and owner_name != villager_name and not allow_occupied:
			continue
		if _home_has_other_occupants(villager_name, shelter_cell) and not allow_occupied:
			continue
		var pos: Vector2 = terrain.to_global(terrain.map_to_local(shelter_cell))
		var d: float = from_world_position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_cell = shelter_cell
			best_pos = pos

	if best_cell == Vector2i(-9999, -9999):
		return {}
	return {"cell": best_cell, "world_position": best_pos, "distance": best_dist}

func enter_home(villager_name: String, home_cell: Vector2i) -> bool:
	if not _shelter_cells.has(home_cell):
		return false
	var owner_name: String = str(_home_owner_by_cell.get(home_cell, ""))
	if not owner_name.is_empty() and owner_name != villager_name:
		return false
	if _home_has_other_occupants(villager_name, home_cell):
		return false

	var occupants: Array = _home_occupants.get(home_cell, [])
	if occupants.find(villager_name) == -1:
		occupants.append(villager_name)
	_home_occupants[home_cell] = occupants
	if owner_name.is_empty():
		_home_owner_by_cell[home_cell] = villager_name
	_villager_home_cell[villager_name] = home_cell
	_update_home_transparency()
	return true

func leave_home(villager_name: String) -> void:
	if not _villager_home_cell.has(villager_name):
		return
	var home_cell: Vector2i = _villager_home_cell[villager_name]
	_villager_home_cell.erase(villager_name)
	if _home_occupants.has(home_cell):
		var occupants: Array = _home_occupants[home_cell]
		var idx: int = occupants.find(villager_name)
		if idx >= 0:
			occupants.remove_at(idx)
		if occupants.is_empty():
			_home_occupants.erase(home_cell)
		else:
			_home_occupants[home_cell] = occupants
	_update_home_transparency()

func _update_home_transparency() -> void:
	var occupied_cells: Dictionary = {}
	for cell_variant in _home_occupants.keys():
		if not (cell_variant is Vector2i):
			continue
		var occupants_variant: Variant = _home_occupants.get(cell_variant, [])
		if not (occupants_variant is Array):
			continue
		if (occupants_variant as Array).is_empty():
			continue
		occupied_cells[cell_variant] = true

	for cell_variant in occupied_cells.keys():
		if cell_variant is Vector2i:
			_set_home_revealed(cell_variant, true)

	for cell_variant in _revealed_home_tiles.keys().duplicate():
		if not (cell_variant is Vector2i):
			continue
		if occupied_cells.has(cell_variant):
			continue
		_set_home_revealed(cell_variant, false)

func _should_hide_layer_for_home(layer: TileMapLayer) -> bool:
	if layer == null:
		return false
	var foundation_node: Node = get_node_or_null(foundation_layer_path)
	if foundation_node is TileMapLayer and layer == (foundation_node as TileMapLayer):
		return false
	var floor_node: Node = get_node_or_null(floor_layer_path)
	if floor_node is TileMapLayer and layer == (floor_node as TileMapLayer):
		return false
	return true

func _ensure_home_transparency_overlay() -> void:
	if _home_transparency_overlay != null and is_instance_valid(_home_transparency_overlay):
		return
	_home_transparency_overlay = Node2D.new()
	_home_transparency_overlay.name = "HomeTransparencyOverlay"
	_home_transparency_overlay.z_as_relative = false
	add_child(_home_transparency_overlay)

func _make_home_translucent_sprite(layer: TileMapLayer, cell: Vector2i, source_id: int, atlas_coords: Vector2i, alternative: int) -> Sprite2D:
	if layer == null or layer.tile_set == null:
		return null
	var source_variant: Variant = layer.tile_set.get_source(source_id)
	if not (source_variant is TileSetAtlasSource):
		return null
	var atlas_source: TileSetAtlasSource = source_variant as TileSetAtlasSource
	var tex: Texture2D = atlas_source.texture
	if tex == null:
		return null
	var region: Rect2i = atlas_source.get_tile_texture_region(atlas_coords, alternative)
	if region.size.x <= 0 or region.size.y <= 0:
		region = atlas_source.get_tile_texture_region(atlas_coords, 0)
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region.position, region.size)
	sprite.centered = true
	sprite.global_position = layer.to_global(layer.map_to_local(cell))
	sprite.modulate = Color(1.0, 1.0, 1.0, clampf(occupied_home_alpha, 0.05, 1.0))
	sprite.z_as_relative = false
	sprite.z_index = layer.z_index

	var transform_bits: int = alternative & (
		TileSetAtlasSource.TRANSFORM_FLIP_H |
		TileSetAtlasSource.TRANSFORM_FLIP_V |
		TileSetAtlasSource.TRANSFORM_TRANSPOSE
	)
	if transform_bits == TILE_ALT_ROT_90:
		sprite.rotation = PI * 0.5
	elif transform_bits == TILE_ALT_ROT_180:
		sprite.rotation = PI
	elif transform_bits == TILE_ALT_ROT_270:
		sprite.rotation = PI * 1.5
	else:
		sprite.flip_h = (transform_bits & TileSetAtlasSource.TRANSFORM_FLIP_H) != 0
		sprite.flip_v = (transform_bits & TileSetAtlasSource.TRANSFORM_FLIP_V) != 0
	return sprite

func _set_home_revealed(home_cell: Vector2i, reveal: bool) -> void:
	if reveal:
		if _revealed_home_tiles.has(home_cell):
			return
		_ensure_home_transparency_overlay()
		var profile_name: String = str(_shelter_cells.get(home_cell, "house"))
		var profile: Dictionary = _make_build_profile_data(profile_name)
		var profile_layers: Array = profile.get("layers", [])
		var profile_offsets: Array = profile.get("offsets", [])
		var saved_tiles: Array = []
		var count: int = mini(profile_layers.size(), profile_offsets.size())
		for i in range(count):
			var layer_variant: Variant = profile_layers[i]
			var offset_variant: Variant = profile_offsets[i]
			if not (layer_variant is TileMapLayer) or not (offset_variant is Vector2i):
				continue
			var layer: TileMapLayer = layer_variant
			if not _should_hide_layer_for_home(layer):
				continue
			var target_cell: Vector2i = home_cell + (offset_variant as Vector2i)
			var source_id: int = layer.get_cell_source_id(target_cell)
			if source_id == -1:
				continue
			var atlas_coords: Vector2i = layer.get_cell_atlas_coords(target_cell)
			var alternative: int = layer.get_cell_alternative_tile(target_cell)
			var sprite: Sprite2D = _make_home_translucent_sprite(layer, target_cell, source_id, atlas_coords, alternative)
			if sprite != null and _home_transparency_overlay != null:
				_home_transparency_overlay.add_child(sprite)
			saved_tiles.append({
				"layer": layer,
				"cell": target_cell,
				"source_id": source_id,
				"atlas": atlas_coords,
				"alternative": alternative,
				"sprite": sprite
			})
			layer.erase_cell(target_cell)
		if not saved_tiles.is_empty():
			_revealed_home_tiles[home_cell] = saved_tiles
			if _shadow_overlay != null:
				_shadow_overlay.queue_redraw()
		return

	if not _revealed_home_tiles.has(home_cell):
		return
	var saved_variant: Variant = _revealed_home_tiles.get(home_cell, [])
	_revealed_home_tiles.erase(home_cell)
	if not (saved_variant is Array):
		return
	for entry_variant in saved_variant:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var layer_variant: Variant = entry.get("layer", null)
		var cell_variant: Variant = entry.get("cell", null)
		if not (layer_variant is TileMapLayer) or not (cell_variant is Vector2i):
			continue
		var layer: TileMapLayer = layer_variant
		var sprite_variant: Variant = entry.get("sprite", null)
		if sprite_variant is Sprite2D and is_instance_valid(sprite_variant):
			(sprite_variant as Sprite2D).queue_free()
		layer.set_cell(
			cell_variant,
			int(entry.get("source_id", -1)),
			entry.get("atlas", Vector2i.ZERO),
			int(entry.get("alternative", 0))
		)
	if _shadow_overlay != null:
		_shadow_overlay.queue_redraw()

func _on_join_requested(viewer_name: String) -> void:
	var final_name := _make_unique_name(viewer_name)
	spawn_villager(final_name)

func _ensure_npc_profile(villager_name: String) -> void:
	if not _npc_physical_genes.has(villager_name):
		_npc_physical_genes[villager_name] = _generate_physical_genes()
	if not _npc_llm_genes.has(villager_name):
		_npc_llm_genes[villager_name] = _generate_llm_genes()
	var physical_profile: Dictionary = _npc_physical_genes[villager_name]
	if not physical_profile.has("sex_drive_interval_seconds"):
		physical_profile["sex_drive_interval_seconds"] = randf_range(45.0, 140.0)
	physical_profile["llm_decision_interval_seconds"] = clampf(
		float(physical_profile.get("llm_decision_interval_seconds", llm_min_decision_interval_seconds)),
		maxf(15.0, llm_min_decision_interval_seconds),
		maxf(maxf(15.0, llm_min_decision_interval_seconds), llm_max_decision_interval_seconds)
	)
	if not physical_profile.has("sex_drive_interval_range_seconds"):
		var base_interval: float = clampf(float(physical_profile.get("sex_drive_interval_seconds", 80.0)), 12.0, 300.0)
		physical_profile["sex_drive_interval_range_seconds"] = clampf(base_interval * randf_range(0.06, 0.16), 2.0, 42.0)
	_npc_physical_genes[villager_name] = physical_profile
	var llm_profile: Dictionary = _npc_llm_genes[villager_name]
	if not llm_profile.has("swim_fear"):
		llm_profile["swim_fear"] = randf_range(0.0, 1.0)
	if not llm_profile.has("bravery"):
		llm_profile["bravery"] = randf_range(0.0, 1.0)
	if not llm_profile.has("direction_word"):
		llm_profile["direction_word"] = _random_direction_word()
		_npc_llm_genes[villager_name] = llm_profile
	if not _npc_llm_contexts.has(villager_name):
		var physical: Dictionary = _npc_physical_genes[villager_name]
		_npc_llm_contexts[villager_name] = {
			"long_term_memories": [],
			"recent_events": [],
			"claims": [],
			"nearby_claim_events": [],
			"allowed_memory_types": physical.get("long_term_memory_types", ["status", "social"]),
			"goals": (_npc_llm_genes[villager_name] as Dictionary).get("goals", []),
			"created_at": Time.get_unix_time_from_system()
		}

func _generate_physical_genes() -> Dictionary:
	var gender_options: Array[String] = ["female", "male", "nonbinary"]
	var hair_options: Array[String] = ["black", "brown", "blonde", "red", "silver"]
	var memory_type_sets: Array = [
		["status", "resources"],
		["status", "social"],
		["status", "conflict"],
		["status", "resources", "social"]
	]
	var metabolism: float = randf_range(0.72, 1.45)
	var llm_interval: float = randf_range(llm_min_decision_interval_seconds, llm_max_decision_interval_seconds)
	return {
		"gender": gender_options[randi() % gender_options.size()],
		"hair_color": hair_options[randi() % hair_options.size()],
		"metabolism": metabolism,
		"skin_melanin": randf_range(0.05, 0.95),
		"move_speed_multiplier": clampf(metabolism * randf_range(0.92, 1.08), 0.65, 2.0),
		"energy_drain_multiplier": clampf(metabolism * randf_range(0.90, 1.12), 0.6, 2.2),
		"hunger_drain_multiplier": clampf((0.7 + metabolism * 0.45) * randf_range(0.92, 1.12), 0.5, 2.2),
		"sex_drive_interval_seconds": randf_range(45.0, 140.0),
		"sex_drive_interval_range_seconds": randf_range(4.0, 20.0),
		"llm_decision_interval_seconds": llm_interval,
		"long_term_memory_types": memory_type_sets[randi() % memory_type_sets.size()]
	}

func _generate_llm_genes() -> Dictionary:
	var goal_pool: Array[String] = ["stay_safe", "build_home", "gather_resources", "help_others", "explore"]
	goal_pool.shuffle()
	var goals: Array[String] = [goal_pool[0], goal_pool[1]]
	return {
		"swim_fear": randf_range(0.0, 1.0),
		"mean": randf_range(0.0, 1.0),
		"compassion": randf_range(0.0, 1.0),
		"selfish": randf_range(0.0, 1.0),
		"talkative": randf_range(0.0, 1.0),
		"funny": randf_range(0.0, 1.0),
		"diligence": randf_range(0.1, 1.0),
		"bravery": randf_range(0.0, 1.0),
		"direction_word": _random_direction_word(),
		"goals": goals,
		"primary_goal": goals[0]
	}

func _random_real_direction_word() -> String:
	if REAL_DIRECTION_WORDS.is_empty():
		return "path"
	return REAL_DIRECTION_WORDS[randi() % REAL_DIRECTION_WORDS.size()]

func _register_direction_word(word: String, force_new: bool = false) -> String:
	var key: String = word.strip_edges().to_lower()
	if key.is_empty() or not REAL_DIRECTION_WORDS.has(key):
		key = _random_real_direction_word()
	if force_new:
		var attempts: int = 0
		while _direction_word_vectors.has(key) and attempts < REAL_DIRECTION_WORDS.size():
			key = _random_real_direction_word()
			attempts += 1
		if _direction_word_vectors.has(key):
			return key
	if not _direction_word_vectors.has(key):
		var angle: float = randf() * TAU
		var radius: float = randf_range(0.35, 1.0)
		_direction_word_vectors[key] = Vector2(cos(angle), sin(angle)) * radius
	return key

func _initialize_direction_word_space() -> void:
	if not _direction_word_vectors.is_empty():
		return
	var shuffled_words: Array = REAL_DIRECTION_WORDS.duplicate(true)
	shuffled_words.shuffle()
	var target_size: int = mini(maxi(16, direction_word_catalog_size), shuffled_words.size())
	for i in range(target_size):
		_register_direction_word(str(shuffled_words[i]), true)

func _random_direction_word() -> String:
	if _direction_word_vectors.is_empty():
		_initialize_direction_word_space()
	var words: Array = _direction_word_vectors.keys()
	if words.is_empty():
		return _register_direction_word(_random_real_direction_word(), true)
	return str(words[randi() % words.size()])

func _direction_word_vector(word: String) -> Vector2:
	var key: String = word.strip_edges().to_lower()
	if key.is_empty():
		key = _random_direction_word()
	if not _direction_word_vectors.has(key):
		key = _register_direction_word(key)
	return _direction_word_vectors[key]

func _nearest_direction_word(target: Vector2, avoid_words: Array[String] = []) -> String:
	if _direction_word_vectors.is_empty():
		_initialize_direction_word_space()
	var avoid_lookup: Dictionary = {}
	for w in avoid_words:
		avoid_lookup[w.to_lower()] = true
	var best_word: String = ""
	var best_score: float = INF
	for key_variant in _direction_word_vectors.keys():
		var key: String = str(key_variant)
		if avoid_lookup.has(key.to_lower()) and _direction_word_vectors.size() > avoid_lookup.size() + 1:
			continue
		var vec: Vector2 = _direction_word_vectors[key]
		var score: float = vec.distance_to(target)
		if score < best_score:
			best_score = score
			best_word = key
	if best_word.is_empty():
		return _random_direction_word()
	return best_word

func _inherit_direction_word_between(parent_word_a: String, parent_word_b: String) -> String:
	var word_a: String = parent_word_a.strip_edges().to_lower()
	var word_b: String = parent_word_b.strip_edges().to_lower()
	if word_a.is_empty():
		word_a = _random_direction_word()
	if word_b.is_empty():
		word_b = _random_direction_word()
	# Expand candidate space with additional real words so children can land between parents.
	for _i in 8:
		_register_direction_word(_random_real_direction_word(), true)
	var vec_a: Vector2 = _direction_word_vector(word_a)
	var vec_b: Vector2 = _direction_word_vector(word_b)
	var midpoint: Vector2 = (vec_a + vec_b) * 0.5
	var child_word: String = _nearest_direction_word(midpoint, [word_a, word_b])
	if randf() < 0.22:
		# Occasional exact parent inheritance keeps strong parent identity in the pool.
		child_word = word_a if randf() < 0.5 else word_b
	if randf() < gene_mutation_chance:
		var mutate_target: Vector2 = midpoint + Vector2(randf_range(-0.28, 0.28), randf_range(-0.28, 0.28))
		child_word = _nearest_direction_word(mutate_target)
	return child_word

func _append_recent_event(villager_name: String, event_text: String) -> void:
	if villager_name.strip_edges().is_empty():
		return
	var clean_text: String = event_text.strip_edges().substr(0, 160)
	if clean_text.is_empty():
		return
	var now: float = Time.get_unix_time_from_system()
	var dedupe_key: String = "%s|%s" % [villager_name, clean_text]
	if now < float(_recent_event_cooldowns.get(dedupe_key, -1.0)):
		return
	_recent_event_cooldowns[dedupe_key] = now + recent_event_dedupe_seconds
	_ensure_npc_profile(villager_name)
	var context: Dictionary = _npc_llm_contexts[villager_name]
	var events: Array = context.get("recent_events", [])
	if not events.is_empty():
		var last_row: Variant = events[events.size() - 1]
		if last_row is Dictionary and str((last_row as Dictionary).get("text", "")) == clean_text:
			(last_row as Dictionary)["t"] = now
			events[events.size() - 1] = last_row
			context["recent_events"] = events
			_npc_llm_contexts[villager_name] = context
			return
	events.append({"t": now, "text": clean_text})
	if events.size() > 20:
		events = events.slice(events.size() - 20, events.size())
	context["recent_events"] = events
	_npc_llm_contexts[villager_name] = context

func _sex_drive_interval_for(villager_name: String) -> float:
	var physical: Dictionary = _npc_physical_genes.get(villager_name, {})
	return clampf(float(physical.get("sex_drive_interval_seconds", 80.0)), 12.0, 300.0)

func _sex_drive_interval_range_for(villager_name: String) -> float:
	var physical: Dictionary = _npc_physical_genes.get(villager_name, {})
	var base: float = _sex_drive_interval_for(villager_name)
	var fallback: float = maxf(4.0, base * 0.1)
	var max_range: float = minf(60.0, base * 0.8)
	return clampf(float(physical.get("sex_drive_interval_range_seconds", fallback)), 0.0, max_range)

func _next_horny_interval_for(villager_name: String) -> float:
	var base: float = _sex_drive_interval_for(villager_name)
	var interval_range: float = _sex_drive_interval_range_for(villager_name)
	if interval_range <= 0.01:
		return base
	return clampf(randf_range(base - interval_range, base + interval_range), 2.0, 360.0)

func _is_npc_horny(villager_name: String, now: float = -1.0) -> bool:
	var t: float = now if now >= 0.0 else float(Time.get_unix_time_from_system())
	return t <= float(_npc_horny_until.get(villager_name, -1.0))

func is_villager_horny(villager_name: String) -> bool:
	return _is_npc_horny(villager_name)

func _ensure_sex_drive_state(villager_name: String, now: float) -> void:
	if not _npc_next_horny_time.has(villager_name):
		_npc_next_horny_time[villager_name] = now + randf_range(2.0, _next_horny_interval_for(villager_name))
	if not _npc_horny_until.has(villager_name):
		_npc_horny_until[villager_name] = -1.0
	if not _npc_last_mate_time.has(villager_name):
		_npc_last_mate_time[villager_name] = -1000000.0

func _update_biological_mating(delta: float) -> void:
	if not biological_mating_enabled:
		return
	_mating_update_timer -= delta
	if _mating_update_timer > 0.0:
		return
	_mating_update_timer = maxf(0.1, mating_check_interval_seconds)
	var now: float = float(Time.get_unix_time_from_system())
	var villagers: Array[VillagerAgent] = _get_active_villagers()
	if villagers.size() >= max_villager_population:
		return
	var mating_distance_sq: float = biological_mating_distance * biological_mating_distance
	for villager in villagers:
		_ensure_npc_profile(villager.villager_name)
		_ensure_sex_drive_state(villager.villager_name, now)
		if now >= float(_npc_next_horny_time.get(villager.villager_name, INF)):
			_npc_horny_until[villager.villager_name] = now + horny_window_seconds
			_npc_next_horny_time[villager.villager_name] = now + _next_horny_interval_for(villager.villager_name)

	var paired: Dictionary = {}
	for i in villagers.size():
		var a: VillagerAgent = villagers[i]
		if paired.has(a.villager_name):
			continue
		if not _is_npc_horny(a.villager_name, now):
			continue
		if now < float(_npc_last_mate_time.get(a.villager_name, -1000000.0)) + mating_cooldown_seconds:
			continue
		for j in range(i + 1, villagers.size()):
			var b: VillagerAgent = villagers[j]
			if paired.has(b.villager_name):
				continue
			if not _is_npc_horny(b.villager_name, now):
				continue
			if now < float(_npc_last_mate_time.get(b.villager_name, -1000000.0)) + mating_cooldown_seconds:
				continue
			if a.position.distance_squared_to(b.position) > mating_distance_sq:
				continue
			paired[a.villager_name] = true
			paired[b.villager_name] = true
			_mate_pair(a, b, now)
			if villagers.size() + paired.size() / 2 >= max_villager_population:
				return
			break

func _mix_numeric_gene(a: float, b: float, min_value: float, max_value: float, jitter: float = 0.08) -> float:
	var base: float = (a + b) * 0.5
	var noise: float = randf_range(-jitter, jitter)
	return clampf(base + noise, min_value, max_value)

func _inherit_shuffled_numeric_gene(parent_a: Dictionary, parent_b: Dictionary, key: String, fallback: float, min_value: float, max_value: float, blend_chance: float = 0.35) -> float:
	var a_val: float = float(parent_a.get(key, fallback))
	var b_val: float = float(parent_b.get(key, fallback))
	var inherited: float = a_val if randf() < 0.5 else b_val
	if randf() < blend_chance:
		inherited = _mix_numeric_gene(a_val, b_val, min_value, max_value, (max_value - min_value) * 0.02)
	return _apply_rare_mutation(inherited, min_value, max_value)

func _apply_rare_mutation(value: float, min_value: float, max_value: float) -> float:
	if randf() >= gene_mutation_chance:
		return clampf(value, min_value, max_value)
	var span: float = maxf(0.0001, max_value - min_value)
	var delta: float = randf_range(-span * gene_mutation_strength, span * gene_mutation_strength)
	return clampf(value + delta, min_value, max_value)

func _mix_physical_genes(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	var memory_types_a: Array = parent_a.get("long_term_memory_types", ["status", "social"])
	var memory_types_b: Array = parent_b.get("long_term_memory_types", ["status", "social"])
	var combined_lookup: Dictionary = {}
	for key in memory_types_a:
		combined_lookup[str(key)] = true
	for key in memory_types_b:
		combined_lookup[str(key)] = true
	var combined_types: Array[String] = []
	for key in combined_lookup.keys():
		combined_types.append(str(key))
	if combined_types.is_empty():
		combined_types = ["status", "social"]
	while combined_types.size() > 4:
		combined_types.remove_at(randi() % combined_types.size())
	if randf() < gene_mutation_chance and not combined_types.has("conflict"):
		combined_types.append("conflict")
	while combined_types.size() > 4:
		combined_types.remove_at(randi() % combined_types.size())

	return {
		"gender": str(parent_a.get("gender", "nonbinary")) if randf() < 0.5 else str(parent_b.get("gender", "nonbinary")),
		"hair_color": str(parent_a.get("hair_color", "brown")) if randf() < 0.5 else str(parent_b.get("hair_color", "brown")),
		"metabolism": _inherit_shuffled_numeric_gene(parent_a, parent_b, "metabolism", 1.0, 0.55, 1.9),
		"skin_melanin": _inherit_shuffled_numeric_gene(parent_a, parent_b, "skin_melanin", 0.5, 0.0, 1.0),
		"move_speed_multiplier": _inherit_shuffled_numeric_gene(parent_a, parent_b, "move_speed_multiplier", 1.0, 0.65, 2.0),
		"energy_drain_multiplier": _inherit_shuffled_numeric_gene(parent_a, parent_b, "energy_drain_multiplier", 1.0, 0.6, 2.2),
		"hunger_drain_multiplier": _inherit_shuffled_numeric_gene(parent_a, parent_b, "hunger_drain_multiplier", 1.0, 0.5, 2.2),
		"sex_drive_interval_seconds": _inherit_shuffled_numeric_gene(parent_a, parent_b, "sex_drive_interval_seconds", 80.0, 20.0, 260.0, 0.22),
		"sex_drive_interval_range_seconds": _inherit_shuffled_numeric_gene(parent_a, parent_b, "sex_drive_interval_range_seconds", 10.0, 0.0, 55.0, 0.18),
		"llm_decision_interval_seconds": _inherit_shuffled_numeric_gene(parent_a, parent_b, "llm_decision_interval_seconds", 4.0, llm_min_decision_interval_seconds, llm_max_decision_interval_seconds, 0.22),
		"long_term_memory_types": combined_types
	}

func _mix_llm_genes(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	var goals_a: Array = parent_a.get("goals", [])
	var goals_b: Array = parent_b.get("goals", [])
	var goals_lookup: Dictionary = {}
	for g in goals_a:
		goals_lookup[str(g)] = true
	for g in goals_b:
		goals_lookup[str(g)] = true
	var goals: Array[String] = []
	for g in goals_lookup.keys():
		goals.append(str(g))
	if goals.size() < 2:
		goals = ["stay_safe", "explore"]
	goals.shuffle()
	if goals.size() > 3:
		goals = goals.slice(0, 3)
	if randf() < gene_mutation_chance:
		var extra_goal_pool: Array[String] = ["stay_safe", "build_home", "gather_resources", "help_others", "explore"]
		extra_goal_pool.shuffle()
		var mutant_goal: String = extra_goal_pool[0]
		if not goals.has(mutant_goal):
			goals.append(mutant_goal)
	while goals.size() > 3:
		goals.remove_at(randi() % goals.size())

	return {
		"swim_fear": _inherit_shuffled_numeric_gene(parent_a, parent_b, "swim_fear", 0.5, 0.0, 1.0),
		"mean": _inherit_shuffled_numeric_gene(parent_a, parent_b, "mean", 0.5, 0.0, 1.0),
		"compassion": _inherit_shuffled_numeric_gene(parent_a, parent_b, "compassion", 0.5, 0.0, 1.0),
		"selfish": _inherit_shuffled_numeric_gene(parent_a, parent_b, "selfish", 0.5, 0.0, 1.0),
		"talkative": _inherit_shuffled_numeric_gene(parent_a, parent_b, "talkative", 0.5, 0.0, 1.0),
		"funny": _inherit_shuffled_numeric_gene(parent_a, parent_b, "funny", 0.5, 0.0, 1.0),
		"diligence": _inherit_shuffled_numeric_gene(parent_a, parent_b, "diligence", 0.5, 0.1, 1.0),
		"bravery": _inherit_shuffled_numeric_gene(parent_a, parent_b, "bravery", 0.5, 0.0, 1.0),
		"direction_word": _inherit_direction_word_between(str(parent_a.get("direction_word", "")), str(parent_b.get("direction_word", ""))),
		"goals": goals,
		"primary_goal": goals[0]
	}

## Mix neural network genes from two parents. Modifies the mixed_genes dictionary in-place.
func _mix_neural_network_genes(mixed_genes: Dictionary, parent_a_genes: Dictionary, parent_b_genes: Dictionary, mutation_chance: float, mutation_strength: float) -> void:
	# Extract parent neural network genes or create defaults
	var parent_a_net = NeuralNetwork.from_genes(parent_a_genes)
	var parent_b_net = NeuralNetwork.from_genes(parent_b_genes)
	
	# Create child network by copying parent A
	var child_net = parent_a_net.duplicate()
	
	# Blend weights and biases with parent B
	for layer_idx in range(child_net.weights.size()):
		for weight_idx in range(child_net.weights[layer_idx].size()):
			var parent_a_weight = parent_a_net.weights[layer_idx][weight_idx]
			var parent_b_weight = parent_b_net.weights[layer_idx][weight_idx]
			
			# 50% chance to take from either parent, then blend
			if randf() < 0.5:
				child_net.weights[layer_idx][weight_idx] = parent_a_weight
			else:
				child_net.weights[layer_idx][weight_idx] = parent_b_weight
			
			# Apply blending
			if randf() < 0.2:  # 20% chance to blend
				child_net.weights[layer_idx][weight_idx] = (parent_a_weight + parent_b_weight) * 0.5
	
	# Similarly for biases
	for layer_idx in range(child_net.biases.size()):
		for bias_idx in range(child_net.biases[layer_idx].size()):
			var parent_a_bias = parent_a_net.biases[layer_idx][bias_idx]
			var parent_b_bias = parent_b_net.biases[layer_idx][bias_idx]
			
			if randf() < 0.5:
				child_net.biases[layer_idx][bias_idx] = parent_a_bias
			else:
				child_net.biases[layer_idx][bias_idx] = parent_b_bias
			
			if randf() < 0.2:
				child_net.biases[layer_idx][bias_idx] = (parent_a_bias + parent_b_bias) * 0.5
	
	# Apply mutations
	child_net.mutate(mutation_chance, mutation_strength)
	
	# Export network to genes and merge into mixed_genes
	var network_genes = child_net.to_genes()
	for key in network_genes:
		mixed_genes[key] = network_genes[key]

func _mate_pair(parent_a: VillagerAgent, parent_b: VillagerAgent, now: float) -> void:
	var a_name: String = parent_a.villager_name
	var b_name: String = parent_b.villager_name
	var a_gender: String = str((_npc_physical_genes.get(a_name, {}) as Dictionary).get("gender", "nonbinary")).to_lower()
	var b_gender: String = str((_npc_physical_genes.get(b_name, {}) as Dictionary).get("gender", "nonbinary")).to_lower()
	var birthing_parent: VillagerAgent = parent_a
	if a_gender == "female" and b_gender != "female":
		birthing_parent = parent_a
	elif b_gender == "female" and a_gender != "female":
		birthing_parent = parent_b
	else:
		birthing_parent = parent_a if randf() < 0.5 else parent_b
	birthing_parent.hunger = maxf(0.0, birthing_parent.hunger - 70.0)
	_append_recent_event(birthing_parent.villager_name, "gave birth and lost 70 hunger")

	_npc_last_mate_time[a_name] = now
	_npc_last_mate_time[b_name] = now
	_npc_horny_until[a_name] = now - 0.1
	_npc_horny_until[b_name] = now - 0.1
	_npc_next_horny_time[a_name] = now + maxf(mating_cooldown_seconds, _next_horny_interval_for(a_name))
	_npc_next_horny_time[b_name] = now + maxf(mating_cooldown_seconds, _next_horny_interval_for(b_name))
	_append_recent_event(a_name, "mated with %s" % b_name)
	_append_recent_event(b_name, "mated with %s" % a_name)

	var mixed_physical: Dictionary = _mix_physical_genes(_npc_physical_genes.get(a_name, {}), _npc_physical_genes.get(b_name, {}))
	var mixed_llm: Dictionary = _mix_llm_genes(_npc_llm_genes.get(a_name, {}), _npc_llm_genes.get(b_name, {}))
	# Mix neural network genes into LLM genes dictionary
	var parent_a_genes = _npc_llm_genes.get(a_name, {})
	var parent_b_genes = _npc_llm_genes.get(b_name, {})
	_mix_neural_network_genes(mixed_llm, parent_a_genes, parent_b_genes, gene_mutation_chance, gene_mutation_strength)
	var midpoint: Vector2 = (parent_a.position + parent_b.position) * 0.5
	var child_spawn_position: Vector2 = midpoint if is_world_position_walkable(midpoint) else _random_walkable_world_point()
	_start_baby_name_conversation_and_spawn(a_name, b_name, child_spawn_position, mixed_physical, mixed_llm)

func _start_baby_name_conversation_and_spawn(parent_a_name: String, parent_b_name: String, child_spawn_position: Vector2, mixed_physical: Dictionary, mixed_llm: Dictionary) -> void:
	var job_id: int = _next_baby_name_job_id
	_next_baby_name_job_id += 1
	_pending_baby_name_jobs[job_id] = {
		"parent_a": parent_a_name,
		"parent_b": parent_b_name,
		"spawn_position": child_spawn_position,
		"mixed_physical": mixed_physical.duplicate(true),
		"mixed_llm": mixed_llm.duplicate(true),
		"proposed_first": "",
		"proposed_last": "",
		"retry_count": 0,
		"defer_pause_until_response": false
	}
	_baby_name_job_queue.append(job_id)
	_pump_baby_name_jobs()

func _pump_baby_name_jobs() -> void:
	if _active_baby_name_job_id >= 0 and _pending_baby_name_jobs.has(_active_baby_name_job_id):
		return
	while not _baby_name_job_queue.is_empty():
		var next_job_id: int = int(_baby_name_job_queue.pop_front())
		if not _pending_baby_name_jobs.has(next_job_id):
			continue
		_active_baby_name_job_id = next_job_id
		_start_active_baby_name_job(next_job_id)
		return
	_active_baby_name_job_id = -1

func _start_active_baby_name_job(job_id: int) -> void:
	if not _pending_baby_name_jobs.has(job_id):
		_pump_baby_name_jobs()
		return
	var job: Dictionary = _pending_baby_name_jobs[job_id]
	var parent_a_name: String = str(job.get("parent_a", ""))
	var parent_b_name: String = str(job.get("parent_b", ""))
	var defer_pause: bool = baby_name_defer_pause_until_response and conversation_lock_enabled and _prefetched_baby_names.is_empty()
	job["defer_pause_until_response"] = defer_pause
	# Enable full conversation pre-generation mode when defer_pause is enabled
	if defer_pause:
		job["baby_name_full_generation_mode"] = true
		job["generated_turns"] = []
	_pending_baby_name_jobs[job_id] = job

	var kickoff: String = "We need a first and last name for our baby."
	if conversation_lock_enabled and not defer_pause:
		_start_locked_conversation(parent_a_name, parent_b_name, kickoff, "baby_naming")
		if _has_active_locked_conversation():
			_active_locked_conversation["baby_job_id"] = job_id
			_active_locked_conversation["awaiting_baby_name_llm"] = false
			_active_locked_conversation["turn_index"] = 0
			_active_locked_conversation["max_turns"] = 2
			_active_locked_conversation["baby_single_llm_turn"] = true
			_active_locked_conversation["turn_timer"] = 0.08
	elif not defer_pause:
		_append_conversation_message(parent_a_name, parent_b_name, kickoff)
		var parent_a: VillagerAgent = _get_villager_by_name(parent_a_name)
		var parent_b: VillagerAgent = _get_villager_by_name(parent_b_name)
		if parent_a != null:
			parent_a.show_chat_bubble(kickoff)
		if parent_b != null:
			if parent_a != null:
				parent_a.fade_chat_bubble()
			parent_b.show_chat_bubble("Let's decide together.")

	if not _llm_backend_ready():
		_finalize_baby_naming_with_fallback(job_id, parent_a_name, parent_b_name, "llm_offline")
		return

	if not _prefetched_baby_names.is_empty():
		var prefetched: Dictionary = _prefetched_baby_names.pop_front()
		var speech_text: String = str(prefetched.get("speech_text", "")).strip_edges()
		var first_name: String = _sanitize_name_part(str(prefetched.get("first_name", "")))
		var last_name: String = _sanitize_name_part(str(prefetched.get("last_name", "")))
		if first_name.is_empty():
			var fallback_name: Dictionary = _generate_fallback_baby_name(parent_a_name, parent_b_name)
			first_name = str(fallback_name.get("first_name", "Nova"))
		if last_name.is_empty():
			last_name = _derive_baby_last_name(parent_a_name, parent_b_name)
			if last_name.is_empty():
				var fallback_last: Dictionary = _generate_fallback_baby_name(parent_a_name, parent_b_name)
				last_name = str(fallback_last.get("last_name", "Vale"))
		var line_a: String = speech_text if not speech_text.is_empty() else _compose_baby_name_reply_line(parent_a_name, parent_b_name, first_name, last_name, false)
		_append_conversation_message(parent_a_name, parent_b_name, line_a)
		var parent_a: VillagerAgent = _get_villager_by_name(parent_a_name)
		if parent_a != null:
			parent_a.show_chat_bubble(line_a)
		_spawn_baby_with_name(job_id, first_name, last_name)
		return

	# If in full generation mode, start generating turns without locking yet
	if defer_pause and bool(job.get("baby_name_full_generation_mode", false)):
		_start_baby_name_llm_turn(job_id, parent_a_name, parent_b_name, kickoff, false)
		return

	if conversation_lock_enabled and _has_active_locked_conversation():
		_active_locked_conversation["awaiting_baby_name_llm"] = true
		_active_locked_conversation["turn_timer"] = 0.0
		_start_baby_name_llm_turn(job_id, parent_a_name, parent_b_name, kickoff, false)
		return

	if not conversation_lock_enabled or not _has_active_locked_conversation():
		_start_baby_name_llm_turn(job_id, parent_a_name, parent_b_name, "", false)

func _start_baby_name_llm_turn(job_id: int, speaker_name: String, listener_name: String, prior_line: String, is_final_turn: bool) -> void:
	if _active_baby_name_job_id >= 0 and _active_baby_name_job_id != job_id:
		return
	if not _pending_baby_name_jobs.has(job_id):
		return
	# Cancel any in-flight NPC LLM requests so Ollama only handles one request at a time.
	for _npc_req_name in _llm_active_requests.keys():
		var _npc_req_variant: Variant = _llm_active_requests.get(_npc_req_name, null)
		if _npc_req_variant is HTTPRequest and is_instance_valid(_npc_req_variant):
			(_npc_req_variant as HTTPRequest).cancel_request()
	_llm_active_requests.clear()
	var job: Dictionary = _pending_baby_name_jobs[job_id]
	var system_prompt: String = "Return ONLY JSON with keys speech_text, first_name, and last_name. speech_text must be one natural sentence of dialogue where the speaker proposes or agrees on a baby name to the listener. Use short human names, title case, no symbols, no markdown, no extra keys."
	var user_payload: Dictionary = {
		"speaker": speaker_name,
		"listener": listener_name,
		"turn": "final" if is_final_turn else "propose",
		"prior_line": prior_line,
		"current_candidate": {
			"first_name": str(job.get("proposed_first", "")),
			"last_name": str(job.get("proposed_last", ""))
		}
	}
	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var listener: VillagerAgent = _get_villager_by_name(listener_name)
	var in_full_generation_mode: bool = bool(job.get("baby_name_full_generation_mode", false))
	if listener != null and _has_active_locked_conversation() and not in_full_generation_mode:
		listener.fade_chat_bubble()
	if speaker != null and baby_name_show_thinking_bubble and not in_full_generation_mode:
		speaker.show_thinking_bubble(true)
	var request := HTTPRequest.new()
	request.timeout = maxf(_get_llm_request_timeout_seconds(), 45.0)
	add_child(request)
	request.request_completed.connect(_on_baby_name_llm_completed.bind(job_id, speaker_name, listener_name, request, is_final_turn), CONNECT_ONE_SHOT)
	var request_body: Dictionary = _build_baby_name_request_body(system_prompt, JSON.stringify(user_payload))
	print("baby_naming request: job_id=%d speaker=%s listener=%s turn=%s" % [job_id, speaker_name, listener_name, "final" if is_final_turn else "propose"])
	var err: int = request.request(
		llm_openai_endpoint,
		_build_llm_request_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify(request_body)
	)
	if err != OK:
		if is_instance_valid(request):
			request.queue_free()
		print("baby_naming fallback: request_error err=%d" % err)
		_retry_baby_name_turn_or_fallback(job_id, speaker_name, listener_name, prior_line, is_final_turn, "request_error")

func _complete_baby_name_job(job_id: int) -> void:
	if _active_baby_name_job_id == job_id:
		_active_baby_name_job_id = -1
	while _baby_name_job_queue.has(job_id):
		_baby_name_job_queue.erase(job_id)
	_pump_baby_name_jobs()

func _retry_baby_name_turn_or_fallback(job_id: int, speaker_name: String, listener_name: String, prior_line: String, is_final_turn: bool, reason: String) -> void:
	if not _pending_baby_name_jobs.has(job_id):
		return
	var job: Dictionary = _pending_baby_name_jobs[job_id]
	var retry_count: int = int(job.get("retry_count", 0))
	if retry_count < 1:
		job["retry_count"] = retry_count + 1
		_pending_baby_name_jobs[job_id] = job
		print("baby_naming retry: job_id=%d speaker=%s reason=%s" % [job_id, speaker_name, reason])
		_start_baby_name_llm_turn(job_id, speaker_name, listener_name, prior_line, is_final_turn)
		return
	_finalize_baby_naming_with_fallback(job_id, speaker_name, listener_name, reason)

func _build_baby_name_request_body(system_prompt: String, user_prompt: String) -> Dictionary:
	if _get_llm_provider() == "ollama":
		return {
			"model": llm_model,
			"format": "json",
			"stream": false,
			"keep_alive": "10m",
			"system": system_prompt,
			"prompt": user_prompt,
			"options": {
				"temperature": maxf(0.35, baby_name_llm_temperature),
				"num_predict": maxi(8, baby_name_llm_num_predict)
			}
		}
	return {
		"model": llm_model,
		"temperature": maxf(0.35, baby_name_llm_temperature),
		"messages": [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": user_prompt}
		]
	}

func _on_baby_name_llm_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, job_id: int, speaker_name: String, listener_name: String, request: HTTPRequest, is_final_turn: bool) -> void:
	if is_instance_valid(request):
		request.queue_free()
	if not _pending_baby_name_jobs.has(job_id):
		return
	var job: Dictionary = _pending_baby_name_jobs[job_id]
	var fallback: Dictionary = _generate_fallback_baby_name(str(job.get("parent_a", "")), str(job.get("parent_b", "")))
	var prior_line: String = ""
	var recent_thread: Array = _get_recent_conversation(speaker_name, listener_name, 1)
	if not recent_thread.is_empty() and recent_thread[recent_thread.size() - 1] is Dictionary:
		prior_line = str((recent_thread[recent_thread.size() - 1] as Dictionary).get("text", ""))
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		print("baby_naming fallback: http_error result=%d response_code=%d" % [result, response_code])
		_retry_baby_name_turn_or_fallback(job_id, speaker_name, listener_name, prior_line, is_final_turn, "http_error")
		return

	var response_text: String = body.get_string_from_utf8()
	print("baby_naming response: %s" % response_text.substr(0, 200))
	var parsed: Variant = JSON.parse_string(response_text)
	var content: String = ""
	if parsed is Dictionary:
		content = _extract_llm_response_content(parsed)
	if content.is_empty():
		content = response_text
	if content.is_empty():
		print("baby_naming fallback: empty_content")
		_retry_baby_name_turn_or_fallback(job_id, speaker_name, listener_name, prior_line, is_final_turn, "empty_content")
		return

	var payload: Dictionary = _extract_baby_name_dialogue_payload(content)
	var speech_text: String = str(payload.get("speech_text", "")).strip_edges()
	var first_name: String = str(payload.get("first_name", "")).strip_edges()
	var last_name: String = str(payload.get("last_name", "")).strip_edges()
	if first_name.is_empty():
		first_name = str(job.get("proposed_first", ""))
	if last_name.is_empty():
		last_name = str(job.get("proposed_last", ""))
	if first_name.is_empty():
		first_name = str(fallback.get("first_name", ""))
	if last_name.is_empty():
		last_name = _derive_baby_last_name(str(job.get("parent_a", "")), str(job.get("parent_b", "")))
	if last_name.is_empty():
		last_name = str(fallback.get("last_name", ""))
	first_name = _sanitize_name_part(first_name)
	last_name = _sanitize_name_part(last_name)
	if first_name.is_empty():
		first_name = str(fallback.get("first_name", ""))
	if last_name.is_empty():
		last_name = str(fallback.get("last_name", ""))
	var line: String = speech_text if not speech_text.is_empty() else _compose_baby_name_reply_line(speaker_name, listener_name, first_name, last_name, bool(is_final_turn))

	job["proposed_first"] = first_name
	job["proposed_last"] = last_name
	job["retry_count"] = 0

	# Handle full generation mode: store turn without displaying, generate next turn
	var in_full_generation_mode: bool = bool(job.get("baby_name_full_generation_mode", false))
	if in_full_generation_mode:
		var generated_turns: Array = job.get("generated_turns", [])
		generated_turns.append({"speaker": speaker_name, "line": line})
		job["generated_turns"] = generated_turns
		print("baby_naming pre-generated turn %d: speaker=%s" % [generated_turns.size(), speaker_name])
		_pending_baby_name_jobs[job_id] = job

		# If we have both turns, start locked conversation with replay mode
		if generated_turns.size() >= 2:
			var parent_a_name: String = str(job.get("parent_a", ""))
			var parent_b_name: String = str(job.get("parent_b", ""))
			var kickoff: String = "We need a first and last name for our baby."
			_start_locked_conversation(parent_a_name, parent_b_name, kickoff, "baby_naming")
			if _has_active_locked_conversation():
				_active_locked_conversation["baby_job_id"] = job_id
				_active_locked_conversation["awaiting_baby_name_llm"] = false
				_active_locked_conversation["replay_pre_generated"] = true
				_active_locked_conversation["turn_index"] = 0
				_active_locked_conversation["max_turns"] = 2
				_active_locked_conversation["turn_timer"] = 2.0  # Time to show first turn
			return
		# Otherwise, generate the other parent's turn
		var other_parent: String = str(job.get("parent_b", "")) if speaker_name == str(job.get("parent_a", "")) else str(job.get("parent_a", ""))
		_start_baby_name_llm_turn(job_id, other_parent, speaker_name, line, true)
		return

	# Normal mode: show bubbles and handle conversation
	_append_conversation_message(speaker_name, listener_name, line)
	var speaker: VillagerAgent = _get_villager_by_name(speaker_name)
	var listener: VillagerAgent = _get_villager_by_name(listener_name)
	if speaker != null:
		if listener != null:
			listener.fade_chat_bubble()
		speaker.show_chat_bubble(line)

	_pending_baby_name_jobs[job_id] = job

	if bool(job.get("defer_pause_until_response", false)) and conversation_lock_enabled and not in_full_generation_mode:
		var kickoff: String = "We need a first and last name for our baby."
		_start_locked_conversation(speaker_name, listener_name, kickoff, "baby_naming")
		if _has_active_locked_conversation():
			_active_locked_conversation["baby_job_id"] = job_id
			_active_locked_conversation["awaiting_baby_name_llm"] = false
			_active_locked_conversation["turn_index"] = 1
			_active_locked_conversation["max_turns"] = 2
			_active_locked_conversation["baby_single_llm_turn"] = true
			_active_locked_conversation["turn_timer"] = 0.0

	var using_locked_baby_mode: bool = false
	if _has_active_locked_conversation() and str(_active_locked_conversation.get("mode", "")) == "baby_naming":
		if int(_active_locked_conversation.get("baby_job_id", -1)) == job_id:
			using_locked_baby_mode = true
	if using_locked_baby_mode:
		_active_locked_conversation["awaiting_baby_name_llm"] = false
		var locked_turn_index: int = int(_active_locked_conversation.get("turn_index", 0)) + 1
		_active_locked_conversation["turn_index"] = locked_turn_index
		if bool(_active_locked_conversation.get("baby_single_llm_turn", false)):
			_spawn_baby_with_name(job_id, first_name, last_name)
			return
		if is_final_turn or locked_turn_index >= int(_active_locked_conversation.get("max_turns", 2)):
			_spawn_baby_with_name(job_id, first_name, last_name)
			return
		_active_locked_conversation["current_speaker"] = listener_name
		_active_locked_conversation["current_listener"] = speaker_name
		_active_locked_conversation["turn_timer"] = 0.05
		return

	if is_final_turn:
		_spawn_baby_with_name(job_id, first_name, last_name)
		return
	_start_baby_name_llm_turn(job_id, listener_name, speaker_name, line, true)

func _derive_baby_last_name(parent_a_name: String, parent_b_name: String) -> String:
	var options: Array[String] = []
	var parts_a: PackedStringArray = parent_a_name.split(" ", false)
	if parts_a.size() > 1:
		options.append(_sanitize_name_part(parts_a[parts_a.size() - 1]))
	var parts_b: PackedStringArray = parent_b_name.split(" ", false)
	if parts_b.size() > 1:
		options.append(_sanitize_name_part(parts_b[parts_b.size() - 1]))
	for opt in options:
		if not str(opt).is_empty():
			return str(opt)
	return ""

func _extract_baby_name_dialogue_payload(content: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		var trimmed: String = content.strip_edges()
		var start_idx: int = trimmed.find("{")
		var end_idx: int = trimmed.rfind("}")
		if start_idx >= 0 and end_idx > start_idx:
			var candidate_json: String = trimmed.substr(start_idx, end_idx - start_idx + 1)
			parsed = JSON.parse_string(candidate_json)
	if not (parsed is Dictionary):
		var speech_guess: String = _extract_json_string_field(content, "speech_text")
		var first_guess: String = _extract_json_string_field(content, "first_name")
		var last_guess: String = _extract_json_string_field(content, "last_name")
		return {
			"speech_text": speech_guess.substr(0, 120),
			"first_name": first_guess.substr(0, 24),
			"last_name": last_guess.substr(0, 24)
		}
	var result: Dictionary = parsed
	return {
		"speech_text": str(result.get("speech_text", "")).substr(0, 120),
		"first_name": str(result.get("first_name", "")).substr(0, 24),
		"last_name": str(result.get("last_name", "")).substr(0, 24)
	}

func _extract_json_string_field(content: String, key: String) -> String:
	if key.strip_edges().is_empty() or content.strip_edges().is_empty():
		return ""
	var regex := RegEx.new()
	var pattern: String = "\\\"%s\\\"\\s*:\\s*\\\"([^\\\"\\n\\r}]*)" % key
	if regex.compile(pattern) != OK:
		return ""
	var match: RegExMatch = regex.search(content)
	if match == null:
		return ""
	return str(match.get_string(1)).strip_edges()

func _compose_baby_name_reply_line(speaker_name: String, listener_name: String, first_name: String, last_name: String, is_final_turn: bool) -> String:
	var full_name: String = (first_name + " " + last_name).strip_edges()
	var line_pool: Array[String] = [
		"I think %s fits perfectly." % full_name,
		"%s feels right to me." % full_name,
		"I like %s a lot." % full_name,
		"%s sounds lovely." % full_name
	]
	if is_final_turn:
		line_pool.append("Let's go with %s." % full_name)
	if speaker_name.to_lower().find("m") >= 0 or listener_name.to_lower().find("m") >= 0:
		line_pool.append("We should name the baby %s." % full_name)
	return line_pool[randi() % line_pool.size()]

func _finalize_baby_naming_with_fallback(job_id: int, speaker_name: String, listener_name: String, reason: String = "fallback") -> void:
	if not _pending_baby_name_jobs.has(job_id):
		return
	var job: Dictionary = _pending_baby_name_jobs[job_id]
	var parent_a_name: String = str(job.get("parent_a", ""))
	var parent_b_name: String = str(job.get("parent_b", ""))
	var fallback: Dictionary = _generate_fallback_baby_name(parent_a_name, parent_b_name)
	var first_name: String = _sanitize_name_part(str(fallback.get("first_name", "Nova")))
	var last_name: String = _sanitize_name_part(str(fallback.get("last_name", "Vale")))
	if first_name.is_empty():
		first_name = "Nova"
	if last_name.is_empty():
		last_name = "Vale"
	var line_a: String = "I am not sure yet, but let's pick %s %s." % [first_name, last_name]
	_append_conversation_message(parent_a_name, parent_b_name, line_a)
	var a_npc: VillagerAgent = _get_villager_by_name(parent_a_name)
	var b_npc: VillagerAgent = _get_villager_by_name(parent_b_name)
	if a_npc != null:
		a_npc.show_chat_bubble(line_a)
	if b_npc != null:
		b_npc.fade_chat_bubble()
	_append_recent_event(parent_a_name, "baby naming used fallback (%s)" % reason)
	_append_recent_event(parent_b_name, "baby naming used fallback (%s)" % reason)
	_spawn_baby_with_name(job_id, first_name, last_name)

func _sanitize_name_part(raw_part: String) -> String:
	var clean: String = ""
	for i in raw_part.length():
		var ch: String = raw_part.substr(i, 1)
		if (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z") or ch == "-" or ch == "'":
			clean += ch
	clean = clean.strip_edges()
	if clean.is_empty():
		return ""
	if clean.length() < 2:
		return ""
	if clean.length() > 16:
		clean = clean.substr(0, 16)
	return clean.capitalize()

func _split_full_name(full_name: String) -> Dictionary:
	var parts: PackedStringArray = full_name.strip_edges().split(" ", false)
	if parts.is_empty():
		return {"first_name": "", "last_name": ""}
	if parts.size() == 1:
		return {"first_name": parts[0], "last_name": ""}
	return {"first_name": parts[0], "last_name": parts[parts.size() - 1]}

func _generate_fallback_baby_name(parent_a_name: String, parent_b_name: String) -> Dictionary:
	var a_split: Dictionary = _split_full_name(parent_a_name)
	var b_split: Dictionary = _split_full_name(parent_b_name)
	var first_pool: Array[String] = []
	var last_pool: Array[String] = []
	var a_first: String = _sanitize_name_part(str(a_split.get("first_name", "")))
	var b_first: String = _sanitize_name_part(str(b_split.get("first_name", "")))
	var a_last: String = _sanitize_name_part(str(a_split.get("last_name", "")))
	var b_last: String = _sanitize_name_part(str(b_split.get("last_name", "")))
	if not a_first.is_empty():
		first_pool.append(a_first)
	if not b_first.is_empty():
		first_pool.append(b_first)
	if not a_last.is_empty():
		last_pool.append(a_last)
	if not b_last.is_empty():
		last_pool.append(b_last)
	var first_name: String = ""
	var last_name: String = ""
	if not first_pool.is_empty() and randf() < 0.4:
		first_name = first_pool[randi() % first_pool.size()]
	if first_name.is_empty():
		first_name = _sanitize_name_part(_random_real_direction_word())
	if not last_pool.is_empty() and randf() < 0.7:
		last_name = last_pool[randi() % last_pool.size()]
	if last_name.is_empty():
		last_name = _sanitize_name_part(_random_real_direction_word())
	if first_name.is_empty():
		first_name = "Nova"
	if last_name.is_empty():
		last_name = "Vale"
	return {"first_name": first_name, "last_name": last_name}

func _remember_baby_name(full_name: String) -> void:
	var clean: String = full_name.strip_edges().to_lower()
	if clean.is_empty():
		return
	_recent_baby_names.append(clean)
	var cap: int = maxi(4, baby_name_repeat_avoid_count)
	if _recent_baby_names.size() > cap:
		_recent_baby_names = _recent_baby_names.slice(_recent_baby_names.size() - cap, _recent_baby_names.size())

func _get_recent_baby_name_blacklist(limit: int) -> Array[String]:
	if limit <= 0 or _recent_baby_names.is_empty():
		return []
	var start: int = maxi(0, _recent_baby_names.size() - limit)
	var source: Array[String] = _recent_baby_names.slice(start, _recent_baby_names.size())
	var result: Array[String] = []
	for name in source:
		if not result.has(name):
			result.append(name)
	return result

func _is_name_currently_taken(full_name: String) -> bool:
	var clean: String = full_name.strip_edges().to_lower()
	if clean.is_empty():
		return false
	for villager in _villagers:
		if villager.villager_name.strip_edges().to_lower() == clean:
			return true
	return false

func _coerce_non_repeating_baby_name(first_name: String, last_name: String, parent_a_name: String, parent_b_name: String) -> Dictionary:
	var first: String = _sanitize_name_part(first_name)
	var last: String = _sanitize_name_part(last_name)
	var fallback: Dictionary = _generate_fallback_baby_name(parent_a_name, parent_b_name)
	if first.is_empty():
		first = str(fallback.get("first_name", "Nova"))
	if last.is_empty():
		last = str(fallback.get("last_name", "Vale"))

	for i in range(12):
		var full: String = (first + " " + last).strip_edges()
		var recently_used: bool = _get_recent_baby_name_blacklist(baby_name_repeat_avoid_count).has(full.to_lower())
		if not recently_used and not _is_name_currently_taken(full):
			return {"first_name": first, "last_name": last}
		if i % 3 == 0:
			first = _sanitize_name_part(_random_real_direction_word())
		elif i % 3 == 1:
			last = _sanitize_name_part(_random_real_direction_word())
		else:
			var mix: Dictionary = _generate_fallback_baby_name(parent_a_name, parent_b_name)
			first = _sanitize_name_part(str(mix.get("first_name", "Nova")))
			last = _sanitize_name_part(str(mix.get("last_name", "Vale")))

	return {"first_name": first, "last_name": last}

func _spawn_baby_with_name(job_id: int, first_name: String, last_name: String) -> void:
	if not _pending_baby_name_jobs.has(job_id):
		_complete_baby_name_job(job_id)
		return
	var job: Dictionary = _pending_baby_name_jobs[job_id]
	var parent_a_name: String = str(job.get("parent_a", ""))
	var parent_b_name: String = str(job.get("parent_b", ""))
	var final_parts: Dictionary = _coerce_non_repeating_baby_name(first_name, last_name, parent_a_name, parent_b_name)
	var safe_first: String = str(final_parts.get("first_name", "Nova"))
	var safe_last: String = str(final_parts.get("last_name", "Vale"))
	var full_name: String = _make_unique_name((safe_first + " " + safe_last).strip_edges())
	if _has_active_locked_conversation() and _is_name_in_active_conversation(parent_a_name) and _is_name_in_active_conversation(parent_b_name):
		_end_locked_conversation("baby_named")
	_npc_physical_genes[full_name] = (job.get("mixed_physical", {}) as Dictionary).duplicate(true)
	_npc_llm_genes[full_name] = (job.get("mixed_llm", {}) as Dictionary).duplicate(true)
	spawn_villager(full_name)
	var child: VillagerAgent = _get_villager_by_name(full_name)
	if child != null:
		child.position = job.get("spawn_position", _random_walkable_world_point())
	_remember_baby_name(full_name)
	_append_recent_event(parent_a_name, "named baby %s with %s" % [full_name, parent_b_name])
	_append_recent_event(parent_b_name, "named baby %s with %s" % [full_name, parent_a_name])
	_append_recent_event(full_name, "born to %s and %s" % [parent_a_name, parent_b_name])
	_queue_event_notification("Birth: %s was born to %s and %s" % [full_name, parent_a_name, parent_b_name])
	_pending_baby_name_jobs.erase(job_id)
	_complete_baby_name_job(job_id)

func record_long_term_memory(villager_name: String, memory_type: String, entry: String) -> void:
	if entry.strip_edges().is_empty():
		return
	_ensure_npc_profile(villager_name)
	var context: Dictionary = _npc_llm_contexts[villager_name]
	var allowed_types: Array = context.get("allowed_memory_types", ["status"])
	if not allowed_types.has(memory_type):
		return
	var memories: Array = context.get("long_term_memories", [])
	memories.append({
		"t": Time.get_unix_time_from_system(),
		"type": memory_type,
		"text": entry.substr(0, 220)
	})
	if memories.size() > llm_long_term_memory_limit:
		memories = memories.slice(memories.size() - llm_long_term_memory_limit, memories.size())
	context["long_term_memories"] = memories
	_npc_llm_contexts[villager_name] = context

func evaluate_npc_llm_decision(villager_name: String, state: Dictionary, physical_genes: Dictionary, llm_genes: Dictionary) -> Dictionary:
	_ensure_npc_profile(villager_name)
	var enriched_state: Dictionary = state.duplicate(true)
	enriched_state["is_horny"] = _is_npc_horny(villager_name)
	var sensory: Dictionary = enriched_state.get("sensory", {})
	var current_position: Vector2 = sensory.get("position", Vector2.ZERO)
	var nearby_players_raw: Array = _get_nearby_player_summaries(villager_name, current_position, llm_player_awareness_radius)
	var nearby_players: Array = []
	for row in nearby_players_raw:
		if not (row is Dictionary):
			continue
		var row_dict: Dictionary = (row as Dictionary).duplicate(true)
		var other_name: String = str(row_dict.get("name", ""))
		row_dict["recent_conversation"] = _get_recent_conversation(villager_name, other_name, mini(6, npc_conversation_history_limit))
		nearby_players.append(row_dict)
	enriched_state["nearby_players"] = nearby_players
	var nearest_player: Dictionary = find_player_target(villager_name, current_position)
	if not nearest_player.is_empty():
		nearest_player = nearest_player.duplicate(true)
		var nearest_name: String = str(nearest_player.get("name", ""))
		nearest_player["recent_conversation"] = _get_recent_conversation(villager_name, nearest_name, npc_conversation_history_limit)
		enriched_state["nearest_player"] = nearest_player
	var nearest_water_position: Vector2 = find_nearest_water_world_position(current_position, 18)
	if is_finite(nearest_water_position.x) and is_finite(nearest_water_position.y):
		enriched_state["nearest_water_world_position"] = nearest_water_position
	_npc_pending_llm_state[villager_name] = enriched_state
	if not _npc_llm_status.has(villager_name):
		_npc_llm_status[villager_name] = "idle"

	if _llm_backend_ready():
		var now: float = float(Time.get_unix_time_from_system())
		var last_request_time: float = float(_npc_last_llm_request_time.get(villager_name, -1000000.0))
		var request_queued: bool = _llm_request_queue.has(villager_name)
		var request_active: bool = _llm_active_requests.has(villager_name)
		var backlog_size: int = _llm_request_queue.size() + _llm_active_requests.size()
		var can_enqueue: bool = backlog_size < llm_queue_hard_limit
		if backlog_size >= llm_queue_soft_limit and _npc_last_llm_decisions.has(villager_name):
			can_enqueue = false
		if not _llm_requests_paused_for_conversation and (now - last_request_time) >= llm_api_request_min_interval_seconds and can_enqueue and not request_queued and not request_active:
			_llm_request_queue.append(villager_name)
			_npc_llm_status[villager_name] = "queued"
			_log_llm(villager_name, "queued for llm request")
		elif not can_enqueue and not request_queued and not request_active:
			_npc_llm_status[villager_name] = "backlog"

		if _npc_last_llm_decisions.has(villager_name):
			var cached_decision: Dictionary = _npc_last_llm_decisions[villager_name]
			var sanitized_cached: Dictionary = _sanitize_llm_decision(cached_decision)
			if not sanitized_cached.is_empty():
				_npc_last_llm_decisions.erase(villager_name)
				if str(sanitized_cached.get("decision_source", "")).is_empty():
					sanitized_cached["decision_source"] = _get_llm_provider()
				if str(sanitized_cached.get("llm_status", "")).is_empty():
					sanitized_cached["llm_status"] = "ready"
				if llm_debug_log_to_output:
					_log_llm(villager_name, "using cached llm decision=%s" % JSON.stringify(sanitized_cached).substr(0, 220))
				return sanitized_cached

		var pending_status: String = str(_npc_llm_status.get(villager_name, "idle"))
		if pending_status == "queued" or pending_status == "requesting" or pending_status == "paused_for_conversation" or pending_status == "backlog":
			return {
				"action": "",
				"decision_source": "pending",
				"llm_status": pending_status,
				"remember": false,
				"memory_type": "status"
			}

	_log_llm(villager_name, "using heuristic fallback status=%s hunger=%.1f energy=%.1f" % [str(_npc_llm_status.get(villager_name, "idle")), float(enriched_state.get("hunger", 0.0)), float(enriched_state.get("energy", 0.0))])
	return _evaluate_npc_heuristic_decision(villager_name, enriched_state, physical_genes, llm_genes)

func _compose_conversation_opener(villager_name: String, llm_genes: Dictionary) -> String:
	var openers: Array[String] = [
		"Hey, how's your day going?",
		"What have you been up to lately?",
		"Want to chat for a bit?",
		"Fancy a quick talk?",
		"Got a moment?",
		"How are you feeling today?",
		"I was just thinking about life.",
		"You seem interesting!",
		"Care to share what's on your mind?",
		"I could use some company."
	]
	var funny: float = float(llm_genes.get("funny", 0.5))
	if randf() < funny * 0.3:
		var jokes: Array[String] = [
			"Why did the NPC cross the road? To get to the other tile!",
			"I tried to be funny once. It didn't compute.",
			"Want to hear a joke? It's about AI... get it?"
		]
		return jokes[randi() % jokes.size()]
	return openers[randi() % openers.size()]

func _evaluate_npc_heuristic_decision(villager_name: String, state: Dictionary, physical_genes: Dictionary, llm_genes: Dictionary) -> Dictionary:
	var sensory: Dictionary = state.get("sensory", {})
	var current_position: Vector2 = sensory.get("position", Vector2.ZERO)
	var hunger: float = float(state.get("hunger", 100.0))
	var energy: float = float(state.get("energy", 100.0))
	var inventory: Dictionary = state.get("inventory", {})
	var has_build_site: bool = bool(state.get("has_build_site", false))
	var has_drop_target: bool = bool(state.get("has_drop_target", false))
	var has_chop_target: bool = bool(state.get("has_chop_target", false))
	var has_home_target: bool = bool(state.get("has_home_target", false))
	var nearest_water_variant: Variant = state.get("nearest_water_world_position", null)
	var nearest_water_distance: float = INF
	if nearest_water_variant is Vector2:
		nearest_water_distance = current_position.distance_to(nearest_water_variant)
	var campfire_unlit_cell: Vector2i = _find_nearest_campfire_cell(current_position, false, true)
	var campfire_lit_cell: Vector2i = _find_nearest_campfire_cell(current_position, true, false)
	var has_unlit_campfire: bool = campfire_unlit_cell != Vector2i(-9999, -9999)
	var has_lit_campfire: bool = campfire_lit_cell != Vector2i(-9999, -9999)
	var nearest_lit_campfire_dist: float = current_position.distance_to(_campfire_world_position(campfire_lit_cell)) if has_lit_campfire else INF

	var compassion: float = clampf(float(llm_genes.get("compassion", 0.5)), 0.0, 1.0)
	var diligence: float = clampf(float(llm_genes.get("diligence", 0.5)), 0.0, 1.0)
	var selfish: float = clampf(float(llm_genes.get("selfish", 0.5)), 0.0, 1.0)
	var talkative: float = clampf(float(llm_genes.get("talkative", 0.5)), 0.0, 1.0)
	var baseline_interval: float = clampf(float(physical_genes.get("llm_decision_interval_seconds", llm_max_decision_interval_seconds)), llm_min_decision_interval_seconds, llm_max_decision_interval_seconds)

	var decision: Dictionary = {
		"preferred_target": "wander",
		"action": "move_random",
		"goal_text": str(llm_genes.get("primary_goal", "explore")),
		"notes": "interval=%.2f" % baseline_interval,
		"decision_source": "heuristic",
		"llm_status": str(_npc_llm_status.get(villager_name, "idle")),
		"remember": false,
		"memory_type": "status"
	}

	if energy < (22.0 + selfish * 16.0):
		decision["preferred_target"] = "home"
		decision["action"] = "go_home"
		decision["memory_entry"] = "I felt exhausted and returned toward shelter."
		_append_recent_event(villager_name, "low_energy")
		return decision

	var sun: float = _sun_intensity()
	var wood_count: int = int(inventory.get("wood", 0))
	if sun < 0.30 and hunger > 55.0 and energy > 26.0:
		if has_unlit_campfire and randf() < clampf(0.18 + compassion * 0.24 + diligence * 0.20, 0.08, 0.62):
			decision["preferred_target"] = "campfire"
			decision["action"] = "light_campfire"
			decision["memory_entry"] = "Night was setting in, so I decided to light a campfire."
			_append_recent_event(villager_name, "light_campfire")
			return decision
		if (not has_lit_campfire or nearest_lit_campfire_dist > campfire_warmth_radius * 1.35) and wood_count >= campfire_build_wood_cost and randf() < clampf(0.12 + diligence * 0.28 + compassion * 0.08, 0.06, 0.52):
			decision["preferred_target"] = "campfire"
			decision["action"] = "build_campfire"
			decision["memory_entry"] = "I built a campfire to keep this area warm and bright."
			_append_recent_event(villager_name, "build_campfire")
			return decision

	if sun > 0.78 and has_lit_campfire and randf() < clampf(0.05 + selfish * 0.08, 0.03, 0.22):
		decision["preferred_target"] = "campfire"
		decision["action"] = "extinguish_campfire"
		decision["memory_entry"] = "Daylight returned, so I put the fire out."
		_append_recent_event(villager_name, "extinguish_campfire")
		return decision

	if has_unlit_campfire and wood_count <= 0 and randf() < 0.04:
		decision["preferred_target"] = "campfire"
		decision["action"] = "destroy_campfire"
		decision["memory_entry"] = "I tore down an old campfire to reclaim materials."
		_append_recent_event(villager_name, "destroy_campfire")
		return decision

	var heal_threshold: float = clampf(52.0 + compassion * 24.0, 45.0, 84.0)
	var injured_target: Dictionary = find_injured_player_target(villager_name, current_position, "", false, heal_threshold)
	if not injured_target.is_empty() and hunger > 70.0 and energy > 34.0 and compassion > 0.34 and randf() < clampf(0.12 + compassion * 0.34 - selfish * 0.08, 0.06, 0.38):
		decision["preferred_target"] = "player"
		decision["action"] = "heal_nearby_player"
		decision["target_player_name"] = str(injured_target.get("name", ""))
		decision["memory_entry"] = "I noticed someone nearby was hurt and went to help them."
		_append_recent_event(villager_name, "seek_heal")
		return decision

	var social_chance_primary: float = clampf(0.16 + talkative * 0.22 + compassion * 0.10 - selfish * 0.04, 0.08, 0.58)
	# Don't socialize when getting hungry — survival comes first.
	if energy >= 25.0 and hunger > 55.0 and randf() < social_chance_primary:
		decision["preferred_target"] = "player"
		decision["action"] = "talk_to_nearby_player"
		decision["speech_text"] = _compose_conversation_opener(villager_name, llm_genes)
		decision["memory_entry"] = "I felt social and moved closer to someone nearby."
		_append_recent_event(villager_name, "seek_social")
		return decision

	if hunger < 70.0:
		# Prefer a ground drop over fishing unless no drop exists nearby.
		var has_nearby_drop: bool = not request_drop_target(villager_name, position, "apple", false, false).is_empty()
		if has_nearby_drop:
			decision["preferred_target"] = "drop"
			decision["action"] = "collect_drop"
			decision["memory_entry"] = "I felt hunger driving me to search for food."
			_append_recent_event(villager_name, "seek_food")
			return decision
		# No drop nearby — try fishing if water is close enough.
		if is_finite(nearest_water_distance) and nearest_water_distance < 180.0 and randf() < clampf(0.22 + compassion * 0.18, 0.10, 0.45):
			decision["preferred_target"] = "water"
			decision["action"] = "fish"
			decision["world_position"] = nearest_water_variant
			decision["memory_entry"] = "I tried fishing to bring back food."
			_append_recent_event(villager_name, "seek_food")
			return decision
		decision["preferred_target"] = "drop"
		decision["action"] = "collect_drop"
		decision["memory_entry"] = "I felt hunger driving me to search for food."
		_append_recent_event(villager_name, "seek_food")
		return decision

	if has_build_site:
		decision["preferred_target"] = "build"
		decision["action"] = "build"
		decision["memory_entry"] = "I continued building our home."
		_append_recent_event(villager_name, "build_progress")
		return decision

	if int(inventory.get("wood", 0)) < 2 and (not has_chop_target or diligence > 0.4):
		decision["preferred_target"] = "tree"
		decision["action"] = "cut_tree"
		decision["memory_entry"] = "I went to gather more wood."
		_append_recent_event(villager_name, "seek_wood")
		return decision

	var social_chance_fallback: float = clampf(0.24 + talkative * 0.34 + compassion * 0.08, 0.12, 0.72)
	if randf() < social_chance_fallback:
		decision["preferred_target"] = "player"
		decision["action"] = "talk_to_nearby_player"
		decision["speech_text"] = _compose_conversation_opener(villager_name, llm_genes)
		decision["memory_entry"] = "I felt like talking and looked for someone nearby."
		_append_recent_event(villager_name, "seek_social")
		return decision

	var bravery: float = clampf(float(llm_genes.get("bravery", 0.5)), 0.0, 1.0)

	if has_home_target and randf() < clampf(0.15 + (0.5 - bravery) * 0.25, 0.05, 0.50):
		decision["preferred_target"] = "home"
		decision["action"] = "go_home"
		return decision

	decision["preferred_target"] = "wander"
	decision["action"] = "move_random"
	if randf() < clampf(0.14 + bravery * 0.20, 0.10, 0.40):
		decision["memory_entry"] = "I wandered around to learn more about this place."
	return decision

func _initialize_drop_system() -> void:
	_drop_layer = Node2D.new()
	_drop_layer.name = "DropLayer"
	_drop_layer.z_index = 2
	add_child(_drop_layer)

	_food_texture = _load_food_texture_with_fallback()
	if _food_texture != null:
		_apple_drop_texture = _make_atlas_item_texture(_food_texture, apple_drop_atlas)
		_seed_drop_texture = _make_atlas_item_texture(_food_texture, seed_drop_atlas)
	if _apple_drop_texture == null:
		_apple_drop_texture = _make_fallback_drop_texture(Color(0.90, 0.15, 0.12, 0.95))
	if _seed_drop_texture == null:
		_seed_drop_texture = _make_fallback_drop_texture(Color(0.86, 0.74, 0.30, 0.95))
	_wood_drop_texture = _make_fallback_drop_texture(Color(0.55, 0.34, 0.14, 0.95))
	_drop_shadow_texture = _make_drop_shadow_texture()

func _load_food_texture_with_fallback() -> Texture2D:
	var texture := load(foods_texture_path) as Texture2D
	if texture != null:
		return texture

	# Fallback: extract embedded PNG from Foods.pixil if foods.png is not present.
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
	var base64_data: String = src.substr(marker_index + marker.length())
	var bytes: PackedByteArray = Marshalls.base64_to_raw(base64_data)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)

func _make_atlas_item_texture(atlas_texture: Texture2D, atlas_coords: Vector2i) -> Texture2D:
	if atlas_texture == null:
		return null
	var region := Rect2(atlas_coords.x * food_item_tile_size.x, atlas_coords.y * food_item_tile_size.y, food_item_tile_size.x, food_item_tile_size.y)
	var out := AtlasTexture.new()
	out.atlas = atlas_texture
	out.region = region
	return out

func _make_fallback_drop_texture(color: Color) -> Texture2D:
	var size := Vector2i(12, 12)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(float(size.x) * 0.5, float(size.y) * 0.5)
	for y in size.y:
		for x in size.x:
			if Vector2(float(x), float(y)).distance_to(center) <= 5.0:
				image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func _make_drop_shadow_texture() -> Texture2D:
	var width: int = maxi(8, int(ceili(drop_shadow_radius * 2.0)))
	var height: int = maxi(4, int(ceili(drop_shadow_radius * 2.0 * drop_shadow_squish)))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(float(width) * 0.5, float(height) * 0.5)
	for y in height:
		for x in width:
			var dx: float = (float(x) - center.x) / maxf(0.001, drop_shadow_radius)
			var dy: float = (float(y) - center.y) / maxf(0.001, drop_shadow_radius * drop_shadow_squish)
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist <= 1.0:
				var a: float = drop_shadow_alpha * (1.0 - dist)
				image.set_pixel(x, y, Color(0, 0, 0, a))
	return ImageTexture.create_from_image(image)

func _spawn_drop(drop_type: String, world_position: Vector2, skip_radius_check: bool = false, quantity: int = 1) -> void:
	if _drop_layer == null:
		return
	if not skip_radius_check and not _is_within_npc_drop_spawn_radius(world_position):
		return
	_cull_excess_ground_drops(maxi(0, max_ground_drop_count - 1))
	var radius: float = randf_range(0.0, tree_drop_radius)
	var angle: float = randf_range(0.0, TAU)
	var radial: Vector2 = Vector2.RIGHT.rotated(angle) * radius
	# Keep drops below the tree by forcing positive Y screen offset.
	var drop_offset := Vector2(radial.x, absf(radial.y) + tree_drop_min_y_offset)
	var drop_node := Node2D.new()
	drop_node.position = world_position + drop_offset
	drop_node.z_index = 2
	_drop_layer.add_child(drop_node)

	var shadow := Sprite2D.new()
	shadow.texture = _drop_shadow_texture
	shadow.position = Vector2(0.0, drop_shadow_floating_offset)
	shadow.centered = true
	drop_node.add_child(shadow)

	var sprite := Sprite2D.new()
	if drop_type == "apple":
		sprite.texture = _apple_drop_texture
	elif drop_type == "wood":
		sprite.texture = _wood_drop_texture
	else:
		sprite.texture = _seed_drop_texture
	sprite.centered = true
	drop_node.add_child(sprite)

	if quantity > 1:
		var qty_label := Label.new()
		qty_label.text = str(quantity)
		qty_label.position = Vector2(4.0, -10.0)
		qty_label.scale = Vector2(0.45, 0.45)
		qty_label.add_theme_font_size_override("font_size", 14)
		qty_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		qty_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
		qty_label.add_theme_constant_override("outline_size", 3)
		drop_node.add_child(qty_label)

	var id: int = _next_drop_id
	_next_drop_id += 1
	_ground_drops[id] = {
		"type": drop_type,
		"quantity": maxi(1, quantity),
		"position": drop_node.position,
		"node": drop_node,
		"item_sprite": sprite,
		"shadow_sprite": shadow,
		"float_phase": randf_range(0.0, TAU),
		"velocity": Vector2.ZERO,
		"mass": seed_mass,
		"created_at": Time.get_unix_time_from_system()
	}
	if drop_type == "apple":
		_ground_drops[id]["seed_timer"] = randf_range(apple_decompose_min_seconds, apple_decompose_max_seconds)

func _is_within_npc_drop_spawn_radius(world_position: Vector2) -> bool:
	var active: Array[VillagerAgent] = _get_active_villagers()
	if active.is_empty():
		return false
	var max_dist_sq: float = npc_drop_spawn_radius * npc_drop_spawn_radius
	for villager in active:
		if villager._is_dead:
			continue
		if villager.position.distance_squared_to(world_position) <= max_dist_sq:
			return true
	return false

func request_drop_target(villager_name: String, from_world_pos: Vector2, preferred_type: String = "", allow_swimming: bool = false, reserve_target: bool = true) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var max_direct_sq: float = drop_target_max_direct_distance * drop_target_max_direct_distance
	for id in _ground_drops.keys():
		if _reserved_drop_ids.has(id):
			continue
		var data: Dictionary = _ground_drops[id]
		if preferred_type != "" and data.get("type", "") != preferred_type:
			continue
		var pos: Vector2 = data.get("position", Vector2.ZERO)
		var direct_sq: float = from_world_pos.distance_squared_to(pos)
		if direct_sq > max_direct_sq:
			continue
		candidates.append({"id": int(id), "position": pos, "direct_sq": direct_sq})

	if candidates.is_empty() and preferred_type != "":
		# Fallback: if filtered type is too far, try any type so villagers do not stall.
		return request_drop_target(villager_name, from_world_pos, "", allow_swimming, reserve_target)
	if candidates.is_empty():
		return {}

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("direct_sq", INF)) < float(b.get("direct_sq", INF))
	)

	var shortlist_count: int = mini(candidates.size(), maxi(1, drop_path_candidate_limit))
	var best_id: int = -1
	var best_pos := Vector2.ZERO
	var best_path_cost: float = INF
	for i in range(shortlist_count):
		var row: Dictionary = candidates[i]
		var id: int = int(row.get("id", -1))
		if id == -1 or not _ground_drops.has(id):
			continue
		var pos: Vector2 = row.get("position", Vector2.ZERO)
		var path_cost: float = _estimate_world_path_cost(from_world_pos, pos, allow_swimming)
		if path_cost < best_path_cost:
			best_path_cost = path_cost
			best_id = id
			best_pos = pos

	if best_id == -1:
		# If no path candidate succeeded, pick nearest direct candidate to avoid expensive retries.
		var fallback_row: Dictionary = candidates[0]
		best_id = int(fallback_row.get("id", -1))
		best_pos = fallback_row.get("position", Vector2.ZERO)
	if best_id == -1 or not _ground_drops.has(best_id):
		return {}

	if reserve_target:
		_reserved_drop_ids[best_id] = villager_name
	return {"id": best_id, "world_position": best_pos, "type": _ground_drops[best_id].get("type", "")}

func pickup_reserved_drop(villager_name: String, drop_id: int) -> Dictionary:
	if _reserved_drop_ids.get(drop_id, "") != villager_name:
		return {}
	if not _ground_drops.has(drop_id):
		_reserved_drop_ids.erase(drop_id)
		return {}
	var data: Dictionary = _ground_drops[drop_id]
	_remove_ground_drop(drop_id)
	var item_type: String = data.get("type", "")
	var qty: int = maxi(1, int(data.get("quantity", 1)))
	if item_type == "apple":
		return {"apple": qty}
	if item_type == "seed":
		return {"seed": qty}
	if item_type == "wood":
		return {"wood": qty}
	if item_type == "prickly_pear":
		return {"prickly_pear": qty}
	if item_type == "cactus_bottle":
		return {"cactus_bottle": 1}
	return {}

func release_drop_target(villager_name: String, drop_id: int) -> void:
	if _reserved_drop_ids.get(drop_id, "") == villager_name:
		_reserved_drop_ids.erase(drop_id)

func _remove_ground_drop(drop_id: int) -> void:
	if not _ground_drops.has(drop_id):
		_reserved_drop_ids.erase(drop_id)
		return
	var data: Dictionary = _ground_drops[drop_id]
	var node: Node = data.get("node", null)
	if node != null and is_instance_valid(node):
		node.queue_free()
	_reserved_drop_ids.erase(drop_id)
	_ground_drops.erase(drop_id)

func _cull_excess_ground_drops(keep_limit: int) -> void:
	if keep_limit < 0:
		keep_limit = 0
	if _ground_drops.size() <= keep_limit:
		return
	var removable: Array[Dictionary] = []
	for id_variant in _ground_drops.keys():
		var id: int = int(id_variant)
		var data: Dictionary = _ground_drops[id]
		var type: String = str(data.get("type", ""))
		var created_at: float = float(data.get("created_at", 0.0))
		var score: float = created_at
		# Prefer culling seeds first because they are numerous and cheaper to regenerate than apples.
		if type == "seed":
			score -= 1000000.0
		removable.append({"id": id, "score": score})
	removable.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) < float(b.get("score", 0.0))
	)
	var to_remove: int = mini(removable.size(), maxi(1, _ground_drops.size() - keep_limit))
	to_remove = mini(to_remove, maxi(1, drop_cull_batch_size))
	for i in range(to_remove):
		_remove_ground_drop(int(removable[i].get("id", -1)))

func _update_ground_drop_decay(delta: float) -> void:
	if _ground_drops.is_empty():
		return
	_cull_excess_ground_drops(max_ground_drop_count)
	for id in _ground_drops.keys().duplicate():
		var data: Dictionary = _ground_drops[id]
		var drop_type: String = data.get("type", "")

		# Wind drift affects seeds only; apples are intentionally unaffected (too heavy).
		if drop_type == "seed" and wind_current_enabled:
			var logical_pos: Vector2 = data.get("position", Vector2.ZERO) as Vector2
			var in_water: bool = _is_water_world_position(logical_pos)
			var wind: Vector2 = _sample_wind_current(logical_pos)
			var mass: float = maxf(0.1, float(data.get("mass", seed_mass)))
			var velocity: Vector2 = data.get("velocity", Vector2.ZERO) as Vector2
			var force_scale: float = 1.0 if in_water else 0.65
			var wind_force: Vector2 = wind * seed_wind_speed * force_scale
			var static_threshold: float = seed_water_static_threshold if in_water else seed_ground_static_threshold
			if wind_force.length() < static_threshold:
				wind_force = Vector2.ZERO
			var acceleration: Vector2 = wind_force / mass
			velocity += acceleration * delta
			var damping: float = seed_water_damping if in_water else seed_ground_damping
			velocity *= exp(-damping * delta)
			if velocity.length() > seed_max_speed:
				velocity = velocity.normalized() * seed_max_speed
			if not in_water and velocity.length() < 2.0 and wind_force.length() <= seed_ground_static_threshold:
				velocity = Vector2.ZERO

			var next_pos: Vector2 = logical_pos + velocity * delta
			if in_water and not _is_water_world_position(next_pos):
				next_pos = logical_pos
				velocity = velocity * 0.35
			data["position"] = next_pos
			data["velocity"] = velocity
			var float_phase: float = float(data.get("float_phase", 0.0)) + delta * water_float_bob_speed
			data["float_phase"] = float_phase
			var bob_y: float = sin(float_phase + _water_wave_time * 1.7) * water_float_bob_amplitude
			var node: Node2D = data.get("node", null) as Node2D
			var shadow_sprite: Sprite2D = data.get("shadow_sprite", null) as Sprite2D
			if node != null and is_instance_valid(node):
				var lift: float = bob_y if in_water else 0.0
				node.position = next_pos + Vector2(0.0, lift)
			if shadow_sprite != null and is_instance_valid(shadow_sprite):
				if in_water:
					shadow_sprite.position.y = drop_shadow_floating_offset + absf(bob_y) * 0.35
					shadow_sprite.modulate.a = drop_shadow_floating_alpha_scale
				else:
					shadow_sprite.position.y = drop_shadow_ground_offset
					shadow_sprite.modulate.a = 1.0

		# Handle seed decay and water planting
		if drop_type == "seed":
			var in_water: bool = _is_water_world_position(data.get("position", Vector2.ZERO))
			if in_water:
				if data.has("seed_ground_timer"):
					data.erase("seed_ground_timer")
				if not data.has("seed_water_spawn_timer"):
					data["seed_water_spawn_timer"] = randf_range(1.0, 3.0)
			else:
				if data.has("seed_water_spawn_timer"):
					data.erase("seed_water_spawn_timer")
				if not data.has("seed_ground_timer"):
					data["seed_ground_timer"] = seed_dry_ground_decay_seconds
			_ground_drops[id] = data
		
		# Dry land seed decay
		if drop_type == "seed" and data.has("seed_ground_timer"):
			var timer: float = float(data["seed_ground_timer"]) - delta
			if timer > 0.0:
				data["seed_ground_timer"] = timer
				_ground_drops[id] = data
				continue
			_remove_ground_drop(id)
			continue
		
		# Water seed planting
		if drop_type == "seed" and data.has("seed_water_spawn_timer"):
			var timer: float = float(data["seed_water_spawn_timer"]) - delta
			if timer > 0.0:
				data["seed_water_spawn_timer"] = timer
				_ground_drops[id] = data
				if _water_seed_plant_budget_remaining > 0 and randf() < seed_water_planting_chance * delta:
					_water_seed_plant_budget_remaining -= 1
					_attempt_water_seed_planting(data.get("position", Vector2.ZERO))
				continue
			data["seed_water_spawn_timer"] = randf_range(1.0, 3.0)
			_ground_drops[id] = data
			if _water_seed_plant_budget_remaining > 0:
				_water_seed_plant_budget_remaining -= 1
				_attempt_water_seed_planting(data.get("position", Vector2.ZERO))
			continue
		
		if drop_type != "apple":
			_ground_drops[id] = data
			continue
		if not data.has("seed_timer"):
			data["seed_timer"] = randf_range(apple_decompose_min_seconds, apple_decompose_max_seconds)
			_ground_drops[id] = data
			continue
		var timer: float = float(data["seed_timer"]) - delta
		if timer > 0.0:
			data["seed_timer"] = timer
			_ground_drops[id] = data
			continue

		data["type"] = "seed"
		data.erase("seed_timer")
		var item_sprite: Node = data.get("item_sprite", null)
		if item_sprite is Sprite2D:
			(item_sprite as Sprite2D).texture = _seed_drop_texture
		if not data.has("seed_ground_timer") and not data.has("seed_water_spawn_timer"):
			var in_water: bool = _is_water_world_position(data.get("position", Vector2.ZERO))
			if in_water:
				data["seed_water_spawn_timer"] = randf_range(1.0, 3.0)
			else:
				data["seed_ground_timer"] = seed_dry_ground_decay_seconds
		_ground_drops[id] = data

func _attempt_water_seed_planting(seed_world_position: Vector2) -> void:
	var layer := _find_tree_layer()
	if layer == null:
		return
	if tree_growth_stages.is_empty():
		return
	if _get_cached_mature_tree_count() > seed_auto_plant_tree_threshold + 4:
		return
	var attempts: int = 6
	for _i in attempts:
		var offset: Vector2 = Vector2(randf_range(-32.0, 32.0), randf_range(-32.0, 32.0))
		var check_point: Vector2 = seed_world_position + offset
		if not _is_water_world_position(check_point):
			continue
		var cell: Vector2i = layer.local_to_map(layer.to_local(check_point))
		if layer.get_cell_source_id(cell) != -1:
			continue
		if _reserved_tree_cells.has(cell):
			continue
		if not _is_land_tree_plant_cell(layer, cell):
			continue
		layer.set_cell(cell, tree_source_id, tree_growth_stages[tree_growth_stages.size() - 1], 0)
		_tree_growth_timers[cell] = tree_growth_step_seconds
		_tree_fruit_timers.erase(cell)
		if _shadow_overlay:
			_shadow_overlay.queue_redraw()
		break

func _get_cached_mature_tree_count() -> int:
	if _mature_tree_count_cache < 0:
		_mature_tree_count_cache = _count_mature_trees()
	return _mature_tree_count_cache

func _tree_stage_index(atlas: Vector2i) -> int:
	for i in tree_growth_stages.size():
		if tree_growth_stages[i] == atlas:
			return i
	return -1

func _is_tree_stage_atlas(atlas: Vector2i) -> bool:
	return _tree_stage_index(atlas) >= 0

func _is_tree_cell(layer: TileMapLayer, cell: Vector2i) -> bool:
	if layer == null:
		return false
	if layer.get_cell_source_id(cell) != tree_source_id:
		return false
	return _is_tree_stage_atlas(layer.get_cell_atlas_coords(cell))

func _is_tree_mature(layer: TileMapLayer, cell: Vector2i) -> bool:
	if not _is_tree_cell(layer, cell):
		return false
	if tree_growth_stages.is_empty():
		return false
	return layer.get_cell_atlas_coords(cell) == tree_growth_stages[0]

func _initialize_tree_growth_from_map() -> void:
	_tree_growth_timers.clear()
	_tree_fruit_timers.clear()
	_mature_tree_count_cache = 0
	var layer := _find_tree_layer()
	if layer == null:
		return
	for cell in layer.get_used_cells():
		if not _is_tree_cell(layer, cell):
			continue
		if not _is_tree_mature(layer, cell):
			_tree_growth_timers[cell] = tree_growth_step_seconds
		else:
			_mature_tree_count_cache += 1
			_tree_fruit_timers[cell] = randf_range(mature_tree_apple_min_seconds, mature_tree_apple_max_seconds)

func _update_tree_growth(delta: float) -> void:
	if _tree_growth_timers.is_empty():
		return
	var layer := _find_tree_layer()
	if layer == null:
		_tree_growth_timers.clear()
		_tree_fruit_timers.clear()
		return
	var dirty: bool = false
	for cell in _tree_growth_timers.keys().duplicate():
		if not _is_tree_cell(layer, cell):
			_tree_growth_timers.erase(cell)
			_tree_fruit_timers.erase(cell)
			continue
		var timer: float = float(_tree_growth_timers[cell]) - delta
		if timer > 0.0:
			_tree_growth_timers[cell] = timer
			continue

		var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
		var index: int = _tree_stage_index(atlas)
		if index <= 0:
			_tree_growth_timers.erase(cell)
			continue

		var next_atlas: Vector2i = tree_growth_stages[index - 1]
		layer.set_cell(cell, tree_source_id, next_atlas, 0)
		dirty = true
		if index - 1 <= 0:
			if _mature_tree_count_cache >= 0:
				_mature_tree_count_cache += 1
			_tree_growth_timers.erase(cell)
			_tree_fruit_timers[cell] = randf_range(mature_tree_apple_min_seconds, mature_tree_apple_max_seconds)
		else:
			_tree_growth_timers[cell] = tree_growth_step_seconds

	if dirty and _shadow_overlay:
		_shadow_overlay.queue_redraw()

func _update_tree_fruiting(delta: float) -> void:
	if _tree_fruit_timers.is_empty():
		return
	var layer := _find_tree_layer()
	if layer == null:
		_tree_fruit_timers.clear()
		return

	for cell in _tree_fruit_timers.keys().duplicate():
		if not _is_tree_mature(layer, cell):
			_tree_fruit_timers.erase(cell)
			continue
		var timer: float = float(_tree_fruit_timers[cell]) - delta
		if timer > 0.0:
			_tree_fruit_timers[cell] = timer
			continue
		if randf() <= mature_tree_apple_chance:
			_spawn_drop("apple", get_tree_world_position(cell))
		_tree_fruit_timers[cell] = randf_range(mature_tree_apple_min_seconds, mature_tree_apple_max_seconds)

func _is_land_tree_plant_cell(tree_layer: TileMapLayer, tree_cell: Vector2i) -> bool:
	if terrain == null or tree_layer == null:
		return false
	var world_position: Vector2 = tree_layer.to_global(tree_layer.map_to_local(tree_cell))
	var terrain_cell: Vector2i = terrain.local_to_map(terrain.to_local(world_position))
	if terrain.get_cell_source_id(terrain_cell) == -1:
		return false
	var terrain_atlas: Vector2i = terrain.get_cell_atlas_coords(terrain_cell)
	for land_tile in GRASS_TILES:
		if terrain_atlas == land_tile:
			return true
	return false

func _count_mature_trees() -> int:
	var layer := _find_tree_layer()
	if layer == null:
		return 0
	var count: int = 0
	for cell in layer.get_used_cells():
		if _is_tree_mature(layer, cell):
			count += 1
	return count

func try_auto_plant_seed(villager_name: String, available_seeds: int) -> int:
	if available_seeds <= 0:
		return 0
	if _get_cached_mature_tree_count() > seed_auto_plant_tree_threshold:
		return 0
	if tree_growth_stages.is_empty():
		return 0
	var layer := _find_tree_layer()
	if layer == null:
		return 0

	for _attempt in seed_auto_plant_attempts:
		var point := _random_walkable_world_point()
		var cell: Vector2i = layer.local_to_map(layer.to_local(point))
		if layer.get_cell_source_id(cell) != -1:
			continue
		if _reserved_tree_cells.has(cell):
			continue
		if not _is_land_tree_plant_cell(layer, cell):
			continue
		layer.set_cell(cell, tree_source_id, tree_growth_stages[tree_growth_stages.size() - 1], 0)
		_tree_growth_timers[cell] = tree_growth_step_seconds
		_tree_fruit_timers.erase(cell)
		if _shadow_overlay:
			_shadow_overlay.queue_redraw()
		return 1
	return 0

func _find_tree_layer() -> TileMapLayer:
	if _cached_tree_layer != null and is_instance_valid(_cached_tree_layer):
		return _cached_tree_layer
	# Try the configured path first
	var node: Node = get_node_or_null(tree_layer_path)
	if node is TileMapLayer:
		_cached_tree_layer = node as TileMapLayer
		return _cached_tree_layer
	# Fall back: scan children, find a TileMapLayer that actually has cells using tree_source_id
	for child in get_children():
		if not (child is TileMapLayer):
			continue
		var layer := child as TileMapLayer
		if layer.tile_set == null:
			continue
		# Skip obvious terrain/ground layers by name
		var lname: String = layer.name.to_lower()
		if "terrain" in lname or "ground" in lname or "grass" in lname:
			continue
		for cell in layer.get_used_cells():
			if layer.get_cell_source_id(cell) == tree_source_id:
				_cached_tree_layer = layer
				return _cached_tree_layer
	return null

func get_tree_cells() -> Array[Vector2i]:
	var layer: TileMapLayer = _find_tree_layer()
	if layer == null:
		return []
	var coords_lookup: Dictionary = {}
	var filter_by_coords: bool = not tree_atlas_coords.is_empty()
	for c in tree_atlas_coords:
		coords_lookup[c] = true
	var result: Array[Vector2i] = []
	for cell in layer.get_used_cells():
		if not _is_tree_mature(layer, cell):
			continue
		if filter_by_coords and not coords_lookup.has(layer.get_cell_atlas_coords(cell)):
			continue
		if not _reserved_tree_cells.has(cell):
			result.append(cell)
	return result

func get_tree_world_position(cell: Vector2i) -> Vector2:
	var layer: TileMapLayer = _find_tree_layer()
	if layer == null:
		return Vector2.ZERO
	# Return the bottom-center of the tile so the villager walks to the base
	var center: Vector2 = layer.to_global(layer.map_to_local(cell))
	var tile_size: Vector2 = Vector2(layer.tile_set.tile_size) if layer.tile_set else Vector2(64, 64)
	return center + Vector2(0, tile_size.y - 8.0)

func get_tree_render_z_for_position(world_position: Vector2, npc_is_inside_building: bool = false, default_z: int = 2) -> int:
	var layer: TileMapLayer = _find_tree_layer()
	if layer == null:
		return default_z

	var tile_size: Vector2 = Vector2(layer.tile_set.tile_size) if layer.tile_set else Vector2(64, 64)
	var center_cell: Vector2i = layer.local_to_map(layer.to_local(world_position))
	var nearest_midpoint_y: float = INF
	var nearest_dist: float = INF

	for y in range(-2, 3):
		for x in range(-2, 3):
			var cell: Vector2i = center_cell + Vector2i(x, y)
			if not _is_tree_cell(layer, cell):
				continue
			var tree_base: Vector2 = get_tree_world_position(cell)
			if world_position.distance_to(tree_base) > tree_depth_influence_radius:
				continue
			var midpoint_y: float = tree_base.y - tile_size.y * tree_depth_midpoint_ratio
			var d: float = absf(world_position.x - tree_base.x) + absf(world_position.y - midpoint_y) * 0.35
			if d < nearest_dist:
				nearest_dist = d
				nearest_midpoint_y = midpoint_y

	if nearest_midpoint_y == INF:
		return default_z

	var in_front: bool = world_position.y >= nearest_midpoint_y
	if npc_is_inside_building:
		in_front = not in_front
	return layer.z_index + (1 if in_front else -1)

func sample_tree_shade_factor(world_position: Vector2) -> float:
	var layer: TileMapLayer = _find_tree_layer()
	if layer == null:
		return 0.0
	var tile_size: Vector2 = Vector2(layer.tile_set.tile_size) if layer.tile_set else Vector2(64, 64)
	var center_cell: Vector2i = layer.local_to_map(layer.to_local(world_position))
	var best_shade: float = 0.0
	for y in range(-2, 3):
		for x in range(-2, 3):
			var cell: Vector2i = center_cell + Vector2i(x, y)
			if not _is_tree_cell(layer, cell):
				continue
			var tree_base: Vector2 = get_tree_world_position(cell)
			var canopy_center: Vector2 = tree_base - Vector2(0.0, tile_size.y * 0.58)
			var canopy_radius: float = maxf(14.0, tile_size.x * 0.95)
			var d: float = world_position.distance_to(canopy_center)
			if d > canopy_radius:
				continue
			var local_shade: float = clampf(1.0 - d / canopy_radius, 0.0, 1.0)
			best_shade = maxf(best_shade, local_shade)
	return best_shade

func reserve_tree(villager_name: String, cell: Vector2i) -> bool:
	if _reserved_tree_cells.has(cell):
		return false
	_reserved_tree_cells[cell] = villager_name
	return true

func chop_tree(villager_name: String, cell: Vector2i) -> int:
	if _reserved_tree_cells.get(cell, "") != villager_name:
		return 0
	var layer: TileMapLayer = _find_tree_layer()
	if layer == null:
		return 0
	if layer.get_cell_source_id(cell) == -1:
		_reserved_tree_cells.erase(cell)
		return 0
	if not _is_tree_mature(layer, cell):
		_reserved_tree_cells.erase(cell)
		return 0
	var world_position: Vector2 = get_tree_world_position(cell)
	layer.erase_cell(cell)
	if _mature_tree_count_cache >= 0:
		_mature_tree_count_cache = maxi(0, _mature_tree_count_cache - 1)
	_tree_growth_timers.erase(cell)
	_tree_fruit_timers.erase(cell)
	_reserved_tree_cells.erase(cell)
	if randf() <= apple_drop_chance:
		_spawn_drop("apple", world_position)
	if _shadow_overlay:
		_shadow_overlay.queue_redraw()
	return wood_per_tree

func release_tree(villager_name: String, cell: Vector2i) -> void:
	if _reserved_tree_cells.get(cell, "") == villager_name:
		_reserved_tree_cells.erase(cell)

func spawn_villager(display_name: String) -> void:
	var villager: VillagerAgent = VillagerAgent.new()
	add_child(villager)
	_ensure_npc_profile(display_name)
	if not _npc_index_records.has(display_name):
		_npc_index_order.append(display_name)
	_npc_index_records[display_name] = {
		"dead": false,
		"hunger": 100,
		"energy": 100,
		"health": 100
	}
	var physical_genes: Dictionary = (_npc_physical_genes.get(display_name, {}) as Dictionary).duplicate(true)
	var llm_genes: Dictionary = (_npc_llm_genes.get(display_name, {}) as Dictionary).duplicate(true)

	var spawn_point: Vector2 = _random_walkable_world_point()
	var sprite: Texture2D = VILLAGER_TEXTURES[randi() % VILLAGER_TEXTURES.size()]
	villager.setup(
		spawn_point,
		_arena_rect,
		sprite,
		display_name,
		Callable(self, "is_world_position_walkable"),
		Callable(self, "find_world_path"),
		Callable(self, "request_build_site"),
		Callable(self, "place_build_part"),
		Callable(self, "release_build_site"),
		Callable(self, "get_tree_cells"),
		Callable(self, "get_tree_world_position"),
		Callable(self, "get_tree_render_z_for_position"),
		Callable(self, "reserve_tree"),
		Callable(self, "chop_tree"),
		Callable(self, "release_tree"),
		Callable(self, "request_drop_target"),
		Callable(self, "pickup_reserved_drop"),
		Callable(self, "release_drop_target"),
		Callable(self, "try_auto_plant_seed"),
		Callable(self, "get_nearest_home"),
		Callable(self, "enter_home"),
		Callable(self, "leave_home"),
		Callable(self, "request_crafting_table_access"),
		Callable(self, "craft_stage_item"),
		Callable(self, "get_stage_wood_cost"),
		Callable(self, "find_player_target"),
		Callable(self, "speak_to_nearby_player"),
		Callable(self, "find_injured_player_target"),
		Callable(self, "heal_nearby_player"),
		in_game_debug_ui_enabled,
		Callable(self, "evaluate_npc_llm_decision"),
		Callable(self, "record_long_term_memory"),
		physical_genes,
		llm_genes,
		Callable(self, "on_villager_died"),
		Callable(self, "_is_water_world_position"),
		Callable(self, "sample_water_current_velocity"),
		Callable(self, "sample_thermal_environment"),
		Callable(self, "find_nearest_water_world_position"),
		Callable(self, "sample_tree_shade_factor"),
		Callable(self, "claim_tile"),
		Callable(self, "trade_with_nearby_player"),
		Callable(self, "is_villager_horny"),
		Callable(self, "is_villager_paused_by_conversation"),
		Callable(self, "get_cactus_water_bottle"),
		Callable(self, "manage_campfire")
	)
	_villagers.append(villager)

func on_villager_died(villager_name: String, death_reason: String = "unknown") -> void:
	if _is_name_in_active_conversation(villager_name):
		_end_locked_conversation("death")
	leave_home(villager_name)
	_release_home_ownership(villager_name)
	_append_recent_event(villager_name, "died")
	var clean_reason: String = death_reason.strip_edges()
	if clean_reason.is_empty():
		clean_reason = "unknown"
	var death_timestamp: float = Time.get_unix_time_from_system()
	var villager: VillagerAgent = _get_villager_by_name(villager_name)
	# Spawn inventory as ground drops so other NPCs can pick them up.
	if villager != null:
		var death_pos: Vector2 = villager.position
		for item_type in villager.inventory:
			var count: int = int(villager.inventory[item_type])
			if count > 0:
				_spawn_drop(str(item_type), death_pos, true, count)
	var h: int = int(villager.hunger) if villager != null else int((_npc_index_records.get(villager_name, {}) as Dictionary).get("hunger", 0))
	var e: int = int(villager.energy) if villager != null else int((_npc_index_records.get(villager_name, {}) as Dictionary).get("energy", 0))
	var hp: int = int(villager.health) if villager != null else int((_npc_index_records.get(villager_name, {}) as Dictionary).get("health", 0))
	if not _npc_index_records.has(villager_name):
		_npc_index_order.append(villager_name)
	_npc_index_records[villager_name] = {
		"dead": true,
		"hunger": h,
		"energy": e,
		"health": hp,
		"hydration": int(villager.hydration) if villager != null else 0,
		"body_temp_c": villager.body_temperature_c if villager != null else 0.0,
		"ambient_temp_c": villager.last_ambient_temperature_c if villager != null else 0.0,
		"humidity": villager.last_humidity if villager != null else 0.0,
		"pos_x": villager.position.x if villager != null else 0.0,
		"pos_y": villager.position.y if villager != null else 0.0,
		"inventory_snapshot": villager.inventory.duplicate(true) if villager != null else {},
		"dead_at": death_timestamp,
		"dead_reason": clean_reason,
		"dead_time_text": _format_timestamp(death_timestamp)
	}
	_queue_event_notification("Death: %s (%s) at %s" % [villager_name, clean_reason, _format_timestamp(death_timestamp)])
	_npc_last_llm_decisions.erase(villager_name)
	_npc_last_llm_error.erase(villager_name)
	_npc_llm_status[villager_name] = "dead"
	_npc_next_horny_time.erase(villager_name)
	_npc_horny_until.erase(villager_name)
	_npc_last_mate_time.erase(villager_name)
	_purge_dead_npc_runtime_state(villager_name)
	
	# Defer check so queue_free() has been processed for the just-dead villager.
	call_deferred("_restart_if_all_villagers_dead")

func _make_unique_name(base_name: String) -> String:
	var clean := base_name.strip_edges()
	if clean.is_empty():
		clean = "Viewer"

	var taken: Dictionary = {}
	for villager in _villagers:
		taken[villager.villager_name] = true

	if not taken.has(clean):
		return clean

	var index := 2
	while taken.has("%s%d" % [clean, index]):
		index += 1
	return "%s%d" % [clean, index]

func _load_texture_from_pixil(pixil_path: String) -> Texture2D:
	if not FileAccess.file_exists(pixil_path):
		return null
	var file := FileAccess.open(pixil_path, FileAccess.READ)
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
