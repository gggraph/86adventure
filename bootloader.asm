org 0x7C00
;Note that the jump and NOP are part of the BPB
jmp short start
nop


; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette
OEMLabel		db "Example "	; Disk label
BytesPerSector		dw 512		; Bytes per sector
SectorsPerCluster	db 1		; Sectors per cluster
ReservedForBoot		dw 1		; Reserved sectors for boot record
NumberOfFats		db 2		; Number of copies of the FAT
RootDirEntries		dw 224		; Number of entries in root dir
; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors		dw 2880		; Number of logical sectors
MediumByte		db 0F0h		; Medium descriptor byte
SectorsPerFat		dw 9		; Sectors per FAT
SectorsPerTrack		dw 18		; >>>>> Nombre de secteurs par piste ( il y a 36 pistes par cylindre), nous avons donc ici 648 secteur par cylindre, soit 331776 octets 
Sides			dw 2		    ; Number of sides/heads
HiddenSectors		dd 0		; Number of hidden sectors
LargeSectors		dd 0		; Number of LBA sectors
; MikeOS's bootloader didn't mention this but the FAT12/FAT16 extension starts here
DriveNo			dw 0		; Drive No: 0
Signature		db 41		; Drive signature: 41 for floppy
VolumeID		dd 00000000h	; Volume ID: any number
VolumeLabel		db "Example    "; Volume Label: any 11 chars
FileSystem		db "FAT12   "	; File system type: don't change!
start: 
; ------------------------------------------------------------------

;Reset disk system
mov ah, 0
int 0x13 ; 0x13 ah=0 dl = drive number
; just reset reg like always


xor ax, ax
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

mov sp, 0x7C00 ; stack grows downwards from 0x7C00

;push 36
;jmp BOOT_EXTENDED
boothere:

; set up es:bx memory addresss/segment:offset to load sector(s) into 
mov bx,0x1000 ; load sector to memory address 0x1000
mov es, bx    ; es = 0x1000
mov bx, 0; es:bx = 0x1000: 0 

;set up disk read
mov dh, 0x0 ; head 0
mov dl, 0x0 ; drive 0
mov ch, 0x0  ; cylinder 0 
mov cl, 0x02 ; starting from sector 2  

read_disk:
mov ah, 0x02 ; bios int 13h, ah=2
mov al, 56; max is 123 
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


end:
jmp end

times 510-($-$$) db 0 ; fill sector 0
dw 0AA55h ; bios signature