; Print a 8x8 sprite with 8bit color given a spritesheet
PRINT_CUSTOM_8BIT_FORMAT:

	push		bp
	mov			bp, sp
	mov			edi, [bp+4] 

	mov			ax, [bp+22]
	cmp			ax, 0
	jne			.cd
	mov			eax, [edi]		
	mov			[bp+22], ax
	.cd:
	mov			ax, [bp+20]
	cmp			ax, 0
	jne			.ce
	mov			eax, [edi+4]	
	mov			[bp+20], ax


	.ce:
	xor			eax, eax
	mov			ax, [bp+22]
	add			ax, [bp+18]
	cmp			eax, dword[edi] 
	jle			.ca
	mov			eax, dword[edi] 
	sub			ax , [bp+18]
	mov			[bp+22], ax
	.ca:
	mov			ax, [bp+20]
	add			ax, [bp+16]
	cmp			eax, dword[edi+4] 
	jle			.cc
	mov			eax, dword[edi+4] 
	sub			ax , [bp+16]
	mov			[bp+20], ax

	.cc:
	mov			ax, [bp+22]
	cmp			ax, 0
	jle			.end
	mov			ax, [bp+20]
	cmp			ax, 0
	jle			.end


	mov			esi , 12						
	; jump to desired line (so esi += ystart *w)
	mov			ax, [bp+16]
	mul			word[edi] ; mul by w			
	add			si, ax

	; Basic Y:X Loop
	xor			dx, dx
	xor			cx, cx
	.loopY:
	cmp			dx, [bp+20]
	je			.end
	xor			cx, cx

	; adjust to xstart 
	add			si, [bp+18]
	

		.loopX:
		cmp			cx, [bp+22]
		je			.endX

		xor			ebx, ebx
		mov			bl, [edi+esi]

		; ByPass black if SpriteSheet is a cursor or character table ...
		mov			al, [PRINT_BLACK]
		test		al, al
		jz			.n
		cmp			bl, 0
		jne			.n
		jmp			.enddraw
		
		.n:
		push		edi
		push		ecx
		push		edx

		; We use graphics function FILL_RECTANGLE TO DRAW THE PIXEL.... 
		; Some dithering effect here we can use some value for fun but its not important
		push		word[PIX_DITHERB]
		push		word[PIX_DITHER]

		; X equal cx * scale + offY
		push		dx
		mov			ax, cx
		mul			word[bp+12]
		pop			dx
		add			ax, [bp+10]
		push		ax
	
		; Y equal dx * scale + offY
		push		dx
		mov			ax, dx
		mul			word[bp+12]
		pop			dx
		add			ax, [bp+ 8]
		push		ax

		push		word [bp+12]
		push		word [bp+12]
		call		FILL_RECTANGLE_DITHERING

		pop			edx
		pop			ecx
		pop			edi
	
		.enddraw:

		inc cx
		inc esi
		jmp .loopX

	.endX: 
	sub			si, [bp+18]
	sub			si, [bp+22]
	add			si, [edi]

	inc			dx
	jmp			.loopY

	.end:
	pop			bp
	ret			20

; Print BMP File with Monochromatic format
PRINT_BITMAP_BW:

	push		bp
	mov			bp, sp
 
	mov			edi,  [bp+4]

	; get bit array offset
	mov			eax, 54 ; this is bitarray ptr. i mean it is always 54 for 16b and 24b
	push		eax ; the counter at [bp-4]

	.af:
	 ; number of byte is word[edi+28]
	xor			eax, eax
	mov			ax, word[edi+28]
	; divide it per 8 
	shr			ax, 3
	push		1               

	; proccess padding. 

	mov			eax,  dword [edi+18]  ; load bmp with in eax
	xor			ecx, ecx
	mov		    cx, [bp-6]
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

	; Do all sanity check condition
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
	mov		    [bp+20], ax

	.cc:

	push		word 128	; BIT MASK


	mov			ax, [bp+22]
	cmp			ax, 0
	jle			.end
	mov			ax, [bp+20]
	cmp			ax, 0
	jle			.end


	; adjusting offset to the desired raw
	mov			eax, [edi+22]
	sub			ax, [bp+16]
	mov			word [bp+16], ax

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
	shr			bx, 3
	add			word [bp-4], bx


	; cx and dx has to be respectively x and y , bl is color 
	xor			edx, edx
	mov			dx, [bp+8]

	; Do the Y:X loop 

	.loopY:

	xor			eax, eax
	mov			ax,  [bp+8] ; should clear either low or high then 
	add			ax, [bp+20] ;
	cmp			edx, eax
	je			.end

	push		edx
	mov			ax, [bp+18]
	mov			cx, [bp-6]
	mul			cx
	shr			ax, 3
	add			word [bp-4], ax
	pop			edx

	xor			ecx, ecx
	mov			cx, [bp+10]
	
		.loopX:
	
		xor			eax, eax
		mov			ax,  [bp+10] 
		add			ax, [bp+22]
		cmp			ecx, eax
		je			.endX
	
		xor			ebx, ebx
		mov			esi, dword[bp-4]

		; GET THE COLOR DEPENDING OF BIT DEPTH ( read colore palette or not )  
		.nocolortable:
		mov			bl,  [edi+esi] 
		mov			ax, [bp-10]
		test		bl, al 
		jz			.notset
		mov			bl,255
		jmp			.updatemask

		.notset:
		mov			bl,0

		.updatemask:
		shr			word[bp-10], 1
		cmp			word[bp-10], 0 
		jne			.convertgrayscale 
		mov			word[bp-10], 128
		inc			si
		mov			dword[bp-4], esi

		.convertgrayscale:
	
		; Normalize GrayScale
		shr			bl, 5
		add			bl, [bp+14]

		; Do not print black
		mov			ax, [bp+14]
		add			ax, 1
		cmp			bl, al
		jb			.enddraw

		push		edi
		push		ecx
		push		edx

		; Do some Double-dithering if we want
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
		mov			di, [bp+12] 
		push		di
		push		di

		call FILL_RECTANGLE_DITHERING

		pop			edx
		pop			ecx
		pop			edi
	
		.enddraw:

		inc			ecx
		jmp			.loopX
	

	.endX:

	push		edx

	; Reajust offset 
	mov			ax, [bp-6]
	mov			cx, [bp+18]
	mul			cx
	shr			ax, 3
	sub			word [bp-4], ax

	mov			ax, [bp-6]
	mov			cx, [bp+22]
	mul			cx
	shr			ax, 3
	sub			word [bp-4], ax

	mov			ax, [bp-8]
	sub			word [bp-4], ax

	mov			ax, [bp-6]
	mov			ecx, dword[edi+18]
	mul			cx
	shr			ax, 3
	sub			word [bp-4], ax
	pop			edx

	inc			edx
	jmp			.loopY

	.end:

	add			sp, 10
	pop			bp

	ret			20