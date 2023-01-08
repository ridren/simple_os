;NOT FUNCTIONAL
;THEREFORE NOT DOCUMENTED

align 	16
timer_counter	dd 0x0

timer_call_list: 
	dd 0x1, terminal_put_int
	dd 0x0, 0x0
	dd 0x0, 0x0
	dd 0x0, 0x0
	dd 0x0, 0x0
	dd 0x0, 0x0
	dd 0x0, 0x0
	dd 0x0, 0x0
%define timer_call_list_size 0x8

print:
	mov 	edi, 0x5
	call	terminal_put_int
	ret

timer_handler:
	inc 	DWORD [timer_counter]
	ret

	mov 	ebx, 0x0
.loop:
	mov 	edi, DWORD [timer_call_list + ebx]

	push 	edi
;	call	terminal_put_int
;	mov 	edi, ebx
;	call	terminal_put_int
;	mov 	edi, 0xF
;	call	terminal_put_int
	pop 	edi

	test 	edi, edi
	jz 		.continue

	xor 	edx, edx
	mov 	eax, edi
	div 	DWORD [timer_counter]

	test 	edx, edx
	jnz		.continue

	call 	DWORD [timer_call_list + ebx + 0x4]

.continue:
	add 	ebx, 0x8
	cmp 	ebx, timer_call_list_size * 0x8
	jl 		.loop

	ret


