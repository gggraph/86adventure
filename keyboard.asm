 TESTKEYBOARD:
    ; loop through all 128 bytes 

     call    SETUP_KEYBOARD
      mov     cx, 127
    .loop:
        test     cx,cx
        jz      .end 
        ; get value 
        mov bx , cx
        xor      ax,ax
        mov      al, [kbdbuf+bx]    ; check code :3
        xor      bx , bx
        or       al, al
        jz      .continue
        mov bx , 10
        mov     ax, cx
        call     print_byte_hex
         .continue:
        mov     ax, cx
        shl     ax, 1
        push    ax
        push	50
		push	6
		call	FILL_SQUARE_FAST
        dec     cx
        jmp     .loop
    .end:
    jmp TESTKEYBOARD
 

 SETUP_KEYBOARD:
    xor     ax, ax
    mov     es, ax
    cli                        
    mov     word [es:9*4], irq1isr
    mov     [es:9*4+2],cs
    sti
    ret 

;; Custom interupt for keystrokes
irq1isr:
    pusha

    ; read keyboard scan code
    in      al, 0x60

    ; update keyboard state
    xor     bh, bh
    mov     bl, al
    and     bl, 0x7F            ; bx = scan code
    shr     al, 7               ; al = 0 if pressed, 1 if released
    xor     al, 1               ; al = 1 if pressed, 0 if released
    
    ; bl is offset in bytes from kdbuff al is value (01 or 00) 
    mov        byte[kbdbuf+bx], al

    ; send EOI to XT keyboard
    in      al, 0x61
    mov     ah, al
    or      al, 0x80
    out     0x61, al
    mov     al, ah
    out     0x61, al

    ; send EOI to master PIC
    mov     al, 0x20
    out     0x20, al

    popa
    iret
 
; Some KeyInfo : 
; Z             = 11
; X             = 2D
; Left Arrow    = 4B
; Right Arrow   = 4D
; Down Arrow    = 50
; Up   Arrow    = 48
; Left Arrow    = 4B
; Space         = 39
; Escape button = 01
; +             = E4
; -             = A4
; Enter         = 1C
kbdbuf:
    times   128 db 0
