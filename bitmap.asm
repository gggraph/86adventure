; Print bitmap file ( See PRINT_BITMAP_BW for monochromatic color space) 

; Arguments : 
;[bp+22] width (cropped)
;[bp+20] height (cropped)
;[bp+18] xstart
;[bp+16] ystart
;[bp+14] un petit kiff pour les mouvements de couleurs
;[bp+12]  is scaling
;[bp+10]  is x offset pos
;[bp+8]  is y offset pos
;[bp+4]  is bitmap binary pointer

PRINT_BITMAP_ADVANCED:

	push		bp
	mov			bp, sp
 
	mov			edi,  [bp+4]

	; bmp size is at  [esi]
	; bit ptr is at   [esi+10]
	; bit count is at [esi+28]

	; get bit array offset
	cmp			word[edi+28], 8  
	jg			.16bp
	; is at [edi+46](biClrUsed) * 4 + 54 
	mov			eax, [edi+46]
	shl			eax, 2 ; mult by 4
	add			eax, 54
	push		eax
	jmp			.af

	.16bp:
	mov			eax, 54 ; this is bitarray ptr. i mean it is always 54 for 16b and 24b
	push		eax ; the counter at [bp-4]

	.af:
	 ; number of byte is word[edi+28]
	xor			eax, eax
	mov			ax, word[edi+28]
	; divide it per 8 
	shr			ax, 3
	push		ax

	; proccess padding. 

	mov			eax,  dword [edi+18]  ; load bmp with in eax
	xor			ecx, ecx
	mov			cx, [bp-6]
	mul			ecx
	mov			ecx, 3
	and			eax, ecx 
	cmp			eax, 0
	je			.condb

	mov			edx, 4
	sub			edx, eax
	push		dx
	jmp			.next
	.condb:
	push		word 0
	.next:

	; si cropwidth = 0 ou cropheight = 0, mettre a [edi+18] et [edi+22]
	mov			ax, [bp+22]
	cmp			ax, 0
	jne			.cd
	mov			eax, [edi+18]
	mov			[bp+22], ax
	.cd:
	mov			ax, [bp+20]
	cmp			ax, 0
	jne			.ce
	mov			eax, [edi+22]
	mov			[bp+20], ax

	;	if (cropwidth + xstart > biWidth)
	;		cropwidth = biWidth - xstart;
	;	if (cropheight + ystart> biHeight)
	;		cropheight = biHeight - ystart;
	;	if (cropheight < 0 || cropwidth < 0)
	;		return 0;

	.ce:
	xor			eax, eax
	mov			ax, [bp+22]
	add			ax, [bp+18]
	cmp			eax, dword[edi+18]
	jle			.ca
	mov			eax, dword[edi+18]
	sub			ax , [bp+18]
	mov			[bp+22], ax
	.ca:
	mov			ax, [bp+20]
	add			ax, [bp+16]
	cmp			eax, dword[edi+22]
	jle			.cc
	mov			eax, dword[edi+22]
	sub			ax , [bp+16]
	mov			[bp+20], ax

	.cc:
	mov			ax, [bp+22]
	cmp			ax, 0
	jle			.end
	mov			ax, [bp+20]
	cmp			ax, 0
	jle			.end

	; adjusting offset to the desired raw
	;ystart = biHeight - ystart;
	mov			eax, [edi+22]
	sub			ax, [bp+16]
	mov			word [bp+16], ax
	;boff += ((3 * biWidth)*ystart) + (ystart * pad);
	mov			eax , [edi+18]
	mov			cx, [bp-6]
	mul			cx
	mov			cx, [bp+16]
	mul			cx
	mov			bx, ax
	mov			ax, [bp-8]
	mov			cx, [bp+16]
	mul			cx
	add			bx, ax
	add			word [bp-4], bx ; it should be an add not an equal ... 


	; cx and dx has to be respectively x and y , bl is color 
	; y = py
	xor			edx, edx
	mov			dx, [bp+8]

	.loopY:
	xor			eax, eax
	mov			ax,  [bp+8] ; should clear either low or high then 
	add			ax, [bp+20] ;
	cmp			edx, eax
	je			.end

	; adjust boff to xstart : 
	;boff += (3 * xstart);
	push		edx
	mov			ax, [bp+18]
	mov			cx, [bp-6]
	mul			cx
	add			word [bp-4], ax
	pop			edx

	xor			ecx, ecx
	mov			cx, [bp+10]
	
		.loopX:
	
		xor			eax, eax
		mov			ax,  [bp+10] ; should clear either low or high then 
		add			ax, [bp+22]
		cmp			ecx, eax
		je			.endX
	
		; we will do some hack here to convert to grayscale:  
		xor			ebx, ebx
		mov			esi, dword[bp-4]; the counter
	
	
		;bmp scaling ( we could use fast scaling using multiple of 2 . but lets go )

		; ---------------------------- GET THE COLOR DEPENDING OF BIT DEPTH ( read colore palette or not )  ----------------------------
		cmp			word[edi+28], 8  
		jg			.nocolortable
		; r g b is at file + 54 +  [edi+esi+1] * 4
		xor			eax, eax
		mov			al, [edi+esi+1] ; read color table index
	
		shl			al, 2 ; mult by 4
		add			eax, 54 ; add 54 b off 
		mov			bl, [edi+eax+1]
		jmp .convertgrayscale

		.nocolortable:
		mov			bl,  [edi+esi+1] 

		.convertgrayscale:
		shr			bl, 5
	
		add			bl, [bp+14];normal grayscale10h
		add			si, [bp-6] ; increment array ptr (by one, two or three)
		mov			dword[bp-4], esi

		; dont print black : 
		mov			ax, [bp+14]
		add			ax, 1
		cmp			bl, al
		jb			.enddraw

		push		edi
		push		ecx
		push		edx

		push		10; dither a
		push		3; dither b
		xor			edi, edi
		mov			eax, ecx
		mov			di, [bp + 10]
		sub			eax, edi
		xor			edi, edi
		mov			di, [bp+12] ; scale
		push		edx
		mul			edi
		pop			edx
		xor			edi, edi
		mov			di, [bp + 10]
		add			eax, edi
		push		ax

		xor			edi, edi
		mov			eax, edx
		mov			di, [bp +8]
		sub			eax, edi
		xor			edi, edi
		mov			di, [bp+12] ; scale
		push		edx
		mul			edi
		pop			edx
		xor			edi, edi
		mov			di, [bp + 8]
		add			eax, edi
		push		ax

		xor			edi, edi
		mov			di, [bp+12] ; scale
		push		di
		push		di

		call		FILL_RECTANGLE_DITHERING

		pop			edx
		pop			ecx
		pop			edi
	
		.enddraw:
		inc			ecx
		jmp			.loopX
	

	.endX:

	push		edx
	;boff -= (3 * xstart);
	mov			ax, [bp-6]
	mov			cx, [bp+18]
	mul			cx
	sub			word [bp-4], ax
	;boff -= (cropwidth * 3);
	mov			ax, [bp-6]
	mov			cx, [bp+22]
	mul			cx
	sub			word [bp-4], ax
	; boff -= pad;
	mov			ax, [bp-8]
	sub			word [bp-4], ax
	;boff -= (biWidth* 3);
	mov			ax, [bp-6]
	mov			ecx, dword[edi+18]
	mul			cx
	sub			word [bp-4], ax
	pop			edx

	inc			edx
	jmp			.loopY

	.end:
	add			sp, 8
	pop			bp

	ret			20

