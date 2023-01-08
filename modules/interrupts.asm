;THIS CODE MAY NOT BE SWAPPED
;new interrupt procedures may be added however
;
;
;macros:
;	
;
;procedures:
;	[I] idt_set_descriptor
;		argc: 3
;		argt: intvec, isrptr, plags
;		desc: copies interrupt from isr to ids[vector], in correct format
;
;	[B] interrupts_idt_setup
;		argc: 0
;		argt: -
;		desc: sets up idtr and idt
;
;	[B] interrupts_PIC_setup
;		argc: 0
;		argt: -
;		desc: sets up PIC to use IDT
;
;	int handler list:
;		int_default_handler
;		int_division_by_zero
;		int_invalid_instruction
;		int_double_fault
;		more handlers are in specific files, look at prefix

;data:
;	idtr
;	idt
;	isr_stub_table

idtr	dw 0x0 ; size
    	dd 0x0 ; offset 

align 16
idt:
%macro entry 4
	dw %1
	dw %2
	db 0x0
	db %3
	dw %4
%endmacro
times 0x100 dq 0x0 
idt_end:

isr_stub_table:
%assign i 0
%rep    0x30
    dd 0x10000 + isr_stub_%+i - $$ 
%assign i i+1 
%endrep


;vector in edi, ptr to isr in esi, flags in dl
idt_set_descriptor:
	lea 	eax, DWORD [idt + edi * 0x8]
	
	mov 	WORD [eax + 0x0], si
	mov 	WORD [eax + 0x2], 0x08 ; offset to kernel cs
	mov 	BYTE [eax + 0x4], 0x0
	mov 	BYTE [eax + 0x5], dl
	shr 	esi, 0x10
	mov 	WORD [eax + 0x6], si

	ret

interrupts_idt_setup:
	;setup idtr
	;assign idtentries with correct values

	;init idt
	mov 	WORD  [idtr], idt_end - idt
	mov 	DWORD [idtr + 0x2], 0x10000 + idt  - $$

	mov 	ebx, 0x2F
.loop:
	mov 	edi, ebx
	mov 	esi, [isr_stub_table + ebx * 0x4]
	mov 	edx, 0x8E
	call	idt_set_descriptor

	dec 	ebx
	jge 	.loop


	lidt 	[idtr]
	ret 

interrupts_PIC_setup:
;remaping PIC
	%define PIC1        0x20
	%define PIC1_COMM   PIC1
	%define PIC1_DATA  (PIC1 + 0x1)
	%define PIC2        0xA0
	%define PIC2_COMM   PIC2
	%define PIC2_DATA  (PIC2 + 0x1)
	
	%define PIC_EOI    0x20

	%define ICW1_ICW4       0x01	; ICW4 (not) needed
	%define ICW1_SINGLE     0x02	; Single (cascade) mode
	%define ICW1_INTERVAL4  0x04	; Call address interval 4 (8)
	%define ICW1_LEVEL      0x08	; Level triggered (edge) mode
	%define ICW1_INIT       0x10	; Initialization - required!

	%define ICW4_8086       0x01	; 8086/88 (MCS-80/85) mode
	%define ICW4_AUTO       0x02	; Auto (normal) EOI
	%define ICW4_BUF_SLAVE  0x08	; Buffered mode/slave
	%define ICW4_BUF_MASTER 0x0C	; Buffered mode/master
	%define ICW4_SFNM       0x10	; Special fully nested (not)

	mov 	al, ICW1_INIT | ICW1_ICW4
	out 	PIC1_COMM, al
	xor 	al, al
	out 	0x80, al ; wait 
	mov 	al, ICW1_INIT | ICW1_ICW4
	out 	PIC2_COMM, al
	xor 	al, al
	out 	0x80, al ; wait 
	
	;PIC master remapped [0x20; 0x27]
	;PIC slave  remapped [0x28; 0x2F] 
	mov 	al, 0x20 
	out 	PIC1_DATA, al
	xor 	al, al
	out 	0x80, al
	mov 	al, 0x28
	out 	PIC2_DATA, al
	xor 	al, al
	out 	0x80, al

	mov 	al, 0x4
	out 	PIC1_DATA, al
	out 	0x80, al
	mov 	al, 0x2
	out 	PIC2_DATA, al
	out 	0x80, al

	mov 	al, ICW4_8086
	out 	PIC1_DATA, al
	out 	0x80, al
	mov 	al, ICW4_8086
	out 	PIC2_DATA, al
	out 	0x80, al

	mov  	al, 0b00000000 
	out 	PIC1_DATA, al
	
	;ints from drive are blocked
	mov 	al, 0b01000000
	out 	PIC2_DATA, al

	ret

