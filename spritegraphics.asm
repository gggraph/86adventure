
; Print a sprite at position [ Args : scale, color?, spritesize, sprite index, x, y, sheet pointer] 
PRINT_SPRITE_CUSTOMFORMAT: 

	push		bp
	mov			bp,sp

	mov			edi, [bp+4] 

	; Get Y Line
	mov			ax, [bp+12]
	mov			cx, [edi+8] 
	shr			ax, cl
	mul			word[bp+14]
	push		ax 

	; Get X Column
	mov			ax, [bp+12]
	mov			cx, [bp+14]
	mul			cx
	push		ax 
	mov			ax, [bp-2]
	mov			cx, [edi+8] 
	shl			ax, cl
	sub			word [bp-4], ax

	; Print 8-Bit
	push		word[bp+14]
	push		word[bp+14]
	push		word[bp-4]
	push		word[bp-2]
	push		word[bp+16]
	push		word[bp+18]
	push		word[bp+10]
	push		word[bp+8]
	push		dword[bp+4];
	call		PRINT_CUSTOM_8BIT_FORMAT

	add			sp, 4
	pop			bp
	ret			16
	 
; Print a single sprite on screen from map [ ARGS : X , Y, spritesheet pointer, Sprite Size, map X, map Y, resolution, map pointer ]
;											       20	18			14			  12	       10	8			         4
PRINT_MAP_SPRITE_EXT:

	push		bp
	mov			bp, sp

	mov			edi, [bp+4] 

	; get sprite offset
	; divide coordinate x=16 and y = 16 will print maptile x=2 and y=2

	mov			ax ,[bp+12]
	mov			bx, [bp+14]
	div			bl
	; save the divide operation 
	xor			bx, bx
	mov			bl, ah
	xor			ah, ah
	push		ax
	push		bx
	; now bp-2 contains real x sprite tile and bp-4 contains pixel start of the one 
	mov			ax ,[bp+10]
	mov			bx, [bp+14]
	div			bl
	; save the divide operation 
	xor			bx, bx
	mov			bl, ah
	xor			ah, ah
	push		ax
	push		bx
	; now bp-6 contains real x sprite tile and bp-8 contains pixel start of the one 

	; get map cell index
	; sprite index is at (8+(y*mapwidth)+x) 
	mov			esi, 8									
	mov			eax, [edi]   ; map width
	mul			word[bp-6]
	add			ax, [bp-2]
	add			si, ax
	xor			ax, ax
	mov			al, byte [edi+esi]
	push		ax


	; get sprite coord in spritesheet
	; YLINE
	mov			ax, [bp-10]
	mov			ebx, [bp+16]
	mov			cx, [ebx+8] 
	shr			ax, cl             
	mul			word[bp+14]
	push		ax

	; XLINE
	mov			ax, [bp-10]
	mov			cx, [bp+14]
	mul			cx
	push		ax
	mov			ax, [bp-12]
	mov			ebx, [bp+16]
	mov			cx, [ebx+8] 
	shl			ax, cl             
	sub			word [bp-14], ax

	
	; width is spritesize - remainder x
	mov			ax, word[bp+14]
	sub			ax, word[bp-4]
	push		ax          ; - remainder x
	; height is spritesize - remainder y 
	mov			ax, word[bp+14]
	sub			ax, word[bp-8]
	push		ax          ; -remainder y

	; xstart is  bp-14 + remainder x
	mov			ax,  word[bp-14]
	add			ax, word[bp-4]
	push		ax          ; + remainder x

	mov			ax, word[bp-12]
	add			ax, word[bp-8]
	push		ax ; + remainder y
	push		0           ; color
	push		word[bp+8]  ; scaling
	push		word[bp+22] ; offX
	push		word[bp+20] ; offY
	push		dword[bp+16]; 
	call		PRINT_CUSTOM_8BIT_FORMAT

	add			sp, 14
	pop			bp
	ret			20

; Print MAP AT 0:0 [ ARGS : width, height, map x, map y, resolution, map pointer] 
PRINT_MAP_AT_ORIGIN_ZERO:

	push		bp 
	mov			bp, sp 

	push		0
	push		0
	push		word[bp+16]
	push		word[bp+14]
	push		word[bp+12]
	push		word[bp+10]
	push		word[bp+8]
	push		dword[bp+4]
	call		PRINT_MAP_EXT

	pop			bp
	ret			14

; Print MAP [ ARGS : top x, top y, width, height, map x , map y, resolution, map pointer] 
;					  20	18		16		14		12		10		8			4
PRINT_MAP_EXT:

	push		bp 
	mov			bp, sp 

	mov			dx, [bp+10]		; mov Y cursor at map Y
	
	.loopY:
	; End loop if Y cursor is above (map Y + height)
	mov			ax, [bp+10]
	add			ax, [bp+14]
	cmp			dx, ax
	jae			.end
	
	; Reset X cursor at map X
	mov			cx, [bp+12]

		.loopX:
		; End loop if X cursor is above (map X + width)
		mov			ax, [bp+12]
		add			ax, [bp+16]
		cmp			cx, ax
		jae			.endX
	
		pusha

		; Get X position in screen 
		; save Y cursor
		push		dx	
		;((x CURSOR - MAP X) * resolution) + top X
		mov			ax, cx 
		sub			ax, [bp+12]
		mul			word[bp+8] 
		pop			dx					
		add			ax, [bp+20] 
		push		ax					; X position in screen
		; Get Y position in screen 
		push		dx						
		mov			ax, dx 
		sub			ax, [bp+10]
		mul			word[bp+8]
		pop			dx
		add			ax, [bp+18]
		push		ax					; Y position in screen 
		xor			eax, eax
		mov			ax, mapsheet
		push		eax					; spritesheet pointer
		push		8					; SpriteSize 
		push		cx					; current map x 
		push		dx					; current map y
		push		2					; resolution
		push		dword[bp+4]			; map pointer
		call		PRINT_MAP_SPRITE_EXT

		popa
		mov			ax , cx
		mov			bx, 8
		div			bl
		xor			bx, bx
		mov			bl, ah
		mov			[bp-2], bx

		mov			ax, 8
		sub			ax, [bp-2] 
		add			cx, ax 
	
		jmp			.loopX
	.endX:

	mov			ax , dx
	mov			bx, 8
	div			bl

	xor			bx, bx
	mov			bl, ah
	mov			[bp-2], bx
	mov			ax, 8
	sub			ax, [bp-2] 
	add			dx, ax 

	jmp			.loopY

	.end:

	pop			bp
	ret			18




; FAST SPRITE DRAWING USING MONOCHROME BMP FUNCTION. CAN BE USEFULL FOR TYPO & OTHER STUFF LIKE MOUSE. NOT USED
PRINT_SPRITE:
	push		bp
	mov			bp,sp

	mov			ax, [bp+12]
	shr			ax, 3 ; div by 8
	mul			word[bp+14]
	push		ax ; [bp-2]

	mov			ax, [bp+12]
	mov			cx, [bp+14]
	mul			cx
	push		ax ; [bp-4]
	mov			ax, [bp-2]
	mul			cx
	sub			word [bp-4], ax


	push		word[bp+14]
	push		word[bp+14]
	push		word[bp-4]
	push		word[bp-2]
	push		word[bp+16]
	push		word[bp+18]
	push		word[bp+10]
	push		word[bp+8]
	push		dword[bp+4];
	call		PRINT_BITMAP_BW


	add			sp, 4
	pop			bp
	ret			16

; Use of custom font in default sprite sheet      [Args : Scaling, ?, X, Y, text pointer]
;															14	  12 10	8		4
PRINT_CUSTOM_FONT_WORD:

	push		bp
	mov			bp,sp
	push		word [bp+8]
	push		word [bp+6]
	mov			si, [bp+4]

		.loopw: 
		; check if character byte is 0. If true, end.
		xor			ax, ax
		mov			al, [si]
		cmp			al, 0
		je			.end
		; jump to next caret if byte equal ' ' character
		cmp			al,32
		je			.enddraw
		
		; print using function PRINT_SPRITE_CUSTOMFORMAT  [ Args : scale, color?, spritesize, sprite index, x, y, sheet pointer] 
		
		; sprite number start 160 for ascii 'a' which is 97 in  ASCII table. So add by (160-97=63) to get sprite index.
		add			al, 63

		push		si ; save si 

		push		2
		push		0
		push		8
		push		ax
		push		word [bp-2]
		push		word [bp-4]
		xor			eax, eax
		mov			ax, mapsheet
		push		eax
		call		PRINT_SPRITE_CUSTOMFORMAT

		pop			si

		mov			ax, [bp+12]
		shl			ax, 3
		add			word[bp-2], ax
		cmp			word[bp-2], 320
		jl			.enddraw
		mov			ax, [bp+8] 
		mov			word[bp-2], ax
		mov			ax, [bp+12]
		shl			ax, 3
		add			word[bp-4], ax

		.enddraw:
		inc			si
		jmp			.loopw

	.end:
	pop			bp
	add			sp, 4
	ret			10

; Use of custom font in bitmap monochrome format [Args : Scaling, ?, X, Y, text pointer]
PRINT_WORD_BMP:

	push		bp
	mov			bp,sp
	push		word [bp+8]
	push		word [bp+6]
	mov			si, [bp+4]

		.loopw: 
		; check if character byte is 0. If true, end.
		xor			ax, ax
		mov			al, [si]
		cmp			al, 0
		je			.end
		; jump to next caret if byte equal ' ' character
		cmp			al,32
		je			.enddraw
		; print 
		push		si
		push		word [bp+12] 
		push		word [bp+10] 
		push		8 ;sprite size
		; sprite number start 0 for ascii 'a' which is  97 in  ASCII table. So sub by 97 to get sprite index.
		sub			al, 97
		push		ax ; sprite number
		push		word [bp-2] ; x
		push		word [bp-4] ; y
		xor			eax, eax
		mov			ax, fonttest
		push		eax
		call		PRINT_SPRITE
		pop			si
		mov			ax, [bp+12]
		shl			ax, 3
		add			word[bp-2], ax
		cmp			word[bp-2], 280
		jl			.enddraw
		mov			ax, [bp+8] 
		mov			word[bp-2], ax
		mov			ax, [bp+12]
		shl			ax, 3
		add			word[bp-4], ax

		.enddraw:
		inc			si
		jmp			.loopw

	.end:
	pop			bp
	add			sp, 4
	ret			10

