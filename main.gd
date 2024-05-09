extends Control

var key = "https://getpantry.cloud/apiv1/pantry/XXXX-XXXX-XXXX-XXXX-XXXX/basket/PROJECTNAME"
var conf = {}
var HTTP
var data
var version = 0.1
var pressed = false

func _ready():
	$button.pressed.connect(check_updates)

func save_conf():
	var s = FileAccess.open("user://conf.dat",FileAccess.WRITE_READ)
	s.store_var(conf)
	s.close()

func load_conf():
	if FileAccess.file_exists("user://conf.dat"):
		var s = FileAccess.open("user://conf.dat",FileAccess.READ)
		conf = s.get_var()
		s.close()

func check_updates():
	if pressed and conf.get("next_update_check") != null and conf.next_update_check > Time.get_unix_time_from_system():
		print("Already checked for updates")
		$button.text = "Already checked for updates\nPress again to check anyway"
		pressed = false
	else:
		pressed = true
		$button.text = "Checking for updates..."
		
		HTTP = HTTPRequest.new()
		add_child(HTTP)
		HTTP.request_completed.connect(request_completed)
		var error = HTTP.request(key)
		if error != OK:
			$label.text = "An error occurred while checking for updates"
			push_error("An error occurred while checking for updates")

func request_completed(result, _response_code, _headers, body):
	$button.text = "Checked for updates"
	if result == HTTPRequest.RESULT_REQUEST_FAILED:
		push_error("REQUEST FAILED while checking for updates")
		$label.text = "REQUEST FAILED while checking for updates"
	else:
		conf.next_update_check = Time.get_unix_time_from_system() + 3600 # 3600 seconds = one hour in the future
#have to use JSON to convert the text
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
#saving the result in the conf file
		data = json.get_data()
		HTTP.queue_free()# dont need it anymore
		
		print("checking for updates successful")
		print(data)
		
	if data != null:
		conf.response = data
		save_conf()
	
		var v = float(conf.response.get("current_version"))

		if v != null and v > version:
			$label.text = str("Version ",v," found")
		else:
			$label.text = "No update found"
	else:
		$label.text = "ERROR"
