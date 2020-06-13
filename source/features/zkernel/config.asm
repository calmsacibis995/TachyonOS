; ------------------------------------------------------------------
; Change operating system settings.
; IN: AX = setting number, BX = value to set
; OUT: CF = set if error, otherwise clear
os_set_config:
	API_START
	
	cmp ax, 8	; Check the setting is with current bounds
	jg .error
	
	shr ax, 1	; Settings values take two bytes each.
	mov si, CONFIG_START
	add si, ax
	mov [fs:si], bx
	
	API_END_NC
	
.error:
	API_END_SC
	 
; ------------------------------------------------------------------
; Read operating system settings.
; IN: AX = setting number
; OUT: BX = current value
	 
os_get_config:
	API_START
	
	cmp ax, 8	; Check the setting is with current bounds
	jg .error
	
	shr ax, 1	; Settings values take two bytes each.
	mov si, CONFIG_START	; It's just a linear offset in the block.
	add si, ax
	mov bx, [fs:si]
	
	API_RETURN_NC bx
	
.error:
	API_END_SC
		

	 
; Configurations options:
; 0 = Dialogue box outside colour	8 Bit Colour
; 1 = Dialogue box content colour	8 Bit Colour
; 2 = Dialogue box selection colour	8 Bit Colour
; 3 = Dialogue box title bar colur	8 Bit Colour
; 4 = Time Format, see os_set_time_fmt	Config Value
; 5 = Date Format, see os_set_date_fmt	Config Value
; 6 = Date Seperator			Character
; 7 = Expected screen height for dialogs
; 8 = Expected screen width  for dialogs
