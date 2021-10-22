nasm bootloader.asm -f bin -o bootloader.bin
PAUSE
nasm kernel.asm -f bin -o kernel.bin
PAUSE
COPY /B bootloader.bin + kernel.bin disk.bin
PAUSE
qemu-system-x86_64.exe -fda disk.bin -soundhw pcspk