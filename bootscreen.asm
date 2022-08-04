; Load mouse configuration.
cli
call mouse_initialize
call mouse_enable

; Enable video mode
call SETUP_VGA_MODE

call    SETUP_KEYBOARD
; Launch 2d Engine at Boot Screen 
;jmp PLAY
jmp START_SCREEN

; Main variable
campos		dw 0, 100
spritesel	dw 0
colorsel	dw 0
mousesel	dw 255
welcome_str db 'run', 0
spr_str     db 'map', 0
map_str     db 'edit', 0
play_str	db 'play', 0

scrollstate dw 0
lovetile    dw 0

; Structure of button
;	center X  
;   center Y
;   height of box 
;   unlight   color 
;   highlight color 
;   mouse state
;   string pointer
welbutton		dw 154, 148, 25, 60, 30, 0, 0
speditbutton	dw 288, 188, 25, 0, 1, 0, 0
playbutton   	dw 288, 12, 25, 0, 1, 0, 0
spleavebutton	dw 288, 188, 25, 0, 1, 0, 0

; Default Pixels Parameters : 

; Allow to print black pixel if not 0 
PRINT_BLACK     db 0
; Color Dithering
PIX_DITHER      dw 0
PIX_DITHERB     dw 0
; Color Offset 
PIX_DISP		db 0 
	

DEBUG_INPUT:
	in			al, 96
	call		print_word_hex
jmp	DEBUG_INPUT 

; BOOT SCREEN FUNCTION
START_SCREEN:
	
	; set up string for  button 
	mov si, welbutton
	add si , 12 
	mov ax, welcome_str
	mov word [si], ax

	.draw_loop:
	; Clear the screen
	call		CLR_SCREEN 
	; Display Scrolling  Map
	push		160				 ; Width cropping 
	push		100				 ; Height cropping
	push		word[campos]     ; X Start on the map sheet
	push		word[campos+2]	 ; Y Start on the map sheet
	push		2				 ; Resolution
	xor			eax, eax
	mov			ax, maptiledata
	push		eax				; Map Data Pointer
	call		PRINT_MAP_AT_ORIGIN_ZERO

	; Display Love Tiles
	mov			byte[PRINT_BLACK], 0
	push		72				; TOP X
	push		0				; TOP Y				
	push		80				; Width cropping
	push		60				; Height Cropping
	push		0				; X start on the map sheet
	push		0				; Y start on the map sheet
	push		2				; Resolution 
	xor			eax, eax
	mov			ax, lovemap
	push		eax		    ; Map Data Pointer 
	call		PRINT_MAP_EXT

	; Increment by 1 index of all tiles in the love map for sweet effect 
	.change_love:
	mov			di, lovemap
	add			di, 8 
	mov			cx, 92 ; do it foreach 92 tiles 
		.loveloop:
		cmp			cx, 0
		je			.updatelovetile
		dec			cx
		xor			ax, ax
		mov			al, byte[di]
		cmp			word[lovetile], ax
		jne			.nextiter
		mov			ax,word[lovetile]
		inc			ax
		cmp			ax, 15
		jne			.apply
		mov			ax, 0
		.apply:
		mov			byte[di], al
		.nextiter:
		inc			di
		jmp			.loveloop

	.updatelovetile:
	inc			word[lovetile]
	cmp			word[lovetile], 15
	jne			.printbutton
	mov			word[lovetile], 0

	.printbutton:
		mov			byte[PRINT_BLACK], 1
	; Proccess button 
	mov			si, welbutton
	push		si
	call		PRINTBUTTON

	; Check if button click 
	mov			si, welbutton ; get back si. PrintButton modify si
	mov			ax, [si+10]
	cmp			ax, 2
	jne			.printcursor
	mov			word [campos],   0
	mov			word [campos+2], 0
	jmp			MAP_EDITOR

	.printcursor:
	; PRINT CURSOR 
	call		PRINTCURSOR

	; Scroll map incrementing camera position
	inc			word[campos]

	; Wait
    call		WAITFORENDOFFRAME

	jmp			.draw_loop


; Apply Color Displacement: [Arg : New displacement] 
APPLY_COLOR_DISP:
	;; Inverted color of all map pixels  so if (10->245) [ 255-10] if (255>10) [255-245] -> 10. There is 1032 bytes ...
	push		bp
	mov			bp,sp
	mov			edi, mapsheet
	mov			eax, [edi]
	mov			ecx, [edi+4]
	mul			ecx
	mov			cl, [PIX_DISP]
	.loopA:
	test		eax, eax
	jz			.applynewdisp
	mov			bx, 12 
	add			bx, ax
	
	sub			byte[di+bx], cl
	dec			eax
	jmp			.loopA

	.applynewdisp:
	mov			ax, word[bp+4]
	mov			byte[PIX_DISP], al
	mov			eax, [edi]
	mov			ecx, [edi+4]
	mul			ecx
	mov			cl, [PIX_DISP]
	.loopB:
	test		eax, eax
	jz			.done
	mov			bx, 12 
	add			bx, ax
	add			byte[di+bx], cl
	dec			eax
	jmp			.loopB

	.done:
	pop			bp
	ret			2



%include 'mapeditor.asm'
%include 'spriteeditor.asm'
%include 'game.asm'
%include 'mapdata.asm'
%include 'graphics.asm'
%include 'system.asm'
%include 'spritegraphics.asm'
%include 'bitmapgraphics.asm'
%include 'mouse.asm'
%include 'keyboard.asm'
