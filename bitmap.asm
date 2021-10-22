
PRINT_SPRITE_CUSTOMFORMAT:
push bp
mov bp,sp

;[bp+18] is scaling
;[bp+16] is color
;[bp+14] is spritesize
;[bp+12] is spritenumber
;[bp+10] is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is bitmap binary pointer

;int ystart = (spritenumber / spritesperline) * spritesize;
mov ax, [bp+12]
shr ax, 2 ; div by 4
mul word[bp+14]
push ax ; [bp-2] 


;int xstart = (spritenumber * spritesize) - (ystart*spritesperline)

mov ax, [bp+12]
mov cx, [bp+14]
mul cx
push ax ; [bp-4]
mov ax, [bp-2]
shl ax, 2   ; mul by spritesperlines...
sub word [bp-4], ax


push word[bp+14]
push word[bp+14]
push word[bp-4]
push word[bp-2]
push word[bp+16]
push word[bp+18]
push word[bp+10]
push word[bp+8]
push dword[bp+4];
call PRINT_CUSTOM_8BIT_FORMAT

add sp, 4
pop bp
ret 16

GET_MAP_FLAG :
;[bp+10] is x pos
;[bp+8]  is y pos
;[bp+4]  is flags binary pointer
; return value in a register
push bp
mov bp, sp
; map cell data is at 8+(y*w)+x
mov edi, [bp+4]
mov ax, word[edi]
mul word[bp+8]
add ax, 8
add ax, word[bp+10]
xor esi, esi
mov si, ax
mov ax, word[edi+esi]
pop bp
ret 8


REPLACE_SPRITE :
;[bp+14] sprite index ; 
;[bp+12] sprite size
;[bp+10] pixel x coordinate
;[bp+8]  pixel y coordinate
;[bp+4]  is MAP binary pointer

push bp
mov bp, sp

mov edi, [bp+4]
; get offset 
mov ax ,[bp+10]
mov bx, [bp+12]
div bl
xor ah, ah
mov word[bp-2], ax
mov ax ,[bp+8]
mov bx, [bp+12]
div bl
xor ah, ah
mov word[bp-4], ax

; sprite index is at (8+(y*mapwidth)+x) 
mov esi, 8 
mov eax, [edi]   ; map width
mul word[bp-4]
add ax, [bp-2]
add si, ax
xor ax, ax
mov ax, [bp+14] 
mov byte[edi+esi],al

pop bp
ret 11



PRINT_MAP_SPRITE_EXT:
;[bp+22] offsetPosX
;[bp+20] offsetPosY
;[bp+16]  is SPRITESHEET binary pointer
;[bp+14] sprite size 
;[bp+12] pixel coordinate x
;[bp+10] pixel coordinate y 
;[bp+8]  scaling
;[bp+4]  is MAP binary pointer

push bp
mov bp, sp

mov edi, [bp+4] 

; ---------------[1]	get sprite offset [each sprite 8*8]-------------- [OK]
; divide coordinate x=16 and y = 16 will print maptile x=2 and y=2
mov ax ,[bp+12]
mov bx, [bp+14]
div bl
; al contains quotient, ah contains remainder 
; save the divide operation 
xor bx, bx
mov bl, ah
xor ah, ah
push ax
push bx
; now bp-2 contains real x sprite tile and bp-4 contains pixel start of the one 
mov ax ,[bp+10]
mov bx, [bp+14]
div bl
; al contains quotient, ah contains remainder 
; save the divide operation 
xor bx, bx
mov bl, ah
xor ah, ah
push ax
push bx
; now bp-6 contains real x sprite tile and bp-8 contains pixel start of the one 



; ---------------[2]	get map cell index [x = bp-2, y = bp-6]-------------- OK
; sprite index is at (8+(y*mapwidth)+x) 
mov esi, 8 
mov eax, [edi]   ; map width
mul word[bp-6]
add ax, [bp-2]
add si, ax
xor ax, ax
mov al, byte [edi+esi]
push ax


; ---------------[3]	get sprite coordinate in spritesheet -------------- OK

;int ystart = (spritenumber / spritesperline) * spritesize;
mov ax, [bp-10]
shr ax, 2 ; div by 4
mul word[bp+14]
push ax


;int xstart = (spritenumber * spritesize) - (ystart*spritesperline)

mov ax, [bp-10]
mov cx, [bp+14]
mul cx
push ax
mov ax, [bp-12]
shl ax, 2   ; mul by spritesperlines...
sub word [bp-14], ax

; some example test : i mean here it is ok 



; ---------------[4]	PRINT THE SPRITE MINUS REMAINDERS --------------
;[bp+22] width (cropped)
;[bp+20] height (cropped)
;[bp+18] xstart
;[bp+16] ystart
;[bp+14] un petit kiff pour les mouvements de couleurs
;[bp+12]  is scaling
;[bp+10]  is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is IMAGE binary pointer

; width is spritesize - remainder x
mov ax, word[bp+14]
sub ax, word[bp-4]
push ax          ; - remainder x
; height is spritesize - remainder y 
mov ax, word[bp+14]
sub ax, word[bp-8]
push ax          ; -remainder y

; xstart is  bp-14 + remainder x
mov ax,  word[bp-14]
add ax, word[bp-4]
push ax          ; + remainder x


mov ax, word[bp-12]
add ax, word[bp-8]
push ax ; + remainder y
push 0           ; color
push word[bp+8]  ; scaling
push word[bp+22] ; offX
push word[bp+20] ; offY
push dword[bp+16];
call PRINT_CUSTOM_8BIT_FORMAT

add sp, 14
pop bp
ret 20

PRINT_MAP_EXT2:

push bp 
mov bp, sp 

mov dx, [bp+10]
.loopY:
mov ax, [bp+10]
add ax, [bp+14]
cmp dx, ax
jae .end
mov cx, [bp+12]
	.loopX:
	mov ax, [bp+12]
	add ax, [bp+16]
	cmp cx, ax
	jae .endX
	
	pusha

	; adjust placement X is (cx-startx) * scale
	push dx
	mov ax, cx 
	sub ax, [bp+12]
	mul word[bp+8]
	pop dx
	add ax, [bp+20]; <----- here
	push ax
	push dx
	mov ax, dx 
	sub ax, [bp+10]
	mul word[bp+8]
	pop dx
	add ax, [bp+18]; <----- here
	push ax
	xor eax, eax
	mov ax, mapsheet
	push eax
	push 8
	push cx
	push dx
	push 2
	push dword[bp+4]
	call PRINT_MAP_SPRITE_EXT


	popa
     mov ax , cx
     mov bx, 8
     div bl
     xor bx, bx
     mov bl, ah
     mov [bp-2], bx

	 mov ax, 8
	 sub ax, [bp-2] 
	 add cx, ax 
	
	jmp .loopX
.endX:

mov ax , dx
mov bx, 8
div bl

xor bx, bx
mov bl, ah
mov [bp-2], bx
mov ax, 8
sub ax, [bp-2] 
add dx, ax 


jmp .loopY
.end:

pop bp
ret 18


PRINT_MAP_EXT:

push bp 
mov bp, sp 

mov dx, [bp+10]
.loopY:
mov ax, [bp+10]
add ax, [bp+14]
cmp dx, ax
jae .end
mov cx, [bp+12]
	.loopX:
	mov ax, [bp+12]
	add ax, [bp+16]
	cmp cx, ax
	jae .endX
	
	pusha

	; adjust placement X is (cx-startx) * scale
	push dx
	mov ax, cx 
	sub ax, [bp+12]
	mul word[bp+8]
	pop dx
	push ax
	push dx
	mov ax, dx 
	sub ax, [bp+10]
	mul word[bp+8]
	pop dx
	push ax
	xor eax, eax
	mov ax, mapsheet
	push eax
	push 8
	push cx
	push dx
	push 2
	push dword[bp+4]
	call PRINT_MAP_SPRITE_EXT


	popa
	; ----------------------------- GET CURRENT CX REMAINDER ---------------------------
     mov ax , cx
     mov bx, 8
     div bl
     ; al contains quotient, ah contains remainder 
     ; save the divide operation 
     xor bx, bx
     mov bl, ah
     mov [bp-2], bx

	 mov ax, 8
	 sub ax, [bp-2] ; nop here we need custom cx remainder ! 
	 add cx, ax 
	
	jmp .loopX
.endX:

; get CURRENT CY REMAINDER
mov ax , dx
mov bx, 8
div bl
; al contains quotient, ah contains remainder 
; save the divide operation 
xor bx, bx
mov bl, ah
mov [bp-2], bx
mov ax, 8
sub ax, [bp-2] ; nop here we need custom cx remainder ! 
add dx, ax 


jmp .loopY
.end:

pop bp
ret 14




PRINT_MAP : 
; this AS EXACTLY SAME FORMAT AS  PRINT_CUSTOM_8BIT_FORMAT
;[bp+22] width (cropped)
;[bp+20] height (cropped)
;[bp+18] xstart
;[bp+16] ystart
;[bp+14] color
;[bp+12] scaling
;[bp+10] is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is MAP binary pointer

push bp
mov bp, sp
mov edi, [bp+4] 


; si cropwidth = 0 ou cropheight = 0, mettre a [edi+18] et [edi+22]
mov ax, [bp+22]
cmp ax, 0
jne .cd
mov eax, [edi]
mov [bp+22], ax
.cd:
mov ax, [bp+20]
cmp ax, 0
jne .ce
mov eax, [edi+4]
mov [bp+20], ax


.ce:
xor eax, eax
mov ax, [bp+22]
add ax, [bp+18]
cmp eax, dword[edi]
jle .ca
mov eax, dword[edi]
sub ax , [bp+18]
mov [bp+22], ax
.ca:
mov ax, [bp+20]
add ax, [bp+16]
cmp eax, dword[edi+4]
jle .cc
mov eax, dword[edi+4]
sub ax , [bp+16]
mov [bp+20], ax

.cc:
mov ax, [bp+22]
cmp ax, 0
jle .end
mov ax, [bp+20]
cmp ax, 0
jle .end

; need a byte jump for first startY+startX
; then another bytejump for 


mov esi , 8 
; jump to desired line (so esi += ystart *w)
mov ax, [bp+16]
mul word[edi] ; mul by w
add si, ax

xor dx, dx
xor cx, cx
.loopY:
cmp dx, [bp+20]
je .end
xor cx, cx

; adjust to xstart 
add si, [bp+18]
	

	.loopX:
	cmp cx, [bp+22]
	je .endX

	; read the sprite number 
	xor ebx, ebx
	mov bl, [edi+esi]
	cmp bx, 255 
	jne .next
	mov bx, 13 ; a place holder somewhat
	.next:
	push edi
	push ecx
	push edx
	push esi

	push word[bp+12]
	push word[bp+14]
	push 8
	push bx

	
	; X equal (cx * scale * spritesize) + offX)
	push dx
	mov ax, cx
	mul word[bp+12]
	mov dx, 8
	mul dx
	pop dx
	add ax, [bp+10]
	push ax
	
	; Y equal dx * scale * spritesize + offY
	push dx
	mov ax, dx
	mul word[bp+12]
	mov dx, 8
	mul dx
	pop dx
	add ax, [bp+ 8]
	push ax

	xor eax, eax
    mov ax, mapsheet
    push  eax	

	call PRINT_SPRITE_CUSTOMFORMAT
	
	; print the sprite
	;[bp+18] is scaling
    ;[bp+16] is color
    ;[bp+14] is spritesize
    ;[bp+12] is spritenumber
    ;[bp+10] is x offset pos
    ;[bp+8]  is y offset pos
    ;[bp+4]  is bitmap binary pointer
	
	pop esi
	pop edx
	pop ecx
	pop edi 

	 
	.enddraw:
    inc cx
	inc esi
	jmp .loopX

.endX: 

;zeroing line ptr and adjust to next line
sub si, [bp+18]
sub si, [bp+22]
add si, [edi] 

inc dx
jmp .loopY
.end:
pop bp
ret 20

PRINT_CUSTOM_8BIT_FORMAT:
;[bp+22] width (cropped)
;[bp+20] height (cropped)
;[bp+18] xstart
;[bp+16] ystart
;[bp+14] un petit kiff pour les mouvements de couleurs
;[bp+12]  is scaling
;[bp+10]  is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is IMAGE binary pointer

push bp
mov bp, sp
mov edi, [bp+4] 


; si cropwidth = 0 ou cropheight = 0, mettre a [edi+18] et [edi+22]
mov ax, [bp+22]
cmp ax, 0
jne .cd
mov eax, [edi]
mov [bp+22], ax
.cd:
mov ax, [bp+20]
cmp ax, 0
jne .ce
mov eax, [edi+4]
mov [bp+20], ax


.ce:
xor eax, eax
mov ax, [bp+22]
add ax, [bp+18]
cmp eax, dword[edi]
jle .ca
mov eax, dword[edi]
sub ax , [bp+18]
mov [bp+22], ax
.ca:
mov ax, [bp+20]
add ax, [bp+16]
cmp eax, dword[edi+4]
jle .cc
mov eax, dword[edi+4]
sub ax , [bp+16]
mov [bp+20], ax

.cc:
mov ax, [bp+22]
cmp ax, 0
jle .end
mov ax, [bp+20]
cmp ax, 0
jle .end

; need a byte jump for first startY+startX
; then another bytejump for 


mov esi , 8 
; jump to desired line (so esi += ystart *w)
mov ax, [bp+16]
mul word[edi] ; mul by w
add si, ax

xor dx, dx
xor cx, cx
.loopY:
cmp dx, [bp+20]
je .end
xor cx, cx

; adjust to xstart 
add si, [bp+18]
	

	.loopX:
	cmp cx, [bp+22]
	je .endX

	xor ebx, ebx
	mov bl, [edi+esi]
	; fast stuff here if it is cursor. dont print black 
	mov ax, cursorsheet
	cmp di, ax
	jne .n
	cmp bl, 0
	jne .n
	jmp .enddraw
	.n:
	push edi
	push ecx
	push edx

	push 0;10; dither a
	push 0;3; dither b

	; X equal cx * scale + offY
	push dx
	mov ax, cx
	mul word[bp+12]
	pop dx
	add ax, [bp+10]
	push ax
	
	; Y equal dx * scale + offY
	push dx
	mov ax, dx
	mul word[bp+12]
	pop dx
	add ax, [bp+ 8]
	push ax

	push word [bp+12]
	push word [bp+12]
	; ditA
	; dit B
	; X
	; Y
	; W
	; H
	call FILL_RECTANGLE_DITHERING

	pop edx
	pop ecx
	pop edi
	
	.enddraw:

    inc cx
	inc esi
	jmp .loopX

.endX: 

;zeroing line ptr and adjust to next line
sub si, [bp+18]
sub si, [bp+22]
add si, [edi]

inc dx
jmp .loopY
.end:
pop bp
ret 20


PRINT_SPRITE:
push bp
mov bp,sp

;[bp+18] is scaling
;[bp+16] is color
;[bp+14] is spritesize
;[bp+12]  is spritenumber
;[bp+10]  is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is bitmap binary pointer

;int ystart = (spritenumber / spritesperline) * spritesize;
mov ax, [bp+12]
shr ax, 3 ; div by 8
mul word[bp+14]
push ax ; [bp-2]

;int xstart = (spritenumber*spritesize) - (ystart*spritesize);
mov ax, [bp+12]
mov cx, [bp+14]
mul cx
push ax ; [bp-4]
mov ax, [bp-2]
mul cx
sub word [bp-4], ax


push word[bp+14]
push word[bp+14]
push word[bp-4]
push word[bp-2]
push word[bp+16]
push word[bp+18]
push word[bp+10]
push word[bp+8]
push dword[bp+4];
call PRINT_BITMAP_BW
add sp, 4
pop bp
ret 16

phrase2 db 'zzzzzzzzzzzzzzzzz ', 0
phrase db 'hello les bimmeurz ', 0 


PRINT_CHAR_BMP:

;[bp+12] is scaling
;[bp+10] is color
;[bp+8]  is x offset pos
;[bp+6]  is y offset pos
;[bp+4]  char 


push bp
mov bp,sp
xor ax, ax
mov al, [bp+4]
push word [bp+12] ;8 ; scaling
push word [bp+10] ;20 ; color
push 8 ;sprite size
; sprite number start at 97
sub al, 97
push ax ; sprite number
push word [bp+8] ; x
push word [bp+6] ; y
xor eax, eax
mov ax, fonttest
push eax
call PRINT_SPRITE
	

.end:
pop bp
ret 10

PRINT_WORD_BMP:

;[bp+12] is scaling
;[bp+10] is color
;[bp+8]  is x offset pos
;[bp+6]  is y offset pos
;[bp+4]  ptr de la phrase

push bp
mov bp,sp
push word [bp+8] ; x at bp-2
push word [bp+6] ; y at bp-4
mov si, [bp+4]

	.loopw: 
	
	xor ax, ax
	mov al, [si]
	cmp al, 0
	je .end
	cmp al,32
	je .enddraw
	push si
	push word [bp+12] ;8 ; scaling
	push word [bp+10] ;20 ; color
	push 8 ;sprite size
	; sprite number start at 97
	sub al, 97
	push ax ; sprite number
	push word [bp-2] ; x
	push word [bp-4] ; y
	xor eax, eax
	mov ax, fonttest
	push eax
	call PRINT_SPRITE
	pop si
	mov ax, [bp+12]
	shl ax, 3
	add word[bp-2], ax
	cmp word[bp-2], 280
	jl .enddraw
	mov ax, [bp+8] 
	mov word[bp-2], ax
	mov ax, [bp+12]
	shl ax, 3
	add word[bp-4], ax
	.enddraw:
	
	inc si
	jmp .loopw
.end:
pop bp
add sp, 4
ret 10



PRINT_BITMAP_ADVANCED:
;[bp+22] width (cropped)
;[bp+20] height (cropped)
;[bp+18] xstart
;[bp+16] ystart
;[bp+14] un petit kiff pour les mouvements de couleurs
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

; si cropwidth = 0 ou cropheight = 0, mettre a [edi+18] et [edi+22]
mov ax, [bp+22]
cmp ax, 0
jne .cd
mov eax, [edi+18]
mov [bp+22], ax
.cd:
mov ax, [bp+20]
cmp ax, 0
jne .ce
mov eax, [edi+22]
mov [bp+20], ax


;	if (cropwidth + xstart > biWidth)
;		cropwidth = biWidth - xstart;
;	if (cropheight + ystart> biHeight)
;		cropheight = biHeight - ystart;
;	if (cropheight < 0 || cropwidth < 0)
;		return 0;

.ce:
xor eax, eax
mov ax, [bp+22]
add ax, [bp+18]
cmp eax, dword[edi+18]
jle .ca
mov eax, dword[edi+18]
sub ax , [bp+18]
mov [bp+22], ax
.ca:
mov ax, [bp+20]
add ax, [bp+16]
cmp eax, dword[edi+22]
jle .cc
mov eax, dword[edi+22]
sub ax , [bp+16]
mov [bp+20], ax

.cc:
mov ax, [bp+22]
cmp ax, 0
jle .end
mov ax, [bp+20]
cmp ax, 0
jle .end


; adjusting offset to the desired raw
;ystart = biHeight - ystart;
mov eax, [edi+22]
sub ax, [bp+16]
mov word [bp+16], ax
;boff += ((3 * biWidth)*ystart) + (ystart * pad);
mov eax , [edi+18]
mov cx, [bp-6]
mul cx
mov cx, [bp+16]
mul cx
mov bx, ax
mov ax, [bp-8]
mov cx, [bp+16]
mul cx
add bx, ax
add word [bp-4], bx ; it should be an add not an equal ... 


; cx and dx has to be respectively x and y , bl is color 
; y = py
xor edx, edx
mov dx, [bp+8]

.loopY:
xor eax, eax
mov ax,  [bp+8] ; should clear either low or high then 
add ax, [bp+20] ;
cmp edx, eax
je .end

; adjust boff to xstart : 
;boff += (3 * xstart);
push edx
mov ax, [bp+18]
mov cx, [bp-6]
mul cx
add word [bp-4], ax
pop edx

xor ecx, ecx
mov cx, [bp+10]
	
	.loopX:
	
	xor eax, eax
	mov ax,  [bp+10] ; should clear either low or high then 
	add ax, [bp+22]
	cmp ecx, eax
	je .endX
	
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

	; dont print black test : 
	mov ax, [bp+14]
	add ax, 1
	cmp bl, al
	jb .enddraw

	push edi
	push ecx
	push edx

	push 10; dither a
	push 3; dither b
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
	
	.enddraw:
	inc ecx
	jmp .loopX
	

.endX:

push edx
;boff -= (3 * xstart);
mov ax, [bp-6]
mov cx, [bp+18]
mul cx
sub word [bp-4], ax
;boff -= (cropwidth * 3);
mov ax, [bp-6]
mov cx, [bp+22]
mul cx
sub word [bp-4], ax
; boff -= pad;
mov ax, [bp-8]
sub word [bp-4], ax
;boff -= (biWidth* 3);
mov ax, [bp-6]
mov ecx, dword[edi+18]
mul cx
sub word [bp-4], ax
pop edx

inc edx
jmp .loopY

.end:
add sp, 8
pop bp

ret 20



PRINT_BITMAP_BW:
;[bp+22] width (cropped)
;[bp+20] height (cropped)
;[bp+18] xstart
;[bp+16] ystart
;[bp+14] un petit kiff pour les mouvements de couleurs
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
mov eax, 54 ; this is bitarray ptr. i mean it is always 54 for 16b and 24b
push eax ; the counter at [bp-4]

.af:
 ; number of byte is word[edi+28]
xor eax, eax
mov ax, word[edi+28]
; divide it per 8 
shr ax, 3
push 1                ;ax <----------------------- IT IS NEW

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

; si cropwidth = 0 ou cropheight = 0, mettre a [edi+18] et [edi+22]
mov ax, [bp+22]
cmp ax, 0
jne .cd
mov eax, [edi+18]
mov [bp+22], ax
.cd:
mov ax, [bp+20]
cmp ax, 0
jne .ce
mov eax, [edi+22]
mov [bp+20], ax


;	if (cropwidth + xstart > biWidth)
;		cropwidth = biWidth - xstart;
;	if (cropheight + ystart> biHeight)
;		cropheight = biHeight - ystart;
;	if (cropheight < 0 || cropwidth < 0)
;		return 0;

.ce:
xor eax, eax
mov ax, [bp+22]
add ax, [bp+18]
cmp eax, dword[edi+18]
jle .ca
mov eax, dword[edi+18]
sub ax , [bp+18]
mov [bp+22], ax
.ca:
mov ax, [bp+20]
add ax, [bp+16]
cmp eax, dword[edi+22]
jle .cc
mov eax, dword[edi+22]
sub ax , [bp+16]
mov [bp+20], ax

.cc:

push word 128	; BIT MASK


mov ax, [bp+22]
cmp ax, 0
jle .end
mov ax, [bp+20]
cmp ax, 0
jle .end


; adjusting offset to the desired raw
;ystart = biHeight - ystart;
mov eax, [edi+22]
sub ax, [bp+16]
mov word [bp+16], ax
;boff += ((3 * biWidth)*ystart) + (ystart * pad);
mov eax , [edi+18]
mov cx, [bp-6]
mul cx
mov cx, [bp+16]
mul cx
mov bx, ax
mov ax, [bp-8]
mov cx, [bp+16]
mul cx
add bx, ax
shr bx, 3
add word [bp-4], bx ; it should be an add not an equal ... 


; cx and dx has to be respectively x and y , bl is color 
; y = py
xor edx, edx
mov dx, [bp+8]

.loopY:
xor eax, eax
mov ax,  [bp+8] ; should clear either low or high then 
add ax, [bp+20] ;
cmp edx, eax
je .end

; adjust boff to xstart : 
;boff += (3 * xstart);
push edx
mov ax, [bp+18]
mov cx, [bp-6]
mul cx
shr ax, 3
add word [bp-4], ax
pop edx

