extends Node


func _ready():
	var notches = DeviceNotches.get_device_notch()
	
	var screen_height  = DisplayServer.screen_get_size().y
	var viewport_height = get_viewport().get_visible_rect().size.y
	var y_scale = viewport_height / screen_height
	
	var separator_size = self.size
	separator_size.y = notches.bottom_size * y_scale
	self.custom_minimum_size = separator_size