; Convert RGB color to VGA color. Result stored in BX. 
; Arguments : [ R, G, B ] 
;               8  6  4
RGB_TO_VGA_COLOR:
	push		bp
	mov			bp, sp

	push		cx
	push		dx
	; loop through all color & get minimum distance 
	mov			si, vgapalette
	mov			cx,  0xff

	push		2000 ; best distance at -2
	push		0    ; current index at -4 

	.loop:
		; compare min distance 
		mov			ax, 3
		mul			cx
		mov			bx, ax
		
		xor			ax, ax
		; red dist
		mov			al, [si+bx]
		sub			al, [bp+8]
		push		ax ; -6 
		; green dist
		inc			bx
		mov			al, [si+bx]
		sub			al, [bp+6]
		push		ax ; -8 
		; blue dist
		inc			bx
		mov			al, [si+bx]
		sub			al, [bp+4]

		; compare
		add			ax, [bp-6]
		add			ax, [bp-8]
		cmp			ax, [bp-2]
		ja			.next
		mov			word[bp-2], ax
		mov			word[bp-4], cx

		.next:
		add			sp, 4
		test		cx,cx
		jz			.end
		dec			cx
		jmp			.loop

	.end:
	; result color 
	mov			bx, [bp-4]
	; clear stack & restore
	add			sp, 4
	pop			dx
	pop			cx
	pop			bp
	ret			6

vgapalette:
; VGA palette in RGB format. range [0-255] 3 bytes for each color
incbin "vgapalette"


