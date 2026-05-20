# Neural Network-Based NPC Heuristics Guide

## Overview

NPCs in Live-Village now have **genetic neural networks** that control their behavior heuristics. Instead of hard-coded rules, each villager's brain is a small neural network whose weights and biases are encoded in their genes. These networks evolve over generations through natural selection.

## How It Works

### Architecture

Each villager has a personal neural network with:
- **8 sensory inputs**: body temperature, hunger, energy, hydration, time of day, nearby players/NPCs
- **2 hidden layers**: 16 neurons → 8 neurons (ReLU activation)
- **4 action outputs**: move priority, seek food, seek water, socialize (sigmoid activation)

```
Sensory Input (8)
     ↓
Hidden Layer 1 (16 neurons, ReLU)
     ↓
Hidden Layer 2 (8 neurons, ReLU)
     ↓
Action Output (4, Sigmoid 0-1)
```

### Behavior Loop

1. Every 0.1 seconds, the network gathers sensory data
2. Feeds it through the neural network
3. Gets priority scores (0-1) for each action
4. Uses these priorities alongside LLM decisions and other heuristics

### Genetic Inheritance

When two villagers mate:
1. A new network is created (copy of parent A)
2. 50% of weights/biases randomly inherit from parent B
3. 20% get blended (average of both parents)
4. Mutations applied at configurable rates
5. Child's genes stored alongside physical/personality traits

Successful behaviors are amplified in offspring through natural selection.

## Sensory Inputs

The network receives normalized inputs:

| Index | Input | Range | Meaning |
|-------|-------|-------|---------|
| 0 | Body Temperature | 0-1 | Normalized around 37°C ±5°C |
| 1 | Hunger | 0-1 | Current hunger / max hunger |
| 2 | Energy | 0-1 | Current energy / max energy |
| 3 | Hydration | 0-1 | Current hydration / max hydration |
| 4 | Time of Day (sin) | 0-1 | Sine of circular day cycle |
| 5 | Time of Day (cos) | 0-1 | Cosine of circular day cycle |
| 6 | Nearby Players | 0-1 | Player count / 3 (clamped) |
| 7 | Nearby NPCs | 0-1 | NPC count / 5 (clamped) |

## Action Outputs

The network outputs priorities (0-1 each) for:

| Index | Output | Meaning |
|-------|--------|---------|
| 0 | Move Priority | How much to prioritize movement |
| 1 | Seek Food | Priority to search for food |
| 2 | Seek Water | Priority to search for water |
| 3 | Socialize | Priority to interact with others |

Higher values = stronger urge for that action.

## Usage in Code

### Getting Network Actions

```gdscript
var villager = _villagers[0]
var actions = villager.get_neural_network_actions()

# Returns dictionary like:
# {"move": 0.7, "seek_food": 0.3, "seek_water": 0.1, "socialize": 0.2}
```

### Integrating Into Decision-Making

Modify `_choose_target()` in VillagerAgent to blend network outputs:

```gdscript
func _choose_target(delta: float) -> Vector2:
	var nn_actions = get_neural_network_actions()
	
	# Blend with existing heuristics
	if nn_actions["seek_food"] > 0.6 and hunger < MAX_HUNGER * 0.3:
		return _FOOD_POINT  # Food location
	elif nn_actions["seek_water"] > 0.6:
		return _find_nearest_water()
	elif nn_actions["socialize"] > 0.5:
		return _find_nearby_player_location()
	else:
		return _current_target  # Continue existing behavior
```

### Inspecting Individual Networks

```gdscript
var net = villager.get_neural_network()
if net:
	# See activation values from last forward pass
	print("Layer outputs: ", net.layer_outputs)
	
	# Get weight/bias counts
	print("Weights per layer: ", net.weights.size())
	print("Biases per layer: ", net.biases.size())
```

### Accessing Genes

Networks are stored in the LLM gene dictionary with keys:
- `network_input_size`: 8
- `network_hidden_layers`: [16, 8]
- `network_output_size`: 4
- `network_weights`: Array of weight matrices
- `network_biases`: Array of bias vectors

## Configuration

### Mutation Rates

Set in VillageWorld export variables:

```gdscript
@export_range(0.0, 0.2, 0.001) var gene_mutation_chance: float = 0.02
@export_range(0.01, 0.8, 0.01) var gene_mutation_strength: float = 0.16
```

- `gene_mutation_chance`: Probability each weight mutates
- `gene_mutation_strength`: Magnitude of mutations

### Network Update Frequency

In VillagerAgent, currently set to **0.1 seconds** in `_update_neural_network_decision()`:

```gdscript
_neural_network_update_timer = 0.1  # Adjust for performance/responsiveness
```

Lower = more responsive but more CPU; higher = better performance but more laggy decisions.

### Network Architecture

To change network size, modify initialization in VillagerAgent:

```gdscript
func _initialize_neural_network(genes: Dictionary) -> void:
	if genes.is_empty():
		# Change [16, 8] to different hidden layer sizes
		_neural_network = NeuralNetwork.new(8, [16, 8], 4)
```

## Observing Evolution

### What to Watch For

1. **Movement Patterns**: Do villagers develop different movement styles?
2. **Resource Seeking**: Do they learn to seek food/water more efficiently?
3. **Social Behavior**: Do networks favor socialization over solitude?
4. **Emergent Strategies**: Do lineages develop unique behavioral quirks?

### Tracking Lineages

Monitor the inspector to see how genes change:
- Click a villager to inspect
- Look at "Genes" section
- Network weights/biases show as arrays in gene dump

### Simulated Evolution Experiment

1. Enable neural networks (default: on)
2. Set low initial population (3-5 villagers)
3. Watch for 10+ generations
4. Note which lineages survive longest
5. Observe if behavior patterns emerge

## Advanced Customization

### Adding More Sensory Inputs

1. Edit `SensoryInput.gd` enum `SENSE_INDEX`
2. Add gathering logic in `gather_sensory_inputs()`
3. Update network input size: `NeuralNetwork.new(NEW_SIZE, [16, 8], 4)`
4. Repopulate villagers (new networks needed)

Example: Add "nearby_food" sensor:
```gdscript
enum SENSE_INDEX {
	# ... existing inputs ...
	NEARBY_FOOD_COUNT = 8,
	TOTAL_SENSES = 9  # Update this!
}

# In gather_sensory_inputs():
var nearby_food = world_state.get("nearby_food_count", 0)
inputs.append(clampf(float(nearby_food) / 5.0, 0.0, 1.0))
```

### Adding More Action Outputs

1. Edit `SensoryInput.gd` enum `ACTION_INDEX`
2. Increase output size: `NeuralNetwork.new(8, [16, 8], NEW_SIZE)`
3. Handle new outputs in decision-making code

Example: Add "rest" action:
```gdscript
enum ACTION_INDEX {
	MOVE_PRIORITY = 0,
	SEEK_FOOD = 1,
	SEEK_WATER = 2,
	SOCIALIZE = 3,
	REST = 4,  # New!
	TOTAL_ACTIONS = 5
}
```

### Custom Activation Functions

Edit NeuralNetwork.gd to use different activations:
- **ReLU** (current hidden): Good for decision networks
- **Tanh**: For continuous outputs (-1 to 1)
- **LeakyReLU**: Prevents dead neurons
- **Linear**: For regression tasks

## Performance Notes

- **Memory**: ~8KB per villager (network weights)
- **CPU**: ~0.5ms per network per 0.1s update (10 villagers = 5ms)
- **Update Rate**: Every 0.1s (10 updates/second) by design

## Troubleshooting

### Networks Not Working
- Check that `_neural_network_enabled = true` in VillagerAgent
- Verify genes are passed during setup
- Log `get_neural_network_actions()` to confirm non-empty

### Strange Behavior
- Weights might be random initially (evolution takes time)
- Try multiple generations before judging
- Check sensory inputs are normalized (0-1 range)

### Performance Issues
- Increase `_neural_network_update_timer` value
- Reduce network size in initialization
- Use fewer villagers for testing

## Architecture Diagram

```
VillageWorld
    ↓
spawn_villager() → VillagerAgent.setup()
    ↓
_initialize_neural_network(genes)
    ↓
NeuralNetwork.from_genes() [loads weights/biases]
    ↓
_process(delta)
    └→ _update_neural_network_decision(delta)
        ↓
    SensoryInput.gather_sensory_inputs()
        ↓
    NeuralNetwork.forward(inputs)
        ↓
    SensoryInput.interpret_action_outputs()
        ↓
    Stored in _last_neural_network_outputs
        ↓
    Available via get_neural_network_actions()

[Mating]
    ↓
_mate_pair() → _mix_neural_network_genes()
    ↓
NeuralNetwork.mutate() applied to child
    ↓
Genes serialized with to_genes()
    ↓
Child spawns with evolved network
```

## Example: Using Network for Food Seeking

```gdscript
# In _choose_target or custom behavior function
var actions = get_neural_network_actions()
var food_priority = actions.get("seek_food", 0.0)

if hunger < MAX_HUNGER * 0.4 and food_priority > 0.5:
	# Network strongly suggests seeking food
	if not _has_chop_target:
		_try_find_tree()  # Go find apples
	return _chop_world_position if _has_chop_target else position
```

## Further Reading

- Papers: "NEAT" (NeuroEvolution of Augmenting Topologies)
- Similar systems: Creatures (1996), OpenAI gym environments
- Godot neural network resources in marketplace

---

**Last Updated**: May 16, 2026
**System Status**: Functional and evolving!
