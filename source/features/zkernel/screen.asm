%define NORMAL_CURSOR 0
%define BLOCK_CURSOR 1

; ------------------------------------------------------------------
; os_get_cursor_pos -- Return position of text cursor
; OUT: DH, DL = row, column

os_get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h				; BIOS interrupt to get cursor position

	mov bp, sp
	mov [bp + 10], dx

	popa
	jmp os_return



; ------------------------------------------------------------------
; os_print_space -- Print a space to the screen
; IN/OUT: Nothing

os_print_space:
	pusha

	mov ah, 0Eh			; BIOS teletype function
	mov al, 20h			; Space is character 20h
	int 10h

	popa
	jmp os_return



; ------------------------------------------------------------------
; os_draw_border -- draw a single character border
; BL = colour, CH = start row, CL = start column, DH = end row, DL = end column

os_draw_border:
	API_START
	API_SEGMENTS

	mov [.start_row], ch
	mov [.start_column], cl
	mov [.end_row], dh
	mov [.end_column], dl

	mov al, [.end_column]
	sub al, [.start_column]
	dec al
	mov [.width], al
	
	mov al, [.end_row]
	sub al, [.start_row]
	dec al
	mov [.height], al
	
	mov ah, 09h
	mov bh, 0
	mov cx, 1

	mov dh, [.start_row]
	mov dl, [.start_column]
	call os_move_cursor

	mov al, [.character_set + 0]
	int 10h
	
	mov dh, [.start_row]
	mov dl, [.end_column]
	call os_move_cursor
	
	mov al, [.character_set + 1]
	int 10h
	
	mov dh, [.end_row]
	mov dl, [.start_column]
	call os_move_cursor
	
	mov al, [.character_set + 2]
	int 10h
	
	mov dh, [.end_row]
	mov dl, [.end_column]
	call os_move_cursor
	
	mov al, [.character_set + 3]
	int 10h
	
	mov dh, [.start_row]
	mov dl, [.start_column]
	inc dl
	call os_move_cursor
	
	mov al, [.character_set + 4]
	mov cx, 0
	mov cl, [.width]
	int 10h
	
	mov dh, [.end_row]
	call os_move_cursor
	int 10h
	
	mov al, [.character_set + 5]
	mov cx, 1
	mov dh, [.start_row]
	inc dh
	
.sides_loop:
	mov dl, [.start_column]
	call os_move_cursor
	int 10h
	
	mov dl, [.end_column]
	call os_move_cursor
	int 10h
	
	inc dh
	dec byte [.height]
	cmp byte [.height], 0
	jne .sides_loop
	
	API_END
	
	
.start_column				db 0
.end_column				db 0
.start_row				db 0
.end_row				db 0
.height					db 0
.width					db 0

.character_set				db 218, 191, 192, 217, 196, 179



; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = width, BL = colour, DH = start row, DL = start column

os_draw_horizontal_line:
	API_START
	
	mov cx, 0
	mov cl, bh
	
	call os_move_cursor
	
	mov ah, 09h
	mov al, 196
	mov bh, 0
	int 10h

	API_END


; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = length, BL = colour, DH = start row, DL = start column

os_draw_vertical_line:
	API_START
	
	mov cx, 0
	mov cl, bh
	
	mov ah, 09h
	mov al, 179
	mov bh, 0
	
.lineloop:
	push cx
	
	call os_move_cursor
	
	mov cx, 1
	int 10h
	
	inc dh
	
	pop cx
	
	loop .lineloop

	API_END
	


; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	jmp os_return



; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

os_draw_block:
	API_START
	API_SEGMENTS
	
	; find starting byte
	
	mov [.colour], bl
	mov byte [.character], 32
	
	mov [.rows], di
	
	; find starting byte
	
	mov ax, 0			; start with row * 80
	mov al, dh
	mov bx, ax			; use bit shifts for fast multiplication
	shl ax, 4			; 2^4 = 16 
	shl bx, 6			; 2^6 = 64
	add ax, bx			; 16 + 64 = 80
	mov bx, 0			; add column
	mov bl, dl
	add ax, bx
	shl ax, 1			; each text mode character takes two bytes (colour and value)
	mov di, ax
	
	mov [.width], si		; store the width, this will need to be reset
	
	mov bx, 80			; find amount to increment by to get to next line ((screen width - block width) * 2)
	sub bx, si
	shl bx, 1
	mov si, bx
	
	mov ax, 0			; find number of rows to do (finish Y - start Y)
	mov al, dh
	sub [.rows], ax
	
	mov ax, 0xB800			; set the text segment
	mov es, ax
	
	mov ax, [.character]		; get the value to write
	
