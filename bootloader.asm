org 0x7C00   ; add 0x7C00 to label addresses
bits 16      ; tell the assembler we want 16 bit code

; just reset reg like always

xor ax, ax  ; set up segments ; xor is always faster than mov ax, 0 or so
mov ds, ax
mov es, ax
mov ss, ax     ; setup stack
mov sp, 0x7C00 ; stack grows downwards from 0x7C00


; set up es:bx memory addresss/segment:offset to load sector(s) into 
mov bx,0x1000 ; load sector to memory address 0x1000
mov es, bx    ; es = 0x1000
mov bx, 0; es:bx = 0x1000: 0 

;set up disk read
mov dh, 0x0 ; head 0
mov dl, 0x0 ; drive 0
mov ch, 0x0  ; drive 0 
mov cl, 0x02 ; starting sector to read from disk


read_disk:
mov ah, 0x02 ; bios int 13h, ah=2
mov al, 0x05 ; number of sectors to read ; the max is 72 .... but it will fail if file is less than size
int 0x13

jc read_disk ; retry if disk read do error 



; reset segment registers for RAM
mov ax, 0x1000
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

jmp 0x1000:0x0


;include 'loaddisk.asm' ; include here load disk asm

end:
jmp end

times 510-($-$$) db 0 ; fill 0 of what it left 
dw 0AA55h ; some BIOSes require this signature ; do the signature for the bioses
