; --------------------------------
; adding  croping parameters
;---------------------------------
PRINT_BITMAP:

; [bp+1] un petit kiff pour les mouvements de couleurs
;[bp+12]  is scaling
;[bp+10]  is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is bitmap binary pointer

push bp
mov bp, sp
 
mov edi,  [bp+4]

; bmp size is at  [esi]
; bit ptr is at   [esi+10]
; bit count is at [esi+28]



; get bit array offset
cmp word[edi+28], 8  
jg .16bp
; is at [edi+46](biClrUsed) * 4 + 54 
mov eax, [edi+46]
shl eax, 2 ; mult by 4
add eax, 54
push eax
jmp .af

.16bp:
mov eax, 54 ; this is bitarray ptr. i mean it is always 54 for 16b and 24b
push eax ; the counter at [bp-4]

.af:
 ; number of byte is word[edi+28]
xor eax, eax
mov ax, word[edi+28]
; divide it per 8 
shr ax, 3
push ax

; proccess padding. 

mov eax,  dword [edi+18]  ; load bmp with in eax
xor ecx, ecx
mov cx, [bp-6]
mul ecx
mov ecx, 3
and eax, ecx 
cmp eax, 0
je .condb

mov edx, 4
sub edx, eax
push dx
jmp .next
.condb:
push word 0
.next:


; cx and dx has to be respectively x and y , bl is color 
xor edx, edx
mov dx, [bp+8]
add edx, dword[edi+22] ; i got 0 but it should be 16 i dont understant
dec edx


.loopY:
xor eax, eax
mov ax,  [bp+8] ; should clear either low or high then 

cmp edx, eax
jl .end
xor ecx, ecx
mov cx, [bp+10]

	
	.loopX:
	
	xor eax, eax
	mov ax,  [bp+10] ; should clear either low or high then 
	add eax,  dword [edi+18] ; this is an int i guess
	cmp ecx, eax
	je .endX
	;;------------ PRINT THE PIXEL HERE 
	
	
	; we will do some hack here to convert to grayscale:  
	xor ebx, ebx
	mov esi, dword[bp-4]; the counter
	
	
	;bmp scaling ( we could use fast scaling using multiple of 2 . but lets go )

	
	; ---------------------------- GET THE COLOR DEPENDING OF BIT DEPTH ( read colore palette or not )  ----------------------------
	cmp word[edi+28], 8  
	jg .nocolortable
	; r g b is at file + 54 +  [edi+esi+1] * 4
	xor eax, eax
	mov al, [edi+esi+1] ; read color table index
	shl al, 2 ; mult by 4
	add eax, 54 ; add 54 b off 
	mov bl, [edi+eax+1]
	jmp .convertgrayscale

	.nocolortable:
	mov bl,  [edi+esi+1] 

	.convertgrayscale:
	; ---------------------------------------------------------------------------------------------------------------
	shr bl, 5
	add bl, [bp+14]; -------------------- : normal grayscale10h
	;mov bh, 10h
	add si, [bp-6] ; increment array ptr (by one, two or three)
	mov dword[bp-4], esi

	push edi
	push ecx
	push edx

	push 10; dither a
	push 2; dither b
	xor edi, edi
	mov eax, ecx
	mov di, [bp + 10]
	sub eax, edi
	xor edi, edi
	mov di, [bp+12] ; scale
	push edx
	mul edi
	pop edx
	xor edi, edi
	mov di, [bp + 10]
	add eax, edi
	push ax

	xor edi, edi
	mov eax, edx
	mov di, [bp +8]
	sub eax, edi
	xor edi, edi
	mov di, [bp+12] ; scale
	push edx
	mul edi
	pop edx
	xor edi, edi
	mov di, [bp + 8]
	add eax, edi
	push ax

	xor edi, edi
	mov di, [bp+12] ; scale
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

mbmp:
