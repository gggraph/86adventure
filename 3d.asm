
;; the mesh [primitive cube]
mesh    dd 12				; number of triangles
		; SOUTH
        dd 0.0, 0.0, 0.0,   0.0, 1.0, 0.0,    1.0,1.0,0.0 ;ok
		dd 0.0, 0.0, 0.0,   1.0, 1.0, 0.0,    1.0,0.0,0.0 ;ok
		; EAST
        dd 1.0, 0.0, 0.0,   1.0, 1.0, 0.0,    1.0,1.0,1.0 ;ok
		dd 1.0, 0.0, 0.0,   1.0, 1.0, 1.0,    1.0,0.0,1.0 ;ok
		; NORTH
        dd 1.0, 0.0, 1.0,   1.0, 1.0, 1.0,    0.0,1.0,1.0 ;ok
		dd 1.0, 0.0, 1.0,   0.0, 1.0, 1.0,    0.0,0.0,1.0 ;ok
		; WEST
        dd 0.0, 0.0, 1.0,   0.0, 1.0, 1.0,    0.0,1.0,0.0 ;ok
		dd 0.0, 0.0, 1.0,   0.0, 1.0, 0.0,    0.0,0.0,0.0 ;ok
		; TOP
        dd 0.0, 1.0, 0.0,   0.0, 1.0, 1.0,    1.0,1.0,1.0 ;ok
		dd 0.0, 1.0, 0.0,   1.0, 1.0, 1.0,    1.0,1.0,0.0 ;ok
		; BOTTOM
		dd 1.0, 0.0, 1.0,   0.0, 0.0, 1.0,    0.0,0.0,0.0 ;ok
		dd 1.0, 0.0, 1.0,   0.0, 0.0, 0.0,    1.0,0.0,0.0 ;ok

;; need to define 3  matrix (16word)
; projection matrix
; rotX matrix
; rotY matrix

projmat dd 1.0, 0.0, 0.0, 0.0
		dd 0.0, 1.0, 0.0, 0.0
		dd 0.0, 0.0, 1.0, 1.0
		dd 0.0, 0.0, 0.0, 0.0

rotxmat dd 1.0, 0.0, 0.0, 0.0
		dd 0.0, 0.0, 0.0, 0.0
		dd 0.0, 0.0, 0.0, 0.0
		dd 0.0, 0.0, 0.0, 1.0

rotzmat dd 0.0, 0.0, 0.0, 0.0
		dd 0.0, 0.0, 0.0, 0.0
		dd 0.0, 0.0, 1.0, 0.0
		dd 0.0, 0.0, 0.0, 1.0

w dd 0.1, 1000.0 ; not used ( only used for pointer_test )
fTheta dd 0.0

DRAW_MESH:
push bp
mov bp,sp

; add 0.01 to fTheta
fld dword[fTheta]
mov esi, __float32__(0.01)
push dword esi 
fadd dword [bp-4]
mov si, fTheta ; obligé de mettre l'addresse que je veux dans un registrer ... 
fstp dword[si]
add sp, 4 ; clear 0.01 ; ok

;matRotZ.m[0][0] = cosf(fTheta);
fld dword[fTheta]
fcos ; compute cosine of st0
mov si, rotzmat
fst dword[si] ; store in m00
add si, 20
fstp dword[si] ; pop and stor in m1.1

;matRotZ.m[0][1] = sinf(fTheta);
fld dword[fTheta]
fsin ; compute sine of st0
mov si, rotzmat ; load address of rotzmat 
add si, 4 ; add here to get m[x]
fstp dword[si] ; pop st0 in m0.1

;matRotZ.m[1][0] = -sinf(fTheta);
fld dword[fTheta]
fsin ; compute sine of st0
fchs ; negate st0
mov si, rotzmat ; load address of rotzmat 
add si, 16 ; add here to get m[x]
fstp dword[si] ; pop st0 in m1.0

;matRotX.m[1][1] = cosf(fTheta * 0.5f);
fld dword[fTheta]
mov esi, __float32__(0.5)
push dword esi 
fmul dword [bp-4]
add sp, 4
fcos ; compute cosine of st0
mov si, rotxmat
add si, 20
fst dword[si] ; store in m1.1
add si, 20
fstp dword[si] ; pop and stor in m2.2

;matRotX.m[1][2] = sinf(fTheta * 0.5f);
fld dword[fTheta]
mov esi, __float32__(0.5)
push dword esi 
fmul dword [bp-4]
add sp, 4
fcos ; compute cosine of st0
mov si, rotxmat
add si, 24
fstp dword[si] ; store in m1.2

;matRotX.m[2][1] = -sinf(fTheta * 0.5f);
fld dword[fTheta]
mov esi, __float32__(0.5)
push dword esi 
fmul dword [bp-4]
add sp, 4
fcos ; compute cosine of st0
fchs ; negate st0
mov si, rotxmat
add si, 36
fstp dword[si] ; store in m2.1

;draw triangles :)
mov ebx, dword[mesh] ; first 4 bytes in mesh tell number of triangles ... 
mov eax, dword 0; eax will be the counter 
mov dx, mesh    ; dx  contains mesh tri pointer 
add dx, 4 ; <-- start of the triangles in mesh 

.loop:
cmp eax, ebx
je .end


mov esi, __float32__(0.0)
xor cx,cx
.looppush:
cmp cx, 18 
je .continue
push dword esi ; 18 times (one 3dtriangle is 9 float or 3*3float ) pushing 2 triangles
inc cx
jmp .looppush
.continue:

; pointer to i bp+8
; pointer to o bp+6
; pointer to m bp+4
;triA; start at [bp-4]
;triB; start at [bp-40]

;// Rotate in Z-Axis
;MultiplyMatrixVector(tri.p[0], triA.p[0], matRotZ);
push dx
push word [bp-4]
push rotzmat
call MULTIPLYMATRIXVECTOR
;MultiplyMatrixVector(tri.p[1], triA.p[1], matRotZ);
mov si, dx
add si, 12 ; [tri p 1]
push si
mov si, bp
sub si, 16
push si ; tri A p 1
push rotzmat
call MULTIPLYMATRIXVECTOR
;MultiplyMatrixVector(tri.p[2], triA.p[2], matRotZ);
mov si, dx
add si, 24 ; [tri p 2]
push si
mov si, bp
sub si, 28
push si ; tri A p 2
push rotzmat
call MULTIPLYMATRIXVECTOR

;// Rotate in X-Axis
;MultiplyMatrixVector(triA.p[0], triB.p[0], matRotX);
mov si, bp
sub si, 4
push si ; tri A p 0
mov si, bp
sub si, 40
push si ; tri B p 1
push rotxmat
call MULTIPLYMATRIXVECTOR
;MultiplyMatrixVector(triA.p[1], triB.p[1], matRotX);
mov si, bp
sub si, 16
push si ; tri A p 1
mov si, bp
sub si, 52
push si ; tri B p 1
push rotxmat
call MULTIPLYMATRIXVECTOR
;MultiplyMatrixVector(triA.p[2], triB.p[2], matRotX);
mov si, bp
sub si, 28
push si ; tri A p 2
mov si, bp
sub si, 64
push si ; tri B p 2
push rotxmat
call MULTIPLYMATRIXVECTOR

;// Offset into the screen
;triB.p[0].z += 3.0f;
mov esi, __float32__(3.0) ; bp - 
push dword esi
fld dword[bp-48] ; triB.p[0].z
fadd dword[bp-76]
fstp dword[bp-48]
;triB.p[1].z += 3.0f;
fld dword[bp-60] ; triB.p[1].z
fadd dword[bp-76]
fstp dword[bp-60]
;triB.p[2].z += 3.0f;
fld dword[bp-72] ; triB.p[0].z
fadd dword[bp-76]
fstp dword[bp-72]
add sp, 4 ; clear 3.0

;// zeroing triA bp-4 to bp-40
xor cx,cx
mov si, bp
sub si, 4
.loopzeroing:
cmp cx, 9
je .continueB
mov dword [si], __float32__(0.0)
sub si, 4
inc cx
jmp .loopzeroing
.continueB:

;// Project triangles from 3D --> 2D
;MultiplyMatrixVector(triB.p[0], triA.p[0], matProj);
mov si, bp
sub si, 40
push si ; tri B p 0
mov si, bp
sub si, 4
push si ; tri A p 0
push projmat
call MULTIPLYMATRIXVECTOR

;MultiplyMatrixVector(triB.p[1], triA.p[1], matProj);
mov si, bp
sub si, 52
push si ; tri B p 1
mov si, bp
sub si, 16
push si ; tri A p 1
push projmat
call MULTIPLYMATRIXVECTOR
;MultiplyMatrixVector(triB.p[2], triA.p[2], matProj);
mov si, bp
sub si, 64
push si ; tri B p 2
mov si, bp
sub si, 28
push si ; tri A p 2
push projmat
call MULTIPLYMATRIXVECTOR

;; SCALE INTO VIEW 
mov esi, __float32__(1.0) ; bp - 
push dword esi
;triA.p[0].x += 1.0f; 
fld dword[bp-4] ; triA.p[0].x
fadd dword[bp-76]
fstp dword[bp-4]
;triA.p[0].y += 1.0f;
fld dword[bp-8] ; triA.p[0].y
fadd dword[bp-76]
fstp dword[bp-8]
;triA.p[1].x += 1.0f; 
fld dword[bp-16] ; triA.p[1].x
fadd dword[bp-76]
fstp dword[bp-16]
;triA.p[1].y += 1.0f;
fld dword[bp-20] ; triA.p[1].y
fadd dword[bp-76]
fstp dword[bp-20]
;triA.p[2].x += 1.0f; 
fld dword[bp-28] ; triA.p[2].x
fadd dword[bp-76]
fstp dword[bp-28]
;triA.p[2].y += 1.0f;
fld dword[bp-32] ; triA.p[2].y
fadd dword[bp-76]
fstp dword[bp-32]
add sp, 4 ; clear 1.0

mov esi, __float32__(160.0) ; bp - 76 : WINDOW_WIDTH : 320/2
push dword esi
mov esi, __float32__(50.0) ; bp - 80 : WINDOW_HEIGHT : 200/2
push dword esi

fld dword[bp-4] ; triA.p[0].x
fadd dword[bp-76]
fstp dword[bp-4]
;triA.p[0].y += 1.0f;
fld dword[bp-8] ; triA.p[0].y
fadd dword[bp-80]
fstp dword[bp-8]
;triA.p[1].x += 1.0f; 
fld dword[bp-16] ; triA.p[1].x
fadd dword[bp-76]
fstp dword[bp-16]
;triA.p[1].y += 1.0f;
fld dword[bp-20] ; triA.p[1].y
fadd dword[bp-80]
fstp dword[bp-20]
;triA.p[2].x += 1.0f; 
fld dword[bp-28] ; triA.p[2].x
fadd dword[bp-76]
fstp dword[bp-28]
;triA.p[2].y += 1.0f;
fld dword[bp-32] ; triA.p[2].y
fadd dword[bp-80]
fstp dword[bp-32]

add sp, 8; clear 

; build value for the need ! with fistp

fld dword[bp-4];triA.p[0].x
fistp dword[bp-4]
fld dword[bp-8];triA.p[0].y
fistp dword[bp-8]
fld dword[bp-16];triA.p[1].x
fistp dword[bp-16]
fld dword[bp-20];triA.p[1].y
fistp dword[bp-20]
fld dword[bp-28];triA.p[2].x
fistp dword[bp-28]
fld dword[bp-32];triA.p[2].y
fistp dword[bp-32]

; need to store eax, ebx, ecx, cause it is use 
push word[bp-4]
push word[bp-8]
push word[bp-16]
push word[bp-20]
push word[bp-28]
push word[bp-32]
CALL DRAW_TRIANGLE


add dx, 36 ; go to next tri mesh (9*4)
add sp, 72 ; clear all temp triangles (2*9*4) 
;jmp .loop
.end:
pop bp
ret

POINTER_TESTB: ; ok <3
push bp
mov bp,sp
; bp+4 is pointer to w ; objectif : multiplier w par w +4  -> it work
mov si, word[bp+4]
fld dword[si]
mov esi, __float32__(1000.0)
push dword esi
fmul dword[bp-4] ; ok :) 
fistp dword[bp+4]
mov eax, dword[bp+4] ; ; w +0 should now contains 80
add sp, 4
pop bp
ret 2



POINTER_TEST:
push bp
mov bp,sp
; bp+4 is pointer to w ; objectif : multiplier w par w +4  -> it work
mov si, word[bp+4]
fld dword[si]
add si, 4 ; jump next 4 bytes
fmul dword[si]
fistp dword[bp+4]
mov eax, dword[bp+4] ; ; w +0 should now contains 80
pop bp
ret 2



;; ------------ float data multiplication love
mov dword[fA], __float32__(2.0) ; load 2.0f at adress
fld dword [fA]                  ; push on float point unit
mov dword[fB], __float32__(10.0) ;load 10.0f at other adress
fmul  dword[fB] ; mul ; mul using address ( result in st 0 )
fistp dword [fA] ; convert float to int and pop to address
;fstp just do the same without converting 
mov eax, dword [fA] ; now load in eax :)

MULTIPLYMATRIXVECTOR:
push bp
mov bp,sp

; pointer to i bp+8
; pointer to o bp+6
; pointer to m bp+4

; o.x = i.x * m.m[0][0] + i.y * m.m[1][0] + i.z * m.m[2][0] + m.m[3][0]
; 
; i.x * m.m[0][0]
mov si, word[bp+8]
;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
;add si here to get o y(4) or z(8)
fstp dword[si]

