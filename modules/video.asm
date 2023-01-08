;this code is used to interface with screen 
;implementation is complete for VGA mode 0x3 and 0x12, and partially for 0x13
;mode 0x12 and 0x13 provide extensions for drawing individual pixels
;
;for VGA specifc code, refer to VGA docs
;
;macros
;	[B] video_macro_change_color_fg
;		argc: 1 
;		argt: num 
;		desc: takes color and changes INTERNAL fg color and screen color
;
;	[B] video_macro_change_color_bg
;		argc: 1
;		argt: num
;		desc: takes color and changes INTERNAL bg color and screen color
;
;	[I] video_macro_planar_color_no_save 
;		argc: 1
;		argt: num
;		desc: takes color and changes screen color without changin internal colors
;
;	[B] video_macro_get_pos
;		argc: 3
;		argt: reg, num, num
;		desc: calculates where on screen is position (x, y) and puts it into reg
;
;	[B] video_macro_put_char
;		argc: 3
;		argt: num, char, fontptr
;		desc: puts char into pos num, using font if possible
;	
;procedures
;	[B] video_init
;		argc: 0
;		argt: -
;		desc: sets up whatever is necesary
;		      may be empty, but always MUST be called before every other procedure/macro
;
;	[B] video_clear_screen
;		argc: 0
;		argt: -
;		desc: fills the screen to INTERNAL bg color
;
;	[E] video_draw_bytes
;		argc: 4
;		argt: num, num, ptr, num
;		desc: draw num bytes from ptr memory to loc defined by first two numbers
;		aval: VIDEO_EXT_DRAW
;
;data
;	[I] video_text_color
;	[I] video_planar_color_fg
;	[I] video_planar_color_bg
;	[I] video_linear_color_fg
;	[I] video_linear_color_bg
;	[B] font
;		desc: required to be 8x16pixels

%define video_BLACK         0x0
%define video_BLUE          0x1
%define video_GREEN         0x2
%define video_CYAN          0x3
%define video_RED           0x4
%define video_MAGENTA       0x5
%define video_BROWN         0x6
%define video_LIGHT_GRAY    0x7
%define video_DARK_GRAY     0x8
%define video_LIGHT_BLUE    0x9
%define video_LIGHT_GREEN   0xA
%define video_LIGHT_CYAN    0xB
%define video_LIGHT_RED     0xC 
%define video_LIGHT_MAGENTA 0xD 
%define video_YELLOW        0xE 
%define video_WHITE         0xF 

%define VIDEO_MODE_TEXT   0x0
%define VIDEO_MODE_PLANAR 0x1
%define VIDEO_MODE_LINEAR 0x2
%define VIDEO_MODE_CUR VIDEO_MODE_PLANAR

%if VIDEO_MODE_CUR == VIDEO_MODE_TEXT
%define video_VGA_ADDR 0xB8000
%warning "Current video mode: text"

%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR
%define video_VGA_ADDR 0xA0000
%warning "Current video mode: planar"

%define VIDEO_EXT_DRAW 0x1

%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
%define video_VGA_ADDR 0xA0000
%fatal "Current video mode: linear"

%define VIDEO_EXT_DRAW 0x1

%endif

video_text_color      db 0x0
video_linear_color_fg:
video_planar_color_fg db 0x0
video_linear_color_bg:
video_planar_color_bg db 0x0

font:
	%include "./fonts/font8x16.txt"

;                                  color
%macro video_macro_change_color_fg 1
	%if VIDEO_MODE_CUR == VIDEO_MODE_TEXT
	and 	BYTE [video_text_color], 0b11110000
	mov 	al, %1
	or  	BYTE [video_text_color], al

	%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR
	mov 	al, 0x2
	mov 	dx, 0x3C4
	out 	dx, al
	mov 	dx, 0x3C5
	mov 	al, %1
	
	mov 	BYTE [video_planar_color_fg], %1

	out 	dx, al

	%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
	mov 	BYTE [video_linear_color_fg], %1
	%endif
%endmacro

;                                  color
%macro video_macro_change_color_bg 1
	%if VIDEO_MODE_CUR == VIDEO_MODE_TEXT
	and 	BYTE [video_text_color], 0b00001111
	mov 	al, %1
	shl 	al, 0x4
	or  	BYTE [video_text_color], al

	%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR
	mov 	BYTE [video_planar_color_bg], %1
	%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
	%warning "change_color_bg not implemented for linear"
	%endif
%endmacro

;                                             color
%macro video_macro_planar_color_no_save 1
	mov 	al, 0x2
	mov 	dx, 0x3C4
	out 	dx, al
	mov 	dx, 0x3C5
	mov 	al, %1
	out 	dx, al

%endmacro

;                          to where, x, y
%macro video_macro_get_pos 3
	
	%if VIDEO_MODE_CUR == VIDEO_MODE_TEXT
	mov 	%1, %3 
	imul 	%1, 0x50
	add 	%1, %2 
	shl 	%1, 0x1

	%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR
	mov 	%1, %3 
	imul 	%1, 0x50 * 0x10 ;16layers for each letter
	add 	%1, %2 
	
	%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
	%warning "get_pos not implemented for linear"
	%endif

