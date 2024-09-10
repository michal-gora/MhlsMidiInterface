extends Control

@onready var rich_text_label: RichTextLabel = $RichTextLabel

#var midi_in = MidiIn.new()
#var midi_out = MidiOut.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	OS.open_midi_inputs()
	rich_text_label.text += str(OS.get_connected_midi_inputs())
	#print(OS.get_connected_midi_inputs())
	#print(midi_in.get_port_names())
	#midi_in.midi_message.connect(_on_midi_message)
	#midi_in.open_port(3)
	#print(midi_out.get_port_names())
	#midi_out.open_port(3)
	#midi_out.send_message([0x90, 60, 42])
	#midi_in.close_port()
	#midi_out.close_port()

func _on_midi_message(delta, message):
	print("MIDI message: ", message)

func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMIDI:
		rich_text_label.text += "\n" + str(event)
		#midi_out.send_message([0x90, 61, 42])
		


func _on_button_button_down_C() -> void:
	#midi_out.send_message([0x90, 60, 42])
	pass

func _on_button_2_button_down_Cis() -> void:
	#midi_out.send_message([0x90, 61, 42])
	pass

func _on_button_3_button_down_D() -> void:
	#midi_out.send_message([0x90, 62, 42])
	pass

func _on_key_button_down(extra_arg_0: int) -> void:
	#midi_out.send_message([0x90, extra_arg_0, 42])
	pass
