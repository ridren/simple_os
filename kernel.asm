;NOTES
;	modularity
;		this kernel is designed is a modular way
;		meaning that most files included in section MODULES can be swapped
;		unless it is explicitly stated otherwise 
;		ALL versions of module MUST provide interface described in each file, they should also provide description of interface
;		they may include other procedures for internal use or for extensions but then the code must check for each extension 
;		
;		each module has description of what it is for 
;		then it there is macro, procedure, data list (in that order) with specs
;		actual code need not be organized in this way 
;		in fact, code from in this project is organized data macros procedures
;
;		each procedure or macro field is defined like this:
;		[X] name
;			argc: parameter count
;			argt: types of parameters
;			desc: short description
;			aval: optional field, defining what macro is set to 0x1 when this extension is avaliable
;
;		X stands for: 
;			B - base,      each other procedure may used it freely and expect it to always work
;			E - extension, before use, has to be checked for availability
;			I - internal,  other modules MUST NOT relay on this code 
;
;		data field is defined like this:
;		name
;			desc: optional field, short description when name is not obvious enough
;
;	macros 
;		some procedures are not as separate procedures, but rather macros
;		this is done when overhead from calling them might be significant 
;		in general, registers should be passed in ebx or ecx
;		everything else may be overwritten
;
;		see postmortem.txt section macros


;TO REMEMBER
;progr1_screen_keyboard_buffer is turned off
;mask for timer is turned on 
;typing data from keyboard may override some memory


[BITS 32]
[ORG 0x10000]

%define TRUE  0x1
%define FALSE 0x0

;starting instructin
;has to be like this because later stuff requires defines in modules
;but modules also contain code so thats workaround

jmp 	kernel_entry

;===========================
;|         MACROS          |
;===========================
%macro	kernel_macro_save    0
	pushad
	terminal_state_macro_save terminal_state
	
	mov 	al, BYTE [keyboard_enable_flag]
	mov 	BYTE [kernel_data + 0x0], al
%endmacro

%macro	kernel_macro_restore 0
	mov 	al, BYTE [kernel_data + 0x0]
	mov 	BYTE [keyboard_enable_flag], al

	terminal_state_macro_restore terminal_state
	popad
%endmacro

;===========================
;|         MODULES         |
;===========================
%include "./modules/interrupts.asm"
%include "./modules/video.asm"
%include "./modules/terminal.asm"
%include "./modules/keyboard.asm"
%include "./modules/memorymanager.asm"
%include "./modules/timer.asm"
%include "./modules/sound.asm"
%include "./modules/drivecontroler.asm"
%include "./modules/graphics.asm"
%include "./modules/shell.asm" 

;===========================
;|          CODE           |
;===========================

kernel_entry:
	;setup stack
	mov 	esp, 0x0FFF0
	
	call	interrupts_idt_setup
	call	interrupts_PIC_setup

	call	video_init
	call	sound_init
	call	drive_init

	jmp 	kernel_main

	
;error text in edi
;error text len in esi
;instruction pointer of where error happend in edx
;ecx error level
; 0 problematic 
; 1 error
; 2
; 3 fatal
kernel_error:
	push 	edi
	push 	esi
	push 	edx
	push 	ecx
	mov 	BYTE [keyboard_enable_flag], KEYBOARD_ENABLE_PANIC

	terminal_macro_change_color_fg video_WHITE
	terminal_macro_change_color_bg video_BLUE

	call	terminal_clear
	pop 	ecx
	lea 	edi, [.sad_face + ecx * 0x8]
	mov 	esi, 0x8
	call	terminal_put_str

	pop 	edx
	pop 	esi
	pop 	edi
	push 	edx
	call	terminal_put_str

	mov 	edi, .eip_in
	mov 	esi, 0x5
	call	terminal_put_str

	pop 	edi
	call	terminal_put_int
	
	sti
.loop:
	hlt
	jmp 	.loop

.sad_face db "-_-    ",0xA
          db ":(     ",0xA
          db "o.o    ",0xA
          db "( ._.) ",0xA
.eip_in   db "eip: "

align 16
kernel_data:
	db 0x0 ;keyboard flags
	db 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0 ;alignment



;screen in edi
terminal_print_screen:
	push 	ebx
	push 	edi
	xor 	ebx, ebx
	mov 	DWORD [terminal_pos_x], ebx
	mov 	DWORD [terminal_pos_y], ebx
