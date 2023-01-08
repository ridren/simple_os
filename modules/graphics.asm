;not finished, interface still may change
;                                         image size
%macro terminal_macro_monochrome_image 2
	mov 	ebx, %2 - 0x1
%%print:
	mov 	edi, 0x0
	mov 	esi, %2 - 0x1
	sub 	esi, ebx
	mov 	edx, ebx
	imul 	edx, %2 / 0x8
	add 	edx, %1
	mov 	ecx, %2 / 0x8
	call	video_draw_bytes
	dec 	ebx
	jge		%%print
%endmacro


;                                  imager imageg imageb size
%macro terminal_macro_rgb_image 4
	;red
	terminal_macro_change_color_fg 0b100
	terminal_macro_monochrome_image %1, %4
	;green
	terminal_macro_change_color_fg 0b010
	terminal_macro_monochrome_image %2, %4
	;blue
	terminal_macro_change_color_fg 0b001
	terminal_macro_monochrome_image %3, %4
%endmacro

