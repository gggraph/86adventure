

cli

loopt:

call SETUP_VGA_MODE

;[bp+12] is scaling
;[bp+10] is color
;[bp+8]  is x offset pos
;[bp+6]  is y offset pos
;[bp+4]  ptr de la phrase

push 8
push 20
push 0
push 0
push phrase
call PRINT_WORD_BMP


push 0			 ; WIDTH
push 0			 ; HEIGHT
push 0			 ; X START PIXEL
push 0			 ; Y START PIXEL 
push 10;word [bp+4]; COLOR STUFF
push 6			 ; SCALING ( CAN BE MULTIPLIED)
push 80			 ; X POS
push 20			 ; Y POS
xor eax, eax
mov ax, mbmp
push  eax		; POINTER TO ARRAY OF THE PIXEL
call PRINT_BITMAP_ADVANCED

pause1:
in al, 96
cmp al, 17
je .seq2
jmp pause1



.seq2:

push 0
call CLEAR_SCREEN
pause2:

waitForKey: mov         ah,01H
                        int   16H
                        jnz   gotKey       ;jmp if key is ready


call CLEAR_SCREEN
push 0			 ; WIDTH
push 20			 ; HEIGHT
push 0			 ; X START PIXEL
push 0			 ; Y START PIXEL 
push 30;word [bp+4]; COLOR STUFF
push 4			 ; SCALING ( CAN BE MULTIPLIED)
push 80			 ; X POS
push 0			 ; Y POS
xor eax, eax
mov ax, mbmp
push  eax		; POINTER TO ARRAY OF THE PIXEL
call PRINT_BITMAP_ADVANCED

push 0			 ; WIDTH
push 20			 ; HEIGHT
push 0			 ; X START PIXEL
push 0			 ; Y START PIXEL 
push 30;word [bp+4]; COLOR STUFF
push 4			 ; SCALING ( CAN BE MULTIPLIED)
push 80			 ; X POS
push 80			 ; Y POS
xor eax, eax
mov ax, mbmp
push  eax		; POINTER TO ARRAY OF THE PIXEL
call PRINT_BITMAP_ADVANCED

mov word[charpx], 0
mov word[charpy], 0
mov cx, 0
	.loopprinta:
	cmp cx, word[inctr]
	je .endprinta
	
	push ax
	push cx
	push 4
	push  10
	push word[charpx]
	push word[charpy]
	mov si , input
	add si, cx
	mov ax, word[si]
	push ax
	call PRINT_CHAR_BMP
	pop cx
	pop ax

	push cx
	push 3
	push 40
	push word[charpx]
	push word[charpy]
		mov si , input
	add si, cx
	mov ax, word[si]
	push ax
	call PRINT_CHAR_BMP
	pop cx

	add word[charpx], 20
	cmp word[charpx], 300
	jl .enddrawa
	mov word[charpx], 0
	add word[charpy], 20 
	.enddrawa:
	inc cx
	jmp .loopprinta
.endprinta:

call WAITSTUFF

mov word[charpx], 0
mov word[charpy], 0
mov cx, 0
	.loopprint:
	cmp cx, word[inctr]
	je .endprint
	
	push ax
	push cx
	push 4
	push  30
	push word[charpx]
	push word[charpy]
	mov si , input
	add si, cx
	mov ax, word[si]
	push ax
	call PRINT_CHAR_BMP
	pop cx
	pop ax

	push cx
	push 3
	push 20
	push word[charpx]
	push word[charpy]
		mov si , input
	add si, cx
	mov ax, word[si]
	push ax
	call PRINT_CHAR_BMP
	pop cx

	add word[charpx], 20
	cmp word[charpx], 300
	jl .enddraw
	mov word[charpx], 0
	add word[charpy], 20 
	.enddraw:
	inc cx
	jmp .loopprint
.endprint:

call WAITSTUFF
gotKey: 

mov   ah,00h
int   16H
xor bx, bx
mov bx, [inctr]
mov word[input+bx], ax

inc bx
mov word[inctr], bx
cmp bx, 200
jne .n
mov word[inctr], 0
.n:


jmp pause2

WAITSTUFF:
mov al, 0
mov ah, 86h
mov cx, 0x2
mov dx, 0x93E0
int 15H ; wait like 300 ms
ret

 mov al, 0
   mov ah, 86h
   mov cx, 0x4
   mov dx, 0x93E0
  int 15H ; wait like 300 ms

end:
jmp end


charpx dw 0
charpy dw 0
inctr  dw 0 
input times 200 dw 0

%include 'graphics.asm'
%include 'system.asm'
%include 'bitmap.asm'

