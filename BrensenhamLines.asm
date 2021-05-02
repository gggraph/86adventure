;-------------- CALL EXEMPLE ----------------
push 100  ; ax
push 30  ; ay
push 200  ; bx
push 160 ; by
call BRESENHAM_LINE ; 
;-------------------------------------------
; using VGA mode 

BRESENHAM_LINE: 
;[bp+8] ; x0
;[bp+6] ; y0
;[bp+4] ; x1
;[bp+2] ; y1 
mov bp, sp

;; define dx
mov ax, [bp+4]     ; x1 in ax
mov bx, [bp+8]     ; x0 in bx
sub ax, bx
push ax ; store the result in dx    ok -->  bp - 2
;; define dy
mov ax, [bp+2]     ; y1 in ax
mov bx, [bp+6]     ; y0 in bx
sub ax, bx
push ax ; store the result in dy    ok --> bp - 4 
;; define p
;; 2*(dy-dx)
mov ax, [bp-4] ; dy
mov bx, [bp-2] ; dx
sub ax, bx
; mul (always store in a register)
mov cx, 2
mul cx ; should try a shift ... probably a lot more efficient 
push ax ; store the result           ok --> bp - 6 
;; define x
mov ax, [bp+8]
push ax ; ok  ---> bp - 8
;; define y
mov ax, [bp+6] ;; this bread
push ax ; ok ---> bp - 10 


bline_loop: ; (while x < x1 )

; ax doit toujour etre superieur a machine
; do the first check : if x<x1 continue else stop 
mov ax, [bp-8]
cmp ax, [bp+4]
jge  bline_end                                 ; (or jae for unsigned ) ok 


;  first draw the pixel 
mov ah, 0ch
mov bh, 0
mov al, 50 ; color
mov cx, [bp - 8 ] ; start pos x
mov dx, [bp - 10 ] ; start pos y
int 10h ;                                    ok 


mov ax, [bp-6] ; si p est inferieur a 0 jump to bline else 
cmp ax, 0
jl bline_else ;; or jb but jl ( signed seem more normal 
; -- the p1 here 

; ---- y++
inc word [bp - 10 ]    ; ok ... 
; ---- p = p+(2*dy)-(2*dx) ; or  -- p = (2*dy) -- p -= (2*dx) -- p += p 

mov ax, [bp-4]
mov cx, 2
mul cx ; should try a shift ... probably a lot more efficient 
add [bp-6], ax

mov ax, [bp-2]
mov cx, 2
mul cx ; should try a shift ... probably a lot more efficient 
sub [bp-6], ax



jmp bline_eloop
bline_else:
; -- the p2 here

; ---- p = p+(2*dy) ; or  -- p += (2*dy) -- -- p += p 
mov ax, [bp-4]
mov cx, 2
mul cx ; should try a shift ... probably a lot more efficient 
add [bp-6], ax

bline_eloop:  
; ---- x++
inc word [bp - 8 ]
jmp bline_loop

bline_end: ; need to pop cause some variable (the four ) are again in the stack ... 
; probably need to pop *5 ... 
ret 