;i.y * m.m[1][0]
mov si, word[bp+8]
add si, 4;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 16;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
;add si here to get o y(4) or z(8)
fadd dword[si] ; +=
fstp dword[si]

;i.z * m.m[2][0]
mov si, word[bp+8]
add si, 8;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 32;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
;add si here to get o y(4) or z(8)
fadd dword[si] ; +=
fstp dword[si]

;m.m[3][0]
mov si, word[bp+4]
add si, 48;add si here to get m[x]
fld dword[si]
mov si, word[bp+6]
;add si here to get o y(4) or z(8)
fadd dword[si] ; +=
fstp dword[si]

;o.y = i.x * m.m[0][1] + i.y * m.m[1][1] + i.z * m.m[2][1] + m.m[3][1];

; i.x * m.m[0][1] 
mov si, word[bp+8]
;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 4;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
add si, 4;add si here to get o y(4) or z(8)
fstp dword[si]

;i.y * m.m[1][1]
mov si, word[bp+8]
add si,4;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 20;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
add si, 4;add si here to get o y(4) or z(8)
fadd dword[si] ; ++
fstp dword[si]

;i.z * m.m[2][1]
mov si, word[bp+8]
add si,8;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 36;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
add si, 4;add si here to get o y(4) or z(8)
fadd dword[si] ; ++
fstp dword[si]

;m.m[3][1]
mov si, word[bp+4]
add si, 52;add si here to get m[x]
fld dword[si]
mov si, word[bp+6]
add si, 4;add si here to get o y(4) or z(8)
fadd dword[si] ; +=
fstp dword[si]

;o.z = i.x * m.m[0][2] + i.y * m.m[1][2] + i.z * m.m[2][2] + m.m[3][2];

; i.x * m.m[0][2]
mov si, word[bp+8]
;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 8;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
add si, 8;add si here to get o y(4) or z(8)
fstp dword[si]

;i.y * m.m[1][2]
mov si, word[bp+8]
add si,4;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 24;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
add si, 8;add si here to get o y(4) or z(8)
fadd dword[si] ; ++
fstp dword[si]

;i.z * m.m[2][2]
mov si, word[bp+8]
add si,8;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 40;add si here to get m[x]
fmul dword[si]
mov si, word[bp+6]
add si, 8;add si here to get o y(4) or z(8)
fadd dword[si] ; ++
fstp dword[si]

;m.m[3][2]
mov si, word[bp+4]
add si, 56;add si here to get m[x]
fld dword[si]
mov si, word[bp+6]
add si, 8;add si here to get o y(4) or z(8)
fadd dword[si] ; +=
fstp dword[si]

;; define w 
;float w = i.x * m.m[0][3] + i.y * m.m[1][3] + i.z * m.m[2][3] + m.m[3][3];

mov esi, dword 0
push dword esi

; i.x * m.m[0][3]
mov si, word[bp+8]
;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 12;add si here to get m[x]
fmul dword[si]
fstp dword[bp-4]

;i.y * m.m[1][3]
mov si, word[bp+8]
add si,4;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 28;add si here to get m[x]
fmul dword[si]
fadd dword[bp-4] ; ++
fstp dword[bp-4]

;i.z * m.m[2][3]
mov si, word[bp+8]
add si,8;add si here to get i y(4) or z(8)
fld dword[si]
mov si, word[bp+4]
add si, 44;add si here to get m[x]
fmul dword[si]
fadd dword[bp-4] ; ++
fstp dword[bp-4]

;m.m[3][3]
mov si, word[bp+4]
add si, 60;add si here to get m[x]
fld dword[si]
fadd dword[bp-4] ; ++
fstp dword[bp-4]

;if (w != 0.0f)
mov eax, dword[bp-4]
cmp eax, 0
je .end
; o.x /= w; 
mov si, word[bp+6]
;add si, 8;add si here to get o y(4) or z(8)
fld dword[si]
fdiv dword[bp-4]
fstp dword[si]
;o.y /= w; 
mov si, word[bp+6]
add si, 4;add si here to get o y(4) or z(8)
fld dword[si]
fdiv dword[bp-4]
fstp dword[si]
;o.z /= w; 
mov si, word[bp+6]
add si, 8;add si here to get o y(4) or z(8)
fld dword[si]
fdiv dword[bp-4]
fstp dword[si]

; clear w
add sp, 4

.end:
pop bp
ret 6



CLEARMATRIX:
push bp
mov bp,sp

xor ax, ax
mov bx, 16
mov si, word[bp+4] ; - [bp+4]point to matrix address

.loop:
cmp ax,bx
je .end
mov [si],dword 0
add si, 4 ; next 4 bytes
inc ax
jmp .loop

.end:
pop bp
ret 2


