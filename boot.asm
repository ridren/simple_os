[BITS 16]
[ORG 0x7C00]

load_data:
	;video modes
	;0x03 text
	;0x12 planar
	;0x13 linear	

	mov 	ax, 0x0012
	int 	0x10

	xor 	cx, cx
	mov 	ds, cx
	mov 	es, cx
	mov 	bp, cx
	
	;check if extensions used to read from drive available
	mov 	ah, 0x41
	mov 	bx, 0x55AA
	mov 	dl, 0x80
	int 	0x13
	jc		error
	inc 	bp

	;loads 32KiB of kernel
	mov 	ah, 0x42
	mov 	dl, 0x80
	mov 	si, kernel_packet
	int 	0x13
	jc 		error

	;shamelesly stolen
	;disable interrupts
	cli
	xor   eax, eax
   	mov   ax, ds
   	shl   eax, 4
   	add   eax, gdt
   	mov   [gdtr + 2], eax
   	mov   eax, gdt_end - gdt
   	mov   [gdtr], ax
   	lgdt  [gdtr]

	;shamelesly stolen
	;set ProtectionEnable bit of ControlRegister0
	mov 	eax, cr0
	or  	eax, 0b1
	mov 	cr0, eax

	;shamelesly stolen
	; Reload CS register containing code selector:
	jmp   0x08:reload_cs ; 0x08 is a stand-in for your code segment
reload_cs:	
[BITS 32]
	mov   ax, 0x10 
	mov   ds, ax
	mov   es, ax
	mov   fs, ax
	mov   gs, ax
	mov   ss, ax

	call	enable_A20
	jmp 	0x08:0x10000


;https://wiki.osdev.org/A20_Line
enable_A20:
        cli
        
		call    a20wait
        mov     al,0xAD
        out     0x64,al

        call    a20wait
        mov     al,0xD0
        out     0x64,al

        call    a20wait2
        in      al,0x60
        push    eax

        call    a20wait
        mov     al,0xD1
        out     0x64,al

        call    a20wait
        pop     eax
        or      al,2
        out     0x60,al

        call    a20wait
        mov     al,0xAE
        out     0x64,al

        call    a20wait
        ret

a20wait:
        in      al,0x64
        test    al,2
        jnz     a20wait
        ret


a20wait2:
        in      al,0x64
        test    al,1
        jz      a20wait2
        ret

%define len 0x1E
[BITS 16]
error:
	;get correct error message
	imul 	bp, 0x1E
	add 	bp, error_list

	;insert error code to the beggining of string
	;in place of "00"
	shr 	ax, 0x4
	shr 	al, 0x4
	add 	WORD [bp + 0x0], ax

	;set video mode to text
	mov 	ax, 0x0003
	int 	0x10
	
	;print string
	mov 	ax, 0x1300
	mov 	bx, 0x000F
	mov 	cx, len
	xor 	dx, dx
	mov 	es, dx
	int 	0x10
	
	cli
.loop:
	hlt
	jmp 	.loop

error_list:
err_LBA  db    "00 LBA not supported          "	
err_PCK  db    "00 Ext read err occured       "	
err_APM  db    "00 APM not supported          "	

align 	16
kernel_packet	db	0x10
            	db	0x0
            	dw	0x40
            	dw  0x0000, 0x1000	
            	dq	0x2
gdtr	dw 0x0
    	dd 0x0

;the last one is probably wrong
;shrug
;code segment and data segment are setup in a way that they essentially doing nothing
;this is because i do not need segments
gdt:           	
nls 	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0b00000000, 0x00
kcs 	db 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x9A, 0b11001111, 0x00
kds 	db 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x92, 0b11001111, 0x00
tss 	db 0x00, 0x00, 0x00, 0x00, 0x00, 0x89, 0b00000000, 0x00
gdt_end:

;fill up to MBR
times 0x1BE-($-$$) db 0x0
	db 0x80, 0x0, 0x0, 0x0, 0x17, 0x0, 0x0, 0x0
	dd 0x0, 0x100

;fill bytes 
times 510-($-$$) db	0x0
;add signature
     		db	0x55, 0xAA

;add one sector so that kernel starts at sector ind 0x2 
;this is purely for aesthetic reasons
times 0x200 db 0x0
