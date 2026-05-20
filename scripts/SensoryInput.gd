## Gathers sensory input data for the neural network
## Inputs include: body temp, hunger, energy, hydration, time of day, nearby NPCs, nearby players, etc.
class_name SensoryInput

## Sensory input indices (must match order in gather_sensory_inputs)
enum SENSE_INDEX {
	BODY_TEMP_NORMALIZED = 0,       # 0-1 normalized body temperature
	HUNGER_NORMALIZED = 1,          # 0-1 normalized hunger
	ENERGY_NORMALIZED = 2,          # 0-1 normalized energy
	HYDRATION_NORMALIZED = 3,       # 0-1 normalized hydration
	TIME_OF_DAY_SIN = 4,            # Sine of time of day (0-1 maps to 0-2pi)
	TIME_OF_DAY_COS = 5,            # Cosine of time of day
	NEARBY_PLAYERS_COUNT = 6,       # 0-1 (clamped count)
	NEARBY_NPCS_COUNT = 7,          # 0-1 (clamped count)
	TOTAL_SENSES = 8
}

## Gather sensory inputs from a villager and world
static func gather_sensory_inputs(
	villager: Node,
	world_state: Dictionary = {}
) -> PackedFloat32Array:
	var inputs = PackedFloat32Array()
	
	# Body temperature (normalize around 37°C ±5°C)
	var body_temp = villager.body_temperature_c if "body_temperature_c" in villager else 37.0
	var temp_norm = clampf((body_temp - 32.0) / 10.0, 0.0, 1.0)
	inputs.append(temp_norm)
	
	# Hunger (normalize to max hunger)
	var hunger = villager.hunger if "hunger" in villager else 0.0
	var max_hunger = villager.MAX_HUNGER if "MAX_HUNGER" in villager else 300.0
	var hunger_norm = clampf(hunger / max_hunger, 0.0, 1.0)
	inputs.append(hunger_norm)
	
	# Energy (normalize to max energy)
	var energy = villager.energy if "energy" in villager else 100.0
	var max_energy = villager.MAX_STAT if "MAX_STAT" in villager else 100.0
	var energy_norm = clampf(energy / max_energy, 0.0, 1.0)
	inputs.append(energy_norm)
	
	# Hydration (normalize to max hydration)
	var hydration = villager.hydration if "hydration" in villager else 500.0
	var max_hydration = villager.MAX_HYDRATION if "MAX_HYDRATION" in villager else 1000.0
	var hydration_norm = clampf(hydration / max_hydration, 0.0, 1.0)
	inputs.append(hydration_norm)
	
	# Time of day (sine and cosine for circular representation)
	# Assuming world tracks time somehow - using a default cycle if not provided
	var time_of_day = world_state.get("time_of_day", Time.get_ticks_msec() / 1000.0)
	var day_cycle = fmod(time_of_day, 24.0 * 60.0)  # 24 minute cycle
	var phase = (day_cycle / (24.0 * 60.0)) * TAU
	inputs.append(sin(phase) * 0.5 + 0.5)  # Normalize sin to 0-1
	inputs.append(cos(phase) * 0.5 + 0.5)  # Normalize cos to 0-1
	
	# Nearby players count (clamped to 0-1)
	var nearby_players = world_state.get("nearby_players_count", 0)
	inputs.append(clampf(float(nearby_players) / 3.0, 0.0, 1.0))
	
	# Nearby NPCs count (clamped to 0-1)
	var nearby_npcs = world_state.get("nearby_npcs_count", 0)
	inputs.append(clampf(float(nearby_npcs) / 5.0, 0.0, 1.0))
	
	return inputs

## Action output indices
enum ACTION_INDEX {
	MOVE_PRIORITY = 0,           # 0-1 priority to move vs stay
	SEEK_FOOD = 1,               # 0-1 priority to seek food
	SEEK_WATER = 2,              # 0-1 priority to seek water
	SOCIALIZE = 3,               # 0-1 priority to socialize with nearby NPCs/players
	TOTAL_ACTIONS = 4
}

## Interpret neural network outputs as action priorities
static func interpret_action_outputs(network_outputs: PackedFloat32Array) -> Dictionary:
	var actions = {
		"move": clampf(network_outputs[ACTION_INDEX.MOVE_PRIORITY] if network_outputs.size() > ACTION_INDEX.MOVE_PRIORITY else 0.0, 0.0, 1.0),
		"seek_food": clampf(network_outputs[ACTION_INDEX.SEEK_FOOD] if network_outputs.size() > ACTION_INDEX.SEEK_FOOD else 0.0, 0.0, 1.0),
		"seek_water": clampf(network_outputs[ACTION_INDEX.SEEK_WATER] if network_outputs.size() > ACTION_INDEX.SEEK_WATER else 0.0, 0.0, 1.0),
		"socialize": clampf(network_outputs[ACTION_INDEX.SOCIALIZE] if network_outputs.size() > ACTION_INDEX.SOCIALIZE else 0.0, 0.0, 1.0),
	}
	return actions
