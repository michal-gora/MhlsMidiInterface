extends Control

@onready var start: Button = $start
@onready var bpm_box: SpinBox = $bpm_selector
@onready var filename: LineEdit = $filename
@onready var mididevice_selector: OptionButton = $mididevice_selector
@onready var file_dialog: FileDialog = $FileDialog
@onready var refresh_button: Button = $refresh
var isrecording: bool = false
var midi_in = MidiIn.new()
var folderpath = "user://"
var file = null
var tpqn = 96
var lengthpos
var trackstartpos
const LASTFOLDERPATHSETTING = "user://lastfolderpath.txt"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	midi_in.midi_message.connect(_incoming_midi_message)
	refresh_midi_devices()
	var file_p = FileAccess.open(LASTFOLDERPATHSETTING, FileAccess.READ)
	if file_p != null:
		folderpath = file_p.get_line()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func refresh_midi_devices():
	mididevice_selector.clear()
	for i in midi_in.get_port_names():
		mididevice_selector.add_item(i)
	mididevice_selector.select(mididevice_selector.item_count-1)

# button pressed to toggle recording
func _on_start_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		#start.text = "STOP RECORDING"
		start.icon = preload("res://assets/radio_button_checked_70dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.svg")
		startrecording(mididevice_selector.get_selected_id())
	else:
		#start.text = "START RECORDING"
		start.icon = preload("res://assets/radio_button_checked_70dp_FF0000_FILL0_wght400_GRAD0_opsz48.svg")
		stoprecording()
	mididevice_selector.disabled = toggled_on
	bpm_box.editable = !toggled_on
	refresh_button.disabled = toggled_on

func startrecording(v_port: int = 2, v_bpm: int = 120, v_tpqn: int = 96):
	midi_in.open_port(v_port)
	
	var path = folderpath + "/" + filename.text + "-" + Time.get_datetime_string_from_system() + ".mid"
	path = path.replace("\\", "/")
	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("File could not be opened!!")
		_on_start_toggled(false)
		return
	file.store_buffer([0x4d, 0x54, 0x68, 0x64]) # "MThd"
	file.store_buffer([0x00, 0x00, 0x00, 0x06]) # length = 6 B
	file.store_buffer([0x00, 0x01, 0x00, 0x01]) # Fileformat 1, tacks = 1
	file.store_buffer([0x00, 0x60])             # tpqn = 96
	file.store_buffer([0x4d, 0x54, 0x72, 0x6b]) # "MTrk
	lengthpos = file.get_position()
	file.store_buffer([0x00, 0x00, 0x00, 0x00]) # temporary track length 0
	trackstartpos = file.get_position()
	# track data:
	store_new_tempo(file, v_bpm)
	
	isrecording = true

func stoprecording(v_port: int = 2):
	isrecording = false
	# ending:
	if file == null:
		midi_in.close_port()
		return
	file.store_buffer([0x00, 0xff, 0x2f, 0x00]) # End of Track
	var trackendpos = file.get_position()
	var trackdatalength = trackendpos - trackstartpos
	print("Trackdatalength: " + str(trackdatalength))
	file.seek(lengthpos)
	store_32_be(file, trackdatalength)
	file.seek_end()
	file.close()
	midi_in.close_port()
	

func _incoming_midi_message(delta, message):
	if isrecording:
		print(delta)
		print(message)
		var ticks = seconds_to_ticks(delta, tpqn, bpm_box.value)
		var encoded = encode_variable_length(ticks)
		file.store_buffer(encoded)
		file.store_buffer(message) # note off
	else:
		print("actually not recording")

func store_new_tempo(file, beatspermin):
	file.store_buffer([0x00, 0xff, 0x51, 0x03]) # Set Tempo...
	var microsecperquarter = 60000000 / beatspermin
	file.store_8(microsecperquarter & 0xff0000)
	file.store_8(microsecperquarter & 0xff00)
	file.store_8(microsecperquarter & 0xff)

func store_32_be(file, value):
	# Convert the 32-bit integer to big-endian format
	var byte1 = (value >> 24) & 0xFF
	var byte2 = (value >> 16) & 0xFF
	var byte3 = (value >> 8) & 0xFF
	var byte4 = value & 0xFF
	# Store each byte in the correct order (big-endian)
	file.store_8(byte1)
	file.store_8(byte2)
	file.store_8(byte3)
	file.store_8(byte4)



func seconds_to_ticks(delta: float, tpqn: int, bpm: float) -> int:
	var microseconds_per_quarter_note = 60_000_000 / bpm
	var ticks = int(round((delta * 1_000_000 / microseconds_per_quarter_note) * tpqn))
	return ticks

func encode_variable_length(value: int) -> PackedByteArray:
	var buffer = []
	var packed_bytes = PackedByteArray()
	# Encode the value in the MIDI variable-length format
	while value > 0:
		var byte = value & 0x7F
		value >>= 7
		if buffer.size() > 0:
			byte |= 0x80
		buffer.insert(0, byte)
	# Handle the case where value is zero
	if buffer.size() == 0:
		buffer.append(0)
	# Convert buffer to PackedByteArray
	for byte in buffer:
		packed_bytes.append(byte)
	return packed_bytes




func _on_file_dialog_dir_selected(dir: String) -> void:
	print(dir)
	folderpath = dir.replace("\\", "/")
	var file_p = FileAccess.open(LASTFOLDERPATHSETTING, FileAccess.WRITE)
	if file_p != null:
		file_p.store_line(folderpath)
		file_p.close()


func _on_openfiledialog_pressed() -> void:
	file_dialog.show()


func _on_openfolder_pressed() -> void:
	OS.shell_show_in_file_manager(folderpath)
