extends Node
class_name ChatBridge

signal join_requested(viewer_name: String)

@export var websocket_url: String = "ws://127.0.0.1:8765"
@export var auto_connect: bool = false
@export var reconnect_interval_sec: float = 3.0

var _socket := WebSocketPeer.new()
var _reconnect_timer: float = 0.0
var _is_open: bool = false

func _ready() -> void:
	if auto_connect:
		_connect_socket()

func _process(delta: float) -> void:
	if not auto_connect:
		return

	if _socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		_is_open = false
		_reconnect_timer -= delta
		if _reconnect_timer <= 0.0:
			_connect_socket()
		return

	_socket.poll()

	var state := _socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		_is_open = true
		while _socket.get_available_packet_count() > 0:
			var msg := _socket.get_packet().get_string_from_utf8()
			_handle_message(msg)
	elif state == WebSocketPeer.STATE_CLOSING:
		_is_open = false

func feed_chat_line(raw_line: String, fallback_user: String = "Viewer") -> void:
	_parse_join(raw_line, fallback_user)

func _connect_socket() -> void:
	_reconnect_timer = reconnect_interval_sec
	var result := _socket.connect_to_url(websocket_url)
	if result != OK:
		push_warning("ChatBridge failed to connect to %s (error %s)" % [websocket_url, result])

func _handle_message(message: String) -> void:
	var parsed: Variant = JSON.parse_string(message)
	if typeof(parsed) == TYPE_DICTIONARY:
		var dict: Dictionary = parsed
		var user := str(dict.get("user", dict.get("username", "Viewer")))
		var text := str(dict.get("message", dict.get("text", "")))
		_parse_join(text, user)
	else:
		_parse_join(message, "Viewer")

func _parse_join(message: String, user: String) -> void:
	var normalized := message.strip_edges()
	if not normalized.begins_with("!join"):
		return

	var parts := normalized.split(" ", false)
	var name := user
	if parts.size() > 1 and not parts[1].strip_edges().is_empty():
		name = parts[1].strip_edges()

	emit_signal("join_requested", name)