.loop:
	mov 	edi, DWORD [esp]
	lea 	edi, [edi + ebx]
	mov 	esi, 0x50
	call	terminal_put_str

	add 	ebx, 0x50
	cmp 	ebx, 0x50 * 0x1E
	jl  	.loop
	

	mov 	DWORD [terminal_pos_x], 0x0
	mov 	DWORD [terminal_pos_y], 0x0

	pop 	edi
	pop 	ebx
	ret


;string with hex to int
;ptr to str in edi
;len in esi
;if str invalid sets g_errno to 0x1
;else returns hex number 
strhtoi:
	xor 	eax, eax
	xor 	ecx, ecx
	cmp 	ecx, esi
	jge 	.ret
.loop:
	shl  	eax, 0x4
	movzx 	edx, BYTE [edi + ecx]
	cmp 	edx, '9' 
	jg  	.test_letter
	cmp 	edx, '0' 
	jl 		.wrong

	sub 	edx, '0' 
	add 	eax, edx
	jmp 	.continue

.test_letter:
	cmp 	edx, 'F' 
	jg 		.wrong
	cmp 	edx, 'A' 
	jl 		.wrong
	sub	 	edx, ('A' - 0xA) 
	add 	eax, edx

	;jmp 	continue

.continue:
	inc 	ecx
	cmp 	ecx, esi
	jl  	.loop
.ret:
	ret

.wrong:
	mov 	BYTE [g_errno], 0x1
	ret


prog0:
	terminal_macro_change_color_fg video_WHITE
	terminal_macro_change_color_bg video_BLACK
	call	terminal_clear
	
	mov 	edi, prog0_screen_keyboard_buffer
	call	terminal_print_screen
	mov 	DWORD [terminal_pos_y], 0x0
	mov 	DWORD [terminal_pos_x], 0x0


	or  	BYTE [keyboard_enable_flag], (KEYBOARD_ENABLE_ARROWS | KEYBOARD_ENABLE_CONTROL)
	mov 	DWORD [keyboard_buffer_ind], 0x0
.loop:
	hlt


	test 	BYTE [keyboard_buffer_new], 0x1
	jz 		.loop
	

	;now we have char
	dec 	BYTE [keyboard_buffer_new]

	mov 	dl, BYTE [keyboard_buffer]

	cmp 	dl, 0x80
	je 		.return

	cmp 	dl, 0xA
	je 		.nline

	cmp 	dl, 0xC0
	jae 	.arrows
.letters:
	mov 	eax, DWORD [terminal_pos_y]
	imul 	eax, 0x50 
	add 	eax, DWORD [terminal_pos_x]
	mov 	BYTE [prog0_screen_keyboard_buffer + eax], dl
	
	movzx 	edi, dl
	call	terminal_put_char


	jmp 	.end_loop
.arrows:
	cmp 	dl, 0xC0
	je 		.up
	cmp 	dl, 0xC1
	je 		.left
	cmp 	dl, 0xC2
	je 		.right
	;cmp 	dl, 0xC3
	jmp 	.down

.up:
	dec 	DWORD [terminal_pos_y]
	jmp 	.end_loop
.left:
	dec 	DWORD [terminal_pos_x]
	jmp 	.end_loop
.right:
	inc 	DWORD [terminal_pos_x]
	jmp 	.end_loop
.down:
	inc 	DWORD [terminal_pos_y]
	jmp 	.end_loop

.nline:
	inc 	DWORD [terminal_pos_y]
	mov 	DWORD [terminal_pos_x], 0x0
	;jmp 	.end_loop

.end_loop:
	
	dec 	DWORD [keyboard_buffer_ind]
	jmp 	.loop

.return:
	mov 	DWORD [keyboard_buffer_ind], 0x0
	and 	BYTE [keyboard_enable_flag], ~(KEYBOARD_ENABLE_ARROWS | KEYBOARD_ENABLE_CONTROL)
	ret


;command table structure
;size of name 
;ptr to name
;ptr to code
;alignment to 16B

;when calling command these should be set 
;argc
;argv table 

;structure of argv
;str size
;str content, at most 32 bytes


argc 	dd	0x0
argv0	dd  0x0
        times 0x20 db 0x0 
argv1	dd  0x0
        times 0x20 db 0x0
argv2	dd  0x0
        times 0x20 db 0x0
argv3	dd  0x0
        times 0x20 db 0x0
argv4	dd  0x0
        times 0x20 db 0x0


kernel_main:	
	sti
	
	mov 	edi, 0x42
	mov 	esi, 0x2FF
	mov 	edx, 0x18000
	call	drive_read

	mov 	DWORD [keyboard_panic_loc], kernel_safe_mode
	call	shell_main

