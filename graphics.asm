; a simple graphic library 


PRINT_PIXEL:
; cx and dx has to be respectively x and y , bx is color 
push bp
mov bp,sp 
push cx ; bp - 2
push dx ; bp - 4
push bx ; bp - 6
mov ax , 0A000h ; vga mem start address
mov es , ax
mov ax , [bp - 4]
mov bx , [bp - 2]
mov cx , 320 ; can we do shifting here ?
mul cx 
add ax , bx
mov di , ax
mov ax , [bp - 6] ; color
mov [es:di] , al 
pop bx
pop dx
pop cx

pop bp
ret

ret
VERT_LINE:
; y0 y1; x 
; +8 +6 +4

push bp
mov bp,sp 

.loop:
; while ( y0 < y1 ) y++ draw(xy)
mov ax, [bp+8]
cmp ax, [bp+6]
ja .endloop
; draw pixel 
mov cx, [bp +4 ] ; start pos x
mov dx, [bp +8 ] ; start pos y
call PRINT_PIXEL   
; inc y0
inc word [bp+8]
jmp .loop
.endloop:
pop bp
ret 6 ; clear stack here

HOR_LINE:
; x0 x1; y 
; +8 +6 +4
push bp
mov bp,sp 
.loop:
; while ( x0 < x1 ) x++ draw(xy)
mov ax, [bp+8]
cmp ax, [bp+6]
ja .endloop
; draw pixel 
mov cx, [bp +8 ] ; start pos x
mov dx, [bp +4 ] ; start pos y
call PRINT_PIXEL 
; inc y0
inc word [bp+8]
jmp .loop
.endloop:
pop bp
ret 6

BRESENHAM_LINE:
;[bp+10] ; x0
;[bp+8] ; y0
;[bp+6] ; x1
;[bp+4] ; y1 

push bp
mov bp, sp

; define dx [bp-2] ( Abs(x1-x0))
mov ax, [bp+6]
sub ax, [bp+10]
cmp ax, 0 
jge .ca ; si  positif dont neg( jump to ca)
neg ax
.ca:
push ax   ; ok 

; define dy [bp-4] (- Abs(y1-y0))
mov ax, [bp+4]
sub ax, [bp+8]
cmp ax, 0 
jle .cb ; si  negatif dont neg ( jump to cb )
neg ax
.cb:
push ax ; ok 

; define sx [bp-6]
mov ax, 1
; si x0 < x1 
mov bx, [bp+10];  x0
cmp bx, [bp+6]; 
; if sup neg ax
jbe .cc ; so if inf jump to cc
sub ax, 2
.cc:
push ax ; ok 

; define sy [bp-8]
mov ax, 1
; si y0 < y1 
mov bx, [bp+8];  y0
cmp bx, [bp+4];  y1
; if sup neg ax
jbe .cd
sub ax, 2
.cd:
push ax; ok

; define err [bp-10] (dx+dy)
mov ax, [bp-2]
add ax, [bp-4]
push ax

; define e2 [bp-12]
push 0

.loop:
;---------- draw the pixel
mov cx, [bp + 10 ] ; x0
mov dx, [bp + 8 ] ; y0
CALL PRINT_PIXEL

; -------- break if x0==x1 && y0==y1
mov ax, [bp+10]
cmp ax, [bp+6]
je .breakA
jmp .continue
.breakA:
mov ax, [bp+8]
cmp ax, [bp+4]
je .end ; ok 

.continue:
;;---- e2 = 2*err
mov ax, [bp-10]
mov cx, 2
mul cx ; -- better use left shift 
mov word[bp-12], ax ; ok 

; ---- if (e2 >= dy) { err += dy; x0 += sx; }
mov ax, [bp-12]
cmp ax, [bp-4]
jl .stateB ;signed ; move next 
;-- err += dy
mov ax, [bp-4]
add word [bp-10], ax
; x0 += sx; <- here
mov ax, [bp-6] 
add word [bp+10], ax

.stateB:
; ---- if (e2 <= dx) { err += dx; y0 += sy; } 
mov ax, [bp-12]
cmp ax, [bp-2]
jg .continueB ; signed move next
;---err += dx; 
mov ax, [bp-2]
add word [bp-10], ax
;---y0 += sy; <- here
mov ax, [bp-8]
add word [bp+8], ax


.continueB:
jmp .loop
.end:
add sp, 12 ; clear all the push ...
pop bp
ret 8; clear the stack args
; better than pop 6 times and ret ?

; [ARGS : x0,y0,x1,y1,x2,y2]
DRAW_TRIANGLE:

	push bp
	mov bp, sp

	push word [bp+14]
	push word [bp+12]
	push word [bp+10]
	push word [bp+8]
	call BRESENHAM_LINE

	push word [bp+10]
	push word [bp+8]
	push word [bp+6]
	push word [bp+4]
	call BRESENHAM_LINE

	push word [bp+6]
	push word [bp+4]
	push word [bp+14]
	push word [bp+12]
	call BRESENHAM_LINE

	pop bp
	ret 12 

