;; we need to add scale function ( so a pixel mult ratio)

PRINT_BITMAP_16b24b:

; [bp+12] un petit kiff pour les mouvements de couleurs
;[bp+10]  is scaling
;[bp+8]  is x offset pos
;[bp+6]  is y offset pos
;[bp+4]  is bitmap binary pointer

push bp
mov bp, sp
 
xor edi, edi
mov di, [bp+4]

; bmp size is at  [esi]
; bit ptr is at   [esi+10]
; bit count is at [esi+28]




mov eax, 54 ; this is bitarray ptr. i mean it is always 54 for 16b and 24b
push eax ; the counter at [bp-4]

mov ax, word[edi+28]
cmp ax, 16
je .ea
cmp ax, 24
je .eb
.ea:
push 2
jmp .n
.eb:
push 3
jmp .n
; here i could do handle erro
.n:

; proccess padding. 

mov eax,  dword [edi+18] 
xor ecx, ecx
mov cx, [bp-6]
mul ecx
and eax, ecx ; we can also use test 
cmp eax, 0
je .next

.conda:
mov edx, 4
sub edx, eax
push dx
jmp .next
.condb:
xor edx, edx
push dx
.next:


;mov eax, 0x18 ; 
;cmp al, [edi+28]
;jne .end ; this is not a 24 bit depth bitmap; nop

; cx and dx has to be respectively x and y , bl is color 
xor edx, edx
mov dx, [bp+6]
add edx, dword[edi+22] ; i got 0 but it should be 16 i dont understant
dec edx



.loopY:
xor eax, eax
mov ax,  [bp+6] ; should clear either low or high then 

cmp edx, eax
jl .end
xor ecx, ecx
mov cx, [bp+8]

	
	.loopX:
	
	xor eax, eax
	mov ax,  [bp+8] ; should clear either low or high then 
	add eax,  dword [edi+18] ; this is an int i guess
	cmp ecx, eax
	je .endX
	;;------------ PRINT THE PIXEL HERE 
	
	
	; we will do some hack here to convert to grayscale:  
	xor ebx, ebx
	mov esi, dword[bp-4]; the counter
	mov bl,  [edi+esi+1] ; 
	shr bl, 5
	add bl, [bp+12]; -------------------- : normal grayscale10h
	;mov bh, 10h
	add si, [bp-6] ; ca devrait etre trois . mais je n'obtiens pas trois .
	mov dword[bp-4], esi
	
	;bmp scaling ( we could use fast scaling using multiple of 2 . but lets go )

	push edi
	push ecx
	push edx

	
	push 10; dither a
	push 2; dither b
	xor edi, edi
	mov eax, ecx
	mov di, [bp + 8]
	sub eax, edi
	xor edi, edi
	mov di, [bp+10] ; scale
	push edx
	mul edi
	pop edx
	xor edi, edi
	mov di, [bp + 8]
	add eax, edi
	push ax

	xor edi, edi
	mov eax, edx
	mov di, [bp +6]
	sub eax, edi
	xor edi, edi
	mov di, [bp+10] ; scale
	push edx
	mul edi
	pop edx
	xor edi, edi
	mov di, [bp + 6]
	add eax, edi
	push ax

	xor edi, edi
	mov di, [bp+10] ; scale
	push di
	push di

	call FILL_RECTANGLE_DITHERING
	;call FILL_SQUARE_FAST ; <<--- this is not working because it is overwriting previous pixel. if we want to scale it. it should be (+x*scale) (origin+yscale)
	;call PRINT_PIXEL

	pop edx
	pop ecx
	pop edi
	
	inc ecx
	jmp .loopX
	

.endX:

; we need to add trailing byte if width is not multiple of 4 .  ( so inc esi by one )
; pad is at [bp-8]
xor esi, esi
add si,  [bp-8];
add esi, dword[bp-4];
mov dword[bp-4], esi

dec edx
jmp .loopY

.end:
add sp, 8
pop bp
ret 10

;; this is an alone field to concat bmp & testing stuff
mbmp: