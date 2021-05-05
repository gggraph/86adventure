


setup_vga_mode:
mov ah, 00h
mov al, 13h
int 10h


caller:

;; mouse init
call mouse_initialize
call mouse_enable           ; Enable the mouse
sti


call DRAW_MESH
push word w
call POINTER_TESTB
push ax
push 10
push 50
push 20
push 220
push 150
call DRAW_TRIANGLE
.loopmesh:

jmp .loopmesh

jmp end
;; moving a triangle test
moving_triangle:

.loop:
xor eax,eax
mov bh, 0 ; 80 nice color here ( yellow)
call CLR_SCREEN

push 50
push 10
push 50
push 100
call FILL_RECTANGLE

push 60
push 10
push 90
push 80
; use mouse x to test stuff
mov ax, [mouseX]
push ax
call MOUSE_POS_TO_SCREEN
push ax
mov ax, [mouseY]
push ax
call MOUSE_POS_TO_SCREEN
push ax
call DRAW_TRIANGLE

push 60
push 10
push 230
push 80
; use mouse x to test stuff
mov ax, [mouseX]
push ax
call MOUSE_POS_TO_SCREEN
push ax
mov ax, [mouseY]
push ax
call MOUSE_POS_TO_SCREEN
push ax
call DRAW_TRIANGLE

push 90
push 80
push 230
push 80
; use mouse x to test stuff
mov ax, [mouseX]
push ax
call MOUSE_POS_TO_SCREEN
push ax
mov ax, [mouseY]
push ax
call MOUSE_POS_TO_SCREEN
push ax
call DRAW_TRIANGLE


mov al, 0
mov ah, 86h
mov cx, 0
mov dx, 15
int 0x15 ;

jmp .loop

jmp end
end:
jmp end


fA dd  100 ; 8.0f
fB dd  1090519040 ; 8.0f

MOUSE_POS_TO_SCREEN: ; will store in ax
push bp
mov bp,sp
; bp+4 is mpos
mov cx, [bp+4] ; keep lower
;shr cl, 1
mov ch, 0
mov ax,[bp+4]
cmp ah, 2
ja .stateB ; dont do anything
xor ah, ah
mov al, cl
mov cx, 4
;mul ax ; multiply per 2 
jmp .end
.stateB:
xor ah, ah
mov al, cl
mov cx, 2
;mul ax ; multiply per 2 
.end:
pop bp
ret 2

%include "system.asm"
%include "graphics.asm"
%include "mouse.asm"
%include "3d.asm"

;sector padding magic
;times 512-($-$$) db 0