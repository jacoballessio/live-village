# Neural Network Integration Examples

These examples show how to integrate neural network action priorities into VillagerAgent's decision-making.

## Example 1: Basic Food/Water Seeking

Modify `_choose_target()` in VillagerAgent.gd to use network outputs:

```gdscript
func _choose_target(delta: float) -> Vector2:
	# Get network action priorities
	var nn_actions = get_neural_network_actions()
	
	# Hunger/hydration drive the network, but network learned priorities override
	if hunger < hunger_health_damage_threshold:
		# Critical hunger: seek food regardless
		return FOOD_POINT
	
	# Use network to decide between food and water seeking
	if nn_actions.get("seek_food", 0.0) > 0.6 and hunger < MAX_HUNGER * 0.5:
		return FOOD_POINT
	elif nn_actions.get("seek_water", 0.0) > 0.6 and hydration < MAX_HYDRATION * 0.4:
		if _find_nearest_water_world_position.is_valid():
			var water: Variant = _find_nearest_water_world_position.call(position, 20)
			if water is Vector2:
				return water
	
	# Default behavior continues as before
	return _destination
```

## Example 2: Weighted Blending with Heuristics

Blend network output with existing heuristic weights:

```gdscript
func _apply_heuristic_targets(delta: float) -> void:
	var nn_actions = get_neural_network_actions()
	
	# Calculate heuristic priorities (0-1)
	var hunger_priority = clampf(hunger / (MAX_HUNGER * 0.3), 0.0, 1.0)
	var hydration_priority = clampf(1.0 - (hydration / (MAX_HYDRATION * 0.4)), 0.0, 1.0)
	var social_priority = randf() * 0.1 if _heuristic_social_chat_cooldown <= 0.0 else 0.0
	
	# Blend with network outputs (60% network, 40% heuristic)
	var final_food_priority = lerpf(hunger_priority, nn_actions.get("seek_food", 0.0), 0.6)
	var final_water_priority = lerpf(hydration_priority, nn_actions.get("seek_water", 0.0), 0.6)
	var final_social_priority = lerpf(social_priority, nn_actions.get("socialize", 0.0), 0.6)
	
	# Choose action with highest priority
	var priorities = {
		"food": final_food_priority,
		"water": final_water_priority,
		"social": final_social_priority
	}
	
	var max_action = "food"
	var max_priority = priorities["food"]
	for action in priorities:
		if priorities[action] > max_priority:
			max_priority = priorities[action]
			max_action = action
	
	# Execute chosen action
	if max_priority > 0.3:  # Only act if priority is meaningful
		match max_action:
			"food":
				_try_find_tree()
			"water":
				_water_seek_cooldown = 0.0
			"social":
				_try_heuristic_social_chat(delta)
```

## Example 3: Neural Network Gate for LLM Decisions

Use network to decide whether to invoke expensive LLM calls:

```gdscript
func _tick_llm_decision(delta: float) -> void:
	if not _evaluate_llm_decision.is_valid():
		return
	
	_llm_decision_timer -= delta
	if _llm_decision_timer > 0.0:
		return
	
	_llm_decision_timer = _get_llm_decision_interval_seconds()
	
	# Use network to decide if LLM is needed
	var nn_actions = get_neural_network_actions()
	var uncertainty = 0.0
	for action in nn_actions.values():
		# High uncertainty when outputs are balanced (near 0.5)
		uncertainty += abs(action - 0.5) / 0.5
	uncertainty /= nn_actions.size()
	
	# Only ask LLM if network is uncertain (uncertainty > 0.7)
	if uncertainty > 0.7 or randf() < 0.3:  # 30% chance anyway
		_run_llm_decision()
	# Otherwise use network decision
```

## Example 4: Movement Modifier Based on Network

Modify movement speed based on network's "move" priority:

```gdscript
func _effective_move_speed() -> float:
	var base_speed = move_speed * _stamina_gene
	
	# Get network move priority
	var nn_actions = get_neural_network_actions()
	var move_priority = nn_actions.get("move", 0.5)
	
	# Faster movement when moving is high priority, slower when not
	# Range: 0.3x to 1.3x of base speed
	var speed_multiplier = lerpf(0.3, 1.3, move_priority)
	
	return base_speed * speed_multiplier
```

## Example 5: Decision Tree with Network Branches

Create decision logic where network helps at each branching point:

```gdscript
func _make_complex_decision(delta: float) -> Vector2:
	var nn_actions = get_neural_network_actions()
	
	# Top-level: Is moving a priority?
	if nn_actions.get("move", 0.0) > 0.6:
		# Sub-level: If moving, where to go?
		if nn_actions.get("seek_food", 0.0) > nn_actions.get("seek_water", 0.0):
			return _find_food_location()
		else:
			return _find_water_location()
	
	# Not moving: stay and do something else
	if nn_actions.get("socialize", 0.0) > 0.5:
		return position  # Stay here and socialize
	
	# Default: wander
	return _random_arena_point()
```

## Example 6: Logging Network State for Analysis

Monitor what the network is learning over time:

```gdscript
func _debug_log_network_state() -> void:
	if not llm_debug_enabled:
		return
	
	var nn_actions = get_neural_network_actions()
	var net = get_neural_network()
	
	# Log sensory inputs (last layer)
	if net and net.layer_outputs.size() > 0:
		var sensory_layer = net.layer_outputs[0]
		print_debug("%s sensory: temp=%.2f, hunger=%.2f, energy=%.2f, hydration=%.2f" % [
			villager_name,
			sensory_layer[SensoryInput.SENSE_INDEX.BODY_TEMP_NORMALIZED],
			sensory_layer[SensoryInput.SENSE_INDEX.HUNGER_NORMALIZED],
			sensory_layer[SensoryInput.SENSE_INDEX.ENERGY_NORMALIZED],
			sensory_layer[SensoryInput.SENSE_INDEX.HYDRATION_NORMALIZED]
		])
	
	# Log network outputs
	print_debug("%s network: move=%.2f, food=%.2f, water=%.2f, social=%.2f" % [
		villager_name,
		nn_actions.get("move", 0.0),
		nn_actions.get("seek_food", 0.0),
		nn_actions.get("seek_water", 0.0),
		nn_actions.get("socialize", 0.0)
	])
```

## Example 7: Stress Test - All Priorities at Once

See how network handles conflicting signals:

```gdscript
func _stress_test_network() -> void:
	# Create maximum conflict scenario
	hunger = 1.0
	hydration = 1.0
	energy = MAX_STAT
	body_temperature_c = 45.0  # Too hot
	
	# Gather inputs and forward pass
	var world_state = _gather_world_state()
	var inputs = SensoryInput.gather_sensory_inputs(self, world_state)
	var outputs = _neural_network.forward(inputs)
	
	print_debug("Conflicting inputs resolved to:")
	print_debug("  Move: %.3f" % outputs[SensoryInput.ACTION_INDEX.MOVE_PRIORITY])
	print_debug("  Seek Food: %.3f" % outputs[SensoryInput.ACTION_INDEX.SEEK_FOOD])
	print_debug("  Seek Water: %.3f" % outputs[SensoryInput.ACTION_INDEX.SEEK_WATER])
	print_debug("  Socialize: %.3f" % outputs[SensoryInput.ACTION_INDEX.SOCIALIZE])
```

## Example 8: Visualizing Network in Inspector

Custom UI code to show network state (VillageWorld):

```gdscript
func _update_neural_network_inspector(villager_name: String) -> void:
	var villager = _get_villager_by_name(villager_name)
	if not villager:
		return
	
	var net = villager.get_neural_network()
	var actions = villager.get_neural_network_actions()
	
	var info_lines = []
	info_lines.append("[b]Neural Network Status[/b]")
	info_lines.append("")
	
	if net:
		info_lines.append("Layers: %d input → [%s] → %d output" % [
			net.input_size,
			", ".join(net.hidden_layer_sizes.map(func(x): return str(x))),
			net.output_size
		])
		info_lines.append("")
		
		info_lines.append("[b]Last Action Priorities:[/b]")
		info_lines.append("  Move: %.2f%%" % (actions.get("move", 0.0) * 100.0))
		info_lines.append("  Seek Food: %.2f%%" % (actions.get("seek_food", 0.0) * 100.0))
		info_lines.append("  Seek Water: %.2f%%" % (actions.get("seek_water", 0.0) * 100.0))
		info_lines.append("  Socialize: %.2f%%" % (actions.get("socialize", 0.0) * 100.0))
	
	# Display in inspector (implementation depends on your UI)
	print_debug("\n".join(info_lines))
```

## Example 9: Evolution Tracking

Track how networks improve over generations:

```gdscript
class GenerationStats:
	var generation: int = 0
	var avg_move_priority: float = 0.0
	var avg_food_priority: float = 0.0
	var avg_water_priority: float = 0.0
	var avg_social_priority: float = 0.0
	var villager_count: int = 0

func _track_generation_stats() -> GenerationStats:
	var stats = GenerationStats.new()
	var villagers = _get_active_villagers()
	stats.villager_count = villagers.size()
	
	var total_move = 0.0
	var total_food = 0.0
	var total_water = 0.0
	var total_social = 0.0
	
	for villager in villagers:
		var actions = villager.get_neural_network_actions()
		total_move += actions.get("move", 0.0)
		total_food += actions.get("seek_food", 0.0)
		total_water += actions.get("seek_water", 0.0)
		total_social += actions.get("socialize", 0.0)
	
	if stats.villager_count > 0:
		stats.avg_move_priority = total_move / stats.villager_count
		stats.avg_food_priority = total_food / stats.villager_count
		stats.avg_water_priority = total_water / stats.villager_count
		stats.avg_social_priority = total_social / stats.villager_count
	
	return stats
```

## Example 10: Hybrid Decision (Network + LLM + Heuristic)

Most realistic approach: combine all three systems:

```gdscript
func _hybrid_decision_making(delta: float) -> Vector2:
	# System 1: Neural Network (fast, evolved)
	var nn_actions = get_neural_network_actions()
	var nn_recommendation = _get_strongest_action(nn_actions)
	
	# System 2: Heuristic (reliable baseline)
	var heuristic_recommendation = _choose_heuristic_target(delta)
	
	# System 3: LLM (intelligent, slow, expensive)
	# Only runs periodically and when uncertain
	var llm_recommendation = position
	if _should_use_llm_decision():
		llm_recommendation = _choose_llm_biased_target(delta)
	
	# Merge with weights
	var combined = heuristic_recommendation  # Default to reliable baseline
	
	# 30% weight to neural network (fast adaptation)
	if randf() < 0.3 and nn_recommendation != position:
		combined = lerpf(combined, nn_recommendation, 0.5)
	
	# 20% weight to LLM (intelligent decisions)
	if randf() < 0.2 and llm_recommendation != position:
		combined = lerpf(combined, llm_recommendation, 0.3)
	
	return combined

func _get_strongest_action(actions: Dictionary) -> Vector2:
	var max_action = "move"
	var max_value = actions.get("move", 0.0)
	
	for action in ["seek_food", "seek_water", "socialize"]:
		if actions.get(action, 0.0) > max_value:
			max_value = actions.get(action, 0.0)
			max_action = action
	
	match max_action:
		"seek_food":
			return FOOD_POINT
		"seek_water":
			return _find_nearest_water_location()
		"socialize":
			return _find_nearby_player_location()
		_:
			return _destination
```

---

These examples show various integration approaches. Mix and match based on your needs!
