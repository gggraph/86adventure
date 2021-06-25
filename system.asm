WAIT_MS:
push bp
mov bp,sp 
; bp+4 is number in ms 
; to convert it to millis we need to multiply per 10000 ( max number should be capped to )
mov al, 0
mov ah, 86h
mov cx, 0x4
mov dx, 0x93E0
int 0x15 ;
pop bp
ret;


SETUP_VGA_MODE:
mov ah, 00h
mov al, 13h
int 10h
ret

CLEAR_SCREEN:
push bp
mov bp,sp 
mov ax, [bp+4]
mov bh,  al  ; YellowOnBlue
mov ah, 06h    ; Scroll up function
xor al, al     ; Clear entire screen
xor cx, cx    ; Upper left corner CH=row, CL=column
mov dx, 184FH  ; lower right corner DH=row, DL=column 
int  10H
pop bp
ret 2

randnum dd 1

RAND:
	xor eax, eax
    mov eax, dword[randnum]       ; pass next to eax for multiplication 
    mov ebx, 1103515245   ; the multiplier
    mul ebx               ; eax = eax * ebx
    add eax, 12345        ; the increment 
    mov dword [randnum], eax ; update next value
    mov ebx, 32768        ; the modulus 
    xor edx, edx          ; avoid Floating point exception
    div ebx               ; edx now holds the random number
    ret                   ; bye
TIMERAND:
	push bp
	mov bp, sp
    mov eax, 0x0d         ; sys_time
    mov ebx, 0x0          ; NULL
    int 0x80              ; syscall
	pop bp
    ret                   ; bye


print_word_hex:
    xchg al, ah                 ; Print the high byte first
    call print_byte_hex
    xchg al, ah                 ; Print the low byte second
    call print_byte_hex
    ret

; Function: print_byte_hex
;           Print a 8-bit unsigned integer in hexadecimal on specified
;           page and in a specified color if running in a graphics mode
;
; Inputs:   AL = Unsigned 8-bit integer to print
;           BH = Page number
;           BL = foreground color (graphics modes only)
; Returns:  None
; Clobbers: Mone

print_byte_hex:
    push ax
    push cx
    push bx

    lea bx, [.table]            ; Get translation table address

    ; Translate each nibble to its ASCII equivalent
    mov ah, al                  ; Make copy of byte to print
    and al, 0x0f                ;     Isolate lower nibble in AL
    mov cl, 4
    shr ah, cl                  ; Isolate the upper nibble in AH
    xlat                        ; Translate lower nibble to ASCII
    xchg ah, al
    xlat                        ; Translate upper nibble to ASCII

    pop bx                      ; Restore attribute and page
    mov ch, ah                  ; Make copy of lower nibble
    mov ah, 0x0e
    int 0x10                    ; Print the high nibble
    mov al, ch
    int 0x10                    ; Print the low nibble

    pop cx
    pop ax
    ret
.table: db "0123456789ABCDEF", 0