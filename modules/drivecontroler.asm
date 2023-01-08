;not finished, interface still may change

;ata driver
%define drive_PORT_IO_0 0x1F0
%define drive_PORT_IO_1 0x1F1
%define drive_PORT_IO_2 0x1F2
%define drive_PORT_IO_3 0x1F3
%define drive_PORT_IO_4 0x1F4
%define drive_PORT_IO_5 0x1F5
%define drive_PORT_IO_6 0x1F6
%define drive_PORT_IO_7 0x1F7

%define drive_PORT_CONTROL_0 0x3F6
%define drive_PORT_CONTROL_1 0x3F7


drive_init:
	mov 	dx, 0x1F6
	mov 	al, 0xA0
	out 	dx, al

	xor 	al, al
	mov 	dx, 0x1F2
	out 	dx, al
	inc 	dx
	out 	dx, al
	inc 	dx
	out 	dx, al

	mov 	al, 0xEC
	mov 	dx, 0x1F7
	out 	dx, al

.poll_status1:
	in 		al, dx
	test 	al, 0b10000000
	jnz 	.poll_status1
.poll_status2:
	in 		al, dx
	test 	al, 0b00001001
	jz 		.poll_status2

	mov 	ebx, 0x100
	mov 	edx, 0x1F0
.read:
	in  	ax, dx

	dec 	ebx
	jge 	.read

	ret

;edi from
;esi to where
drive_read_512B:
	push 	ebx

	mov 	dx, 0x1F6
	mov 	al, 0xE0
	out 	dx, al
	
	mov 	dx, 0x1F1
	mov 	al, 0x0
	out 	dx, al

	mov 	dx, 0x1F2
	mov 	al, 0x00
	out 	dx, al

	mov 	ax, di
	
	mov 	dx, 0x1F3
	;mov 	al, al 
	out 	dx, al

	mov 	ax, di
	shr 	ax, 0x8
	
	mov 	dx, 0x1F4
	out 	dx, al
	
	mov 	dx, 0x1F5
	mov 	al, 0x00
	out 	dx, al

	mov 	dx, 0x1F7
	mov 	al, 0x20
	out 	dx, al

	mov 	dx, 0x1F7
.wait:
	in 		al, dx
	test 	al, 0b00001001
	jz  	.wait

	mov 	ebx, 0x100
	mov 	edx, 0x1F0
.read:
	in  	ax, dx

	mov 	WORD [esi], ax
	
	add 	esi, 0x2
	dec 	ebx
	jnz 	.read
	
	pop 	ebx
	ret

;edi from
;esi how many 512B
;edx to where
;later move the code to drive_init
drive_read:
	push 	ebx
	mov 	ebx, esi
	
	;mov 	edi, edi
	mov 	esi, edx 
.loop:
	push 	edi
	push 	esi

	call	drive_read_512B
	
	pop 	esi
	add 	esi, 0x200
	pop 	edi
	inc 	edi

	dec 	ebx
	jnz 	.loop

	pop 	ebx
	ret

drive_interrupt_ack:
	mov 	edi, .text
	mov 	esi, DWORD [.text_len]
	call	terminal_put_str
	ret

.text     db "Interrupt from drive occured",0xA
.text_len dd .text_len - .text