; [ARGS: x, y, size]
FILL_SQUARE_FAST:
	push		bp
	mov			bp,sp
	; save cx and dx registers
	push		cx
	push		dx
	; set		cx at top x
	mov			cx, [bp+8]
	.loopX:
	; check if cx equal x+size
	mov			ax, [bp+4]
	add			ax, [bp+8]
	cmp			cx, ax
	je .end
	; reset y
	mov			dx, [bp+6]
		.loopY:
		mov			ax, [bp+4]
		add			ax, [bp+6]
		cmp			dx, ax
		je			.endY
		call		PRINT_PIXEL
		inc			dx
		jmp			.loopY
	.endY:
	inc			cx
	jmp			.loopX
	; end of loop 
	.end:
	; get back register & return
	pop			dx
	pop			cx
	pop			bp
	ret			6


DRAW_RECTANGLE_EXT:
; line width +12 
; x : +10
; y : +8
; w : +6
; h : +4
push bp
mov bp, sp

.loop:
cmp word[bp+12], 0
je .end

mov ax, [bp+10]
push ax
add ax, [bp+6]
push ax
push word[bp+8]
call HOR_LINE

mov ax, [bp+10]
push ax
add ax, [bp+6]
push ax
mov ax, [bp+8]
add ax, [bp+4]
push ax
call HOR_LINE

mov ax, [bp+8]
push ax
add ax, [bp+4]
push ax
push word [bp+10]
call VERT_LINE

mov ax, [bp+8]
push ax
add ax, [bp+4]
push ax
mov ax, [bp+10]
add ax, [bp+6]
push ax
call VERT_LINE

inc word[bp+10]
inc word[bp+8]
sub word[bp+6], 2
sub word[bp+4], 2
dec word[bp+12]
jmp .loop
.end:
pop bp
ret 10


FILL_RECTANGLE_DITHERING:
push bp
mov bp,sp 


; for x ( for y( )) 
push word[bp+10] ; bp-2 x to inc
push word[bp+8] ; bp -4  y to inc

.loopX:
mov ax, [bp+10]
add ax, [bp+6]
cmp word[bp-2], ax
je .end
	.loopY:
	; print pixel 
	mov cx, [bp - 2 ] ; x0
	mov dx, [bp - 4 ] ; y0
	; i will add to bl +8 if cx is multiple of 2 
	push bx
	test cl, 1
	jz .noditherA
	add bl, [bp+14] ; <<--- dither a offset
	.noditherA:
	test dl, 1
	jz .noditherB
	add bl, [bp+12] ; <<--- dither a offset
	.noditherB:
	call PRINT_PIXEL
	pop bx

	mov ax, [bp+8]
	add ax, [bp+4]
	cmp word[bp-4], ax
	je .Continue
	inc word[bp-4]
	jmp .loopY

.Continue:
mov ax, [bp+8]
mov word[bp-4], ax
inc word[bp-2]
jmp .loopX

.end:
add sp, 4
pop bp
ret 12


FILL_RECTANGLE:
push bp
mov bp,sp 
; arg : x y w h  ()
; x : +10
; y : +8
; w : +6
; h : +4

; for x ( for y( )) 
push word[bp+10] ; bp-2 x to inc
push word[bp+8] ; bp -4  y to inc

.loopX:
mov ax, [bp+10]
add ax, [bp+6]
cmp word[bp-2], ax
je .end
	.loopY:
	; print pixel 
	mov cx, [bp - 2 ] ; x0
	mov dx, [bp - 4 ] ; y0
	call PRINT_PIXEL

	mov ax, [bp+8]
	add ax, [bp+4]
	cmp word[bp-4], ax
	je .Continue
	inc word[bp-4]
	jmp .loopY

.Continue:
mov ax, [bp+8]
mov word[bp-4], ax
inc word[bp-2]
jmp .loopX

.end:
add sp, 4
pop bp
ret 8

DRAW_RECTANGLE:

push bp; 
mov bp, sp

; arg : x y w h  ()
; x : +10
; y : +8
; w : +6
; h : +4

; draw x y to x+w y ( HOR LINE)
; draw x y+h to x+w y+h (HOR LINE)


; HOR LINE push order : x0,x1,y

mov ax, [bp+10]
push ax
add ax, [bp+6]
push ax
push word[bp+8]
call HOR_LINE

mov ax, [bp+10]
push ax
add ax, [bp+6]
push ax
mov ax, [bp+8]
add ax, [bp+4]
push ax
call HOR_LINE



; draw x y to x y+h ( VERT LINE)
; draw x+w y to x+w y+h (VERT LINE)
; VERT LINE push order : y0,y1,x
mov ax, [bp+8]
push ax
add ax, [bp+4]
push ax
push word [bp+10]
call VERT_LINE

mov ax, [bp+8]
push ax
add ax, [bp+4]
push ax
mov ax, [bp+10]
add ax, [bp+6]
push ax
call VERT_LINE


pop bp
ret 8

CLR_SCREEN: 
; bh is the color
;mov ah, 06h    ; Scroll up function
;xor al, al     ; Clear entire screen
;xor cx, cx    ; Upper left corner CH=row, CL=column
;mov dx, 184FH  ; lower right corner DH=row, DL=column 
;int  10H

cld                    ; Set forward direction for STOSD
push es                ; Save ES if you want to restore it after
mov ax, 0xa000
mov es, ax             ; Beginning of VGA memory in segment 0xA000
mov ax, 0              ; Set the color to clear with 0x76 (green?) 0x00=black
xor di, di             ; Destination address set to 0
mov cx, (320*200)/4    ; We are doing 4 bytes at a time so count = (320*200)/4 DWORDS
rep stosd              ; Clear video memory
pop es                 ; Restore ES

ret



