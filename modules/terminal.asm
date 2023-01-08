;this code provides terminal interface that abstracts video details 
;allows to print char, string, int 
;as well as have uniform color management, position, state
;
;macros
;	[B] terminal_macro_put_nline
;		argc: 0
;		argt: -
;		desc: jump to beggining of next line
;
;	[B] terminal_macro_change_color_fg
;		argc: 1
;		argt: col
;		desc: changes fg color of terminal AND video 
;
;	[B] terminal_macro_change_color_bg
;		argc: 1
;		argt: col
;		desc: changes bg color of terminal AND video
;
;	[I] terminal_macro_change_color_fg_no_save
;		argc: 1
;		argt: col
;		desc: changes fg color of video but not terminal
;
;	[I] terminal_macro_change_color_bg_no_savg
;		argc: 1
;		argt: col
;		desc: changes bg color of video but not terminal
;
;	[B] terminal_state_macro_save
;		argc: 1
;		argt: destptr
;		desc: saves current variables to destination
;
;	[B] terminal_state_macro_restore
;		argc: 1
;		argt: srcptr
;		desc: restores variables from destination
;
;procedures
;	[B] terminal_clear
;		argc: 0
;		argt: -
;		desc: clears screen
;
;	[B] terminal_put_char
;		argc: 1
;		argt: char
;		desc: puts char to the screen, if nline starts new line
;
;	[I] terminal_put_char_no_color
;		argc: 1
;		argt: char
;		desc: puts char to the screen without setting colors, for performacne reasons
;
;	[B] terminal_put_str
;		argc: 2
;		argt: strptr, strlen
;		desc: puts string to screen using put_char
;
;	[B] terminal_put_int
;		argc: 1
;		argt: int
;		desc: puts int to screen
;
;data
;	[B] terminal_pos_x
;	[B] terminal_pos_y
;	[I] terminal_color_fg
;	[I] terminal_color_bg
;	[B] terminal_state
;		desc: used to save state of terminal

terminal_pos_x      dd 0x0
terminal_pos_y      dd 0x0
terminal_color_fg   db 0x0
terminal_color_bg   db 0x0

align 16
terminal_state:
	dd 0x0 ;x
	dd 0x0 ;y
	dw 0x0 ;color
align 16



%macro terminal_macro_put_nline 0
	inc 	BYTE [terminal_pos_y]
	mov 	BYTE [terminal_pos_x], 0x0
%endmacro

%macro terminal_macro_change_color_fg 1
	video_macro_change_color_fg  %1

	mov 	BYTE [terminal_color_fg], %1
%endmacro
%macro terminal_macro_change_color_fg_no_save 1
	video_macro_change_color_fg %1
%endmacro

%macro terminal_macro_change_color_bg 1
	video_macro_change_color_bg %1

	mov 	BYTE [terminal_color_bg], %1
%endmacro
%macro terminal_macro_change_color_bg_no_save 1
	video_macro_change_color_bg %1 
%endmacro
;                                where
%macro terminal_state_macro_save 1 
	mov 	eax, DWORD [terminal_pos_x]
	mov 	DWORD [%1 + 0x00], eax
	
	mov 	eax, DWORD [terminal_pos_y]
	mov 	DWORD [%1 + 0x04], eax
	
	mov 	ax, WORD [terminal_color_fg]
	mov 	WORD  [%1 + 0x08], ax
%endmacro
;                                  from 
%macro terminal_state_macro_restore 1 
	mov 	eax, DWORD [%1 + 0x00]
	mov 	DWORD [terminal_pos_x], eax
	
	mov 	eax, DWORD [%1 + 0x04]
	mov 	DWORD [terminal_pos_y], eax
	
	mov 	ax, WORD [%1 + 0x08]
	mov 	WORD [terminal_color_fg], ax
%endmacro

terminal_clear:
	push 	ebx
	mov 	bl, BYTE [terminal_color_fg]
	terminal_macro_change_color_fg_no_save bl
	mov 	bl, BYTE [terminal_color_bg]
	terminal_macro_change_color_bg_no_save bl
	
	call	video_clear_screen
	pop 	ebx
	ret


;arg in edi
terminal_put_char:
	push 	ebx

	mov 	bl, BYTE [terminal_color_fg]
	terminal_macro_change_color_fg_no_save bl
	mov 	bl, BYTE [terminal_color_bg]
	terminal_macro_change_color_bg_no_save bl
	
	video_macro_get_pos  ebx, DWORD [terminal_pos_x], DWORD [terminal_pos_y] 
	video_macro_put_char ebx, edi, font

	;increment x pos, if too big, move to next line
	inc 	DWORD [terminal_pos_x]
	cmp 	DWORD [terminal_pos_x], 0x50
	jl  	.ret

	mov 	DWORD [terminal_pos_x], 0x0
	inc 	DWORD [terminal_pos_y]
.ret:
	pop 	ebx
	ret
;arg in edi
terminal_put_char_no_color:		
	video_macro_get_pos  ebx, DWORD [terminal_pos_x], DWORD [terminal_pos_y] 
	video_macro_put_char ebx, edi, font

	;increment x pos, if too big, move to next line
	inc 	DWORD [terminal_pos_x]
	cmp 	DWORD [terminal_pos_x], 0x50
	jl  	.ret

	mov 	DWORD [terminal_pos_x], 0x0
	inc 	DWORD [terminal_pos_y]
.ret:
	ret

;str ptr in edi
;str len in esi
terminal_put_str:
	push 	ebx
	push 	esi
	push 	edi
	
	mov 	bl, BYTE [terminal_color_fg]
	terminal_macro_change_color_fg_no_save bl
	mov 	bl, BYTE [terminal_color_bg]
	terminal_macro_change_color_bg_no_save bl

	pop 	edi
	mov 	ebx, edi
	xor 	ecx, ecx
.print_loop:
	movzx 	edi, BYTE [ebx + ecx]
	cmp 	edi, 0xA
	je 		.print_ln
	push 	ecx
	call	terminal_put_char
	pop 	ecx
	;terminal_macro_put_char dx 
	jmp 	.next_iter
.print_ln:
	mov 	BYTE [terminal_pos_x], 0x0
	inc 	BYTE [terminal_pos_y]
.next_iter:
	inc 	ecx
	cmp 	DWORD ecx, [esp]
	jl  	.print_loop
	
	pop 	esi
	pop 	ebx
	ret


;num in edi
terminal_put_int:
	sub 	esp, 0x8
	mov 	ecx, 0x8

.loop:
	dec 	ecx
	mov 	eax, edi
	and 	eax, 0xF
	cmp 	eax, 0xA
	jge 	.add_hex
.add_dec:
	add 	eax, '0' 
	mov 	BYTE [esp + ecx], al
	
	jmp 	.cont
.add_hex:
	sub 	eax, 0xA
	add 	eax, 'A' 
	mov 	BYTE [esp + ecx], al
.cont:
	shr 	edi, 0x4
	jnz 	.loop

	lea 	edi, [esp + ecx]
	mov 	esi, ecx
	sub 	esi, 0x8
	neg 	esi
	call	terminal_put_str


	add 	esp, 0x8
	ret



