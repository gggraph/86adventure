SETUP_VGA_MODE:
    mov			ah, 00h
    mov			al, 13h
    int			10h
    ret


print_word_hex:
    xchg		al, ah                 ; Print the high byte first
    call		print_byte_hex
    xchg		al, ah                 ; Print the low byte second
    call		print_byte_hex
    ret


print_byte_hex:
    push		ax
    push		cx
    push		bx

    lea			bx, [.table]            ; Get translation table address

    ; Translate each nibble to its ASCII equivalent
    mov			ah, al                  ; Make copy of byte to print
    and			al, 0x0f                ;     Isolate lower nibble in AL
    mov			cl, 4
    shr			ah, cl                  ; Isolate the upper nibble in AH
    xlat                        ; Translate lower nibble to ASCII
    xchg		ah, al
    xlat                        ; Translate upper nibble to ASCII

    pop			bx                      ; Restore attribute and page
    mov			ch, ah                  ; Make copy of lower nibble
    mov			ah, 0x0e
    int			0x10                    ; Print the high nibble
    mov			al, ch
    int			0x10                    ; Print the low nibble

    pop			cx
    pop			ax
    ret

.table: db "0123456789ABCDEF", 0

; PRINT & PROCCESS A BUTTON 
PRINTBUTTON: 
; arg is button data pointer 
;[bp+4]  is button data pointer 
    push		bp
	mov			bp,sp
	mov			si, [bp+4] ; get address of the button 
	push		si		   ; save si register
	; Get width depending of string length 
	push        word[si+12]
	call		GETSTRINGLENGTH
	pop			si         ; get back si 
	; value stored in cx 
	; we are using 16 pixel per character
	shl			cx, 4 ; this is actual width
	; Save Width at -2 
	push		cx    
	; Save Heigth at -4
	push		word[si+4]
	; Save Top X at -6 
	mov			ax, [si] 
	shr			cx, 1
	sub			ax, cx
	push		ax
	; Save Top Y at -8 
	mov			ax, [si+2] 
	mov			cx, [si+4]
	shr			cx, 1 
	sub			ax, cx
	push        ax

    ; Get Mouse Status inside button 
	; Check if mouse is lower than topX
	push		word[bp-6] 
	push		word[bp-8] 
	push		word[bp-2] 
	push		word[bp-4] 
	call		ISMOUSEINSIDEBOX
	test		ax,ax
	jz			.mousenotinside


	
	; Update mouse status inside box. 0 is not inside. 1 is inside. 2 is inside & clicking 
	call		ISLEFTMOUSEDOWN
	test		al, al
	jz			.mouseclick
    ; set mouse status to 1
	mov			word[si+10],1
	mov			bx, [si+8]
	jmp			.print
	.mouseclick: 
	; set mouse status to 2
	mov			word[si+10],2
	jmp			.print
	.mousenotinside: 
	; set mouse status to 0
	mov			word[si+10],0
	mov			bx, [si+6]

	.print:
	; Print the box. BX is color
	push		0
	push		0
	push		word [bp-6]
	push		word [bp-8]
	push		word [bp-2]
	push		word [bp-4]
	call		FILL_RECTANGLE_DITHERING
	
	; Print the text 
	mov			ax,  [si+12] 
	push		2  ; scaling 
	push        0 ;  
	push		word[bp-6] 
	mov			bx, [bp-8]
	add			bx, 4
	push		bx
	push	    ax
	call	    PRINT_CUSTOM_FONT_WORD
	
	; clear temp memory
	add			sp, 8

	pop			bp
	ret			2

; return ax 0 if not inside ... [PARAMS : X, Y, W, H ]
;										  10 8  6  4
ISMOUSEINSIDEBOX:
	push		bp
	mov			bp, sp

	mov			ax, [mouseX] 
	cmp			ax, [bp+10] 
	jl			.mousenotinside
	; Check if mouse is higer than topX + width
	mov			bx, [bp+10] 
	add         bx, [bp+6]
	cmp			ax, bx
	jg			.mousenotinside
	; Check if mouse is lower than Y
	mov			ax, [mouseY] 
	cmp			ax, [bp+8] 
	jl			.mousenotinside
	; Check if mouse is higher than Y + HEIGHT
	mov			bx, [bp+8] 
	add         bx, [bp+4]
	cmp			ax, bx
	jg			.mousenotinside

	xor			ax, ax
	inc			ax
	jmp			.ret
	.mousenotinside: 
	xor			ax, ax
	.ret:
	pop			bp
	ret			8

; GET LENGTH OF A STRING. VALUE RETURNED IN CX
GETSTRINGLENGTH:
	 push		bp
	 mov		bp,sp
	 mov		si, [bp+4] ; get address of the string
	 xor		cx, cx
	 .loop: 
		xor ax, ax
		mov al, [si]
		cmp al, 0
		je .end
		inc si
		inc cx
		jmp .loop
	 .end: 
	 pop bp 
	 ret 2

;MISC FUNCTION TO PRINT MOUSE
PRINTCURSOR: 

	push		2
	push		0
	push		8
	push		0xc1           ; default cursor tile 
	push		word[mouseX]
	push		word[mouseY]
	xor			eax, eax
	mov			ax, mapsheet
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT
	ret


; Return ax 0 if left mouse down is true 
ISLEFTMOUSEDOWN:
	xor			ax, ax
	mov			al, byte[curStatus]	
	shl			al, 4
	sub			al, 0x90
	ret 

;return 0 if right mouse down is true 
ISRIGHTMOUSEDOWN:
	xor			ax, ax
	mov			al, byte[curStatus]	
	shl			al, 4
	sub			al, 0xA0
	ret 

; Wait for next frame 

WAITFORENDOFFRAME:
	mov			al, 0
	mov			ah, 86h
	mov			cx, 0x0
	mov			dx, 0x7530
	int			15H ; wait like 300 ms
	ret