xor ecx, ecx
mov cx, [bp+10]
	
	.loopX:
	
	xor eax, eax
	mov ax,  [bp+10] ; should clear either low or high then 
	add ax, [bp+22]
	cmp ecx, eax
	je .endX
	
	; we will do some hack here to convert to grayscale:  
	xor ebx, ebx
	mov esi, dword[bp-4]; the counter
	
	
	;bmp scaling ( we could use fast scaling using multiple of 2 . but lets go )

	
	; ---------------------------- GET THE COLOR DEPENDING OF BIT DEPTH ( read colore palette or not )  ----------------------------
	
	.nocolortable:
	mov bl,  [edi+esi] 
	mov ax, [bp-10]
	test bl, al ; test bit mask
	jz .notset
	mov bl,255
	jmp .updatemask
	.notset:
	mov bl,0
	.updatemask:
	shr word[bp-10], 1
	cmp word[bp-10], 0 ;and one 
	jne .convertgrayscale ; n'ai jamais bpn ... 
	mov word[bp-10], 128
	inc si
	mov dword[bp-4], esi
	.convertgrayscale:
	
	; ---------------------------------------------------------------------------------------------------------------
	shr bl, 5
	add bl, [bp+14]; -------------------- : normal grayscale10h

	; dont print black test : 
	mov ax, [bp+14]
	add ax, 1
	cmp bl, al
	jb .enddraw

	push edi
	push ecx
	push edx

	push 10; dither a
	push 3; dither b
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
	
	.enddraw:
	inc ecx
	jmp .loopX
	

.endX:

push edx
;boff -= (3 * xstart);
mov ax, [bp-6]
mov cx, [bp+18]
mul cx
shr ax, 3
sub word [bp-4], ax
;boff -= (cropwidth * 3);
mov ax, [bp-6]
mov cx, [bp+22]
mul cx
shr ax, 3
sub word [bp-4], ax
; boff -= pad;
mov ax, [bp-8]
sub word [bp-4], ax
;boff -= (biWidth* 3);
mov ax, [bp-6]
mov ecx, dword[edi+18]
mul cx
shr ax, 3
sub word [bp-4], ax
pop edx

inc edx
jmp .loopY

.end:
add sp, 10
pop bp

ret 20



fonttest :
db 0x42,0x4D,0x3E,0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x3E,0x0,0x0,0x0,0x28,0x0,0x0,0x0,0x40,0x0
db 0x0,0x0,0x20,0x0,0x0,0x0,0x1,0x0,0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x1,0x0,0x0,0x12,0xB
db 0x0,0x0,0x12,0xB,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xFF,0xFF
db 0xFF,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x40,0x3C,0x0,0x0,0x0,0x0,0x0,0x0,0x40,0x30
db 0x0,0x0,0x0,0x0,0x0,0x0,0x30,0x18,0x0,0x0,0x0,0x0,0x0,0x0,0x78,0xC,0x0,0x0,0x0,0x0
db 0x0,0x0,0xCC,0x6,0x0,0x0,0x0,0x0,0x0,0x0,0x84,0x1C,0x0,0x0,0x0,0x0,0x0,0x0,0x80,0x0
db 0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x1C,0x0,0x0,0x0,0x4,0x20,0x38,0x0,0x36,0x0
db 0x0,0x0,0xC,0x26,0xC,0x8,0x22,0x8,0xC,0x33,0xF8,0x2C,0x4,0x8,0x22,0x1C,0x3E,0x1E,0x98,0x3E
db 0x3C,0x8,0x22,0x16,0x3F,0xC,0x90,0x32,0x30,0x8,0x23,0x32,0x2C,0x1E,0xF0,0x1E,0x1C,0x3E,0x21,0x22
db 0x20,0x13,0x80,0x0,0x0,0x0,0x0,0x0,0x0,0x20,0x0,0x0,0x40,0x0,0x0,0x0,0x0,0x0,0x0,0x70
db 0x4C,0x3C,0x22,0x10,0x38,0x40,0x10,0x58,0x58,0x20,0x22,0x16,0x2C,0x60,0x10,0x8,0x70,0x30,0x22,0x16
db 0x24,0x3E,0x10,0xC,0x38,0x18,0x6B,0x3E,0x24,0x32,0x10,0x4,0x2C,0x8,0x49,0x2A,0x24,0x12,0x10,0x3C
db 0x22,0xC,0x7F,0x3A,0x3E,0x1E,0x0,0x0,0x20,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0
db 0x0,0x0,0x7A,0x1C,0x0,0x0,0x0,0x0,0x38,0x48,0xCE,0x36,0x1E,0x38,0x38,0x20,0x8,0x64,0x84,0x36
db 0x10,0x3C,0x20,0x20,0xC,0x64,0xCC,0x1C,0x10,0x4,0x38,0x30,0x7C,0x3C,0x78,0x10,0x10,0x4,0x2C,0x20




mbmp:
