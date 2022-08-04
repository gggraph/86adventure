; TO DO
; Correct mapsheet color replacement from new header 
; WEIRD GLITCH WHEN CHANGING COLOR & THEN PRINTING COLOR TABLE
; Better UI 
;  -----> +- for sprite select

SPRITE_EDITOR:

	; Wait for mouse released 
	call		WAIT_MOUSE_RELEASED

	; Set up Close Button string 
	mov			si, spleavebutton
	add			si , 12 
	mov			ax, spr_str
	mov			word [si], ax

	; Main loop for sprite edition
	.drawloop:
	
	call		CLR_SCREEN 
	mov			word[mousesel], 0xff
	
	.drawmap:
	push		160 
	push		100
	push		word[campos]
	push		word[campos+2]
	push		2 
	xor			eax, eax
	mov			ax, maptiledata
	push		eax
	call		PRINT_MAP_AT_ORIGIN_ZERO
	

	; Draw Sprite Bloc
	mov			byte[PRINT_BLACK] , 0
	.draw_sprite: 

	;Draw the sprite 
	push		8
	push		0
	push		8
	push		word[spritesel]
	push		20
	push		40
	xor			eax, eax
	mov			ax, mapsheet
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT

	; Draw block border of sprite
	mov			bx, 60
	push		3
	push		17
	push		37
	push		68
	push		70
	call		DRAW_RECTANGLE_EXT

	; Apply draw if mouse click
	.draw_on_sprite:

	push		 bp
	mov			bp, sp
	mov			ax, word[mouseX]
	sub			ax, 20
	shl			ax, 3 ; multiply by 8 
	cmp			ax, 0 
	jl			.draw_color
	cmp			ax, 512 
	jge			.draw_color
	mov			ax, word[mouseY]
	sub			ax, 40
	shl			ax, 3
	cmp			ax, 0 
	jl			.draw_color
	cmp			ax, 512 
	jge			.draw_color

	; Check if mouse click & replace pixel
	call		ISLEFTMOUSEDOWN
	test		ax, ax
	jnz			.draw_color	

	.rp_pixel:
	; get current x y coordinate of the sprite  
	mov			ax, [spritesel]
	shr			ax, 4 ; div by 16
	shl			ax, 3 ; mul by 8 (spritesize)
	mov			word[bp-2], ax

	mov			ax, [spritesel]
	shl			ax, 3 ; mul by 8
	mov			word[bp-4], ax
	mov			ax, [bp-2]
	shl			ax, 4 ; div by 16
	sub			word [bp-4], ax

	mov			di, mapsheet
	mov			ax, [bp-2]
	shl			ax, 7 ; mult by 128 
	add			ax, 12; add offset 
	add			ax, word[bp-4]
	add			di ,ax
	mov			ax, [mouseX]
	sub			ax, 20
	shr			ax, 3
	add			di, ax
	mov			ax, [mouseY]
	sub			ax, 40
	shr			ax, 3
	shl			ax, 7 ; mult by 128 
	add			di, ax
	mov			bx, [colorsel]
	mov			byte[di], bl ; write 
	pop			bp


	; Draw color table in a 16x16 grid
	.draw_color: 
	xor			dx, dx
	; Do a basic Y:X loop 
	.loopY:
	cmp			dx, 16
	je			.drawspriteselection
	xor			cx, cx
		.loopX:
		cmp			cx, 16
		je			.endX

		push		bx
		push		cx
		push		dx

		; check if mouseX is over 
		push		bx
		mov			ax, [mouseX]
		mov			bx, cx 
		shl			bx, 3
		add			bx, 140 
		cmp			ax, bx
		jb			.drawclr
		mov			bx, 268
		cmp			ax, bx
		ja			.drawclr
		mov			ax, [mouseY]
		mov			bx, dx
		shl			bx, 3
		add			bx, 20
		cmp			ax, bx
		jb			.drawclr
		mov			bx, 148
		cmp			ax, bx
		ja			.drawclr
		mov			word[mousesel], 0xc1
		call		ISLEFTMOUSEDOWN
		test		al, al
		jnz			.drawclr

		.changecolor:
		pop			bx
		push		cx
		push		dx
		mov			word[colorsel], bx
		; Draw the full color at place of the sprite
		push		0
		push		0
		push		20
		push		40
		push		64
		push		64
		call		FILL_RECTANGLE_DITHERING
		pop			dx
		pop			cx
		push		bx
		

		.drawclr:
		pop			bx
		push		0
		push		0
		mov			ax, cx
		shl			ax, 3
		add			ax, 140
		push		ax
		mov			ax, dx
		shl			ax, 3
		add			ax, 20
		push		ax
		push		8
		push		8
		call		FILL_RECTANGLE_DITHERING
		pop			dx
		pop			cx
		pop			bx

		; increment color and x axis
		inc			bx 
		inc			cx

		jmp			.loopX

	.endX:
	inc			dx
	jmp			.loopY


	.drawspriteselection:
	call DRAW_SPRITE_SELECTOR

	push		0
	push		6
	push		320
	push		24
	call		ISMOUSEINSIDEBOX
	test		ax,ax
	jz			.checkinsidespritestools
	mov			 word[mousesel], 0xc1

	.checkinsidespritestools:
	push		0
	push		176
	push		320
	push		6
	call		ISMOUSEINSIDEBOX
	test		ax,ax
	jz			.printbutton
	mov			 word[mousesel], 0xc1	

	.printbutton:
	mov			byte[PRINT_BLACK] , 1
	; Proccess closed button
	mov			si, spleavebutton
	push		si
	call		PRINTBUTTON

	; Check if button click 
	mov			si, spleavebutton ; get back si. PrintButton modify si
	mov			ax, [si+10]
	cmp			ax, 2
	je			MAP_EDITOR
	cmp			byte[kbdbuf+0x01], 1
	je			MAP_EDITOR

	; Draw the cursor depending if color or not 
	.drawcursor: 
	cmp			word[mousesel], 255
	je			.drawcolorsel

	push		2
	push		0
	push		8
	push		word [mousesel] 
	push		word[mouseX]
	push		word[mouseY]
	xor			eax, eax
	mov			ax, mapsheet
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT
	jmp			.wait

	.drawcolorsel:
	push		0
	push		0
	push		word[mouseX]
	push		word[mouseY]
	push		8
	push		8
	mov			bx, word[colorsel]
	call		FILL_RECTANGLE_DITHERING

	call		UPDATE_SELECTION_OFFSET
	mov			al, byte[kbdbuf+0x4e]
	mov			byte[lastplusrec], al
	mov			al, byte[kbdbuf+0x4a]
	mov			byte[latminrec], al

	.wait:


	call WAITFORENDOFFRAME
	; print escape sprite 

	jmp .drawloop

lastplusrec		db	0
latminrec		db  0