; Load mouse configuration.
cli
call mouse_initialize
call mouse_enable

; Enable video mode
call SETUP_VGA_MODE

;jmp	TESTKEYBOARD
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
spleavebutton	dw 288, 12, 25, 0, 1, 0, 0

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
	;inc			word[PIX_DITHER] ; some tesr :) 
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

	; Increment by 1 pointer of all tiles in the love map for sweet effect 
	.change_love:
	mov			byte[PRINT_BLACK], 0
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
    call WAITFORENDOFFRAME

	jmp			.draw_loop



;MISC FUNCTION TO PRINT A BUTTON, ITS COLOR DEPENDING OF MOUSE POSITION AND ITS TEXT. SET ALSO IF MOUSE WAS INSIDE 
PRINTBUTTON: 
; arg is button data pointer 
;[bp+4]  is button data pointer 
    push		bp
	mov			bp,sp
	mov			si, [bp+4] ; get address of the button 
	push		si		   ; save si register
	; Get width depending of string length 
	push        word[si+12]
	call		GETSTRINGLENGTH
	pop			si         ; get back si 
	; value stored in cx 
	; we are using 16 pixel per character
	shl			cx, 4 ; this is actual width
	; Save Width at -2 
	push		cx    
	; Save Heigth at -4
	push		word[si+4]
	; Save Top X at -6 
	mov			ax, [si] 
	shr			cx, 1
	sub			ax, cx
	push		ax
	; Save Top Y at -8 
	mov			ax, [si+2] 
	mov			cx, [si+4]
	shr			cx, 1 
	sub			ax, cx
	push        ax

    ; Get Mouse Status inside button 
	; Check if mouse is lower than topX
	push		word[bp-6] 
	push		word[bp-8] 
	push		word[bp-2] 
	push		word[bp-4] 
	call		ISMOUSEINSIDEBOX
	test		ax,ax
	jz			.mousenotinside


	
	; Update mouse status inside box. 0 is not inside. 1 is inside. 2 is inside & clicking 
	call		ISLEFTMOUSEDOWN
	test		al, al
	jz			.mouseclick
    ; set mouse status to 1
	mov			word[si+10],1
	mov			bx, [si+8]
	jmp			.print
	.mouseclick: 
	; set mouse status to 2
	mov			word[si+10],2
	jmp			.print
	.mousenotinside: 
	; set mouse status to 0
	mov			word[si+10],0
	mov			bx, [si+6]

	.print:
	; Print the box. BX is color
	push		0
	push		0
	push		word [bp-6]
	push		word [bp-8]
	push		word [bp-2]
	push		word [bp-4]
	call		FILL_RECTANGLE_DITHERING
	
	; Print the text 
	mov			ax,  [si+12] 
	push		2  ; scaling 
	push        0 ;  
	push		word[bp-6] 
	mov			bx, [bp-8]
	add			bx, 4
	push		bx
	push	    ax
	call	    PRINT_CUSTOM_FONT_WORD
	
	; clear temp memory
	add			sp, 8

	pop			bp
	ret			2

; return ax 0 if not inside ... [PARAMS : X, Y, W, H ]
;										  10 8  6  4

ISMOUSEINSIDEBOX:
	push		bp
	mov			bp, sp

	mov			ax, [mouseX] 
	cmp			ax, [bp+10] 
	jl			.mousenotinside
	; Check if mouse is higer than topX + width
	mov			bx, [bp+10] 
	add         bx, [bp+6]
	cmp			ax, bx
	jg			.mousenotinside
	; Check if mouse is lower than Y
	mov			ax, [mouseY] 
	cmp			ax, [bp+8] 
	jl			.mousenotinside
	; Check if mouse is higher than Y + HEIGHT
	mov			bx, [bp+8] 
	add         bx, [bp+4]
	cmp			ax, bx
	jg			.mousenotinside

	xor			ax, ax
	inc			ax
	jmp			.ret
	.mousenotinside: 
	xor			ax, ax
	.ret:
	pop			bp
	ret			8

; GET LENGTH OF A STRING. VALUE RETURNED IN CX
GETSTRINGLENGTH:
	 push		bp
	 mov		bp,sp
	 mov		si, [bp+4] ; get address of the string
	 xor		cx, cx
	 .loop: 
		xor ax, ax
		mov al, [si]
		cmp al, 0
		je .end
		inc si
		inc cx
		jmp .loop
	 .end: 
	 pop bp 
	 ret 2

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

;MISC FUNCTION TO PRINT MOUSE
PRINTCURSOR: 

	push		2
	push		0
	push		8
	push		0xc1           ; the mouse 
	push		word[mouseX]
	push		word[mouseY]
	xor			eax, eax
	mov			ax, mapsheet
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT
	ret


; Return ax 0 if left mouse down is true 
ISLEFTMOUSEDOWN:
	xor			ax, ax
	mov			al, byte[curStatus]	
	shl			al, 4
	sub			al, 0x90
	ret 

;return 0 if right mouse down is true 
ISRIGHTMOUSEDOWN:
	xor			ax, ax
	mov			al, byte[curStatus]	
	shl			al, 4
	sub			al, 0xA0
	ret 

; Wait for next frame 

WAITFORENDOFFRAME:
	; Wait
	mov al, 0
	mov ah, 86h
	mov cx, 0x0
	mov dx, 0x7530
	int 15H ; wait like 300 ms
	ret

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