.write_data:
	mov cx, [.width]		; get line width
	rep stosw			; write character value
	
	add di, si			; move to next line
	
	cmp word [.rows], 0		; check if we have processed every row
	dec word [.rows]
	
	jne .write_data			; if not continue
	
	API_END


	.width				dw 0
	.rows				dw 0
	.character			db 0
	.colour				db 0
	


; ------------------------------------------------------------------
; os_file_selector -- Show a file selection dialog
; IN: Nothing; OUT: FS:AX = location of filename string (or carry set if Esc pressed)

os_file_selector:
	API_START
	API_SEGMENTS

	; Nasty hack to get the disk API to output to the system segment. :(
	; Messing with FS is otherwise discouraged.
	push fs
	push gs
	pop fs

	mov ax, .buffer			; Get comma-separated list of filenames
	call os_get_file_list

	pop fs
	
	mov ax, .buffer			; Show those filenames in a list dialog box
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog
	jc .esc_pressed

	dec ax				; Result from os_list_box starts from 1, but
					; for our file list offset we want to start from 0

	mov cx, ax
	mov bx, 0

	mov si, .buffer			; Get our filename from the list
.loop1:
	cmp bx, cx
	je .got_our_filename
	lodsb
	cmp al, ','
	je .comma_found
	jmp .loop1

.comma_found:
	inc bx
	jmp .loop1


.got_our_filename:
	; Copy filename into the crossover buffer.
	; This should ensure unsegmented programs can use the list.
	mov ax, gs

	push fs
	pop es

	mov di, CROSSOVER_BUFFER
.loop2:
	lodsb
	cmp al, ','
	je .finished_copying
	cmp al, 0
	je .finished_copying
	mov [es:di], al
	inc di
	jmp .loop2

.finished_copying:
	mov byte [es:di], 0		; Zero terminate the filename string

	mov ax, CROSSOVER_BUFFER
	API_RETURN_NC ax


.esc_pressed:				; Set carry flag if Escape was pressed
	mov byte [fs:CROSSOVER_BUFFER], 0
	API_END_SC
	


	.buffer		times 1024 db 0

	.help_msg1	db 'Please select a file using the cursor', 0
	.help_msg2	db 'keys from the list below...', 0



; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: ES:AX = comma-separated list of strings to show (zero-terminated),
;     ES:BX = first help string, ES:CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog:
	API_START

	push gs
	pop ds
	
.prepare_list:
	mov [.list_string], ax
	mov [.help1], bx
	mov [.help2], cx

	call os_hide_cursor


	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	mov byte al, [es:si]
	inc si
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	mov bl, [FS:CFG_DLG_OUTER_COLOUR]
	mov dl, 20			; Start X position
	mov dh, 2			; Start Y position
	mov si, 40			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov dl, 21			; Show first line of help text...
	mov dh, 3
	call os_move_cursor

	push es
	pop ds
	
	; Show the help strings at the top of the dialog box.
	mov si, [gs:.help1]
	call os_print_string

	inc dh
	call os_move_cursor

	mov si, [gs:.help2]
	call os_print_string

	push gs
	pop ds

	mov si, [.list_string]

	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 25			; Set up starting position for selector
	mov dh, 7

	call os_move_cursor

.more_select:
	pusha
	mov bl, [FS:CFG_DLG_INNER_COLOUR]
	mov dl, 21
	mov dh, 6
	mov si, 38
	mov di, 22
	call os_draw_block
	popa

.change_select:
	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list
	
.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp ah, 49h
	je .page_up
	cmp ah, 51h
	je .page_down
	cmp ah, 47h
	je .go_top
	cmp ah, 4Fh
	je .go_bottom
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	jmp .more_select		; If not, wait for another key


.go_up:
	cmp dh, 7			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .change_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .change_select

.page_up:
	cmp dh, 11			; check if we have to scroll
	jle .scroll_up
	
	call .draw_white_bar		; erase current entry

	sub dh, 5			; more cursor up 5 places
	
	jmp .change_select
	
.scroll_up:
	mov cl, 12			; find the number of places to scroll
	sub cl, dh
	
	cmp cl, [.skip_num]		; check if there are enough
	jg .go_top			; if not just jump to the top
	
	sub byte [.skip_num], cl	; if so scroll required amount
	
	call .draw_white_bar
		
	mov dh, 7			; move cursor to top
	jmp .more_select
	
.go_top:
	cmp dh, 7
	je .at_top
	
	mov byte [.skip_num], 0
	
	call .draw_white_bar
	
	mov dh, 7
	jmp .more_select

.at_top:
	cmp byte [.skip_num], 0
	je .another_key
	
	mov byte [.skip_num], 0
	
	jmp .more_select
	
.page_down:
	cmp dh, 16
	jge .scroll_down
	
	mov cl, dh
	sub cl, 6
	add cl, [.skip_num]
	add cl, 5
	cmp cl, [.num_of_entries]
	jg .go_bottom
	
	call .draw_white_bar
		
	add dh, 5
	
	jmp .change_select
	
.scroll_down:
	mov ch, dh			; Find the number of entries to scroll
	sub ch, 15
	
	mov cl, dh			; New entry number (screen row - 2 + previous offscreen items + scroll amount)
	sub cl, 2
	add cl, [.skip_num]
	add cl, ch
	
	cmp cl, [.num_of_entries]	; Would this amount exceed the number of items in the list?
	jg .go_bottom			; If so jump to the last.
	
	call .draw_white_bar
	
	add byte [.skip_num], ch	; Otherwise scroll the list down and set the last item selected
	mov dh, 20
	
	jmp .more_select
	
.go_bottom:
	cmp byte [.num_of_entries], 14
	jle .no_skip
	
	mov cl, [.num_of_entries]
	sub cl, 14
	cmp cl, [.skip_num]
	je .at_bottom
	
.not_at_bottom:
	call .draw_white_bar
	
	mov cl, [.num_of_entries]
	sub cl, 14
	mov [.skip_num], cl
	mov dh, 20
	
	jmp .more_select
	
.at_bottom:
	cmp dh, 20
	jne .not_at_bottom
	
	jmp .another_key

.no_skip:
	cmp dh, 20
	je .another_key
	
	mov dh, [.num_of_entries]
	add dh, 6
	
	jmp .more_select

.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .another_key			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	API_RETURN_NC ax



.esc_pressed:
	mov ax, 1
	call os_pause
	call os_check_for_key
	call os_check_for_key

	call os_show_cursor
	API_END_SC



.draw_list:
	pusha

	mov dl, 23			; Get into position for option list text
	mov dh, 7
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	mov al, [es:si]
	inc si
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	mov al, [es:si]			; Get next character in file name, increment pointer
	inc si

	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 23			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 14			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, [FS:CFG_DLG_SELECT_COLOUR]
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, [FS:CFG_DLG_INNER_COLOUR]	
	mov al, ' '
	int 10h

	popa
	ret

	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0
	.help1			dw 0
	.help2			dw 0



; ------------------------------------------------------------------
os_get_text_block:
	; CH = start row, CL = start column, DH = end row, DL = end column, ES:SI = address
	API_START
	
	xchg cx, dx
.read_characters:
	inc dl
	call os_move_cursor
	
	cmp dl, cl
	jg .next_line
	
	mov ah, 08h
	mov bh, 0
	int 10h
	
	mov [es:si], ax
	add si, 2
	
	jmp .read_characters
	
.next_line:
	mov dl, 0
	inc dh
	call os_move_cursor
	
	cmp dh, ch
	jle .read_characters
	
	API_END



; ------------------------------------------------------------------
os_put_text_block:
	; CH = start row, CL = start column, DH = end row, DL = end column, ES:SI = address
	
	API_START
	xchg cx, dx

.write_characters:
	inc dl
	call os_move_cursor
	
	cmp dl, cl
	jg .next_line
	
	mov ax, [es:si]
	add si, 2
	mov bl, ah
	
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
	
	jmp .write_characters
	
.next_line:
	mov dl, 0
	inc dh
	call os_move_cursor
	
	cmp dh, ch
	jle .write_characters
	
	API_END



; ------------------------------------------------------------------
os_set_text_block:
	; AH = colour, AL = character, CH = start row, CL = start column
	; DH = end row, DL = end column
	
	API_START
	
	mov bx, 0
	mov bl, dl
	sub bl, cl
	mov [.length], bx
	
	xchg cx, dx
	
	mov [.colour], ah
	mov [.char], al
	
.write_lines:
	inc dh
	call os_move_cursor
	
	cmp dh, ch
	jle .finish
	
	mov ah, 09h
	mov al, [.char]
	mov bh, 0
	mov bl, [.colour]
	mov cx, [.length]
	int 10h

	jmp .write_lines
	
.finish:
	API_END
	
	.length					dw 0
	.char					db 0
	.colour					db 0



; ==== New contents...
; ***
; ***
; ***

os_print_string:
	pusha

	mov ah, 0x0E			; int 10h teletype function
	mov bh, 0

.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string

	int 0x10			; Otherwise, print it

	jmp .repeat			; And move on to next char

.done:
	popa
	jmp os_return


; ------------------------------------------------------------------
; os_clear_screen -- Clears the screen to background
; IN/OUT: Nothing (registers preserved)

os_clear_screen:
	API_START

	mov dx, 0			; Position cursor at top-left
	call os_move_cursor

	mov ah, 6			; Scroll full-screen
	mov al, 0			; Normal white on black
	mov bh, 7			;
	mov cx, 0			; Top-left
	mov dh, 24			; Bottom-right
	mov dl, 79
	int 10h

	API_END



; ------------------------------------------------------------------
; os_print_horiz_line -- Draw a horizontal line on the screen
; IN: AX = line type (1 for double (-), otherwise single (=))
; OUT: Nothing (registers preserved)

os_print_horiz_line:
	pusha

	mov cx, ax			; Store line type param
	mov al, 196			; Default is single-line code

	cmp cx, 1			; Was double-line specified in AX?
	jne .ready
	mov al, 205			; If so, here's the code

.ready:
	mov cx, 0			; Counter
	mov ah, 0Eh			; BIOS output char routine

.restart:
	int 10h
	inc cx
	cmp cx, 80			; Drawn 80 chars yet?
	je .done
	jmp .restart

.done:
	popa
	jmp os_return



; ------------------------------------------------------------------
; os_show_cursor -- Turns on cursor in text mode
; IN/OUT: Nothing

os_show_cursor:
	pusha

	mov ch, 6
	mov cl, 7
	mov ah, 1
	mov al, 3
	int 10h

	popa
	jmp os_return



; ------------------------------------------------------------------
; os_hide_cursor -- Turns off cursor in text mode
; IN/OUT: Nothing

os_hide_cursor:
	pusha

	mov ch, 32
	mov ah, 1
	mov al, 3			; Must be video mode for buggy BIOSes!
	int 10h

	popa
	jmp os_return


; ------------------------------------------------------------------

os_cursor_mode:
	pusha

	cmp al, NORMAL_CURSOR
	je .normal

	cmp al, BLOCK_CURSOR
	je .block

	jmp .done

.normal:
	mov ah, 1
	mov cx, 0x0607
	int 0x10
	jmp .done

.block: 
	mov ah, 1
	mov cx, 0x0007
	int 0x10
	jmp .done

.done:
	popa
	jmp os_return


; ------------------------------------------------------------------
; os_draw_background -- Clear screen with white top and bottom bars
; containing text, and a coloured middle section.
; IN: AX/BX = top/bottom string locations, CX = colour

os_draw_background:
	API_START

	push ax				; Store params to pop out later
	push bx
	push cx

	mov dl, 0
	mov dh, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, [FS:CFG_SCREEN_WIDTH]
	mov bl, [FS:CFG_TITLEBAR_COLOUR]
	mov al, ' '
	int 10h

	mov dh, 1
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw colour section
	mov al, [FS:CFG_SCREEN_HEIGHT]
	mov cx, 1840
	pop bx				; Get colour param (originally in CX)
	mov bh, 0
	mov al, ' '
	int 10h

	mov dh, [FS:CFG_SCREEN_HEIGHT]
	dec dh
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at bottom
	mov bh, 0
	mov cx, [FS:CFG_SCREEN_WIDTH]
	mov bl, [FS:CFG_TITLEBAR_COLOUR]
	mov al, ' '
	int 10h

	mov dh, [FS:CFG_SCREEN_HEIGHT]
	dec dh
	mov dl, 1
	call os_move_cursor
	pop bx				; Get bottom string param
	mov si, bx
	call os_print_string

	mov dh, 0
	mov dl, 1
	call os_move_cursor
	pop ax				; Get top string param
	mov si, ax
	call os_print_string

	mov dh, 1			; Ready for app text
	mov dl, 0
	call os_move_cursor

	API_END



; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: Nothing (registers preserved)

os_print_newline:
	pusha

	mov ah, 0Eh			; BIOS output char code

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	jmp os_return


; ------------------------------------------------------------------
; os_dump_registers -- Displays register contents in hex on the screen
; IN/OUT: AX/BX/CX/DX = registers to show

os_dump_registers:
	API_START

	push gs
	pop ds

	call os_print_newline

	push di
	push si
	push dx
	push cx
	push bx

	mov si, .ax_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .bx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .cx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .dx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .si_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .di_string
	call os_print_string
	call os_print_4hex

	call os_print_newline

	API_END

	.ax_string		db 'AX:', 0
	.bx_string		db ' BX:', 0
	.cx_string		db ' CX:', 0
	.dx_string		db ' DX:', 0
	.si_string		db ' SI:', 0
	.di_string		db ' DI:', 0


; ------------------------------------------------------------------
; os_input_dialog -- Get text string from user via a dialog box
; IN: AX = string location, BX = message to show; OUT: AX = string location

os_input_dialog:
	API_START

	push ax				; Save string location
	push bx				; Save message to show


	mov dh, 10			; First, draw red background box
	mov dl, 12

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, [FS:CFG_DLG_OUTER_COLOUR]
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov dl, 14
	mov dh, 11
	call os_move_cursor


	pop bx				; Get message back and display it
	mov si, bx
	call os_print_string

	mov dl, 14
	mov dh, 13
	call os_move_cursor


	pop ax				; Get input string back
	mov bx, 50
	call os_input_string


	API_END


; ------------------------------------------------------------------
; os_dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: AX, BX, CX = string locations (set registers to 0 for no display)
; IN: DX = 0 for single 'OK' dialog, 1 for two-button 'OK' and 'Cancel'
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

os_dialog_box:
	API_START
	
	push fs
	pop es

	call os_hide_cursor

	pusha

	; Draw the outer outline of the box
	mov bl, [FS:CFG_DLG_OUTER_COLOUR]
	mov dl, 19			; Start X position
	mov dh, 9			; Start Y position
	mov si, 42			; Width
	mov di, 16			; Finish Y position
	call os_draw_block

	; Draw the outer outline of the box
	mov bl, [FS:CFG_DLG_INNER_COLOUR]
	mov dl, 20			; Start X position
	mov dh, 10			; Start Y position
	mov si, 40			; Width
	mov di, 13			; Finish Y position
	call os_draw_block

	popa

	; Print the given information strings
	mov bp, (10 << 8) | 20
	mov di, 40
	mov si, ax
	call .print_string

	mov bp, (11 << 8) | 20
	mov si, bx
	call .print_string

	mov bp, (12 << 8) | 20
	mov si, cx
	call .print_string

	push gs
	pop es

	mov bx, 0
	call .draw_buttons

.mainloop:
	call os_wait_for_key

	cmp ax, LEFT_KEY
	je .go_left

	cmp ax, RIGHT_KEY
	je .go_right

	cmp al, 13
	je .select_option

	jmp .mainloop


.go_left:
	; Is it a single option dialog box?
	cmp dx, 0
	je .mainloop

	; Is the left most option already selected?
	cmp bx, 0
	je .mainloop

	; Otherwise change the selection and redraw the dialog box.
	dec bx
	call .draw_buttons

	jmp .mainloop


.go_right:
	cmp dx, 0
	je .mainloop

	cmp bx, dx
	jge .mainloop

	inc bx
	call .draw_buttons

	jmp .mainloop


.select_option:
	mov ax, bx
	API_RETURN ax


.draw_buttons:
	push ax
	push bx
	push cx

	cmp dx, 0
	je .single_button

	mov cx, bx

	mov ax, .okay_text
	mov bp, (14 << 8) | 27
	cmp cx, 0
	sete bl
	call .draw_button

	mov ax, .cancel_text
	mov bp, (14 << 8) | 44
	cmp cx, 1
	sete bl
	call .draw_button

.finished_buttons:
	pop cx
	pop bx
	pop ax
	ret

.single_button:
	mov ax, .okay_text
	mov bp, (14 << 8) | 35
	mov bl, 1
	call .draw_button
	jmp .finished_buttons


.draw_button:
	pusha
	
	cmp bl, 1
	je .button_selected

	mov bl, [FS:CFG_DLG_OUTER_COLOUR]

.fill_button:
	mov dx, bp
	mov si, 8			; Width
	movzx di, dh			; Finish Y position
	inc di
	call os_draw_block

	mov si, ax
	mov di, 8
	call .print_string

	popa
	ret

.button_selected:
	mov bl, [FS:CFG_DLG_SELECT_COLOUR]
	jmp .fill_button
	

	; String printing subroutine.
	; IN: SI = address of string, DI = maximum length, BP = screen location
.print_string:
	pusha

	mov dx, bp
	call os_move_cursor

	cmp si, 0
	je .print_done


.print_char:
	cmp di, 0
	je .print_done
	dec di

	mov al, [es:si]
	inc si

	cmp al, 0
	je .print_done

	mov ah, 0x0E
	mov bh, 0
	int 0x10

	jmp .print_char

.print_done:
	popa
	ret

	
.okay_text		db '   OK   ', 0
.cancel_text		db ' Cancel ', 0




; ------------------------------------------------------------------
; os_dump_string -- Dump string as hex bytes and printable characters
; IN: SI = points to string to dump

os_dump_string:
	API_START

	mov bx, si			; Save for final print

.line:
	mov di, si			; Save current pointer
	mov cx, 0			; Byte counter

.more_hex:
	lodsb
	cmp al, 0
	je .chr_print

	call os_print_2hex
	call os_print_space		; Single space most bytes
	inc cx

	cmp cx, 8
	jne .q_next_line

	call os_print_space		; Double space centre of line
	jmp .more_hex

.q_next_line:
	cmp cx, 16
	jne .more_hex

.chr_print:
	call os_print_space
	mov ah, 0Eh			; BIOS teletype function
	mov al, '|'			; Break between hex and character
	int 10h
	call os_print_space

	mov si, di			; Go back to beginning of this line
	mov cx, 0

.more_chr:
	lodsb
	cmp al, 0
	je .done

	cmp al, ' '
	jae .tst_high

	jmp short .not_printable

.tst_high:
	cmp al, '~'
	jbe .output

.not_printable:
	mov al, '.'

.output:
	mov ah, 0Eh
	int 10h

	inc cx
	cmp cx, 16
	jl .more_chr

	call os_print_newline		; Go to next line
	jmp .line

.done:
	call os_print_newline		; Go to next line

	API_END
	


; ------------------------------------------------------------------
; os_print_digit -- Displays contents of AX as a single digit
; Works up to base 37, ie digits 0-Z
; IN: AX = "digit" to format and print

os_print_digit:
	pusha

	cmp ax, 9			; There is a break in ASCII table between 9 and A
	jle .digit_format

	add ax, 'A'-'9'-1		; Correct for the skipped punctuation

.digit_format:
	add ax, '0'			; 0 will display as '0', etc.	

	mov ah, 0Eh			; May modify other registers
	int 10h

	popa
	jmp os_return


; ------------------------------------------------------------------
; os_print_1hex -- Displays low nibble of AL in hex format
; IN: AL = number to format and print

os_print_1hex:
	API_START

	and ax, 0Fh			; Mask off data to display
	call os_print_digit

	API_END


; ------------------------------------------------------------------
; os_print_2hex -- Displays AL in hex format
; IN: AL = number to format and print

os_print_2hex:
	API_START

	push ax				; Output high nibble
	shr ax, 4
	call os_print_1hex

	pop ax				; Output low nibble
	call os_print_1hex

	API_END


; ------------------------------------------------------------------
; os_print_4hex -- Displays AX in hex format
; IN: AX = number to format and print

os_print_4hex:
	API_START

	push ax				; Output high byte
	mov al, ah
	call os_print_2hex

	pop ax				; Output low byte
	call os_print_2hex

	API_END



; ------------------------------------------------------------------
; os_input_string -- Take string from keyboard entry
; IN: DS:AX = location of buffer to store string, BX = maximum string length

os_input_string:
	API_START

	; Register Variables
	; BX = string address
	; DX = cursor position of first character
	; SI = selected character number
	; DI = last character number

	; Reserve space for the null terminator.
	dec bx

	mov [gs:.max_length], bx
	mov bx, ax
	mov si, 0
	mov di, 0
	call os_get_cursor_pos

	mov byte [gs:.overwrite], 0

.keyloop:
	; Main input loop
	call os_wait_for_key

	; Check if the key is an action key
	; Some need two byte sequences to be identified.
	cmp ax, LEFT_KEY
	je .cursor_back

	cmp ax, RIGHT_KEY
	je .cursor_fwd

	cmp ax, HOME_KEY
	je .cursor_start

	cmp ax, END_KEY
	je .cursor_end

	cmp ax, INSERT_KEY
	je .change_mode

	cmp ax, DELETE_KEY
	je .delete_char

	cmp al, BACKSP_KEY
	je .backsp_char

	cmp al, ESCAPE_KEY
	je .cancel_input

	cmp al, ENTER_KEY
	je .finish_input

	; If not, just insert the character of the key.

	; Filter out non-printing keys
	cmp al, 0x20
	jb .keyloop

	cmp al, 0x7E
	ja .keyloop

	call .add_char
	jmp .keyloop


.cursor_back:
	; Don't move back from the first position.
	cmp si, 0
	je .keyloop
	
	; Move back to the previous position and move the cursor to it.
	dec si
	call .reloc_cursor

	jmp .keyloop

	
.cursor_fwd:
	; Don't move forward from the last available position.
	cmp si, di
	jge .keyloop

	; Advance to the next position and move the cursor to it.
	inc si
	call .reloc_cursor

	jmp .keyloop


.cursor_start:
	; Move to the first position.
	mov si, 0
	call .reloc_cursor
	jmp .keyloop


.cursor_end:
	; Move to the last position.
	mov si, di
	call .reloc_cursor
	jmp .keyloop


.change_mode:
	cmp byte [gs:.overwrite], 1
	je .clear_overwrite

.set_overwrite:
	mov byte [gs:.overwrite], 1	
	mov al, BLOCK_CURSOR
	call os_cursor_mode
	jmp .keyloop

.clear_overwrite:
	mov byte [gs:.overwrite], 0
	mov al, NORMAL_CURSOR
	call os_cursor_mode
	jmp .keyloop

	
.cancel_input:
	; If the input is cancelled then return a string with only a single
	; null character (zero length).
	mov di, 0

.finish_input:
	; The overwrite mode could have change the cursor, change it back.
	mov al, NORMAL_CURSOR
	call os_cursor_mode

	mov byte [bx + di], 0
	API_END


.add_char:
	; A printing or whitespace character has been entered. 
	; The character is in the AL register.
	;
	; The tricky part if figuring out how to add it.
	; There are four possible cases:
	;   Change - Replace existing value - Overwriting and not at the end. 
	;   Ignore - Do nothing - If the string is full and not overwriting.
	;   Append - Add to the end - If the cursor is at the end.
	;   Insert - Add in the middle - Not overwriting and not at the end.

	; If the length limit has been reached it's change or ignore.
	cmp di, [gs:.max_length]
	jae .add_at_limit

	; Append if the cursor is at the end regardless of overwrite mode.
	cmp si, di
	jae .append

	; Otherwise the cursor is halfway though the string.
	; If overwrite mode change the value.
	cmp byte [gs:.overwrite], 1
	je .change

	; Otherwise insert a value between the existing ones.
.insert:
	; Move everything forward to make space.
	call .insert_data

	; Increase the total length.
	inc di

	; Store the new data for the current position.
	mov [bx + si], al
	inc si

	; Make sure the string is terminated.
	mov byte [bx + di], 0

	; Print the new character
	call .print_char

	; Now print the rest of the string after it.
	push si
	add si, bx
	call os_print_string
	pop si

	call .reloc_cursor
	ret

.append:
	; Put the new character	at the end of the stirng.
	mov [bx + si], al
	inc si

	; Display the new character at the end.
	call .print_char
	
	; Increase the total length
	inc di

	ret
	
.add_at_limit:
	; Adding a new character when the length limit has been reached.
	; Any operations that increase the length (i.e. insert or append), 
	; should be ignored. Overwriting an existing character is fine.

	; If the cursor is at the last position in the string, ignore.
	; That would add to the end of the string.
	cmp si, di
	jae .cancel_insert

	; If overwrite mode is off, ignore.
	; That would insert in the middle and increase the length.
	cmp byte [gs:.overwrite], 0
	je .cancel_insert

.change:
	mov [bx + si], al
	inc si

	call .print_char

.cancel_insert:
	ret


.backsp_char:
	; Make sure there is a previous character.
	cmp si, 0
	je .keyloop

	; Move the cursor back and delete the character.
	dec si
	call .reloc_cursor

.delete_char:
	; Make sure there is a character to delete.
	cmp di, 0
	je .keyloop

	; Shift data back over the current position in the string.
	call .remove_data

	; Reduce the length of the string.
	dec di

	; Zero out the last value.
	mov byte [bx + di], 0

	; Overwrite the text on the screen.
	push si
	add si, bx
	call os_print_string
	pop si

	; Remove the duplicated ending character on the screen.
	mov al, ' '
	call .print_char

	call .reloc_cursor

	jmp .keyloop



.reloc_cursor:
	push ax
	push cx

	; This routine will find the proper cursor location from the position
	; in the input string. Here are the formulae:
	; y = ((input_pos + start_x) / screen_width) + start_y
	; x = (input_pos + start_x) % screen_width

	; input_pos + start_x
	mov ax, si
	movzx cx, dl
	add ax, cx

	; Now the divison and mod.
	mov cl, [FS:CFG_SCREEN_WIDTH]
	div cl
	; Giving:
	; (input_pos + start_x) / screen_width --- in al
	; (input_pos + start_x) % screen_width --- in ah

	
	; x = AH, y = (AL + start_y)
	add al, dh

	; Move the cursor to the new position
	push dx
	xchg ah, al
	mov dx, ax
	call os_move_cursor
	pop dx
	
	pop cx
	pop ax
	ret

.print_char:
	push ax
	push bx

	mov ah, 0x0E
	mov bh, 0
	mov bl, 7
	int 0x10

	pop bx
	pop ax

	ret

.insert_data:
	push si
	push di
	push cx

	mov cx, di
	sub cx, si

	add di, bx
	mov si, di
	dec si

	std
	rep movsb
	cld

	pop cx
	pop di
	pop si

	ret

.remove_data:
	push si
	push di
	push cx

	mov cx, di
	sub cx, si
	dec cx

	add si, bx
	mov di, si
	inc si
	cld
	rep movsb

	pop cx
	pop di
	pop si

	ret

.max_length		dw 0
.overwrite		db 0

	
; ------------------------------------------------------------------
; AL = character to print
os_print_char:
	push ax

	mov ah, 0x0E
	int 0x10
	
	pop ax
	jmp os_return

; ==================================================================
