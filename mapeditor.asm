
; MISC FUNCTION TO WAIT WHILE MOUSE IS UP
WAIT_MOUSE_RELEASED:
	; Wait
	call		WAITFORENDOFFRAME
	; check mouse
	call		ISLEFTMOUSEDOWN
	jz			WAIT_MOUSE_RELEASED
	ret


MAP_EDITOR:

	call		WAIT_MOUSE_RELEASED


	; Set up sprite edition button string 
	mov			si, speditbutton
	add			si , 12 
	mov			ax, map_str
	mov			word [si], ax

	; Set up play button string 
	mov			si, playbutton
	add			si , 12 
	mov			ax, play_str
	mov			word [si], ax

	; Main loop for map editor
	.drawloop:

	call		CLR_SCREEN 
	mov			word[mousesel], 0xff

	.movecamera:

	; Move Camera position depending of mouse position (or arrow) 
	.checkright:
	cmp			word[mouseX], 303
	jb			.checkleft
	add			word[campos], 2
	mov			word[mousesel], 2
	.checkleft: 
	cmp			 word[mouseX], 8
	ja			.checkup
	sub			 word[campos], 2
	mov			 word[mousesel], 0
	.checkup:
	cmp			 word[mouseY], 183
	jb			 .checkdown
	add			word[campos+2], 2
	mov			word[mousesel], 3
	.checkdown: 
	cmp			word[mouseY], 8
	ja			.adjustcameraposition
	sub			word[campos+2], 2
	mov			word[mousesel], 4


	.adjustcameraposition: ; COULD BE ITS OWN METHOD
	mov			cx, [campos]
	mov			dx, [campos+2]
	call		ADJUST_POSITION_FROM_BORDER
	mov			[campos],cx
	mov			[campos+2],dx

	; Test If we are interacting tools bar if true set mouse and jump map cell editing... 
	
	push		0
	push		6
	push		320
	push		24
	call		ISMOUSEINSIDEBOX
	test		ax,ax
	jz			.checkinsidespritestools
	mov			 word[mousesel], 1
	jmp			.drawmap

	.checkinsidespritestools:
	push		0
	push		176
	push		320
	push		6
	call		ISMOUSEINSIDEBOX
	test		ax,ax
	jz			.editmap
	mov			 word[mousesel], 1	
	jmp			.drawmap

	.editmap:
	; Edit map 
	call		ISRIGHTMOUSEDOWN
	test		al, al
	jz			.suppspr

	call		ISLEFTMOUSEDOWN
	test		al, al
	jz			.replacespr
	
	jmp			.drawmap
	.suppspr:
	mov			ax, 0xff
	jmp			.applynewspr
	; Replace sprite in map data. Sprite sel is in ax
	.replacespr:
	mov			ax, [spritesel]
	.applynewspr:
	push		ax				; set sprite index to change with 
	push		8				; set sprite dimension (8x8)
	mov			ax, [mouseX]
	shr			ax, 1
	add			ax, [campos] 
	push		ax
	mov			ax, [mouseY]
	shr			ax, 1
	add			ax, [campos+2] 
	push		ax
	xor			eax, eax
	mov			ax, maptiledata 
	push		eax		 ; Push map pointer

	call		REPLACE_SPRITE


	; Draw the map 
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


	mov			al, byte[kbdbuf+0x39]
	cmp			al, 1 
	jne			.drawchar
	; set char origin pos at mouse position + camera offset ...
	mov			ax, [mouseX]
	shr			ax, 1
	add			ax, [campos] 
	mov			[originpos], ax
	mov			ax, [mouseY]
	shr			ax, 1
	add			ax, [campos+2] 
	mov			[originpos+2], ax



	.drawchar: 

	mov			cx, [originpos]
	sub			cx, [campos]
	shl			cx, 1
	mov			dx, [originpos+2]
	sub			dx, [campos+2]
	shl			dx, 1

	cmp			cx, 0
	jl			.drawtools
	cmp			cx, 312
	jg			.drawtools
	cmp			dx, 0
	jl			.drawtools
	cmp			dx, 92
	jg			.drawtools


	push		2
	push		0
	push		8
	push		224
	push		cx
	push		dx
	xor			eax, eax
	mov			ax, mapsheet
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT

	.drawtools:
	; Draw the sprite selection tools (16 sprites)
	call DRAW_SPRITE_SELECTOR
	call DRAW_GRAPH_PARAMS_BAR

	.printbuttons:
	; Draw and proccess button s
	; Proccess Edit button 
	mov			si, speditbutton
	push		si
	call		PRINTBUTTON

	; Check if button click 
	mov			si, speditbutton ; get back si. PrintButton modify si
	mov			ax, [si+10]
	cmp			ax, 2
	je			SPRITE_EDITOR

	; Proccess Play button 
	mov			si, playbutton
	push		si
	call		PRINTBUTTON

	; Check if button click 
	mov			si, playbutton ; get back si. PrintButton modify si
	mov			ax, [si+10]
	cmp			ax, 2
	je			PLAY
	cmp			byte[kbdbuf+0x1C], 1
	je			PLAY

	; Print cursor depending  on mouse sel 
	;call		PRINTCURSOR
	.drawcursor:
	mov			bx, [spritesel] 
	cmp			word[mousesel], 255 
	je			.da
	mov			bx, [mousesel]
	add			bx, 0xc0
	.da:
	push		2
	push		0
	push		8
	push		bx 
	push		word[mouseX]
	push		word[mouseY]
	xor			eax, eax
	mov			ax, mapsheet
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT

	call		UPDATE_SELECTION_OFFSET
	mov			al, byte[kbdbuf+0x4e]
	mov			byte[lastplusrec], al
	mov			al, byte[kbdbuf+0x4a]
	mov			byte[latminrec], al



	call WAITFORENDOFFRAME

	jmp .drawloop

; set up a sel offset 
seloffset		dw   0

UPDATE_SELECTION_OFFSET:
	; Update sprite selection offset from + or - pressed
	cmp			byte[lastplusrec], 1
	je			.checkminpressed
	cmp			byte[kbdbuf+0x4e], 0
	je			.checkminpressed
	add			word[seloffset], 16
	add			word[spritesel] , 16
	.checkminpressed:
	cmp			byte[latminrec], 1
	je			.limitseloffset
	cmp			byte[kbdbuf+0x4a], 0
	je			.limitseloffset
	sub			word[seloffset], 16
	sub			word[spritesel] , 16
	.limitseloffset: 
	cmp			word[seloffset], 0
	jge			.checkabove
	mov			word[seloffset], 240
	mov			word[spritesel] , 240
	.checkabove:
	cmp			word[seloffset], 240
	jle			.done
	mov			word[seloffset], 0
	mov			word[spritesel] , 0
	.done:
	ret

DRAW_SPRITE_SELECTOR: 
	; fill a rectangle
	; print at 180 + 16 : 
	xor			bx,bx
	push		0 ; dither
	push		0 ; dither
	push		0 ;  x
	push		176 ;  y 
	push		320 ; width
	push		24 ; heeight
	call		FILL_RECTANGLE_DITHERING	

	

	.printsprites:
	mov cx, 0
		.loopsel:
		cmp			cx, 16 
		je			.hightlight_sel
		push		cx 
		push		2
		push		0
		push		8
		mov			ax, [seloffset]
		add			ax, cx
		push		ax; SPRITE INDEX
		mov			ax, cx
		shl			ax, 3
		shl			ax, 1
		; fast detect here if mouse is over 
		mov			bx, [mouseX]
		cmp			bx, ax
		jb			.lsA
		mov			dx, ax
		add			dx, 16 
		cmp			bx, dx
		ja			.lsA
		mov			bx, [mouseY]
		cmp			bx, 180
		jb			.lsA
		mov			bx, [seloffset]
		add			bx,  cx
		mov			word[spritesel], bx ; change sprite sel here 

		.lsA:
		push		ax    ;SCREEN X
		push		180   ; SCREEN Y
		xor			eax, eax
		mov			ax, mapsheet
		push		eax
		call		PRINT_SPRITE_CUSTOMFORMAT
		pop			cx
		inc			cx
		jmp .loopsel

	; Draw square on selected sprite in selector
	.hightlight_sel:
	mov			bx, 60
	push		2
	mov			ax, [spritesel]
	sub			ax, [seloffset]
	shl			ax, 3
	shl			ax, 1
	push		ax
	push		180
	push		16
	push		16
	call		DRAW_RECTANGLE_EXT

	ret

DRAW_GRAPH_PARAMS_BAR:

	; black bar 
	xor			bx,bx
	push		0 ; dither
	push		0 ; dither
	push		0 ;  x
	push		0 ;  y 
	push		320 ; width
	push		24 ; heeight
	call		FILL_RECTANGLE_DITHERING

	; draw dithering bar : full
	mov			bx, 30
	push		0 ; dither
	push		0 ; dither
	push		10 ;  x
	push		7 ;  y 
	push		64 ; width
	push		10 ; heeight
	call		FILL_RECTANGLE_DITHERING

	mov			ax, word[PIX_DITHER]
	shr			ax, 2 ; scale on 64 
	mov			bx, 40
	push		0 ; dither
	push		0 ; dither
	push		10 ;  x 
	push		7 ;  y 
	push		ax ; width
	push		10 ; heeight
	call		FILL_RECTANGLE_DITHERING

	; if mouse inside : 
	call		ISLEFTMOUSEDOWN
	test		ax, ax
	jnz			.ditherBBar

	push		10 ; 
	push		7
	push		64
	push		10
	call		ISMOUSEINSIDEBOX
	test		ax, ax
	jz			.ditherBBar

	mov			ax, [mouseX]
	sub			ax, 10  ; 
	shl			ax, 2
	mov			word[PIX_DITHER], ax

	.ditherBBar:

	; draw dithering bar : full
	mov			bx, 30
	push		0 ; dither
	push		0 ; dither
	push		94 ;  x 
	push		7 ;  y 
	push		64 ; width
	push		10 ; heeight
	call		FILL_RECTANGLE_DITHERING

	mov			ax, word[PIX_DITHERB]
	shr			ax, 2 ; scale on 64 
	mov			bx, 40
	push		0 ; dither
	push		0 ; dither
	push		94 ;  x 
	push		7 ;  y 
	push		ax ; width
	push		10 ; heeight
	call		FILL_RECTANGLE_DITHERING

	; if mouse inside : 
	call		ISLEFTMOUSEDOWN
	test		ax, ax
	jnz			.dispBar

	push		94 ; 
	push		7
	push		64
	push		10
	call		ISMOUSEINSIDEBOX
	test		ax, ax
	jz			.dispBar

	mov			ax, [mouseX]
	sub			ax, 94  ; 
	shl			ax, 2
	mov			word[PIX_DITHERB], ax

	.dispBar:

	mov			bx, 30
	push		0 ; dither
	push		0 ; dither
	push		178 ;  x ; 
	push		7 ;  y 
	push		64 ; width
	push		10 ; heeight
	call		FILL_RECTANGLE_DITHERING

	xor			ax, ax
	mov			al, byte[PIX_DISP]
	shr			ax, 2 ; scale on 64 
	mov			bx, 40
	push		0 ; dither
	push		0 ; dither
	push		178 ;  x
	push		7 ;  y 
	push		ax ; width
	push		10 ; heeight
	call		FILL_RECTANGLE_DITHERING

	; if mouse inside : 
	call		ISLEFTMOUSEDOWN
	test		ax, ax
	jnz			.done

	push		178 ; 
	push		7
	push		64
	push		10
	call		ISMOUSEINSIDEBOX
	test		ax, ax
	jz			.done

	mov			ax, [mouseX]
	sub			ax, 178  ; 
	shl			ax, 2
	push		ax
	call		APPLY_COLOR_DISP

	.done:
	ret

; Adjust positon in CX:DX from border of map 
ADJUST_POSITION_FROM_BORDER:
	; check if cx is above (mapwdith *spritesize - screenwidth/scale ) 
	; check if cy is above (mapheight*spritesize - screenheight/scale ) 
	mov			edi, maptiledata
	mov			ax, [edi]
	mov			bx, [edi+4] 
	shl			ax, 3 ; mul by spritesize
	shl			bx, 3 ; mul by spritesize
	sub			ax, 160
	sub			bx, 100

	; if x below 0, zero x
	cmp			cx, 0
	jl			.zx
	jmp			.b
	.zx:
	xor			cx, cx
	.b:
	cmp			dx, 0
	jl			.zy
	jmp			.c
	.zy:
	xor			dx, dx
	
	.c:
	
	cmp			cx, ax
	jg			.capx
	jmp			.d
	.capx:
	mov			cx,ax
	.d:
	cmp			dx, bx
	jg			.capy
	jmp			.done
	.capy:
	mov			dx,bx
	.done:
	ret

;[ARGS : SPRITEINDEX +14, SPRITESIZE +12 , PIXEL X +10 , PIXEL Y +8 , MAP POITNER +4 ] 
REPLACE_SPRITE:

	push		bp
	mov			bp, sp

	mov			edi, [bp+4]
	
	; get offset 
	mov			ax ,[bp+10]
	mov			bx, [bp+12]
	div			bl
	xor			ah, ah
	mov			word[bp-2], ax
	mov			ax ,[bp+8]
	mov			bx, [bp+12]
	div			bl
	xor			ah, ah
	mov			word[bp-4], ax

	; Get sprite index at (8+(y*mapwidth)+x) 
	mov			esi, 8 
	mov			eax, [edi]   ; map width
	mul			word[bp-4]
	add			ax, [bp-2]
	add			si, ax
	xor			ax, ax
	mov			ax, [bp+14] 
	mov			byte[edi+esi],al

	pop			bp
	ret			12