%endmacro

;                           pos, letter, font
%macro video_macro_put_char 3
%if VIDEO_MODE_CUR == VIDEO_MODE_TEXT

	mov 	al, BYTE [video_text_color]
	mov 	BYTE [video_VGA_ADDR + %1 + 0x1], al
	mov 	eax, %2
	mov 	BYTE [video_VGA_ADDR + %1 + 0x0], al 

%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR
	;works by turning off bits where char has to be placed
	;then turning whichever are neccessary
	;16 iterations because font is 8x16 

	shl 	%2, 0x4
	lea 	%2, [%3 + %2]

	;turn off everything
	pushad
	video_macro_planar_color_no_save 0xF
	popad
%assign i 0
%rep 0x10
	mov 	BYTE [video_VGA_ADDR + %+i * 0x50 + %1], 0x0
%assign i i+1
%endrep

	;turn on bits where ONLY char is on 
	mov 	cl, BYTE [video_planar_color_fg]
	xor 	cl, BYTE [video_planar_color_bg]
	and 	cl, BYTE [video_planar_color_fg]
	pushad
	video_macro_planar_color_no_save cl
	popad
%assign i 0
%rep 0x10
	mov 	dl, BYTE [%2 + %+i]
	mov 	BYTE [video_VGA_ADDR + %+i * 0x50 + %1], dl
%assign i i+1
%endrep

	;turn on bits where background is on
	mov 	cl, BYTE [video_planar_color_bg]
	pushad
	video_macro_planar_color_no_save cl
	popad
%assign i 0
%rep 0x10
	mov 	BYTE [video_VGA_ADDR + %+i * 0x50 + %1], 0xFF
%assign i i+1
%endrep

%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
%warning "put_char not implemented for linear"
%endif

%endmacro

video_init:
	%if VIDEO_MODE_CUR == VIDEO_MODE_TEXT
	;intentionally blank, nothing to init
	%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR
	xor 	al, al
	mov 	dx, 0x3CE
	out 	dx, al

	mov 	al, 0x2
	mov 	dx, 0x3C4
	out 	dx, al
	mov 	dx, 0x3C5
	mov 	al, 0b00001111
	out 	dx, al

	%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
	;intentionally left blank, nothing to init
	%endif
	
	ret

video_clear_screen:
	%if   VIDEO_MODE_CUR == VIDEO_MODE_TEXT
	push 	ebx
	mov 	DWORD [terminal_pos_x], 0x0
	mov 	DWORD [terminal_pos_y], 0x0

	mov 	bl, BYTE [video_text_color]
	shl 	bx, 0x8
	add 	bx, ' ' 

	xor 	ecx, ecx
.loop:
	;put correctly colored space everywhere
	mov 	WORD [video_VGA_ADDR + ecx], bx

	add 	ecx, 0x2
	cmp 	ecx, 0x50 * 0x19 * 0x2
	jl 		.loop

	pop 	ebx
	%elif VIDEO_MODE_CUR == VIDEO_MODE_PLANAR

	video_macro_change_color_fg 0b1111
;first have to clear turned on bits 
	mov 	eax, video_VGA_ADDR 
.clear_loop:
	mov 	DWORD [eax], 0x0

	add 	eax, 0x4
	cmp 	eax, video_VGA_ADDR | 0x0FFFF
	jle 	.clear_loop

	mov 	cl, BYTE [terminal_color_bg]
	video_macro_change_color_fg cl 
	mov 	eax, video_VGA_ADDR 
.loop:
	;turn on every bit, that is part of background
	mov 	DWORD [eax], 0xFFFFFFFF

	add 	eax, 0x4
	cmp 	eax, video_VGA_ADDR | 0x0FFFF
	jle 	.loop
	
	mov 	cl, BYTE [terminal_color_fg]
	video_macro_change_color_fg cl

	%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
	
	push 	ebx
	
	mov 	bl, BYTE [video_linear_color_bg]
	
	xor 	ecx, ecx
.loop:
	mov 	BYTE [video_VGA_ADDR + ecx], 0xFF 

	inc 	ecx
	cmp 	ecx, 320 * 200 
	jl 		.loop

	pop 	ebx

	%endif
	
	mov 	DWORD [terminal_pos_x], 0x0
	mov 	DWORD [terminal_pos_y], 0x0

	ret

;edi x
;esi y
;edx source
;ecx count
;essentially memcpy
video_draw_bytes:
	%if VIDEO_MODE_CUR == VIDEO_MODE_PLANAR

	imul 	esi, 0x50
	add 	edi, esi

	test 	ecx, ecx
	jz 		.ret
.loop:
	mov 	al, BYTE [edx]
	mov 	BYTE [video_VGA_ADDR + edi], al 

	inc 	edx
	inc 	edi
	dec 	ecx
	jnz 	.loop

.ret:
	ret

	%elif VIDEO_MODE_CUR == VIDEO_MODE_LINEAR
	%warning "draw_bytes not implemented in linear mode"
	%endif
