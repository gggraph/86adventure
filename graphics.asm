; a simple graphic library 
;-------------------- CALL CONVENTION -----------------
push 10
push 10
push 50
push 20
push 30
push 80
call DRAW_TRIANGLE
;-----------------------------------------------------

VERT_LINE:
;[bp+8] ; x1
;[bp+6] ; y1
;[bp+4] ; y0 

push bp
mov bp,sp 

.loop:
; while ( y0 < y1 ) y++ draw(xy)
mov ax, [bp+4]
cmp ax, [bp+6]
ja .endloop
; draw pixel 
mov ah, 0ch
mov bh, 0
mov al, 50 ; color
mov cx, [bp +8 ] ; start pos x
mov dx, [bp +4 ] ; start pos y
int 10h ;     
; inc y0
inc word [bp+4]
jmp .loop
.endloop:
pop bp
ret 6 ; clear stack here

HOR_LINE:

push bp
mov bp,sp 
.loop:
; while ( x0 < x1 ) x++ draw(xy)
mov ax, [bp+4]
cmp ax, [bp+6]
ja .endloop
; draw pixel 
mov ah, 0ch
mov bh, 0
mov al, 50 ; color
mov cx, [bp +4 ] ; start pos x
mov dx, [bp +8 ] ; start pos y
int 10h ;     
; inc y0
inc word [bp+4]
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
mov bx, 0 ; security ?
mov ah, 0ch
mov bh, 0
mov al, 50 ; color
mov cx, [bp + 10 ] ; x0
mov dx, [bp + 8 ] ; y0
int 10h ;   ; ok 

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


DRAW_TRIANGLE:
;[bp+14] ; x0
;[bp+12] ; y0
;[bp+10] ; x1
;[bp+8] ; y1 
;[bp+6] ; x2
;[bp+4] ; y2

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

;add sp, 24 ; ----------> we dont need to clear args here cause bresenham already clear the arg . we need to clear it if no clearing during process
ret 12 ; clear stack 



