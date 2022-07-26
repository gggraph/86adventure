

		

; Character Data
xm dw 0
ym dw 0
x  dw 0
y  dw 0
dir db 0 ; UP RIGHT DOWN LEFT
charsprite db 0

lastfloor	dw 0, 0 

; some flags need better system
onground	db 0
canjump		db 1
candash     db 0

ongrimp		db 0
grimping	db 0

; player cam
playercam	dw 0, 0 

; origin position
; moon   >  40 : 0 
; desert >  20 : 0
originpos  dw 20, 0

;special events 
cheatmode		db 0
autoswitch      db 0
clockswitch     db 0

PLAY:
	;set player pos at origin pos
	mov			ax, [originpos]
	mov			word[x], ax
	mov			word[lastfloor], ax
	mov			ax, [originpos+2]
	mov			word[y], ax
	mov			word[lastfloor+2], ax
	
	
	; Initialize position of player
	.loop:
	; Clear Display
	call		CLR_SCREEN
	; Get Switching mechanism
	call		CHECK_GRAVITY_SWITCH
	; Get status of char depending of block collision 
	call		HITMYCHARMAP
	; Compute physics on char
	call		MOVEMYCHAR
	; Check death if outside map
	call		CHECK_OOB
	; Update Camera
	call		UPDATECAMPOS
	; Draw Graphics 
	call		DRAWGAMEGRAPHICS
	; Wait next frame
	call		WAITFORENDOFFRAME

	; Check for [escape]
	cmp			byte[kbdbuf+0x01], 1
	je			QUIT_PLAY


	jmp			.loop

; Unsafe. Should be called inside main loop.
QUIT_PLAY:
	call		DEATHMYCHAR
	jmp			MAP_EDITOR



; Physics variables 
dash1		dw 76 ; 76
maxdash		dw 500 ; 500
resist		dw 40 ; 51
gravity1	dw 80 ; 80
gravity2	dw 32 ; 32
jump		dw 860 ; 860
speedlimit  dw 1535 ; 1535 

; RINT
lastZrecorded db 0

MOVEMYCHAR:

	;mov			byte[dir], 0   <------------------------- JUST FOR DEBUG.... SPRITE ANIM SHOULD DETECT 

	.checkdash:
	cmp			byte[kbdbuf+0x2D], 0
	je			.leftAxisMovement
	cmp			byte[candash], 0
	je			.leftAxisMovement
	; dash depending of direction...
	cmp			byte[dir], 1
	jne			.dorightdash
	mov			ax, [speedlimit]
	neg			ax
	mov			word[xm], ax
	mov			word[ym], 0
	mov			ax, [jump]
	sar			ax, 1
	sub			word[ym], ax
	mov			byte[candash], 0
	jmp			.leftAxisMovement
	.dorightdash:
	mov			ax, [speedlimit]
	mov			word[xm], ax
	mov			ax, [jump]
	mov			word[ym], 0
	sar			ax, 1
	sub			word[ym], ax
	mov			byte[candash], 0

	.leftAxisMovement: 
	cmp			byte[kbdbuf+0x4B], 0 
	je			.rightAxisMovement
	mov			ax, [maxdash]
	neg			ax
	cmp			word[xm], ax
	jle			.rightAxisMovement

	mov			ax, [dash1]
	sub			word[xm], ax
	mov			byte[dir], 1
	
	.rightAxisMovement: 
	cmp			byte[kbdbuf+0x4D], 0 
	je			.dofriction          
	mov			ax, [maxdash]
	cmp			word[xm], ax         
	jge			.dofriction

	mov			ax, [dash1]
	add			word[xm], ax ; should set xm here 
	mov			byte[dir], 2

	
	.dofriction:
	cmp			word[xm], 0
	jge			.subfriction
	mov			ax, [resist]
	neg			ax
	cmp			word[xm], ax
	; if upper do zeroA
	jg			.zeroA ; never called ...
	; we can do sub do less line but do it fancy way
	;mov			ax, [resist]
	;add			word[xm], ax
	sub			word[xm], ax
	jmp			.subfriction
	.zeroA:
	mov			word[xm], 0
	.subfriction:
	cmp			word[xm], 0
	jle			.checkgrimpingstatus

	mov			ax, [resist]
	cmp			word[xm], ax
	; if upper do zeroA
	jl			.zeroB
	; we can do sub do less line but do it fancy way
	sub			word[xm], ax
	jmp			.checkgrimpingstatus
	.zeroB:
	mov			word[xm], 0

	; Proccess Grimping
	.checkgrimpingstatus:
	cmp			byte[ongrimp], 1
	je			.processjump
	cmp			byte[grimping], 0
	je			.processjump
	;; grimping = true ongrimp = false 
	mov			byte[grimping], 0
	mov			byte[canjump], 0

	; the jump stuff 
	.processjump:
	;TODO
	; check if keyjump 
	cmp			byte[lastZrecorded], 1
	je			.applygravity
	cmp			byte[kbdbuf+0x11], 0
	je			.applygravity
	; check if can jump 
	cmp			byte[canjump], 1
	jne			.applygravity
	; apply jump here 
	mov			word[ym],     0
	mov			byte[canjump], 0
	mov			ax, [jump]
	sub			word[ym], ax  
	mov			byte[grimping] ,0

	; Apply gravity here. It will be different if gravity is inverted 
	.applygravity:
	mov			al, byte[kbdbuf+0x11]
	mov			byte[lastZrecorded], al

	cmp			byte[grimping], 0
	je			.checkinv;
	; proc grimping
	.upAxisMovement: 
	cmp			byte[kbdbuf+0x48], 0 
	je			.downAxisMovement
	sub			word[y], 2
	jmp			.limitspeed
	.downAxisMovement: 
	cmp			byte[kbdbuf+0x50], 0 
	je			.limitspeed          
	add			word[y], 2
	jmp			.limitspeed

	; Apply Gravity2 which is lighter if we are jumping and pressing jump (will make jump higher) 
	.checkinv:
	cmp			byte[INVGRAVITY], 0
	je			.normalgravmode
	cmp			word[ym], 0
	jle			.applynormalgravity 
	jmp			.lightergravcheck
	.normalgravmode:
	cmp			word[ym], 0
	jge			.applynormalgravity 
	.lightergravcheck:
	cmp			byte[kbdbuf+0x11], 1
	jne			.applynormalgravity
	mov			ax, [gravity2]
	add			word[ym], ax
	jmp			.limitspeed
	.applynormalgravity: 
	; Apply normal gravity
	mov			ax, [gravity1]
	add			word[ym], ax

	; SHOULD HAVE GRIPPING MECHANISM HERE ... 

	.limitspeed:
	mov			ax, [speedlimit]
	mov			bx, ax
	neg			bx

	cmp			[xm], bx
	jge			.lsb
	mov			[xm], bx
	.lsb:
	cmp			[xm], ax
	jle			.lsc
	mov			[xm], ax
	.lsc:
	cmp			[ym],bx
	jge			.lsd
	mov			[ym],bx
	.lsd:
	cmp			[ym],ax
	jle			.computecharsprite
	mov			[ym],ax

	.computecharsprite:
	mov			ax,  [xm]
	mov			bx,  [ym]
	sar			ax, 8	; this different value for xm when negative
	sar			bx, 8

	mov			cl, 224
	test		bx, bx
	jz			.ccs1
	add			cl, 3
	.ccs1: 
	cmp			byte[grimping], 0
	je			.applydir
	mov			cl, 230
	.applydir:
	add			cl, byte[dir]
	mov			byte[charsprite], cl
	cmp			byte [INVGRAVITY], 0
	je			.done
	sub			byte[charsprite], 16

	
	; shift right (use sar for signed) by 8. or div by 256
	.done:
	mov			ax,  [xm]
	mov			bx,  [ym]
	sar			ax, 8	; this different value for xm when negative
	sar			bx, 8
	add			word[x], ax
	add			word[y], bx

	ret
	
; [ ARGS : SPRITE SIZE +16, Position X +14, Position Y +12 , Flag data pointer +8, Map Data pointer +4 ] return value in A reg
GET_MAP_FLAG:
	push		bp
	mov			bp, sp

	; SAVE CX AND DX
	mov			word[bp-8],  cx
	mov			word[bp-6],  dx

	; End if cx or cy is 0 
	cmp			word[bp+14], 0
	jl			.end
	cmp			word[bp+12], 0
	jl			.end

	; get map pointer 
	mov			edi, [bp+4]

	; get offset 
	mov			ax ,[bp+14]
	mov			bx, [bp+16]
	div			bl
	xor			ah, ah
	mov			word[bp-2], ax 
	mov			ax ,[bp+12]
	mov			bx, [bp+16]
	div			bl
	xor			ah, ah
	mov			word[bp-4], ax ; save at sp-4 

	; Get sprite index at (y*mapwidth)+x) 
	mov			esi, 8 
	mov			eax, [edi]   ; map width
	mul			word[bp-4]
	add			ax, [bp-2]
	add			si, ax

	; get sprite index in si
	; Get sprite index at (8+(y*mapwidth)+x) . 8 offset because we jump width and height variables... 
	mov			esi, 8       
	mov			eax, [edi]   ; map width
	mul			word[bp-4]
	add			ax, [bp-2]
	add			si, ax
	; get the sprite index 
	xor			ebx, ebx
	mov			ax, bx
	mov			bl, byte[edi+esi] 
	;cmp			byte[kbdbuf+0x2D], 0 ; <----------- JUST A DEBUG....
	;je			.next
	;mov			byte[edi+esi], 3 ; 4 debug
	;.next:
	; if bl = 0xff return 0 
	cmp			bl, 0xff
	je			.wasnull
	mov			al, bl
	mov			edi, [bp+8]
	mov			al, byte[flagdata+bx]
	jmp			.end	
	.wasnull:
	xor			ax,ax
	.end:
	mov			cx, word[bp-8]
	mov			dx, word[bp-6]
	pop			bp
	ret			14


DEATHMYCHAR:

	add			word[PIX_DITHER], 16
	mov			cx, 20
	.freeze:
	push		cx
	call		DRAWGAMEGRAPHICS
	call		WAITFORENDOFFRAME
	pop			cx
	test		cx, cx
	jz			.next
	dec			cx
	jmp			.freeze
	.next:
	sub			word[PIX_DITHER], 16
	cmp			byte[INVGRAVITY], 0
	je			.resetvalues
	call		SWITCH_GRAVITY

	.resetvalues:
	;set player pos at origin pos
	mov			ax, [originpos]
	mov			word[x], ax
	mov			word[lastfloor], ax
	mov			ax, [originpos+2]
	mov			word[y], ax
	mov			word[lastfloor+2], ax

	;reset ym and xm  and others values ...
	mov			word[xm], 0
	mov			word[ym], 0

	; switch gravity if needed

	; restore items
	call		RESTORE_ITEMS
	ret 

RESTORE_ITEMS:
	; iterate through all map value.
	mov			edi, maptiledata
	mov			eax, [edi]
	mov			ecx, [edi+4]
	mul			cx

	mov			cx, ax
	mov			bx, 8
	.loop:
	test		cx,cx
	jz			.end
	mov			al, [di+bx]
	.checkcoin:
	cmp			al, 0xf0
	jne			.checkgrav
	mov			byte[di+bx], 17
	jmp			.next
	.checkgrav:
	cmp			al, 0xf1
	jne			.checkjmp
	mov			byte[di+bx], 16 
	jmp			.next
	.checkjmp:
	cmp			al, 0xf2
	jne			.checkdsh
	mov			byte[di+bx], 66 ; ?
	jmp			.next
	.checkdsh:
	cmp			al, 0xf3
	jne			.next
	mov			byte[di+bx], 105 ; ?
	
	.next:
	inc			bx
	dec			cx
	jmp			.loop
	.end:
	ret
	; 0 : null, 1: solid, 2: coin, 3: gravity switch, 4: portal, 
	; 5: jump cooin, 6: dash coin, 7: death block , 8: water, 9: grimp

; Proccess game blocks (coin, switch, death block etc...) [Args : x scan +6 , y scan +4] 
; How to keep A register ?
HITMYCHARFLAG:
	push		bp
	mov			bp, sp

	push		ax ; save ax
	; Check coin 
	cmp			ax, 2
	jne			.checkgravity
	; Proccess coin
	; do sound 
	; remove coin with REPLACE_SPRITE
	push		0xf0
	push		8
	push		word[bp+6]
	push		word[bp+4]
	xor			eax, eax
	mov			ax, maptiledata 
	push		eax		 ; Push map pointer
	call		REPLACE_SPRITE
	jmp			.done
	; Check gravity switch
	.checkgravity:
	cmp			ax, 3
	jne			.checkportal
	; remove switch with REPLACE_SPRITE
	push		0xf1
	push		8
	push		word[bp+6]
	push		word[bp+4]
	xor			eax, eax
	mov			ax, maptiledata 
	push		eax		 ; Push map pointer
	call		REPLACE_SPRITE
	; Proccess gravity
	call		SWITCH_GRAVITY 
	jmp			.done
	; Check portal
	.checkportal:
	cmp			ax, 4
	jne			.checkextrajump
	; Proccess portal
	cmp			byte[kbdbuf+0x4B], 1
	je			QUIT_PLAY
	cmp			byte[kbdbuf+0x48], 1
	je			QUIT_PLAY
	jmp			.done
	; Check jump coin
	.checkextrajump:
	cmp			ax, 5
	jne			.checkdashitem
	; Proccess jump coin
	; do sound
	; clear jump coin
	push		0xf2
	push		8
	push		word[bp+6]
	push		word[bp+4]
	xor			eax, eax
	mov			ax, maptiledata 
	push		eax		 ; Push map pointer
	call		REPLACE_SPRITE
	; enable jump 
	;mov			word[ym],     0
	mov			byte[canjump],1
	jmp			.done
	.checkdashitem:
	cmp			ax, 6
	jne			.checkdeath
	; Proccess dash coin
	push		0xf3
	push		8
	push		word[bp+6]
	push		word[bp+4]
	xor			eax, eax
	mov			ax, maptiledata 
	push		eax		 ; Push map pointer
	call		REPLACE_SPRITE
	mov			byte[candash],1
	jmp			.done
	.checkdeath:
	cmp			ax, 7
	jne			.checkwater
	; Proccess death
	call		DEATHMYCHAR
	jmp			.done
	.checkwater:
	cmp			ax, 8
	jne			.checkgrimp
	; Proccess inside water
	jmp			.done
	.checkgrimp:
	cmp			ax, 9
	jne			.checkeventswitch
	mov			byte[ongrimp], 1
	mov			byte[canjump], 1
	; Proccess grimp
	cmp			byte[kbdbuf+0x48], 1
	je			.startgrimp
	cmp			byte[kbdbuf+0x50], 1
	je			.startgrimp
	jmp			.done
	.startgrimp:
	mov			byte[grimping], 1
	mov			word[ym], 0
	

	.checkeventswitch:
	cmp			ax, 10
	jne			.done
	cmp			byte[autoswitch], 1
	je			.done
	call		ENABLEEVENTSWITCH
	.done:
	pop		ax  
	pop		bp
	ret		4

ENABLEEVENTSWITCH:
	mov			byte[autoswitch], 1
	;mov			word[PIX_DITHER], 16	

	mov			edi, maptiledata
	mov			eax, [edi]
	mov			ecx, [edi+4]
	mul			cx

	mov			cx, ax
	mov			bx, 8
	.loop:
	test		cx,cx
	jz			.end
	mov			al, [di+bx]
	cmp			al, 0xff
	jb			.next
	mov			byte[di+bx], 0x82

	.next:
	inc			bx
	dec			cx
	jmp			.loop
	.end:

	ret


HITMYCHARMAP:
	; Get flag of NESW blocks. (pixels closed) 
	mov			byte[onground], 0
	mov			byte[ongrimp], 0
	; Proccess Floor
	.ProcessFloor:
	; LEFT FLOOR CHECK
	push		8			; push spritesize
	mov			cx, word[x]
	add			cx, 2
	push		cx			; push pixel x
	mov			dx, word[y]
	add			dx, 8
	push		dx			; push pixel y

	xor			eax, eax
	mov			ax, flagdata	; push flag pointer
	push		eax

	mov			ax, maptiledata ; push map pointer
	push		eax
	call		GET_MAP_FLAG


	push		cx
	push		dx
	call		HITMYCHARFLAG
	cmp			ax, 1
	je			.OnHitFloor

	; RIGHT FLOOR CHECK
	push		8			; push spritesize
	mov			cx, word[x]
	add			cx, 6
	push		cx			; push pixel x
	mov			dx, word[y]
	add			dx, 8
	push		dx			; push pixel y

	xor			eax, eax
	mov			ax, flagdata	; push flag pointer
	push		eax

	mov			ax, maptiledata ; push map pointer
	push		eax
	call		GET_MAP_FLAG

	push		cx
	push		dx
	call		HITMYCHARFLAG
	cmp			ax, 1
	jne			.ProccessCeil
	
	.OnHitFloor: ; [Apply bounce] if inverted or [STOPYMOVEMENT]
	cmp			byte[INVGRAVITY], 0
	je			.nmgr0
	call		STOPYMOVEMENT
	jmp			.ProcessWestBlock
	.nmgr0:
	call		APPLYBOUNCE


	.ProccessCeil:
	; LEFT CEIL CHECK
	push		8			; push spritesize
	mov			cx, word[x]
	add			cx, 2
	push		cx			; push pixel x
	mov			dx, word[y]
	sub			dx, 6
	push		dx			; push pixel y

	xor			eax, eax
	mov			ax, flagdata	; push flag pointer
	push		eax

	mov			ax, maptiledata ; push map pointer
	push		eax
	call		GET_MAP_FLAG

	push		cx
	push		dx
	call		HITMYCHARFLAG
	cmp			ax, 1
	je			.OnHitCeil

	; RIGHT CEIL CHECK
	push		8			; push spritesize
	mov			cx, word[x]
	add			cx, 6
	push		cx			; push pixel x
	mov			dx, word[y]
	sub			dx, 6
	push		dx			; push pixel y

	xor			eax, eax
	mov			ax, flagdata	; push flag pointer
	push		eax

	mov			ax, maptiledata ; push map pointer
	push		eax
	call		GET_MAP_FLAG

	push		cx
	push		dx
	call		HITMYCHARFLAG
	cmp			ax, 1
	jne			.ProcessWestBlock

	.OnHitCeil:
	cmp			byte[INVGRAVITY], 0
	je			.nmgr1
	call		APPLYBOUNCE
	jmp			.ProcessWestBlock
	.nmgr1:
	call		STOPYMOVEMENT

	.ProcessWestBlock:

	push		8			; push spritesize
	mov			cx, word[x]
	sub			cx, 1
	push		cx			; push pixel x
	mov			dx, word[y]
	push		dx			; push pixel y

	xor			eax, eax
	mov			ax, flagdata	; push flag pointer
	push		eax

	mov			ax, maptiledata ; push map pointer
	push		eax
	call		GET_MAP_FLAG

	cmp			ax, 1
	jne			.ProcessEastBlock

	.OnHitWestBlock:
	; only process if xm is negative ...
	cmp			word[xm], 0
	jge			.ProcessEastBlock
	add			word[ym], 80
	mov			ax, word[xm]
	neg			ax
	add			ax, 400
	mov			word[xm], ax

	.ProcessEastBlock:

	push		8			; push spritesize
	mov			cx, word[x]
	add			cx, 9
	push		cx			; push pixel x
	mov			dx, word[y]
	push		dx			; push pixel y

	xor			eax, eax
	mov			ax, flagdata	; push flag pointer
	push		eax

	mov			ax, maptiledata ; push map pointer
	push		eax
	call		GET_MAP_FLAG

	cmp			ax, 1
	jne			.end

	.OnHitEastBlock:
	; only process if xm is negative ...
	cmp			word[xm], 0
	jle			.end
	add			word[ym], 80
	mov			ax, word[xm]
	sub			ax, 400
	mov			word[xm], ax


	.end:
	ret

CHECK_OOB:
	mov			dx, [y]
	mov			edi, maptiledata
	mov			bx, [edi+4] 
	shl			bx, 3 

	; if x below 0
	cmp			byte [INVGRAVITY], 0
	jne			.nograv

	cmp			dx, bx
	jg			.py
	jmp			.done
	.py:
	call		DEATHMYCHAR

	.nograv:
	cmp			dx, 0
	jl			.zy
	jmp			.done
	.zy:
	call		DEATHMYCHAR

	.done:
	ret 

INVGRAVITY		db  0
LASTSPVALUE		db  0

CHECK_GRAVITY_SWITCH:
    cmp			byte[autoswitch], 0
	je			.checkspace
	dec			byte[clockswitch]
	cmp			byte[clockswitch], 0
	jg			.checkspace
	call		SWITCH_GRAVITY
	mov			byte[clockswitch], 100 ; 4 s			

    .checkspace:
	cmp			byte[cheatmode], 0
	je			.done
	mov			al, byte[kbdbuf+0x39]
	cmp			al, 1 
	jne			.done
	cmp			byte[LASTSPVALUE], 1 
	je			.done
	call		SWITCH_GRAVITY		
	.done:
	xor			ax, ax
	mov			al, byte[kbdbuf+0x39]
	mov			byte[LASTSPVALUE], al
	ret 

SWITCH_GRAVITY: ; LOSING A REGISTER COULD BE BETTER DONE

	neg			word[gravity1]
	neg			word[gravity2]
	neg			word[jump]
	;; Basic Boolean : if 1 become 0 (or 1-1) = 0 if 0 become 1 or (1-0)
	mov			al, 1
	sub			al, byte[INVGRAVITY]
	mov			byte[INVGRAVITY], al
	jmp			.done    ;;; disable pixels switch .... for test
	;; Inverted color of all map pixels  so if (10->245) [ 255-10] if (255>10) [255-245] -> 10. There is 1032 bytes ...
	mov			edi, mapsheet
	mov			eax, [edi]
	mov			ecx, [edi+4]
	mul			ecx
	.loop:
	test		eax, eax
	jz			.done
	mov			bx, 12 ; offfset ?
	add			bx, ax
	mov			cl, 140 ; 255
	sub			cl, byte[di+bx]
	mov			byte[di+bx], cl
	dec			eax
	jmp			.loop
	.done:
	; Do some grizzy sound

	ret
STOPYMOVEMENT:
	cmp			byte[INVGRAVITY], 0
	je			.normalgravity	
	cmp			word[ym], 0
	jle			.done           
	mov			word[ym], 0
	jmp			.done
	.normalgravity:
	; FOR NORMAL GRAVITY = 0
	cmp			word[ym], 0
	jge			.done            
	mov			word[ym], 0
	.done:
	ret
	
APPLYBOUNCE:

	mov			cx, [x] ; we can boost x too . it could be fun
	mov			dx, [y]
	mov			ax, word[lastfloor+2]
	mov			word[ym], 0
	shr			dx, 3
	shl			dx, 3
	mov			word[y], dx
	mov			bx, dx

    cmp			byte[INVGRAVITY], 0
	je			.normalgravity	
	add			word[y], 3 ; correct y to 3++ (depend of jump value/32)
	cmp			ax, bx ; ax is last floor. bx is current y. proccess bounce if last floor touched is higher 
	jle			.setfloorflag
	sub			ax, bx  ; sub ax with bx to get Y distance                    
	shl			ax, 3 ; bounce multiplicator (*8)
	add			word[ym], ax    ; add multiplicator to current ym            
	jmp			.setfloorflag 
	.normalgravity:
	; reset y to lowest multiple of 8
	
	cmp			bx, ax
	jle			.setfloorflag
	sub			bx, ax                       
	shl			bx, 3 ; bounce multiplicator
	sub			word[ym], bx                 

	.setfloorflag:
	mov			byte[onground], 1
	mov			byte[canjump],1
	; save last floor data
	mov			word[lastfloor],   cx
	mov			word[lastfloor+2], dx

	ret

camtarget	dw 0 , 0
lerpspeed	db 2 ; IDK if we feel it ? Do we keep it ?

UPDATECAMPOS:
    
	mov			ax, [x]
	mov			bx, [y]

	; Lerp Smoothly
	mov			dx, ax
	sub			dx, word[campos]
	cmp			dx, 0
	jge			.lpa
	neg			dx  
	.lpa:
	xor			cx, cx
	mov			cl, [lerpspeed] 
	cmp			dx, cx
	jae			.lerpX
	mov			dx, 1

	.lerpX:
	cmp			word[campos], ax
	jl			.lerpcamxp
	jg			.lerpcamxm
	jmp			.lerpcamy
	.lerpcamxp:
	add			word[campos],dx ; adjust lerp speed (1) 
	jmp			.lerpcamy
	.lerpcamxm:
	sub			word[campos],dx ; adjust lerp speed (1) 
	
	.lerpcamy:
	mov			dx, bx
	sub			dx, word[campos+2]
	cmp			dx, 0
	jge			.lpb
	neg			dx  
	.lpb:
	xor			cx, cx
	mov			cl, [lerpspeed] 
	cmp			dx, cx
	jae			.lerpY
	mov			dx, 1

	.lerpY:
	cmp			word[campos+2], bx
	jl			.lerpcamyp
	jg			.lerpcamym
	jmp			.adjustmidscreen

	.lerpcamyp:
	add			word[campos+2],dx ; adjust lerp speed (1) 
	jmp			.adjustmidscreen
	.lerpcamym:
	sub			word[campos+2],dx ; adjust lerp speed (1) 

	.adjustmidscreen:
	mov			cx, [campos]
	mov			dx, [campos+2]
	sub			cx, 80	
	sub			dx, 50

	; adjust from map border 
	call		ADJUST_POSITION_FROM_BORDER

	.updatecamtarget:
	mov			word[camtarget],cx
	mov			word[camtarget+2],dx

	ret



DRAWGAMEGRAPHICS:

	; Print Map at target
	.printmap: 
		; Just an example of background using scaling 1. We can use shift [camtarget] to do some parallax :) 
	;It s twice and screen is 320 and 40*8 is 320 so we cannot do x scrolling 
	;push		320 
	;push		200
	;push		word[camtarget]
	;push		word[camtarget+2]
	;push		1 
	;xor			eax, eax
	;mov			ax , maptiledata
	;push		eax
	;call		PRINT_MAP_AT_ORIGIN_ZERO

	push		160 
	push		100
	push		word[camtarget]
	push		word[camtarget+2]
	push		2 
	xor			eax, eax
	mov			ax , maptiledata
	push		eax
	call		PRINT_MAP_AT_ORIGIN_ZERO

	
	
	; [3] Print character. 
	push		2		;  Scaling 
	push		0		;  Color 0 means bypass black color when printing 
	push		8		;  Sprite size is 8x8 
	xor			ax, ax
	mov			al, byte[charsprite]
	push		ax	    ;  Sprite ID
	
	; origin
	mov			edi, maptiledata
	cmp			word[camtarget], 0	
	je			.mapxwaszero
	; check if camtarget y equal 
	mov			bx, [edi] 
	shl			bx, 3 
	sub			bx, 160
	cmp			word[camtarget], bx
	jne			.inairx
	.abovex:
	mov			ax, word[x]
	shl			ax, 1 ; mult by 2 
	; ; mapheight * spritesize * scale 
	mov			bx, [maptiledata] 
	shl			bx, 3
	shl			bx, 1
	sub			bx, ax
	mov			ax, bx
	; Invert    ax by 200 (width of the creen) 
	mov			bx, 320
	sub			bx, ax
	mov			ax, bx
	push		ax
	jmp			.computetopy

	.inairx:
	mov			ax, [x]
	mov			bx, [camtarget]
	sub			ax, bx
	add			ax, 80
	push		ax
	jmp			.computetopy
	.mapxwaszero:
	mov			ax, word[x]
	shl			ax, 1
	push		ax
	.computetopy: ;;;; HERE WE NEED TO CHECK IF WE ARE ON BORDER ....
	
	cmp			word[camtarget+2], 0	
	je			.mapywaszero
	; check if camtarget y equal 
	mov			bx, [edi+4] 
	shl			bx, 3 
	sub			bx, 100
	cmp			word[camtarget+2], bx
	jne			.inairy
	.abovey:
	; i want to print it to the screen and need to compute topY in term of pixel 
	; get y and div by scale (2) 
	mov			ax, word[y]
	shl			ax, 1 ; mult by 2 
	; ; mapheight * spritesize * scale 
	mov			bx, [maptiledata+4] 
	shl			bx, 3
	shl			bx, 1
	sub			bx, ax
	mov			ax, bx
	; Invert    ax by 200 (height of the creen) 
	mov			bx, 200
	sub			bx, ax
	mov			ax, bx
	push		ax
	jmp			.endcompute
	.inairy:
	mov			ax, [y]
	mov			bx, [camtarget+2]
	sub			ax, bx
	add			ax, 50
	push		ax
	jmp			.endcompute
	.mapywaszero:
	mov			ax, word[y]
	shl			ax, 1
	push		ax
	.endcompute:
	mov			cx, mapsheet
	xor			eax, eax
	mov			ax, cx
	push		eax
	call		PRINT_SPRITE_CUSTOMFORMAT

	ret 