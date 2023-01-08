;not finished, interface still may change

shell_init:
	
	ret

shell_main:
	terminal_macro_change_color_fg video_WHITE
	terminal_macro_change_color_bg video_BLACK
	
	call	terminal_clear

	mov 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_LETTERS | KEYBOARD_ENABLE_NUMBERS | KEYBOARD_ENABLE_PANIC

	mov 	edi, '>' 
	call	terminal_put_char
	
loop:
	hlt

	sound_macro_turn_off
	
	cmp 	BYTE [keyboard_buffer_new], 0x1
	jb		continue
	dec 	BYTE [keyboard_buffer_new]

	mov 	eax, DWORD [keyboard_buffer_ind]
	cmp 	BYTE [keyboard_buffer + eax - 0x1], 0xA
	je  	nline
	cmp 	BYTE [keyboard_buffer + eax - 0x1], 0x8
	je 		backspace
	cmp 	BYTE [keyboard_buffer + eax - 0x1], 0x8
	je 		backspace



	movzx 	edi, BYTE [keyboard_buffer + eax - 0x1]
	call	terminal_put_char
	jmp 	continue

backspace:
	dec 	DWORD [keyboard_buffer_ind]
	
	cmp 	DWORD [keyboard_buffer_ind], 0x0
	jz 		continue

	dec 	DWORD [keyboard_buffer_ind]
	
	dec 	DWORD [terminal_pos_x]
	mov 	edi, ' ' 
	call	terminal_put_char
	dec 	DWORD [terminal_pos_x]


	jmp 	continue


nline:
	terminal_macro_put_nline

	mov 	ebx, DWORD [keyboard_buffer_ind]
	mov 	DWORD [keyboard_buffer_ind], 0x0
	

	mov 	DWORD [argc], 0x0
	;now here we parse it 
	xor 	eax, eax ;curent index
	xor 	ecx, ecx ;prev index
parse:
	
.loop:
	mov 	dl, BYTE [keyboard_buffer + eax]
	cmp 	dl, ' ' 
	je 		.add_arg
	cmp 	dl, 0xA
	je 		.add_arg
	jmp 	.continue

.add_arg:
	mov 	edx, eax
	sub	 	edx, ecx 
	test 	edx, edx
	jz  	.empty_arg
	;edx has len of arg 
	
	lea 	edi, [keyboard_buffer + ecx]

	mov 	ecx, DWORD [argc]
	imul 	ecx, 0x24

	push 	eax
	push 	ebx
	push 	ecx
	push 	edx
	lea 	esi, [argv0 + 0x4 + ecx]
	;mov 	edx, edx
	call	memcpy
	pop 	edx
	pop 	ecx
	pop 	ebx
	pop 	eax


	mov 	DWORD [argv0 + ecx], edx 
	mov 	ecx, eax
	inc 	ecx

	;lea 	esi, 
	
	inc 	DWORD [argc]
	cmp 	DWORD [argc], 0x5
	je 		.end
	jmp 	.continue
.empty_arg:
	inc 	ecx
.continue:
	inc 	eax
	cmp 	eax, ebx
	jne 	.loop
.end:
	
	test 	DWORD [argc], -1 ;all bytes turned on
	;if argc is 0 jmp to next command
	jz 		next_command

choose_command:
	;now compare each command
	xor 	ebx, ebx
.loop:

	mov 	edi, ebx
	shl 	edi, 0x4 ;times 0x10
	lea 	edi, [command_table + edi]

	mov 	eax, DWORD [argv0]
	cmp 	DWORD [edi], eax
	jne		.continue

	mov 	edi, [edi   + 0x4] 
	lea 	esi, [argv0 + 0x4] 
	mov 	edx, DWORD [argv0]
	call	memcmp
	test 	eax, eax
	jz 		.continue

	mov 	edi, ebx
	shl 	edi, 0x4 ;times 0x10
	call	DWORD [command_table + 0x8 + edi]