int_default_handler:
	cli
	pushad
	mov 	edi, .text
	mov 	esi, 0x16
	call	terminal_put_str
	
	popad
	sti
	ret
.text db "Interrupt has occured", 0xA	

int_division_by_zero:
	cli
	mov 	edi, .text
	mov 	esi, 0x18
	add 	esp, 0x4
	pop 	edx ;instruction ptr of instr that caused problem
	mov 	ecx, 0x0
	jmp 	kernel_error

.text db "ERROR: division by zero",0xA

int_invalid_instruction:
	cli
	mov 	edi, .text 
	mov 	esi, 0x1B
	add 	esp, 0x4
	pop 	edx
	mov 	ecx, 0x1
	jmp 	kernel_error

.text db "ERROR: invalid instruction",0xA

int_handle_PIC:
	cli
	pushad
	mov 	edi, .text
	mov 	esi, 0x1C
	call	terminal_put_str
	popad
	sti
	ret
.text db "interrupt detected from PIC", 0xA

int_double_fault:
	cli
	mov 	edi, .text
	mov 	esi, 0x15
	add 	esp, 0x4
	pop 	edx
	mov 	ecx, 0x3
	jmp 	kernel_error
.text db "Double fault occured", 0xA

%macro m_isr_stub 1
isr_stub_%+%1:
	call	0x10000 + int_default_handler - $$
	iret
%endmacro

isr_table:

isr_stub_0:
	call	0x10000 + int_division_by_zero - $$
	iret

	m_isr_stub 1
	m_isr_stub 2
	m_isr_stub 3
	m_isr_stub 4
	m_isr_stub 5

isr_stub_6:
	call	0x10000 + int_invalid_instruction - $$
	iret
	
	m_isr_stub 7

isr_stub_8:
	call	0x10000 + int_double_fault - $$
	iret
%assign i 9

%rep    0x17
    m_isr_stub i 
%assign i i+1 
%endrep

isr_stub_32:
;	mov 	edi, 32
;	call	terminal_put_int
	call	0x10000 + timer_handler - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_33:
	;mov 	edi, 33
	;call	terminal_put_int
	call	0x10000 + keyboard_handler - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_34:
	mov 	edi, 34
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_35:
	mov 	edi, 35
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_36:
	mov 	edi, 36
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_37:
	mov 	edi, 37
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al

	iret
isr_stub_38:
	mov 	edi, 38
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_39:
	mov 	edi, 39
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret

isr_stub_40:
	mov 	edi, 40
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_41:
	mov 	edi, 41
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_42:
	mov 	edi, 42
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_43:
	mov 	edi, 43
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_44:
	mov 	edi, 44
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	
	;maybe helps?
	;problem on v3s machine, when using touchpad OS frezees
	in 		al, 0x60
	
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_45:
	mov 	edi, 45
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_46:
;	mov 	edi, 46
;	call	terminal_put_int
	call	0x10000 + drive_interrupt_ack - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret
isr_stub_47:
	mov 	edi, 47
	call	terminal_put_int
	call	0x10000 + int_handle_PIC - $$
	mov 	al, PIC_EOI
	out 	PIC2_COMM, al
	mov 	al, PIC_EOI
	out 	PIC1_COMM, al
	iret



isr_table_end:
