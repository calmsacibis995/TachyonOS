jmp os_text_mode				; 0x0000
jmp os_graphics_mode				; 0x0003
jmp os_set_pixel				; 0x0006
jmp os_get_pixel				; 0x0009
jmp os_draw_line				; 0x000C
jmp os_draw_rectangle				; 0x000F
jmp os_draw_polygon				; 0x0012
jmp os_clear_graphics				; 0x0015
jmp os_memory_allocate				; 0x0018
jmp os_memory_release				; 0x001B
jmp os_memory_free				; 0x001E
jmp os_memory_reset				; 0x0021
jmp os_memory_read				; 0x0024
jmp os_memory_write				; 0x0027
jmp os_speaker_freq				; 0x002A
jmp os_speaker_tone				; 0x002D
jmp os_speaker_off				; 0x0030
jmp os_draw_border				; 0x0033
jmp os_draw_horizontal_line			; 0x0036
jmp os_draw_vertical_line			; 0x0039
jmp os_move_cursor				; 0x003C
jmp os_draw_block				; 0x003F
jmp os_mouse_setup				; 0x0042
jmp os_mouse_locate				; 0x0045
jmp os_mouse_move				; 0x0048
jmp os_mouse_show				; 0x004B
jmp os_mouse_hide				; 0x004E
jmp os_mouse_range				; 0x0051
jmp os_mouse_wait				; 0x0054
jmp os_mouse_anyclick				; 0x0057
jmp os_mouse_leftclick				; 0x005A
jmp os_mouse_middleclick			; 0x005D
jmp os_mouse_rightclick				; 0x0060
jmp os_input_wait				; 0x0063
jmp os_mouse_scale				; 0x0066
jmp os_wait_for_key				; 0x0069
jmp os_check_for_key				; 0x006C
jmp os_seed_random				; 0x006F
jmp os_get_random				; 0x0072
jmp os_bcd_to_int				; 0x0075
jmp os_long_int_negate				; 0x0078
jmp os_port_byte_out				; 0x007B
jmp os_port_byte_in				; 0x007E
jmp os_serial_port_enable			; 0x0081
jmp os_send_via_serial				; 0x0084
jmp os_get_via_serial				; 0x0087
jmp os_square_root				; 0x008A
jmp os_check_for_extkey				; 0x008D
jmp os_draw_circle				; 0x0090
jmp os_add_custom_icons				; 0x0093
jmp os_boot_start				; 0x0096
jmp os_load_file				; 0x0099
jmp os_get_file_list				; 0x009C
jmp os_write_file				; 0x009F
jmp os_file_exists				; 0x00A2
jmp os_create_file				; 0x00A5
jmp os_remove_file				; 0x00A8
jmp os_rename_file				; 0x00AB
jmp os_get_file_size				; 0x00AE
jmp os_file_selector				; 0x00B1
jmp os_list_dialog				; 0x00B4
jmp os_pause					; 0x00B7
jmp os_mouse_exists				; 0x00BA
jmp os_get_cursor_pos				; 0x00BD
jmp os_print_space				; 0x00C0
jmp os_print_string				; 0x00C3
jmp os_clear_screen				; 0x00C6
jmp os_print_horiz_line				; 0x00C9
jmp os_show_cursor				; 0x00CC
jmp os_hide_cursor				; 0x00CF
jmp os_draw_background				; 0x00D2
jmp os_print_newline				; 0x00D5
jmp os_dump_registers				; 0x00D8
jmp os_input_dialog				; 0x00DB
jmp os_dialog_box				; 0x00DE
jmp os_dump_string				; 0x00E1
jmp os_print_digit				; 0x00E4
jmp os_input_string				; 0x00E7
jmp os_print_char				; 0x00EA
jmp os_print_1hex				; 0x00ED
jmp os_print_2hex				; 0x00F0
jmp os_print_4hex				; 0x00F3
jmp os_set_config				; 0x00F6
jmp os_get_config				; 0x00F9

os_return:
	pushf
	pop word [gs:flags_tmp]

	cmp byte [gs:internal_call], 0
	jne .nested_call

	mov [gs:ret_ax], ax

	mov ax, fs
	mov ds, ax
	mov es, ax

	pop ax
	push fs
	push ax

	mov ax, [gs:ret_ax]

	push word [gs:flags_tmp]
	popf
	retf


.nested_call:
	push word [gs:flags_tmp]
	popf
	ret



internal_call			dw 0		; cancels os_return
ret_ax				dw 0
flags_tmp			dw 0


;os_return:
;	pushf
;	pop word [gs:flags_tmp]
;
;	cmp byte [gs:internal_call], 1
;	jge .internal_return
;	
;	mov word [gs:return_ax_tmp], ax
;		
;	mov ax, fs
;	mov ds, ax
;	mov es, ax
; 
;	pop ax
;	push 0x2000
;	push ax
;	
;	mov ax, [gs:return_ax_tmp]
;	
;	push word [gs:flags_tmp]
;	popf
;	
;	retf
;
;	.internal_return:
;		ret
;
;flags_tmp			dw 0
;internal_call			dw 0		; cancels os_return
;return_ax_tmp			dw 0

%INCLUDE 'constants/api.asm'
%INCLUDE 'constants/buffer.asm'
%INCLUDE 'constants/bootmsg.asm'
%INCLUDE 'constants/diskbuf.asm'
%INCLUDE 'constants/colours.asm'
%INCLUDE 'constants/config.asm'
%INCLUDE 'constants/defaults.asm'
%INCLUDE 'constants/osdata.asm'
%INCLUDE 'constants/keycode.asm'

%INCLUDE 'features/debug.asm'

%INCLUDE 'features/zkernel/boot.asm'
%INCLUDE 'features/zkernel/graphics.asm' 
%INCLUDE 'features/zkernel/memory.asm'
%INCLUDE 'features/zkernel/sound.asm'
%INCLUDE 'features/zkernel/screen.asm'
%INCLUDE 'features/zkernel/mouse.asm'
%INCLUDE 'features/zkernel/keyboard.asm'
%INCLUDE 'features/zkernel/math.asm'
%INCLUDE 'features/zkernel/ports.asm'
%INCLUDE 'features/zkernel/disk.asm'
%INCLUDE 'features/zkernel/misc.asm'
%INCLUDE 'features/string.asm'
%INCLUDE 'constants/menuicons.asm'
%INCLUDE 'features/zkernel/config.asm'