;	mov 	edi, eax
;	call	terminal_put_int
;	terminal_macro_put_nline

	jmp 	next_command
.continue:
	inc 	ebx
	cmp 	ebx, DWORD [command_count]
	jl  	.loop
	jmp 	next_command


error:
	mov 	edi, err_detected
	mov 	esi, 0x1D
	call	terminal_put_str
	movzx 	edi, BYTE [g_errno]
	call	terminal_put_int
	mov 	BYTE [g_errno], 0x0

	terminal_macro_put_nline

	jmp 	next_command

next_command:
	mov 	edi, '>' 
	call	terminal_put_char
continue:
	jmp 	loop

comm_shutdown:
%define comm_shutdown.len	0x8
.text                    	db "SHUTDOWN"
.code:
	
	ret

comm_reboot:
%define comm_reboot.len 	0x6
.text                    	db "REBOOT"
.code:
	;causes triple fault
	lidt [0x0]
	int  0x0
	ret


comm_clear:
%define comm_clear.len	0x5
.text                 	db "CLEAR"
.code:
	call	terminal_clear
	ret

comm_error:
%define comm_error.len	0x5
.text                 	db "ERROR"
.code:
	
	xor 	eax, eax
	div 	eax

	ret

comm_image:
%define comm_image.len	0x5
.text                 	db "IMAGE"
.code:

	kernel_macro_save

	terminal_macro_rgb_image imager, imageg, imageb, 0x100

	kernel_macro_restore

	ret

music:
%include "./music.txt"
.len dd ($ - music)

comm_sound:
%define comm_sound.len	0x5
.text                 	db "SOUND"
.code:
	push 	ebx
	xor 	ebx, ebx

	mov 	edi, 0x2
	call	terminal_put_int

.repeat:
	mov 	ecx, 0x0 
.loop:
	hlt
	cmp 	DWORD [timer_counter], 0x1
	jle 	.loop
	mov 	DWORD [timer_counter], 0x0

	
	sound_macro_play_beep WORD [music + ecx] 

	push 	ecx
	mov 	edi, ecx
	call	terminal_put_int
	pop 	ecx

	cmp 	ebx, 9
	jl 		.nchange
	mov 	ebx, -1
.nchange:
	inc 	ebx

	pushad
	call	DWORD [gif_jt + ebx * 0x4]
	popad


	add 	ecx, 0x2
	cmp 	ecx, DWORD [music.len] 
	jl	 	.loop

	sound_macro_turn_off 

	terminal_macro_put_nline
	pop 	ebx
	ret


comm_help:
%define comm_help.len   0x4
.text 	                db "HELP"
.code:
	mov 	edi, help_text
	mov 	esi, help_text_len
	call	terminal_put_str
	ret

comm_play:
%define comm_play.len	0x4
.text                	db "PLAY"
.code:
	push 	ebx
	xor 	ebx, ebx
	;current frame stored in ebx
.loop:
	hlt

	cmp 	BYTE [keyboard_buffer_new], 0x1
	jne 	.loop
	mov 	DWORD [keyboard_buffer_ind], 0x0
	mov 	BYTE  [keyboard_buffer_new], 0x0


	movzx 	eax, BYTE [keyboard_buffer]
	sub 	eax, '0' 
	mov 	dx, WORD [sound_key_to_freq + eax * 2]
	
;	push 	edx
;	movzx 	edi, dx
;	call	terminal_put_int
;	pop 	edx

;	cmp 	eax, '8' 
;	jg 		.note
;.oct:
;	sub 	al, '0' 
;	mov 	ebx, eax
;	jmp 	.loop
;.note:
;	mov 	ecx, ebx
;	imul 	ecx, 12 * 2 ; 12 2B entries for octave
;	add 	ecx, eax
;	sub 	ecx, 'A' 
;	mov 	dx, WORD [sound_octaves + ecx]

	sound_macro_play_beep dx

	cmp 	ebx, 9
	jl 		.nchange
	mov 	ebx, -1
