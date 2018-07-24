; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; This is loaded from the drive by BOOTLOAD.BIN, as KERNEL.BIN.
; First we have the system call vectors, which start at a static point
; for programs to use. Following that is the main kernel code and
; then additional system call code is included.
; ==================================================================


	BITS 16
	
	%INCLUDE 'constants/bootmsg.asm'
	%INCLUDE 'constants/buffer.asm'
	%INCLUDE 'constants/config.asm'
	%INCLUDE 'constants/colours.asm'
	%INCLUDE 'constants/defaults.asm'
	%INCLUDE 'constants/osdata.asm'
	
	
	
%INCLUDE 'features/debug.asm'

	disk_buffer	equ	24576

; ------------------------------------------------------------------
; OS CALL VECTORS -- Static locations for system call vectors
; Note: these cannot be moved, or it'll break the calls!

; The comments show exact locations of instructions in this section,
; and are used in programs/mikedev.inc so that an external program can
; use a MikeOS system call without having to know its exact position
; in the kernel source code...

os_call_vectors:
	jmp os_main			; 0x0000 -- Called from bootloader
	jmp os_print_string		; 0x0003
	jmp os_move_cursor		; 0x0006 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_clear_screen		; 0x0009
	jmp os_print_horiz_line		; 0x000C
	jmp os_print_newline		; 0x000F
	jmp os_wait_for_key		; 0x0012 --- Moved to zkernel, redirects for binary compatibility with MikeOS--- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_check_for_key		; 0x0015 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_int_to_string		; 0x0018
	jmp os_speaker_tone		; 0x001B --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_speaker_off		; 0x001E --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_load_file		; 0x0021
	jmp os_pause			; 0x0024
	jmp os_fatal_error		; 0x0027
	jmp os_draw_background		; 0x002A
	jmp os_string_length		; 0x002D
	jmp os_string_uppercase		; 0x0030
	jmp os_string_lowercase		; 0x0033
	jmp os_input_string		; 0x0036
	jmp os_string_copy		; 0x0039
	jmp os_dialog_box		; 0x003C
	jmp os_string_join		; 0x003F
	jmp os_get_file_list		; 0x0042
	jmp os_string_compare		; 0x0045
	jmp os_string_chomp		; 0x0048
	jmp os_string_strip		; 0x004B
	jmp os_string_truncate		; 0x004E
	jmp os_bcd_to_int		; 0x0051 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_get_time_string		; 0x0054
	jmp os_get_api_version		; 0x0057
	jmp os_file_selector		; 0x005A
	jmp os_get_date_string		; 0x005D
	jmp os_send_via_serial		; 0x0060 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_get_via_serial		; 0x0063 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_find_char_in_string	; 0x0066
	jmp os_get_cursor_pos		; 0x0069
	jmp os_print_space		; 0x006C
	jmp os_dump_string		; 0x006F
	jmp os_print_digit		; 0x0072
	jmp os_print_1hex		; 0x0075
	jmp os_print_2hex		; 0x0078
	jmp os_print_4hex		; 0x007B
	jmp os_long_int_to_string	; 0x007E
	jmp os_long_int_negate		; 0x0081 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_set_time_fmt		; 0x0084
	jmp os_set_date_fmt		; 0x0087
	jmp os_show_cursor		; 0x008A
	jmp os_hide_cursor		; 0x008D
	jmp os_dump_registers		; 0x0090
	jmp os_string_strincmp		; 0x0093
	jmp os_write_file		; 0x0096
	jmp os_file_exists		; 0x0099
	jmp os_create_file		; 0x009C
	jmp os_remove_file		; 0x009F
	jmp os_rename_file		; 0x00A2
	jmp os_get_file_size		; 0x00A5
	jmp os_input_dialog		; 0x00A8
	jmp os_list_dialog		; 0x00AB
	jmp os_string_reverse		; 0x00AE
	jmp os_string_to_int		; 0x00B1
	jmp os_draw_block		; 0x00B4 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_get_random		; 0x00B7 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_string_charchange	; 0x00BA
	jmp os_serial_port_enable	; 0x00BD --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_sint_to_string		; 0x00C0
	jmp os_string_parse		; 0x00C3
	jmp os_run_basic		; 0x00C6
	jmp os_port_byte_out		; 0x00C9 --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_port_byte_in		; 0x00CC --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_string_tokenize		; 0x00CF
	jmp os_speaker_freq		; 0x00D2
	
