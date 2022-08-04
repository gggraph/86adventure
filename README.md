# 86adventure
![](git-content/intro.gif)

X86adventure is a **light kernel** (bootloader included) for **x86-64** microprocessor working in **real mode**.

It provides a **graphic library** (13h vga mode)  allowing you to:

1 : Draw generic shapes ( lines, rectangles, triangles, circles ...)

2 : Draw all bitmap format (32bit, 16bit, 8bit indexed-color, monochrome...)

3 : Print text with your own bitmap font!

4 : Draw sprites from spritesheet.



## About the demo 

The demo includes a **realtime map and sprite editors** and a basic menu screen.

You can make default map and spritesheet using mapeditor.exe (save them clicking on save 8bit buttons, then copy binary data below related label in kernel.asm).

You can use byte2nasmdef.exe to convert binary file data to its NASM definition, (typing path of the file). 
 
### Making custom spritesheet
![](git-content/spediting.gif)

### Building level
![](git-content/mapediting.gif)

### Post-Proccessing
![](git-content/postproc.gif)

## Boot it on real hardware! 

- Convert .asm files to binary using nasm, or run launch.bat (for windows users). 

- Run sectorpadding.exe to make **disk.bin size multiple of 512 bytes**. Output is **usb.bin**
 
**Make sure sector numbers equal al value at int 13h, ah 0x02 instructions (line 66 of bootloader.asm)** 
 
- Write usb.bin to usb drive starting from sector 0 (use a software like HDDRawCopy).

- Restart your computer. 