.nchange:
	inc 	ebx


	push 	ebx
	call	DWORD [gif_jt + ebx * 0x4]
	pop 	ebx
.time:
	hlt
	cmp 	DWORD [timer_counter], 0x2
	jle 	.time


	jmp 	.loop

	pop 	ebx
	ret


comm_prog:
%define comm_prog.len	0x4
.text                	db "PROG"
.code:
	jmp 	.exec
	cmp 	DWORD [argc], 0x1
	jle		.no_input
	
	mov 	esi, 0x1
	lea 	edi, [argv1 + 0x4]
	call	strhtoi
	test 	BYTE [g_errno], 0x1
	jnz 	error

	mov 	ebx, eax
.exec:
	xor 	ebx, ebx
	kernel_macro_save

	call	[prog0_code + ebx * 0x4]

	kernel_macro_restore
	call	terminal_clear

	ret

.no_input:
	mov 	edi, err_not_enough_args 
	mov 	esi, 0x1C
	call	terminal_put_str

	ret

comm_col:
%define comm_col.len	0x3
.text               	db "COL"
.code:
	cmp 	DWORD [argc], 0x2
	jl		.no_input
	
	cmp 	DWORD [argv1], 0x2
	jl 		.only_fg
.fg_bg:
	lea 	edi, [argv1 + 0x4]
	mov 	esi, 0x2
	call	strhtoi
	test 	BYTE [g_errno], 0x1
	jnz 	error
		
	shl 	ax, 0x4
	shr 	al, 0x4
	mov 	ecx, eax
	terminal_macro_change_color_fg ch
	terminal_macro_change_color_bg cl
	
	ret
.only_fg:
	lea 	edi, [argv1 + 0x4]
	mov 	esi, 0x1
	call	strhtoi
	test 	BYTE [g_errno], 0x1
	jnz 	error

	mov 	ecx, eax
	terminal_macro_change_color_fg cl

	ret
.no_input:
	mov 	edi, err_not_enough_args 
	mov 	esi, 0x1C
	call	terminal_put_str

	ret

comm_int:
%define comm_int.len	0x3
.text               	db "INT"
.code:	
	cmp 	DWORD [argc], 0x1
	jle		.no_input
	
	mov 	esi, 0x1
	cmp 	DWORD [argv1], 0x2
	jl 		.len1
	inc 	esi
.len1:
	lea 	edi, [argv1 + 0x4]
	call	strhtoi
	test 	BYTE [g_errno], 0x1
	jnz 	error

	;self modyfing code
	;mischievious 
	;>:) 
	mov 	BYTE [.mod + 0x1], al
.mod: 
	int 	0x0

	ret

.no_input:
	mov 	edi, err_not_enough_args 
	mov 	esi, 0x1C
	call	terminal_put_str

	ret

command_table:
%macro command_table_entry 1
	dd	%1.len  ;name size
	dd	%1.text ;name ptr
	dd	%1.code ;code ptr
	dd  0x0 ;alignment
%endmacro
command_table_entry comm_shutdown
command_table_entry comm_reboot
command_table_entry comm_clear
command_table_entry comm_error
command_table_entry comm_image
command_table_entry comm_sound
command_table_entry comm_help
command_table_entry comm_play
command_table_entry comm_prog
command_table_entry comm_col
command_table_entry comm_int

command_count dd ($ - command_table) / 0x10 


err_no_command      db "ERROR: command does not exist", 0xA
err_not_enough_args db "ERROR: not enough arguments",0xA
err_detected        db "ERROR: error detected, code: " 


help_text           db "REBOOT - reboots ",0xA
                    db "CLEAR  - clears the screen",0xA
                    db "ERROR  - cause div by 0 error",0xA
                    db "IMAGE  - displays image loaded to memory",0xA
                    db "HELP   - displays this help",0xA
                    db "INT    - causes interrupt with value of argument",0xA
                    db "COL    - changes term colors to fg and bg passed as two hex digits",0xA
help_text_len equ $ - help_text