; Extended Call Vectors
; Intersegmental kernel calls
%INCLUDE 'zkernel.inc'

	jmp 0x1000:ptr_text_mode		; 0x00D5
	jmp 0x1000:ptr_graphics_mode		; 0x00DA
	jmp 0x1000:ptr_set_pixel		; 0x00DF
	jmp 0x1000:ptr_get_pixel		; 0x00E4
	jmp 0x1000:ptr_draw_line		; 0x00E9
	jmp 0x1000:ptr_draw_rectangle		; 0x00EE
	jmp 0x1000:ptr_draw_polygon		; 0x00F3
	jmp 0x1000:ptr_clear_graphics		; 0x00F8
	jmp 0x1000:ptr_memory_allocate		; 0x00FD
	jmp 0x1000:ptr_memory_release		; 0x0102
	jmp 0x1000:ptr_memory_free		; 0x0107
	jmp 0x1000:ptr_memory_reset		; 0x010C
	jmp 0x1000:ptr_memory_read		; 0x0111
	jmp 0x1000:ptr_memory_write		; 0x0116
	jmp 0x1000:ptr_speaker_freq		; 0x011B
	jmp 0x1000:ptr_speaker_tone		; 0x0120
	jmp 0x1000:ptr_speaker_off		; 0x0125
	jmp 0x1000:ptr_draw_border		; 0x012A
	jmp 0x1000:ptr_draw_horizontal_line	; 0x012F
	jmp 0x1000:ptr_draw_vertical_line	; 0x0134
	jmp 0x1000:ptr_move_cursor		; 0x0139
	jmp 0x1000:ptr_draw_block		; 0x013E
	jmp 0x1000:ptr_mouse_setup		; 0x0143
	jmp 0x1000:ptr_mouse_locate		; 0x0148
	jmp 0x1000:ptr_mouse_move		; 0x014D
	jmp 0x1000:ptr_mouse_show		; 0x0152
	jmp 0x1000:ptr_mouse_hide		; 0x0157
	jmp 0x1000:ptr_mouse_range		; 0x015C
	jmp 0x1000:ptr_mouse_wait		; 0x0161
	jmp 0x1000:ptr_mouse_anyclick		; 0x0166
	jmp 0x1000:ptr_mouse_leftclick		; 0x016B
	jmp 0x1000:ptr_mouse_middleclick	; 0x0170
	jmp 0x1000:ptr_mouse_rightclick		; 0x0175
	jmp 0x1000:ptr_input_wait		; 0x017A
	jmp 0x1000:ptr_mouse_scale		; 0x017F
	jmp 0x1000:ptr_wait_for_key		; 0x0184
	jmp 0x1000:ptr_check_for_key		; 0x0189
	jmp 0x1000:ptr_seed_random		; 0x018E
	jmp 0x1000:ptr_get_random		; 0x0193
	jmp 0x1000:ptr_bcd_to_int		; 0x0198
	jmp 0x1000:ptr_long_int_negate		; 0x019D
	jmp 0x1000:ptr_port_byte_out		; 0x01A2
	jmp 0x1000:ptr_port_byte_in		; 0x01A7
	jmp 0x1000:ptr_serial_port_enable	; 0x01AC
	jmp 0x1000:ptr_send_via_serial		; 0x01B1
	jmp 0x1000:ptr_get_via_serial		; 0x01B6
	jmp 0x1000:ptr_square_root		; 0x01BB
	jmp 0x1000:ptr_check_for_extkey		; 0x01C0
	jmp 0x1000:ptr_draw_circle		; 0x01C5
	jmp 0x1000:ptr_add_custom_icons		; 0x01CA
	jmp 0x1000:ptr_load_file		; 0x01CF
	jmp 0x1000:ptr_get_file_list		; 0x01D4
	jmp 0x1000:ptr_write_file		; 0x01D9
	jmp 0x1000:ptr_file_exists		; 0x01DE
	jmp 0x1000:ptr_create_file		; 0x01E3
	jmp 0x1000:ptr_remove_file		; 0x01E8
	jmp 0x1000:ptr_rename_file		; 0x01ED
	jmp 0x1000:ptr_get_file_size		; 0x01F2
	jmp 0x1000:ptr_file_selector		; 0x01F7
	jmp 0x1000:ptr_list_dialog		; 0x01FC
	jmp 0x1000:ptr_pause			; 0x0201
	jmp 0x1000:ptr_mouse_exists		; 0x0206
	jmp 0x1000:ptr_get_cursor_pos		; 0x020B
	jmp 0x1000:ptr_print_space		; 0x0210
	jmp 0x1000:ptr_print_string		; 0x0215
	jmp 0x1000:ptr_clear_screen		; 0x021A
	jmp 0x1000:ptr_print_horiz_line		; 0x021F
	jmp 0x1000:ptr_show_cursor		; 0x0224
	jmp 0x1000:ptr_hide_cursor		; 0x0229
	jmp 0x1000:ptr_draw_background		; 0x022E
	jmp 0x1000:ptr_print_newline		; 0x0233
	jmp 0x1000:ptr_dump_registers		; 0x0238
	jmp 0x1000:ptr_input_dialog		; 0x023D
	jmp 0x1000:ptr_dialog_box		; 0x0242
	jmp 0x1000:ptr_dump_string		; 0x0247
	jmp 0x1000:ptr_print_digit		; 0x024C
	jmp 0x1000:ptr_input_string		; 0x0251
	jmp 0x1000:ptr_print_char		; 0x0256
	jmp 0x1000:ptr_print_1hex		; 0x025B
	jmp 0x1000:ptr_print_2hex		; 0x0260
	jmp 0x1000:ptr_print_4hex		; 0x0265


	


; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:
	; Install the mouse driver
	BOOTMSG 'Installing Mouse Driver...'
	call os_mouse_setup
	BOOTOK
	
	call os_mouse_exists

	; Define the range of cursor movement
	BOOTMSG 'Setting Mouse Parameters...'
	mov ax, 0
	mov bx, 0
	mov cx, [CFG_SCREEN_WIDTH]
	mov dx, [CFG_SCREEN_HEIGHT]
	dec cx
	dec dx
	call os_mouse_range
	
	mov dh, 3
	mov dl, 2
	call os_mouse_scale
	BOOTOK
	
	; Let's see if there's a file called AUTORUN.BIN and execute
	; it if so, before going to the program launcher menu
	
	BOOTMSG 'Checking for autorun binary...'
	mov ax, autorun_bin_file_name
	call os_file_exists
	jc no_autorun_bin		; Skip next three lines if AUTORUN.BIN doesn't exist
	BOOTOK

	mov cx, 32768			; Otherwise load the program into RAM...
	call os_load_file
	jnc execute_bin_program		; ...and move on to the executing part
	
	jmp start_shell


	; Or perhaps there's an AUTORUN.BAS file?

no_autorun_bin:
	BOOTFAIL
	BOOTMSG 'Checking for autorun BASIC program...'
	mov ax, autorun_bas_file_name
	call os_file_exists
	jc no_autorun_bas		; Skip next section if AUTORUN.BAS doesn't exist
	
	BOOTOK
	
	mov cx, 32768			; Otherwise load the program into RAM
	call os_load_file

	mov ax, 32768
	call os_run_basic		; Run the kernel's BASIC interpreter

	jmp start_shell			; And start the UI shell when BASIC ends
	
no_autorun_bas:
	BOOTFAIL
	jmp start_shell

	
load_kernel_extentions:	

	mov ax, zkernel_filename
	mov cx, 32768
	call os_load_file
	jc missing_important_file
	
	push es
	push 0x1000
	pop es
	
	mov si, 32768
	mov di, 0
	mov cx, bx
	rep movsb
	
	mov ax, 0000h
	mov es, ax
	
	mov word [es:0014h], 0x2000
	mov word [es:0016h], ctrl_break
	
	mov word [es:006Ch], 0x2000 
	mov word [es:006Eh], ctrl_break
	
	pop es
	
	call os_add_custom_icons

	ret

ctrl_break:
	cli
	pop ax
	pop ax
	push 2000h
	push load_menu
	sti
	iret
	
missing_important_file:
	mov si, ax
	mov di, missing_file_name
	call os_string_copy
	
	mov ax, missing_file_string
	call os_fatal_error

	; And now data for the above code...

	kern_file_name		db OS_KERNEL_FILENAME, 0
	zkernel_filename	db OS_KERNEL_EXT_FILENAME, 0
	autorun_bin_file_name	db OS_AUTORUN_BIN_FILE, 0
	autorun_bas_file_name	db OS_AUTORUN_BAS_FILE, 0
	background_file_name	db OS_BACKGROUND_FILE, 0
	menu_file_name		db OS_MENU_DATA_FILE, 0

	missing_file_string	db OS_MISSING_FILE_MSG, 0
	missing_file_name	__FILENAME_BUFFER__
	

; ------------------------------------------------------------------
; FEATURES -- Code to pull into the kernel
	%INCLUDE "features/cli.asm"
	%INCLUDE "features/misc.asm"
	%INCLUDE "features/shell.asm"
	%INCLUDE "features/string.asm"
	%INCLUDE "features/basic.asm"
	
	BOOT_DATA_BLOCK
	
	; Configuration section
	times CROSSOVER_BUFFER-($-$$) db 0
	times CONFIG_START-($-$$) db 0
	dw DEF_DLG_OUTER_COLOUR
	dw DEF_DLG_INNER_COLOUR
	dw DEF_DLG_SELECT_COLOUR
	dw DEF_TITLEBAR_COLOUR
	dw DEF_24H_TIME
	dw DEF_DATE_FMT
	dw DEF_DATE_SEPARATOR
	dw DEF_SCREEN_HEIGHT
	dw DEF_SCREEN_WIDTH


; ==================================================================
; END OF KERNEL
; ==================================================================

