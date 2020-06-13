; Pointers from extended kernel to regular kernel.

; Disk API calls
ptr_load_file			equ	0099h
ptr_get_file_list		equ	009Ch
ptr_write_file			equ	009Fh
ptr_file_exists			equ	00A2h
ptr_create_file			equ	00A5h
ptr_remove_file			equ	00A8h
ptr_rename_file			equ	00ABh
ptr_get_file_size		equ	00AEh

; Graphics API calls
ptr_text_mode			equ	0000h
ptr_graphics_mode		equ	0003h
ptr_set_pixel			equ	0006h
ptr_get_pixel			equ	0009h
ptr_draw_line			equ	000Ch
ptr_draw_rectangle		equ	000Fh
ptr_draw_polygon		equ	0012h
ptr_clear_graphics		equ	0015h
ptr_draw_border			equ	0033h
ptr_draw_horizontal_line	equ	0036h
ptr_draw_vertical_line		equ	0039h
ptr_draw_block			equ	003Fh
ptr_draw_circle			equ	0090h

; Memory API calls
ptr_memory_allocate		equ	0018h
ptr_memory_release		equ	001Bh
ptr_memory_free			equ	001Eh
ptr_memory_reset		equ	0021h
ptr_memory_read			equ	0024h
ptr_memory_write		equ	0027h

; Sound API calls

ptr_speaker_freq		equ	002Ah
ptr_speaker_tone		equ	002Dh
ptr_speaker_off			equ	0030h

; Mouse API calls
ptr_mouse_setup			equ	0042h
ptr_mouse_locate		equ	0045h
ptr_mouse_move			equ	0048h
ptr_mouse_show			equ	004Bh
ptr_mouse_hide			equ	004Eh
ptr_mouse_range			equ	0051h
ptr_mouse_wait			equ	0054h
ptr_mouse_anyclick		equ	0057h
ptr_mouse_leftclick		equ	005Ah
ptr_mouse_middleclick		equ	005Dh
ptr_mouse_rightclick		equ	0060h
ptr_input_wait			equ	0063h
ptr_mouse_scale			equ	0066h
ptr_mouse_exists		equ	00BAh

; Keyboard API calls
ptr_wait_for_key		equ	0069h
ptr_check_for_key		equ	006Ch
ptr_check_for_extkey		equ	008Dh

; Math API calls
ptr_seed_random			equ	006Fh
ptr_get_random			equ	0072h
ptr_bcd_to_int			equ	0075h
ptr_long_int_negate		equ	0078h
ptr_square_root			equ	008Ah

; Port API calls
ptr_port_byte_out		equ	007Bh
ptr_port_byte_in		equ	007Eh
ptr_serial_port_enable		equ	0081h
ptr_send_via_serial		equ	0084h
ptr_get_via_serial		equ	0087h

; Screen API calls
ptr_file_selector		equ	00B1h
ptr_list_dialog			equ	00B4h
ptr_move_cursor			equ	003Ch
ptr_get_cursor_pos		equ	00BDh
ptr_print_space			equ	00C0h
ptr_print_string		equ	0x00C3
ptr_clear_screen		equ	0x00C6
ptr_print_horiz_line		equ	0x00C9
ptr_show_cursor			equ	0x00CC
ptr_hide_cursor			equ	0x00CF
ptr_draw_background		equ	0x00D2
ptr_print_newline		equ	0x00D5
ptr_dump_registers		equ	0x00D8
ptr_input_dialog		equ	0x00DB
ptr_dialog_box			equ	0x00DE
ptr_dump_string			equ	0x00E1
ptr_print_digit			equ	0x00E4
ptr_input_string		equ	0x00E7
ptr_print_char			equ	0x00EA
ptr_print_1hex			equ	0x00ED
ptr_print_2hex			equ	0x00F0
ptr_print_4hex			equ	0x00F3

; Config API
ptr_set_config			equ	0x00F6
ptr_get_config			equ	0x00F9

; Other API calls
ptr_add_custom_icons		equ	0093h
ptr_pause			equ	00B7h

; Data

program_stack			equ	0xE000
aap_file			equ	0xF000

; API Pointers for kernel internals

os_text_mode			equ	0x00D5
os_graphics_mode		equ	0x00DA
os_set_pixel			equ	0x00DF
os_get_pixel			equ	0x00E4
os_draw_line			equ	0x00E9
os_draw_rectangle		equ	0x00EE
os_draw_polygon			equ	0x00F3
os_clear_graphics		equ	0x00F8
os_memory_allocate		equ	0x00FD
os_memory_release		equ	0x0102
os_memory_free			equ	0x0107
os_memory_reset			equ	0x010C
os_memory_read			equ	0x0111
os_memory_write			equ	0x0116
os_speaker_freq			equ	0x011B
os_speaker_tone			equ	0x0120
os_speaker_off			equ	0x0125
os_draw_border			equ 	0x012A
os_draw_horizontal_line		equ 	0x012F
os_draw_vertical_line		equ 	0x0134
os_move_cursor			equ	0x0139
os_draw_block			equ	0x013E
os_mouse_setup			equ	0x0143
os_mouse_locate			equ	0x0148
os_mouse_move			equ	0x014D
os_mouse_show			equ	0x0152
os_mouse_hide			equ	0x0157
os_mouse_range			equ	0x015C
os_mouse_wait			equ	0x0161
os_mouse_anyclick		equ	0x0166
os_mouse_leftclick		equ	0x016B
os_mouse_middleclick		equ	0x0170
os_mouse_rightclick		equ	0x0175
os_input_wait			equ	0x017A
os_mouse_scale			equ	0x017F
os_wait_for_key			equ	0x0184
os_check_for_key		equ	0x0189
os_seed_random			equ	0x018E
os_get_random			equ	0x0193
os_bcd_to_int			equ	0x0198
os_long_int_negate		equ	0x019D
os_port_byte_out		equ	0x01A2
os_port_byte_in			equ	0x01A7
os_serial_port_enable		equ	0x01AC
os_send_via_serial		equ	0x01B1
os_get_via_serial		equ	0x01B6
os_square_root			equ	0x01BB
os_check_for_extkey		equ	0x01C0
os_draw_circle			equ	0x01C5
os_add_custom_icons		equ	0x01CA
os_load_file			equ	0x01CF
os_get_file_list		equ	0x01D4
os_write_file			equ	0x01D9
os_file_exists			equ	0x01DE
os_create_file			equ	0x01E3
os_remove_file			equ	0x01E8
os_rename_file			equ	0x01ED
os_get_file_size		equ	0x01F2
os_file_selector		equ	0x01F7
os_list_dialog			equ	0x01FC
os_pause			equ	0x0201
os_mouse_exists			equ	0x0206
os_get_cursor_pos		equ	0x020B
os_print_space			equ	0x0210
os_print_string			equ	0x0215
os_clear_screen			equ	0x021A
os_print_horiz_line		equ	0x021F
os_show_cursor			equ	0x0224
os_hide_cursor			equ	0x0229
os_draw_background		equ	0x022E
os_print_newline		equ	0x0233
os_dump_registers		equ	0x0238
os_input_dialog			equ	0x023D
os_dialog_box			equ	0x0242
os_dump_string			equ	0x0247
os_print_digit			equ	0x024C
os_input_string			equ	0x0251
os_print_char			equ	0x0256
os_print_1hex			equ	0x025B
os_print_2hex			equ	0x0260
os_print_4hex			equ	0x0265

