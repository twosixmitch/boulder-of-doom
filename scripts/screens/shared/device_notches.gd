class_name DeviceNotches

static func get_device_notch() -> DeviceNotch:
	var os = OS.get_name()
	
	if os == "Android" || os ==  "iOS":
		var safe_area = DisplayServer.get_display_safe_area()
		var window_size = DisplayServer.window_get_size()
		
		# Calculate top inset (notch/cutout area)
		var top_size = int(safe_area.position.y)
		
		# Calculate bottom inset (navigation bar area)
		# Bottom inset = total window height - safe area bottom edge
		var bottom_size = int(window_size.y - safe_area.end.y)
		
		# For Android, add buffer for transparent navigation bar background
		# The safe area gives us the interactive area, but the transparent
		# background extends beyond it. Typical buffer is 15-25 pixels.
		if os == "Android" and bottom_size > 0:
			# Add buffer for transparent background area
			bottom_size += 15
		elif os == "iOS":
			bottom_size = 20
		
		return DeviceNotch.new(top_size, bottom_size)
	else:
		return DeviceNotch.new(0, 0)