prog_code:
prog0_code 	dd	prog0
prog1_code 	dd	0x0
prog2_code 	dd	0x0
prog3_code 	dd	0x0


kernel_safe_mode:
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	sti
	;setup stack
	mov 	esp, 0x0FFF0
	mov 	DWORD [keyboard_buffer_ind], 0x0


	jmp 	kernel_main


prog0_screen_keyboard_buffer:
	times 0x50 * 0x1E db ' ' 

g_errno db 0x0

gif_jt:
	dd 	.frame0
	dd 	.frame1
	dd 	.frame2
	dd 	.frame3
	dd 	.frame4
	dd 	.frame5
	dd 	.frame6
	dd 	.frame7
	dd 	.frame8
	dd 	.frame9

.frame0:
	terminal_macro_rgb_image gif_frame0r, gif_frame0g, gif_frame0b, 0x80
	ret                                                          
.frame1:                                                         
	terminal_macro_rgb_image gif_frame1r, gif_frame1g, gif_frame1b, 0x80
	ret                                                          
.frame2:                                                         
	terminal_macro_rgb_image gif_frame2r, gif_frame2g, gif_frame2b, 0x80
	ret                                                          
.frame3:                                                         
	terminal_macro_rgb_image gif_frame3r, gif_frame3g, gif_frame3b, 0x80
	ret                                                          
.frame4:                                                         
	terminal_macro_rgb_image gif_frame4r, gif_frame4g, gif_frame4b, 0x80
	ret                                                          
.frame5:                                                         
	terminal_macro_rgb_image gif_frame5r, gif_frame5g, gif_frame5b, 0x80
	ret                                                          
.frame6:                                                         
	terminal_macro_rgb_image gif_frame6r, gif_frame6g, gif_frame6b, 0x80
	ret                                                          
.frame7:                                                         
	terminal_macro_rgb_image gif_frame7r, gif_frame7g, gif_frame7b, 0x80
	ret                                                          
.frame8:                                                         
	terminal_macro_rgb_image gif_frame8r, gif_frame8g, gif_frame8b, 0x80
	ret                                                          
.frame9:                                                         
	terminal_macro_rgb_image gif_frame9r, gif_frame9g, gif_frame9b, 0x80
	ret


;32KiB mem for kernel
times	 0x8000-($-$$)	db	0x0
drive_start:

imager:
%include "imgs/imgr.txt"
imageg:
%include "imgs/imgg.txt"
imageb:
%include "imgs/imgb.txt"

gif_frame0r:
%include "gif/frame0r.txt"
gif_frame0g:
%include "gif/frame0g.txt"
gif_frame0b:
%include "gif/frame0b.txt"
gif_frame1r:
%include "gif/frame1r.txt"
gif_frame1g:
%include "gif/frame1g.txt"
gif_frame1b:
%include "gif/frame1b.txt"
gif_frame2r:
%include "gif/frame2r.txt"
gif_frame2g:
%include "gif/frame2g.txt"
gif_frame2b:
%include "gif/frame2b.txt"
gif_frame3r:
%include "gif/frame3r.txt"
gif_frame3g:
%include "gif/frame3g.txt"
gif_frame3b:
%include "gif/frame3b.txt"
gif_frame4r:
%include "gif/frame4r.txt"
gif_frame4g:
%include "gif/frame4g.txt"
gif_frame4b:
%include "gif/frame4b.txt"
gif_frame5r:
%include "gif/frame5r.txt"
gif_frame5g:
%include "gif/frame5g.txt"
gif_frame5b:
%include "gif/frame5b.txt"
gif_frame6r:
%include "gif/frame6r.txt"
gif_frame6g:
%include "gif/frame6g.txt"
gif_frame6b:
%include "gif/frame6b.txt"
gif_frame7r:
%include "gif/frame7r.txt"
gif_frame7g:
%include "gif/frame7g.txt"
gif_frame7b:
%include "gif/frame7b.txt"
gif_frame8r:
%include "gif/frame8r.txt"
gif_frame8g:
%include "gif/frame8g.txt"
gif_frame8b:
%include "gif/frame8b.txt"
gif_frame9r:
%include "gif/frame9r.txt"
gif_frame9g:
%include "gif/frame9g.txt"
gif_frame9b:
%include "gif/frame9b.txt"

;when loaded, for now, it should be at 0x18000
;256KiB drive space
times 	0x50000 - ($ - $$) db 0x0

