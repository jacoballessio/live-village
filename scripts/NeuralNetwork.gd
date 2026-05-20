## Simple feedforward neural network with sensory inputs and action outputs.
## Weights and biases are controlled by genes for evolutionary adaptation.
class_name NeuralNetwork

# Network architecture
var input_size: int = 0
var hidden_layer_sizes: Array[int] = []
var output_size: int = 0

# Network parameters (genes)
var weights: Array[PackedFloat32Array] = []
var biases: Array[PackedFloat32Array] = []

# Layer outputs for forward pass (cached for analysis)
var layer_outputs: Array[PackedFloat32Array] = []

func _init(p_input_size: int, p_hidden_layers: Array[int], p_output_size: int) -> void:
	input_size = p_input_size
	hidden_layer_sizes = p_hidden_layers
	output_size = p_output_size
	
	# Initialize weights and biases randomly
	_initialize_layers()

static func _to_int_array(values: Variant) -> Array[int]:
	var result: Array[int] = []
	if values is Array:
		for value in values:
			result.append(int(value))
	return result

## Initialize weights and biases for all layers
func _initialize_layers() -> void:
	weights.clear()
	biases.clear()
	
	var layer_sizes = [input_size] + hidden_layer_sizes + [output_size]
	
	for i in range(layer_sizes.size() - 1):
		var in_size = layer_sizes[i]
		var out_size = layer_sizes[i + 1]
		
		# Xavier initialization for weights
		var limit = sqrt(6.0 / float(in_size + out_size))
		var w = PackedFloat32Array()
		for j in range(in_size * out_size):
			w.append(randf_range(-limit, limit))
		weights.append(w)
		
		# Biases initialized to 0
		var b = PackedFloat32Array()
		for j in range(out_size):
			b.append(0.0)
		biases.append(b)

## Forward pass through the network
func forward(inputs: PackedFloat32Array) -> PackedFloat32Array:
	if inputs.size() != input_size:
		push_error("Input size mismatch: expected %d, got %d" % [input_size, inputs.size()])
		return PackedFloat32Array()
	
	layer_outputs.clear()
	var current = inputs
	layer_outputs.append(current)
	
	# Forward pass through each layer
	for layer_idx in range(weights.size()):
		var w = weights[layer_idx]
		var b = biases[layer_idx]
		var in_size = [input_size] + hidden_layer_sizes
		if layer_idx < in_size.size():
			in_size = in_size[layer_idx]
		else:
			in_size = hidden_layer_sizes[-1] if hidden_layer_sizes.size() > 0 else input_size
		
		var is_output_layer = layer_idx == weights.size() - 1
		var next = _matrix_multiply_and_add_bias(current, w, b, in_size, is_output_layer)
		
		# Apply activation function (ReLU for hidden, sigmoid for output)
		if not is_output_layer:
			next = _relu(next)
		else:
			next = _sigmoid(next)
		
		layer_outputs.append(next)
		current = next
	
	return current

## Matrix multiply + bias add
func _matrix_multiply_and_add_bias(
	inputs: PackedFloat32Array,
	weights: PackedFloat32Array,
	biases: PackedFloat32Array,
	in_size: int,
	is_output: bool
) -> PackedFloat32Array:
	var out_size = biases.size()
	var result = PackedFloat32Array()
	result.resize(out_size)
	
	for j in range(out_size):
		var sum = biases[j]
		for i in range(in_size):
			sum += inputs[i] * weights[i * out_size + j]
		result[j] = sum
	
	return result

## ReLU activation
func _relu(x: PackedFloat32Array) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	for val in x:
		result.append(maxf(0.0, val))
	return result

## Sigmoid activation
func _sigmoid(x: PackedFloat32Array) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	for val in x:
		result.append(1.0 / (1.0 + exp(-clampf(val, -10.0, 10.0))))
	return result

## Export network to gene dictionary
func to_genes() -> Dictionary:
	var gene_dict = {
		"network_input_size": input_size,
		"network_hidden_layers": hidden_layer_sizes.duplicate(),
		"network_output_size": output_size,
		"network_weights": [],
		"network_biases": []
	}
	
	for w in weights:
		var w_array: Array = []
		for val in w:
			w_array.append(val)
		gene_dict["network_weights"].append(w_array)
	
	for b in biases:
		var b_array: Array = []
		for val in b:
			b_array.append(val)
		gene_dict["network_biases"].append(b_array)
	
	return gene_dict

## Load network from gene dictionary
static func from_genes(genes: Dictionary) -> NeuralNetwork:
	var input_size: int = int(genes.get("network_input_size", 8))
	var hidden_layers: Array[int] = _to_int_array(genes.get("network_hidden_layers", [16, 8]))
	if hidden_layers.is_empty():
		hidden_layers = [16, 8]
	var output_size: int = int(genes.get("network_output_size", 4))
	
	var network = NeuralNetwork.new(input_size, hidden_layers, output_size)
	
	var weights_data = genes.get("network_weights", [])
	if weights_data.size() == network.weights.size():
		for i in range(weights_data.size()):
			var w = PackedFloat32Array()
			for val in weights_data[i]:
				w.append(float(val))
			network.weights[i] = w
	
	var biases_data = genes.get("network_biases", [])
	if biases_data.size() == network.biases.size():
		for i in range(biases_data.size()):
			var b = PackedFloat32Array()
			for val in biases_data[i]:
				b.append(float(val))
			network.biases[i] = b
	
	return network

## Mutate network weights and biases
func mutate(mutation_chance: float, mutation_strength: float) -> void:
	for w in weights:
		for i in range(w.size()):
			if randf() < mutation_chance:
				w[i] += randf_range(-mutation_strength, mutation_strength)
	
	for b in biases:
		for i in range(b.size()):
			if randf() < mutation_chance:
				b[i] += randf_range(-mutation_strength, mutation_strength)

## Create a copy of this network
func duplicate() -> NeuralNetwork:
	var copied_hidden_layers: Array[int] = _to_int_array(hidden_layer_sizes)
	var network = NeuralNetwork.new(input_size, copied_hidden_layers, output_size)
	network.weights.clear()
	for w in weights:
		network.weights.append(w.duplicate())
	network.biases.clear()
	for b in biases:
		network.biases.append(b.duplicate())
	return network
